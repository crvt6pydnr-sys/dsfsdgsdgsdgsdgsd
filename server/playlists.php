<?php
// playlists.php
require_once __DIR__ . '/db.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Authorization, Content-Type");
header("Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

$user = getAuthenticatedUser();
$db = getDB();

$action = $_GET['action'] ?? '';
$playlistId = isset($_GET['playlist_id']) ? (int)$_GET['playlist_id'] : 0;

$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'];
$baseUrl = $protocol . '://' . $host . dirname($_SERVER['SCRIPT_NAME']);
$baseUrl = rtrim($baseUrl, '/\\');

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // 1. Get tracks of a specific playlist
    if ($playlistId > 0) {
        $stmt = $db->prepare("SELECT id, name, cover_path, user_id FROM playlists WHERE id = ?");
        $stmt->execute([$playlistId]);
        $playlist = $stmt->fetch();
        if (!$playlist) {
            sendJSON(['error' => 'Playlist not found or access denied'], 404);
        }

        if ($playlist['cover_path']) {
            $playlist['cover_url'] = $baseUrl . '/' . $playlist['cover_path'];
        } else {
            $playlist['cover_url'] = null;
        }

        // Fetch tracks
        $query = "
            SELECT t.*, u.username as uploader, 
            (CASE WHEN f.user_id IS NOT NULL THEN 1 ELSE 0 END) as is_favorite
            FROM playlist_tracks pt
            JOIN tracks t ON pt.track_id = t.id
            JOIN users u ON t.user_id = u.id
            LEFT JOIN favorites f ON t.id = f.track_id AND f.user_id = ?
            WHERE pt.playlist_id = ?
            ORDER BY pt.created_at ASC
        ";
        
        try {
            $stmt = $db->prepare($query);
            $stmt->execute([$user['id'], $playlistId]);
            $tracks = $stmt->fetchAll();

            foreach ($tracks as &$track) {
                if ($track['cover_path']) {
                    $track['cover_url'] = $baseUrl . '/' . $track['cover_path'];
                } else {
                    $track['cover_url'] = null;
                }
                $track['audio_url'] = $baseUrl . '/' . $track['audio_path'];
                $track['id'] = (int)$track['id'];
                $track['user_id'] = (int)$track['user_id'];
                $track['duration'] = (int)$track['duration'];
                $track['is_favorite'] = (int)$track['is_favorite'];
            }
            sendJSON([
                'playlist' => $playlist,
                'tracks' => $tracks
            ]);
        } catch (Exception $e) {
            sendJSON(['error' => 'Database error: ' . $e->getMessage()], 500);
        }
    } 
    // 2. List or Search playlists
    else {
        $search = trim($_GET['q'] ?? '');
        if ($search !== '') {
            // Search all matching playlists across all users
            $stmt = $db->prepare("SELECT p.*, u.username as creator FROM playlists p JOIN users u ON p.user_id = u.id WHERE p.name LIKE ? ORDER BY p.id DESC");
            $stmt->execute(['%' . $search . '%']);
        } else {
            // Default: own playlists
            $stmt = $db->prepare("SELECT p.*, u.username as creator FROM playlists p JOIN users u ON p.user_id = u.id WHERE p.user_id = ? ORDER BY p.id DESC");
            $stmt->execute([$user['id']]);
        }
        $playlists = $stmt->fetchAll();
        foreach ($playlists as &$playlist) {
            if ($playlist['cover_path']) {
                $playlist['cover_url'] = $baseUrl . '/' . $playlist['cover_path'];
            } else {
                $playlist['cover_url'] = null;
            }
        }
        sendJSON($playlists);
    }
} 

elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Determine input format (multipart vs JSON)
    $contentType = $_SERVER["CONTENT_TYPE"] ?? '';
    if (strpos($contentType, 'multipart/form-data') !== false) {
        $data = $_POST;
        $name = trim($_POST['name'] ?? '');
    } else {
        $data = json_decode(file_get_contents('php://input'), true);
        $name = trim($data['name'] ?? '');
    }

    // 1. Add track to playlist
    if ($action === 'add_track') {
        $pId = isset($data['playlist_id']) ? (int)$data['playlist_id'] : 0;
        $tId = isset($data['track_id']) ? (int)$data['track_id'] : 0;
        
        if ($pId <= 0 || $tId <= 0) {
            sendJSON(['error' => 'Invalid parameters'], 400);
        }
        
        // Verify ownership
        $stmt = $db->prepare("SELECT 1 FROM playlists WHERE id = ? AND user_id = ?");
        $stmt->execute([$pId, $user['id']]);
        if (!$stmt->fetch()) {
            sendJSON(['error' => 'Playlist not found or access denied'], 404);
        }

        // Insert track relation (ignore if already added)
        try {
            $stmt = $db->prepare("INSERT OR IGNORE INTO playlist_tracks (playlist_id, track_id) VALUES (?, ?)");
            $stmt->execute([$pId, $tId]);
            sendJSON(['message' => 'Track added to playlist successfully']);
        } catch (Exception $e) {
            sendJSON(['error' => 'Database error: ' . $e->getMessage()], 500);
        }
    } 
    // 2. Remove track from playlist
    elseif ($action === 'remove_track') {
        $pId = isset($data['playlist_id']) ? (int)$data['playlist_id'] : 0;
        $tId = isset($data['track_id']) ? (int)$data['track_id'] : 0;
        
        if ($pId <= 0 || $tId <= 0) {
            sendJSON(['error' => 'Invalid parameters'], 400);
        }
        
        // Verify ownership
        $stmt = $db->prepare("SELECT 1 FROM playlists WHERE id = ? AND user_id = ?");
        $stmt->execute([$pId, $user['id']]);
        if (!$stmt->fetch()) {
            sendJSON(['error' => 'Playlist not found or access denied'], 404);
        }

        try {
            $stmt = $db->prepare("DELETE FROM playlist_tracks WHERE playlist_id = ? AND track_id = ?");
            $stmt->execute([$pId, $tId]);
            sendJSON(['message' => 'Track removed from playlist successfully']);
        } catch (Exception $e) {
            sendJSON(['error' => 'Database error: ' . $e->getMessage()], 500);
        }
    } 
    // 3. Create playlist
    else {
        if (empty($name)) {
            sendJSON(['error' => 'Playlist name is required'], 400);
        }
        
        // Process optional cover upload
        $coverPath = null;
        if (isset($_FILES['cover']) && $_FILES['cover']['error'] === UPLOAD_ERR_OK) {
            $ext = pathinfo($_FILES['cover']['name'], PATHINFO_EXTENSION);
            if (empty($ext)) $ext = 'jpg';
            $fileName = 'playlist_' . uniqid('', true) . '.' . $ext;
            $targetDir = __DIR__ . '/uploads/covers/';
            if (!is_dir($targetDir)) {
                mkdir($targetDir, 0777, true);
            }
            $targetFile = $targetDir . $fileName;
            if (move_uploaded_file($_FILES['cover']['tmp_name'], $targetFile)) {
                $coverPath = 'uploads/covers/' . $fileName;
            }
        }
        
        try {
            $stmt = $db->prepare("INSERT INTO playlists (user_id, name, cover_path) VALUES (?, ?, ?)");
            $stmt->execute([$user['id'], $name, $coverPath]);
            $insertedId = $db->lastInsertId();
            sendJSON([
                'message' => 'Playlist created successfully',
                'playlist' => [
                    'id' => $insertedId,
                    'name' => $name,
                    'user_id' => $user['id'],
                    'cover_url' => $coverPath ? ($baseUrl . '/' . $coverPath) : null
                ]
            ], 201);
        } catch (Exception $e) {
            sendJSON(['error' => 'Database error: ' . $e->getMessage()], 500);
        }
    }
} 

elseif ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    $data = json_decode(file_get_contents('php://input'), true);
    $pId = isset($data['playlist_id']) ? (int)$data['playlist_id'] : 0;
    
    if ($pId <= 0) {
        sendJSON(['error' => 'Invalid playlist ID'], 400);
    }
    
    // Verify ownership
    $stmt = $db->prepare("SELECT 1 FROM playlists WHERE id = ? AND user_id = ?");
    $stmt->execute([$pId, $user['id']]);
    if (!$stmt->fetch()) {
        sendJSON(['error' => 'Playlist not found or access denied'], 404);
    }
    
    try {
        $stmt = $db->prepare("DELETE FROM playlists WHERE id = ?");
        $stmt->execute([$pId]);
        sendJSON(['message' => 'Playlist deleted successfully']);
    } catch (Exception $e) {
        sendJSON(['error' => 'Database error: ' . $e->getMessage()], 500);
    }
} 

else {
    sendJSON(['error' => 'Method not allowed'], 405);
}
?>
