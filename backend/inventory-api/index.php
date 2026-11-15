<?php
// ============================================
// CORS Headers
// ============================================
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ============================================
// Config file (database connection)
// ============================================
require __DIR__ . '/config.php';

header('Content-Type: application/json; charset=utf-8');

// ============================================
// Helper functions
// ============================================
function send($data) {
    echo json_encode($data);
    exit;
}

function ok($extra = []) {
    send(array_merge(['success' => true], $extra));
}

function fail($message, $code = 400) {
    http_response_code($code);
    send(['success' => false, 'message' => $message]);
}

function getInput() {
    return json_decode(file_get_contents('php://input'), true) ?? [];
}

// ============================================
// Auto-create sessions table (agar pehle se nahi hai)
// ============================================
 $pdo->exec("CREATE TABLE IF NOT EXISTS sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token_hash CHAR(64) UNIQUE NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
)");

// ============================================
// Auto-create admin user (admin / admin123)
// Har baar file load hone par password refresh hoga
// ============================================
 $stmt = $pdo->prepare("SELECT id FROM users WHERE name = 'admin'");
 $stmt->execute();
 $adminExists = $stmt->fetch();

if (!$adminExists) {
    $stmt = $pdo->prepare("INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)");
    $stmt->execute([
        'admin',
        'admin@inventory.com',
        password_hash('admin123', PASSWORD_DEFAULT)
    ]);
} else {
    // Make sure password is admin123
    $stmt = $pdo->prepare("UPDATE users SET password_hash = ? WHERE name = 'admin'");
    $stmt->execute([password_hash('admin123', PASSWORD_DEFAULT)]);
}

// ============================================
// Token helpers
// ============================================
function makeToken($pdo, $userId) {
    $token = bin2hex(random_bytes(32));
    $hash = hash('sha256', $token);
    $stmt = $pdo->prepare("INSERT INTO sessions (user_id, token_hash, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY))");
    $stmt->execute([$userId, $hash]);
    return $token;
}

// ROBUST Authorization header detection
function getAuthorizationHeader() {
    $header = '';

    if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $header = $_SERVER['HTTP_AUTHORIZATION'];
    } elseif (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $header = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
    } elseif (function_exists('getallheaders')) {
        $allHeaders = getallheaders();
        foreach ($allHeaders as $key => $value) {
            if (strtolower($key) === 'authorization') {
                $header = $value;
                break;
            }
        }
    } elseif (getenv('HTTP_AUTHORIZATION')) {
        $header = getenv('HTTP_AUTHORIZATION');
    } elseif (getenv('REDIRECT_HTTP_AUTHORIZATION')) {
        $header = getenv('REDIRECT_HTTP_AUTHORIZATION');
    }

    return $header;
}

