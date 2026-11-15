<?php
header('Content-Type: application/json; charset=utf-8');

// Database settings (same as index.php)
 $host = 'localhost';
 $dbname = 'inventory_db';
 $user = 'root';
 $pass = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    die(json_encode(['error' => 'DB failed: ' . $e->getMessage()]));
}

// admin123 ka fresh hash banayein
 $password = 'admin123';
 $hash = password_hash($password, PASSWORD_DEFAULT);

// Check karein admin already exist karta hai ya nahi
 $stmt = $pdo->prepare('SELECT id FROM users WHERE username = ?');
 $stmt->execute(['admin']);
 $existing = $stmt->fetch(PDO::FETCH_ASSOC);

if ($existing) {
    // Update karein
    $stmt = $pdo->prepare('UPDATE users SET password_hash = ?, full_name = ? WHERE username = ?');
    $stmt->execute([$hash, 'Store Manager', 'admin']);
    echo json_encode([
        'status' => 'updated',
        'message' => 'Admin password updated successfully!',
        'username' => 'admin',
        'password' => 'admin123',
        'new_hash' => $hash,
    ]);
} else {
    // Naya admin user banayein
    $stmt = $pdo->prepare('INSERT INTO users (username, password_hash, full_name, email) VALUES (?, ?, ?, ?)');
    $stmt->execute(['admin', $hash, 'Store Manager', 'admin@store.com']);
    echo json_encode([
        'status' => 'created',
        'message' => 'Admin user created successfully!',
        'username' => 'admin',
        'password' => 'admin123',
        'new_hash' => $hash,
    ]);
}