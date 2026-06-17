<?php
// favorites.php
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

$data = json_decode(file_get_contents('php://input'), true);
$trackId = isset($data['track_id']) ? (int)$data['track_id'] : 0;

if ($trackId <= 0) {
    sendJSON(['error' => 'Invalid track ID'], 400);
}

// Check if track exists
$stmt = $db->prepare("SELECT id FROM tracks WHERE id = ?");
$stmt->execute([$trackId]);
if (!$stmt->fetch()) {
    sendJSON(['error' => 'Track not found'], 44);
}

// Toggle favorite
$stmt = $db->prepare("SELECT 1 FROM favorites WHERE user_id = ? AND track_id = ?");
$stmt->execute([$user['id'], $trackId]);
$isFavorite = $stmt->fetch();

if ($isFavorite) {
    // Already favorite, remove it
    $stmt = $db->prepare("DELETE FROM favorites WHERE user_id = ? AND track_id = ?");
    $stmt->execute([$user['id'], $trackId]);
    sendJSON(['message' => 'Removed from favorites', 'is_favorite' => 0]);
} else {
    // Add to favorites
    $stmt = $db->prepare("INSERT INTO favorites (user_id, track_id) VALUES (?, ?)");
    $stmt->execute([$user['id'], $trackId]);
    sendJSON(['message' => 'Added to favorites', 'is_favorite' => 1]);
}
