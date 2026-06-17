<?php
// auth.php
require_once __DIR__ . '/db.php';

// Handle CORS
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Authorization, Content-Type");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

$db = getDB();

// Ensure DB is initialized
initDB();

$action = $_GET['action'] ?? '';

if ($action === 'register') {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendJSON(['error' => 'Method not allowed'], 405);
    }
    
    // Get JSON body
    $data = json_decode(file_get_contents('php://input'), true);
    $username = trim($data['username'] ?? '');
    $password = $data['password'] ?? '';
    
    if (strlen($username) < 3 || strlen($password) < 6) {
        sendJSON(['error' => 'Username must be >= 3 chars, password >= 6 chars'], 400);
    }
    
    // Check if user exists
    $stmt = $db->prepare("SELECT id FROM users WHERE username = ?");
    $stmt->execute([$username]);
    if ($stmt->fetch()) {
        sendJSON(['error' => 'Username already exists'], 409);
    }
    
    $passwordHash = password_hash($password, PASSWORD_DEFAULT);
    $stmt = $db->prepare("INSERT INTO users (username, password_hash) VALUES (?, ?)");
    try {
        $stmt->execute([$username, $passwordHash]);
        sendJSON(['message' => 'Registration successful'], 201);
    } catch (Exception $e) {
        sendJSON(['error' => 'Registration failed: ' . $e->getMessage()], 500);
    }
} 

elseif ($action === 'login') {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendJSON(['error' => 'Method not allowed'], 405);
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    $username = trim($data['username'] ?? '');
    $password = $data['password'] ?? '';
    
    $stmt = $db->prepare("SELECT id, username, password_hash, avatar_path FROM users WHERE username = ?");
    $stmt->execute([$username]);
    $user = $stmt->fetch();
    
    if (!$user || !password_verify($password, $user['password_hash'])) {
        sendJSON(['error' => 'Invalid username or password'], 401);
    }
    
    // Create session token
    $token = bin2hex(random_bytes(32));
    // Expire in 30 days
    $expiresAt = date('Y-m-d H:i:s', strtotime('+30 days'));
    
    $stmt = $db->prepare("INSERT INTO sessions (token, user_id, expires_at) VALUES (?, ?, ?)");
    $stmt->execute([$token, $user['id'], $expiresAt]);
    
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'];
    $baseUrl = $protocol . '://' . $host . dirname($_SERVER['SCRIPT_NAME']);
    $baseUrl = rtrim($baseUrl, '/\\');
    
    $avatarUrl = $user['avatar_path'] ? $baseUrl . '/' . $user['avatar_path'] : null;
    
    sendJSON([
        'message' => 'Login successful',
        'token' => $token,
        'user' => [
            'id' => $user['id'],
            'username' => $user['username'],
            'avatar_url' => $avatarUrl
        ]
    ]);
} 

elseif ($action === 'me') {
    // Return current authenticated user
    $user = getAuthenticatedUser();
    
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'];
    $baseUrl = $protocol . '://' . $host . dirname($_SERVER['SCRIPT_NAME']);
    $baseUrl = rtrim($baseUrl, '/\\');
    
    $user['avatar_url'] = $user['avatar_path'] ? $baseUrl . '/' . $user['avatar_path'] : null;
    sendJSON(['user' => $user]);
} 

elseif ($action === 'logout') {
    $headers = getallheaders();
    $token = null;
    if (isset($headers['Authorization']) && preg_match('/Bearer\s(\S+)/', $headers['Authorization'], $matches)) {
        $token = $matches[1];
    }
    
    if ($token) {
        $stmt = $db->prepare("DELETE FROM sessions WHERE token = ?");
        $stmt->execute([$token]);
    }
    
    sendJSON(['message' => 'Logged out successfully']);
} 

elseif ($action === 'update_avatar') {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendJSON(['error' => 'Method not allowed'], 405);
    }
    
    $user = getAuthenticatedUser();
    
    if (!isset($_FILES['avatar']) || $_FILES['avatar']['error'] !== UPLOAD_ERR_OK) {
        sendJSON(['error' => 'No avatar file uploaded'], 400);
    }
    
    $ext = pathinfo($_FILES['avatar']['name'], PATHINFO_EXTENSION);
    if (empty($ext)) $ext = 'jpg';
    $fileName = 'avatar_' . $user['id'] . '_' . uniqid('', true) . '.' . $ext;
    
    $targetDir = __DIR__ . '/uploads/avatars/';
    if (!is_dir($targetDir)) {
        mkdir($targetDir, 0777, true);
    }
    
    $targetFile = $targetDir . $fileName;
    if (move_uploaded_file($_FILES['avatar']['tmp_name'], $targetFile)) {
        $avatarPath = 'uploads/avatars/' . $fileName;
        
        // Update database
        $stmt = $db->prepare("UPDATE users SET avatar_path = ? WHERE id = ?");
        $stmt->execute([$avatarPath, $user['id']]);
        
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
        $host = $_SERVER['HTTP_HOST'];
        $baseUrl = $protocol . '://' . $host . dirname($_SERVER['SCRIPT_NAME']);
        $baseUrl = rtrim($baseUrl, '/\\');
        
        sendJSON([
            'message' => 'Avatar updated successfully',
            'avatar_url' => $baseUrl . '/' . $avatarPath
        ]);
    } else {
        sendJSON(['error' => 'Failed to save avatar image'], 500);
    }
}

else {
    sendJSON(['error' => 'Invalid action'], 400);
}