function getAuthUser($pdo) {
    $header = getAuthorizationHeader();

    if (empty($header) || !preg_match('/Bearer\s+(.+)/i', $header, $m)) {
        return null;
    }

    $token = trim($m[1]);
    $hash = hash('sha256', $token);

    $stmt = $pdo->prepare("
        SELECT u.id, u.name, u.email
        FROM sessions s
        JOIN users u ON u.id = s.user_id
        WHERE s.token_hash = ? AND s.expires_at > NOW()
    ");
    $stmt->execute([$hash]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) return null;

    return [
        'id' => (int)$user['id'],
        'username' => $user['name'],
        'full_name' => $user['name'],
        'email' => $user['email'],
    ];
}

function requireAuth($pdo) {
    $user = getAuthUser($pdo);
    if (!$user) fail('Login required', 401);
    return $user;
}

// ============================================
// Parse request
// ============================================
 $action = $_GET['action'] ?? '';
 $method = $_SERVER['REQUEST_METHOD'];
 $data = getInput();

// ============================================
// PUBLIC ACTIONS (no auth required)
// ============================================

// HEALTH CHECK
if ($action === 'health') {
    ok(['message' => 'API running']);
}

// ============================================
// LOGIN
// ============================================
if ($action === 'login' && $method === 'POST') {
    $username = trim($data['username'] ?? '');
    $password = $data['password'] ?? '';

    if ($username === '' || $password === '') {
        fail('Username and password required', 422);
    }

    // Login with name OR email
    $stmt = $pdo->prepare("SELECT * FROM users WHERE name = ? OR email = ?");
    $stmt->execute([$username, $username]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user || !password_verify($password, $user['password_hash'])) {
        fail('Invalid username or password', 401);
    }

    $token = makeToken($pdo, $user['id']);

    ok([
        'token' => $token,
        'user' => [
            'id' => (int)$user['id'],
            'username' => $user['name'],
            'full_name' => $user['name'],
            'email' => $user['email'],
        ],
    ]);
}

// ============================================
// REGISTER
// ============================================
if ($action === 'register' && $method === 'POST') {
    $fullName = trim($data['full_name'] ?? '');
    $username = trim($data['username'] ?? '');
    $password = $data['password'] ?? '';

    if ($fullName === '' || $username === '' || strlen($password) < 6) {
        fail('All fields required (password min 6 chars)', 422);
    }

    // Check duplicate username
    $stmt = $pdo->prepare("SELECT id FROM users WHERE name = ?");
    $stmt->execute([$username]);
    if ($stmt->fetch()) fail('Username already taken', 409);

    $stmt = $pdo->prepare("INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)");
    $stmt->execute([$username, '', password_hash($password, PASSWORD_DEFAULT)]);
    $userId = (int)$pdo->lastInsertId();

    $token = makeToken($pdo, $userId);

    ok([
        'token' => $token,
        'user' => [
            'id' => $userId,
            'username' => $username,
            'full_name' => $fullName,
            'email' => '',
        ],
    ]);
}

// ============================================
// LOGOUT
// ============================================
if ($action === 'logout') {
    $header = getAuthorizationHeader();
    if (preg_match('/Bearer\s+(.+)/i', $header, $m)) {
        $hash = hash('sha256', trim($m[1]));
        $stmt = $pdo->prepare("DELETE FROM sessions WHERE token_hash = ?");
        $stmt->execute([$hash]);
    }
    ok([]);
}

// ============================================
// From here onwards — require auth
// ============================================
 $currentUser = requireAuth($pdo);

// ============================================
// ME (current user info)
// ============================================
if ($action === 'me' && $method === 'GET') {
    ok(['user' => $currentUser]);
}

// ============================================
// DASHBOARD STATS
// ============================================
if ($action === 'dashboard_stats') {
    $totalProducts = (int)$pdo->query("SELECT COUNT(*) FROM products")->fetchColumn();
    $totalStock = (int)$pdo->query("SELECT COALESCE(SUM(quantity), 0) FROM products")->fetchColumn();

    // Detect low stock column name
    $lowStockCol = 'min_stock';
    try {
        $pdo->query("SELECT reorder_level FROM products LIMIT 1");
        $lowStockCol = 'reorder_level';
    } catch (PDOException $e) {}

    $stmt = $pdo->prepare("SELECT COUNT(*) FROM products WHERE quantity <= $lowStockCol");
    $stmt->execute();
    $lowStockCount = (int)$stmt->fetchColumn();

    $totalCategories = 0;
    try {
        $totalCategories = (int)$pdo->query("SELECT COUNT(*) FROM categories")->fetchColumn();
    } catch (PDOException $e) {}

    $totalSuppliers = 0;
    try {
        $totalSuppliers = (int)$pdo->query("SELECT COUNT(*) FROM suppliers")->fetchColumn();
    } catch (PDOException $e) {}

    $totalServices = 0;
    try {
        $totalServices = (int)$pdo->query("SELECT COUNT(*) FROM services")->fetchColumn();
    } catch (PDOException $e) {}

    $inventoryValue = 0;
    try {
        $inventoryValue = (float)$pdo->query("SELECT COALESCE(SUM(quantity * cost_price), 0) FROM products")->fetchColumn();
    } catch (PDOException $e) {
        try {
            $inventoryValue = (float)$pdo->query("SELECT COALESCE(SUM(quantity * unit_price), 0) FROM products")->fetchColumn();
        } catch (PDOException $e2) {}
    }

    ok([
        'total_products' => $totalProducts,
        'total_stock' => $totalStock,
        'low_stock_count' => $lowStockCount,
        'total_categories' => $totalCategories,
        'total_suppliers' => $totalSuppliers,
        'total_services' => $totalServices,
        'inventory_value' => $inventoryValue,
    ]);
}

// ============================================
// LOW STOCK PRODUCTS
// ============================================
if ($action === 'get_low_stock') {
    $lowStockCol = 'min_stock';
    try {
        $pdo->query("SELECT reorder_level FROM products LIMIT 1");
        $lowStockCol = 'reorder_level';
    } catch (PDOException $e) {}

    $stmt = $pdo->prepare("
        SELECT p.*, c.name AS category_name
        FROM products p
        LEFT JOIN categories c ON c.id = p.category_id
        WHERE p.quantity <= p.$lowStockCol
        ORDER BY (p.quantity - p.$lowStockCol) ASC, p.name ASC
    ");
    $stmt->execute();
    ok(['products' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
}

// ============================================
// PRODUCTS - LIST
// ============================================
if ($action === 'get_products' && $method === 'GET') {
    $sql = "SELECT p.*, c.name AS category_name, s.name AS supplier_name
            FROM products p
            LEFT JOIN categories c ON c.id = p.category_id
            LEFT JOIN suppliers s ON s.id = p.supplier_id
            WHERE 1=1";
    $params = [];

    if (!empty($_GET['search'])) {
        $sql .= " AND (p.name LIKE ? OR p.sku LIKE ?)";
        $term = '%' . $_GET['search'] . '%';
        $params[] = $term;
        $params[] = $term;
    }
    if (!empty($_GET['category_id'])) {
        $sql .= " AND p.category_id = ?";
        $params[] = (int)$_GET['category_id'];
    }
    if (!empty($_GET['low_stock'])) {
        $lowStockCol = 'min_stock';
        try {
            $pdo->query("SELECT reorder_level FROM products LIMIT 1");
            $lowStockCol = 'reorder_level';
        } catch (PDOException $e) {}
        $sql .= " AND p.quantity <= p.$lowStockCol";
    }

    $sort = $_GET['sort'] ?? 'name_asc';
    $sortMap = [
        'name_asc' => 'p.name ASC',
        'name_desc' => 'p.name DESC',
        'stock_asc' => 'p.quantity ASC',
        'stock_desc' => 'p.quantity DESC',
        'price_asc' => 'p.unit_price ASC',
        'price_desc' => 'p.unit_price DESC',
    ];
    $sql .= " ORDER BY " . ($sortMap[$sort] ?? 'p.name ASC');

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    ok(['products' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
}

// ============================================
// PRODUCTS - GET SINGLE
// ============================================
if ($action === 'get_product' && $method === 'GET') {
    $id = (int)($_GET['id'] ?? 0);
    $stmt = $pdo->prepare("SELECT p.*, c.name AS category_name, s.name AS supplier_name
                           FROM products p
                           LEFT JOIN categories c ON c.id = p.category_id
                           LEFT JOIN suppliers s ON s.id = p.supplier_id
                           WHERE p.id = ?");
    $stmt->execute([$id]);
    $product = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$product) fail('Product not found', 404);
    ok(['product' => $product]);
}

// ============================================
// PRODUCTS - ADD
// ============================================
if ($action === 'add_product' && $method === 'POST') {
    $name = trim($data['name'] ?? '');
    $sku = trim($data['sku'] ?? '');
    if ($name === '' || $sku === '') fail('Name and SKU required', 422);

    // Check duplicate SKU
    $stmt = $pdo->prepare("SELECT id FROM products WHERE sku = ?");
    $stmt->execute([$sku]);
    if ($stmt->fetch()) fail('A product with this SKU already exists', 409);

    // Detect reorder column name
    $reorderCol = 'min_stock';
    try {
        $pdo->query("SELECT reorder_level FROM products LIMIT 1");
        $reorderCol = 'reorder_level';
    } catch (PDOException $e) {}

    // Check if cost_price column exists
    $hasCostPrice = true;
    try {
        $pdo->query("SELECT cost_price FROM products LIMIT 1");
    } catch (PDOException $e) {
        $hasCostPrice = false;
    }

    if ($hasCostPrice) {
        $stmt = $pdo->prepare("INSERT INTO products
            (name, sku, description, category_id, supplier_id, unit_price, cost_price, quantity, $reorderCol)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $name,
            $sku,
            trim($data['description'] ?? ''),
            $data['category_id'] ?? null,
            $data['supplier_id'] ?? null,
            (float)($data['unit_price'] ?? 0),
            (float)($data['cost_price'] ?? 0),
            (int)($data['quantity'] ?? 0),
            (int)($data['reorder_level'] ?? $data['min_stock'] ?? 10),
        ]);
    } else {
        $stmt = $pdo->prepare("INSERT INTO products
            (name, sku, description, category_id, supplier_id, unit_price, quantity, $reorderCol)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $name,
            $sku,
            trim($data['description'] ?? ''),
            $data['category_id'] ?? null,
            $data['supplier_id'] ?? null,
            (float)($data['unit_price'] ?? 0),
            (int)($data['quantity'] ?? 0),
            (int)($data['reorder_level'] ?? $data['min_stock'] ?? 10),
        ]);
    }
    $newId = (int)$pdo->lastInsertId();

    // Initial stock transaction
    $qty = (int)($data['quantity'] ?? 0);
    if ($qty > 0) {
        $txTable = 'stock_transactions';
        try {
            $pdo->query("SELECT 1 FROM stock_movements LIMIT 1");
            $txTable = 'stock_movements';
        } catch (PDOException $e) {}

        try {
            $stmt = $pdo->prepare("INSERT INTO $txTable (product_id, type, quantity, note, user_id) VALUES (?, 'STOCK_IN', ?, ?, ?)");
            $stmt->execute([$newId, $qty, 'Initial stock', $currentUser['id']]);
        } catch (PDOException $e) {
            $stmt = $pdo->prepare("INSERT INTO $txTable (product_id, type, quantity, note, user_id) VALUES (?, 'IN', ?, ?, ?)");
            $stmt->execute([$newId, $qty, 'Initial stock', $currentUser['id']]);
        }
    }

    ok(['product_id' => $newId]);
}

// ============================================
// PRODUCTS - UPDATE
// ============================================
if ($action === 'update_product' && $method === 'PUT') {
    $id = (int)($_GET['id'] ?? 0);
    $name = trim($data['name'] ?? '');
    $sku = trim($data['sku'] ?? '');
    if ($id === 0 || $name === '' || $sku === '') fail('Invalid product', 422);

    $reorderCol = 'min_stock';
    try {
        $pdo->query("SELECT reorder_level FROM products LIMIT 1");
        $reorderCol = 'reorder_level';
    } catch (PDOException $e) {}

    $hasCostPrice = true;
    try {
        $pdo->query("SELECT cost_price FROM products LIMIT 1");
    } catch (PDOException $e) {
        $hasCostPrice = false;
    }

    if ($hasCostPrice) {
        $stmt = $pdo->prepare("UPDATE products SET
            name = ?, sku = ?, description = ?, category_id = ?, supplier_id = ?,
            unit_price = ?, cost_price = ?, $reorderCol = ?
            WHERE id = ?");
        $stmt->execute([
            $name,
            $sku,
            trim($data['description'] ?? ''),
            $data['category_id'] ?? null,
            $data['supplier_id'] ?? null,
            (float)($data['unit_price'] ?? 0),
            (float)($data['cost_price'] ?? 0),
            (int)($data['reorder_level'] ?? $data['min_stock'] ?? 10),
            $id,
        ]);
    } else {
        $stmt = $pdo->prepare("UPDATE products SET
            name = ?, sku = ?, description = ?, category_id = ?, supplier_id = ?,
            unit_price = ?, $reorderCol = ?
            WHERE id = ?");
        $stmt->execute([
            $name,
            $sku,
            trim($data['description'] ?? ''),
            $data['category_id'] ?? null,
            $data['supplier_id'] ?? null,
            (float)($data['unit_price'] ?? 0),
            (int)($data['reorder_level'] ?? $data['min_stock'] ?? 10),
            $id,
        ]);
    }
    ok([]);
}

// ============================================
// PRODUCTS - DELETE
// ============================================
if ($action === 'delete_product' && $method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);

    $txTable = 'stock_transactions';
    try {
        $pdo->query("SELECT 1 FROM stock_movements LIMIT 1");
        $txTable = 'stock_movements';
    } catch (PDOException $e) {}

    $stmt = $pdo->prepare("DELETE FROM $txTable WHERE product_id = ?");
    $stmt->execute([$id]);
    $stmt = $pdo->prepare("DELETE FROM products WHERE id = ?");
    $stmt->execute([$id]);
    ok([]);
}

// ============================================
// STOCK IN / OUT
// ============================================
if (($action === 'stock_in' || $action === 'stock_out') && $method === 'POST') {
    $productId = (int)($data['product_id'] ?? 0);
    $qty = (int)($data['quantity'] ?? 0);
    $note = trim($data['note'] ?? '');

    if ($productId === 0 || $qty <= 0) fail('Invalid product or quantity', 422);

    $stmt = $pdo->prepare("SELECT * FROM products WHERE id = ?");
    $stmt->execute([$productId]);
    $product = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$product) fail('Product not found', 404);

    if ($action === 'stock_out' && $qty > (int)$product['quantity']) {
        fail("Cannot remove $qty - only {$product['quantity']} in stock", 422);
    }

    $newQty = $action === 'stock_in'
        ? (int)$product['quantity'] + $qty
        : (int)$product['quantity'] - $qty;

    $stmt = $pdo->prepare("UPDATE products SET quantity = ? WHERE id = ?");
    $stmt->execute([$newQty, $productId]);

    $type = $action === 'stock_in' ? 'STOCK_IN' : 'STOCK_OUT';

    $txTable = 'stock_transactions';
    try {
        $pdo->query("SELECT 1 FROM stock_movements LIMIT 1");
        $txTable = 'stock_movements';
    } catch (PDOException $e) {}

    try {
        $stmt = $pdo->prepare("INSERT INTO $txTable (product_id, type, quantity, note, user_id) VALUES (?, ?, ?, ?, ?)");
        $stmt->execute([$productId, $type, $qty, $note, $currentUser['id']]);
    } catch (PDOException $e) {
        $shortType = $action === 'stock_in' ? 'IN' : 'OUT';
        $stmt = $pdo->prepare("INSERT INTO $txTable (product_id, type, quantity, note, user_id) VALUES (?, ?, ?, ?, ?)");
        $stmt->execute([$productId, $shortType, $qty, $note, $currentUser['id']]);
    }

    ok(['new_quantity' => $newQty]);
}

// ============================================
// TRANSACTIONS HISTORY
// ============================================
if ($action === 'get_transactions') {
    $txTable = 'stock_transactions';
    try {
        $pdo->query("SELECT 1 FROM stock_movements LIMIT 1");
        $txTable = 'stock_movements';
    } catch (PDOException $e) {}

    $sql = "SELECT t.*, p.name AS product_name, u.name AS user_name
            FROM $txTable t
            JOIN products p ON p.id = t.product_id
            JOIN users u ON u.id = t.user_id
            WHERE 1=1";
    $params = [];

    if (!empty($_GET['product_id'])) {
        $sql .= " AND t.product_id = ?";
        $params[] = (int)$_GET['product_id'];
    }

    $limit = (int)($_GET['limit'] ?? 200);
    $sql .= " ORDER BY t.created_at DESC LIMIT " . $limit;

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    ok(['transactions' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
}

// ============================================
// CATEGORIES
// ============================================
if ($action === 'get_categories') {
    $rows = $pdo->query("SELECT c.*, (SELECT COUNT(*) FROM products p WHERE p.category_id = c.id) AS product_count FROM categories c ORDER BY c.name ASC")->fetchAll(PDO::FETCH_ASSOC);
    ok(['categories' => $rows]);
}

if ($action === 'add_category' && $method === 'POST') {
    $name = trim($data['name'] ?? '');
    if ($name === '') fail('Name required', 422);

    $hasDesc = true;
    try {
        $pdo->query("SELECT description FROM categories LIMIT 1");
    } catch (PDOException $e) {
        $hasDesc = false;
    }

    if ($hasDesc) {
        $stmt = $pdo->prepare("INSERT INTO categories (name, description) VALUES (?, ?)");
        $stmt->execute([$name, trim($data['description'] ?? '')]);
    } else {
        $stmt = $pdo->prepare("INSERT INTO categories (name) VALUES (?)");
        $stmt->execute([$name]);
    }
    ok([]);
}

if ($action === 'update_category' && $method === 'PUT') {
    $id = (int)($_GET['id'] ?? 0);
    $name = trim($data['name'] ?? '');

    $hasDesc = true;
    try {
        $pdo->query("SELECT description FROM categories LIMIT 1");
    } catch (PDOException $e) {
        $hasDesc = false;
    }

    if ($hasDesc) {
        $stmt = $pdo->prepare("UPDATE categories SET name = ?, description = ? WHERE id = ?");
        $stmt->execute([$name, trim($data['description'] ?? ''), $id]);
    } else {
        $stmt = $pdo->prepare("UPDATE categories SET name = ? WHERE id = ?");
        $stmt->execute([$name, $id]);
    }
    ok([]);
}

if ($action === 'delete_category' && $method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
    $stmt = $pdo->prepare("DELETE FROM categories WHERE id = ?");
    $stmt->execute([$id]);
    ok([]);
}

// ============================================
// SUPPLIERS
// ============================================
if ($action === 'get_suppliers') {
    $rows = $pdo->query("SELECT * FROM suppliers ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);
    ok(['suppliers' => $rows]);
}

if ($action === 'add_supplier' && $method === 'POST') {
    $name = trim($data['name'] ?? '');
    if ($name === '') fail('Name required', 422);

    $cols = ['name'];
    $vals = [$name];

    foreach (['phone', 'email', 'address'] as $col) {
        try {
            $pdo->query("SELECT $col FROM suppliers LIMIT 1");
            $cols[] = $col;
            $vals[] = trim($data[$col] ?? '');
        } catch (PDOException $e) {}
    }

    $placeholders = implode(',', array_fill(0, count($cols), '?'));
    $colStr = implode(',', $cols);
    $stmt = $pdo->prepare("INSERT INTO suppliers ($colStr) VALUES ($placeholders)");
    $stmt->execute($vals);
    ok([]);
}

if ($action === 'update_supplier' && $method === 'PUT') {
    $id = (int)($_GET['id'] ?? 0);
    $name = trim($data['name'] ?? '');
    if ($name === '') fail('Name required', 422);

    $sets = ['name = ?'];
    $vals = [$name];

    foreach (['phone', 'email', 'address'] as $col) {
        try {
            $pdo->query("SELECT $col FROM suppliers LIMIT 1");
            $sets[] = "$col = ?";
            $vals[] = trim($data[$col] ?? '');
        } catch (PDOException $e) {}
    }

    $vals[] = $id;
    $stmt = $pdo->prepare("UPDATE suppliers SET " . implode(', ', $sets) . " WHERE id = ?");
    $stmt->execute($vals);
    ok([]);
}

if ($action === 'delete_supplier' && $method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
    $stmt = $pdo->prepare("DELETE FROM suppliers WHERE id = ?");
    $stmt->execute([$id]);
    ok([]);
}

// ============================================
// SERVICES
// ============================================
 $hasServices = true;
try {
    $pdo->query("SELECT 1 FROM services LIMIT 1");
} catch (PDOException $e) {
    $hasServices = false;
}

if ($hasServices) {
    if ($action === 'get_services') {
        ok(['services' => $pdo->query("SELECT * FROM services ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC)]);
    }

    if ($action === 'get_service' && $method === 'GET') {
        $id = (int)($_GET['id'] ?? 0);
        $stmt = $pdo->prepare("SELECT * FROM services WHERE id = ?");
        $stmt->execute([$id]);
        $service = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$service) fail('Service not found', 404);
        ok(['service' => $service]);
    }

    if ($action === 'add_service' && $method === 'POST') {
        $name = trim($data['name'] ?? '');
        if ($name === '') fail('Name required', 422);
        $stmt = $pdo->prepare("INSERT INTO services (name, description, price) VALUES (?, ?, ?)");
        $stmt->execute([$name, trim($data['description'] ?? ''), (float)($data['price'] ?? 0)]);
        ok([]);
    }

    if ($action === 'update_service' && $method === 'PUT') {
        $id = (int)($_GET['id'] ?? 0);
        $stmt = $pdo->prepare("UPDATE services SET name = ?, description = ?, price = ? WHERE id = ?");
        $stmt->execute([trim($data['name'] ?? ''), trim($data['description'] ?? ''), (float)($data['price'] ?? 0), $id]);
        ok([]);
    }

    if ($action === 'delete_service' && $method === 'DELETE') {
        $id = (int)($_GET['id'] ?? 0);
        $stmt = $pdo->prepare("DELETE FROM services WHERE id = ?");
        $stmt->execute([$id]);
        ok([]);
    }
} else {
    if ($action === 'get_services') {
        ok(['services' => []]);
    }
    if ($action === 'get_service') {
        fail('Services table not set up', 404);
    }
}

// ============================================
// Unknown action
// ============================================
fail("Unknown API action: $action", 404);