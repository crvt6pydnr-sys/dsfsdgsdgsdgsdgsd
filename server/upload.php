<?php
// upload.php
require_once __DIR__ . '/db.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Authorization, Content-Type");
header("Access-Control-Allow-Methods: POST, OPTIONS");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

$user = getAuthenticatedUser();
$db = getDB();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendJSON(['error' => 'Method not allowed'], 405);
}

// Basic text fields
$title = trim($_POST['title'] ?? '');
$artist = trim($_POST['artist'] ?? '');
$album = trim($_POST['album'] ?? '');
$lyrics = trim($_POST['lyrics'] ?? '');

if (empty($title) || empty($artist)) {
    sendJSON(['error' => 'Title and artist are required'], 400);
}

// Check for audio file
if (!isset($_FILES['audio']) || $_FILES['audio']['error'] !== UPLOAD_ERR_OK) {
    sendJSON(['error' => 'Valid audio file is required'], 400);
}

$audioFile = $_FILES['audio'];

// Create directories if they don't exist
$uploadsDir = __DIR__ . '/uploads';
$audioDir = $uploadsDir . '/audio';
$coverDir = $uploadsDir . '/covers';

if (!is_dir($uploadsDir)) mkdir($uploadsDir, 0755, true);
if (!is_dir($audioDir)) mkdir($audioDir, 0755, true);
if (!is_dir($coverDir)) mkdir($coverDir, 0755, true);

// Create unique filenames
$fileId = uniqid('track_', true);
$tempAudioPath = $audioFile['tmp_name'];
$finalAudioName = $fileId . '.opus';
$finalAudioPath = $audioDir . '/' . $finalAudioName;

// --- STEP 1: Process Audio with FFmpeg (Transcode to Opus) ---
// We convert to Opus at 160kbps which is high-quality and extremely compact
$cmd = sprintf("ffmpeg -y -i %s -c:a libopus -b:a 160k %s 2>&1", escapeshellarg($tempAudioPath), escapeshellarg($finalAudioPath));
exec($cmd, $output, $returnCode);

if ($returnCode !== 0) {
    sendJSON(['error' => 'Failed to compress audio file. FFmpeg exit code: ' . $returnCode, 'details' => implode("\n", $output)], 500);
}

// Get duration using ffprobe
$ffprobeCmd = sprintf("ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 %s 2>&1", escapeshellarg($finalAudioPath));
exec($ffprobeCmd, $durationOutput, $durationReturnCode);
$duration = 0;
if ($durationReturnCode === 0 && !empty($durationOutput)) {
    $duration = (int)round(floatval($durationOutput[0]));
}

// --- STEP 2: Process Cover Image (Crop to Square and Save as WebP) ---
$coverPathDB = null;
if (isset($_FILES['cover']) && $_FILES['cover']['error'] === UPLOAD_ERR_OK) {
    $coverFile = $_FILES['cover'];
    $tempCoverPath = $coverFile['tmp_name'];
    $finalCoverName = $fileId . '.jpg';
    $finalCoverPath = $coverDir . '/' . $finalCoverName;
    
    if (processCoverImage($tempCoverPath, $finalCoverPath, 300)) {
        // Relative path for database
        $coverPathDB = 'uploads/covers/' . $finalCoverName;
    }
}

// Relative path for audio in DB
$audioPathDB = 'uploads/audio/' . $finalAudioName;

// --- STEP 3: Insert into DB ---
$stmt = $db->prepare("
    INSERT INTO tracks (user_id, title, artist, album, lyrics, cover_path, audio_path, duration)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
");

try {
    $stmt->execute([
        $user['id'],
        $title,
        $artist,
        $album,
        $lyrics,
        $coverPathDB,
        $audioPathDB,
        $duration
    ]);
    
    sendJSON([
        'message' => 'Track uploaded and compressed successfully',
        'track' => [
            'id' => $db->lastInsertId(),
            'title' => $title,
            'artist' => $artist,
            'album' => $album,
            'lyrics' => $lyrics,
            'cover_path' => $coverPathDB,
            'audio_path' => $audioPathDB,
            'duration' => $duration
        ]
    ], 201);
} catch (Exception $e) {
    sendJSON(['error' => 'Database error while saving track: ' . $e->getMessage()], 500);
}

// --- HELPER FUNCTION: Process Image (Crop to square, resize to 300x300, save WebP) ---
function processCoverImage($src, $dst, $size = 300) {
    $info = getimagesize($src);
    if ($info === false) {
        return false;
    }
    
    $mime = $info['mime'];
    switch ($mime) {
        case 'image/jpeg':
            $srcImg = imagecreatefromjpeg($src);
            break;
        case 'image/png':
            $srcImg = imagecreatefrompng($src);
            break;
        case 'image/webp':
            $srcImg = imagecreatefromwebp($src);
            break;
        default:
            return false;
    }
    
    if (!$srcImg) {
        return false;
    }
    
    $width = imagesx($srcImg);
    $height = imagesy($srcImg);
    
    // Crop to square
    $cropSize = min($width, $height);
    $x = (int)(($width - $cropSize) / 2);
    $y = (int)(($height - $cropSize) / 2);
    
    // Create new square image
    $dstImg = imagecreatetruecolor($size, $size);
    
    // Keep transparency for PNG/WebP conversions
    imagealphablending($dstImg, false);
    imagesavealpha($dstImg, true);
    
    // Resample/resize
    imagecopyresampled($dstImg, $srcImg, 0, 0, $x, $y, $size, $size, $cropSize, $cropSize);
    
    // Save as JPEG
    $success = imagejpeg($dstImg, $dst, 90); // 85% quality is visually lossless
    
    imagedestroy($srcImg);
    imagedestroy($dstImg);
    
    return $success;
}
