<?php
// tracks.php
require_once __DIR__ . '/db.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Authorization, Content-Type");
header("Access-Control-Allow-Methods: GET, OPTIONS");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

$db = getDB();

// Determine optional authenticated user to show favorite status
$currentUserId = null;
$headers = getallheaders();
$token = null;
if (isset($headers['Authorization']) && preg_match('/Bearer\s(\S+)/', $headers['Authorization'], $matches)) {
    $token = $matches[1];
} elseif (isset($_GET['token'])) {
    $token = $_GET['token'];
}

if ($token) {
    $stmt = $db->prepare("SELECT user_id FROM sessions WHERE token = ? AND expires_at > datetime('now')");
    $stmt->execute([$token]);
    $session = $stmt->fetch();
    if ($session) {
        $currentUserId = $session['user_id'];
    }
}

$search = trim($_GET['q'] ?? '');
$filterFavorites = isset($_GET['favorites']) && $_GET['favorites'] == 1;

$params = [];
$query = "SELECT t.*, u.username as uploader ";

if ($currentUserId) {
    $query .= ", (CASE WHEN f.user_id IS NOT NULL THEN 1 ELSE 0 END) as is_favorite ";
} else {
    $query .= ", 0 as is_favorite ";
}

$query .= "FROM tracks t ";
$query .= "JOIN users u ON t.user_id = u.id ";

if ($currentUserId) {
    $query .= "LEFT JOIN favorites f ON t.id = f.track_id AND f.user_id = ? ";
    $params[] = $currentUserId;
}

$whereClauses = [];

if ($filterFavorites && $currentUserId) {
    // If filtering by favorites, we can just require a match in favorites table
    if ($currentUserId) {
        $whereClauses[] = "f.user_id IS NOT NULL";
    }
}

if (!empty($search)) {
    $whereClauses[] = "(t.title LIKE ? OR t.artist LIKE ? OR t.album LIKE ?)";
    $searchWildcard = "%" . $search . "%";
    $params[] = $searchWildcard;
    $params[] = $searchWildcard;
    $params[] = $searchWildcard;
}

if (count($whereClauses) > 0) {
    $query .= " WHERE " . implode(" AND ", $whereClauses);
}

$query .= " ORDER BY t.id DESC";

try {
    $stmt = $db->prepare($query);
    $stmt->execute($params);
    $tracks = $stmt->fetchAll();
    
    // Normalize URL paths to absolute or server-relative paths
    // e.g. cover_path -> "http://ip/uploads/covers/xxx.webp"
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'];
    $baseUrl = $protocol . '://' . $host . dirname($_SERVER['SCRIPT_NAME']);
    // Clean trailing slash
    $baseUrl = rtrim($baseUrl, '/\\');

    foreach ($tracks as &$track) {
        if ($track['cover_path']) {
            $track['cover_url'] = $baseUrl . '/' . $track['cover_path'];
        } else {
            // Default placeholder if no cover uploaded
            $track['cover_url'] = null;
        }
        $track['audio_url'] = $baseUrl . '/' . $track['audio_path'];
        // Cast integer fields
        $track['id'] = (int)$track['id'];
        $track['user_id'] = (int)$track['user_id'];
        $track['duration'] = (int)$track['duration'];
        $track['is_favorite'] = (int)$track['is_favorite'];
    }
    
    sendJSON($tracks);
} catch (Exception $e) {
    sendJSON(['error' => 'Database error: ' . $e->getMessage()], 500);
}
