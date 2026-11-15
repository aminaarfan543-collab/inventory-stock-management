<?php
// Simple debug file — admin login fix
header('Content-Type: application/json; charset=utf-8');

// ============================================
// Database settings
// ============================================
 $db_host = 'localhost';
 $db_name = 'inventory_db';      // <-- apna actual DB naam likhein
 $db_user = 'root';
 $db_pass = '';

// ============================================
// Connection test
// ============================================
try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name;charset=utf8mb4", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    die(json_encode([
        'error' => 'Database connection failed',
        'reason' => $e->getMessage(),
    ], JSON_PRETTY_PRINT));
}

// ============================================
// TABLE STRUCTURE CHECK KAREIN
// ============================================
 $stmt = $pdo->query("DESCRIBE users");
 $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
 $column_names = array_column($columns, 'Field');

// Auto-detect: koi bhi column jo 'name', 'user', 'login', 'email' pattern match kare
 $username_col = null;
 $password_col = null;
foreach ($column_names as $col) {
    $lower = strtolower($col);
    if ($username_col === null) {
        if (in_array($lower, ['username', 'user_name', 'user', 'login', 'name', 'email', 'user_id'])) {
            $username_col = $col;
        }
    }
    if ($password_col === null) {
        if (in_array($lower, ['password_hash', 'password', 'pass', 'pwd', 'user_password', 'hash'])) {
            $password_col = $col;
        }
    }
}

if (!$username_col || !$password_col) {
    die(json_encode([
        'error' => 'Cannot auto-detect column names',
        'all_columns' => $column_names,
        'hint' => 'Send me this list. I need to know which column stores username and which stores password.'
    ], JSON_PRETTY_PRINT));
}

// ============================================
// ADMIN USER CREATE YA UPDATE KAREIN
// ============================================
 $correct_hash = password_hash('admin123', PASSWORD_DEFAULT);

// Check karein admin exist karta hai
 $stmt = $pdo->prepare("SELECT * FROM users WHERE $username_col = 'admin'");
 $stmt->execute();
 $existing = $stmt->fetch(PDO::FETCH_ASSOC);

if ($existing) {
    $stmt = $pdo->prepare("UPDATE users SET $password_col = ? WHERE $username_col = 'admin'");
    $stmt->execute([$correct_hash]);
    $action = 'updated';
} else {
    // Naya admin create karein — sirf zaroori columns set karein
    $other_cols = array_diff($column_names, [$username_col, $password_col, 'id', 'created_at']);
    $insert_cols = [$username_col, $password_col];
    $insert_vals = ['admin', $correct_hash];

    // Agar 'full_name' ya 'name' column hai to us mein bhi value daal dein
    if (in_array('full_name', $column_names)) {
        $insert_cols[] = 'full_name';
        $insert_vals[] = 'Store Manager';
    } elseif (in_array('name', $column_names) && $username_col !== 'name') {
        $insert_cols[] = 'name';
        $insert_vals[] = 'Store Manager';
    }
    if (in_array('email', $column_names) && $username_col !== 'email') {
        $insert_cols[] = 'email';
        $insert_vals[] = 'admin@store.com';
    }

    $placeholders = implode(',', array_fill(0, count($insert_cols), '?'));
    $cols_str = implode(',', $insert_cols);

    $stmt = $pdo->prepare("INSERT INTO users ($cols_str) VALUES ($placeholders)");
    $stmt->execute($insert_vals);
    $action = 'created';
}

// ============================================
// VERIFY KAREIN
// ============================================
 $stmt = $pdo->prepare("SELECT * FROM users WHERE $username_col = 'admin'");
 $stmt->execute();
 $final_admin = $stmt->fetch(PDO::FETCH_ASSOC);

 $verify_result = password_verify('admin123', $final_admin[$password_col]);

// ============================================
// FINAL OUTPUT
// ============================================
echo json_encode([
    'status' => 'success',
    'database' => $db_name,
    'detected_username_column' => $username_col,
    'detected_password_column' => $password_col,
    'all_columns' => $column_names,
    'admin_action' => $action,
    'hash_set' => $correct_hash,
    'verify_admin123_works' => $verify_result ? 'YES' : 'NO',
    'final_message' => $verify_result
        ? 'Login should work now. Username: admin, Password: admin123'
        : 'Still failing. Send me this JSON output.',
    'important_note' => 'Apne index.php mein bhi same column naam use karein. Abhi index.php mein "username" likha hai, usay "' . $username_col . '" se replace kar dein. Aur "password_hash" ko "' . $password_col . '" se replace kar dein.'
], JSON_PRETTY_PRINT);