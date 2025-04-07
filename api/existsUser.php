<?php
// Set CORS headers
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: https://löschwasserförderung.at');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');

// Include required scrips
require_once "crypto.php";
require_once "db_connection.php";

// Ensure request is POST
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Get and decrypt input data
    $encryptedInput = file_get_contents("php://input");
    $decryptedInput = Crypto::decrypt($encryptedInput);
    $inputData = json_decode($decryptedInput, true);

    // Ensure needed fields are present
    if (!isset($inputData['username']) || !isset($inputData['password'])) {
        echo Crypto::encrypt(json_encode(['error' => 'Fehledende Eingabedaten']));
        http_response_code(400);
        exit;
    }

    //Extract user credentials
    $username = trim($inputData['username']);
    $password = trim($inputData['password']);

    try {
        // Prepare and execute query to check user credentials
        $stmt = $conn->prepare("SELECT * FROM Login WHERE username = ?");
        $stmt->bind_param("s", $username);
        $stmt->execute();

        // Get the result of query
        $result = $stmt->get_result();
        $user_data = $result->fetch_assoc();

        // Verify username and password
        if ($user_data && $user_data['password'] === $password) {
            // Successful login
            echo Crypto::encrypt(json_encode([
                'login' => true,
                'admin' => $user_data['admin'] === 1,
            ]));
            http_response_code(200);  // OK
        } else {
            // Failed login
            echo Crypto::encrypt(json_encode([
                'login' => false,
                'admin' => false,
            ]));
            http_response_code(401);
        }
    } catch (Exception $e) {
        // Database error
        echo Crypto::encrypt(json_encode([
            'login' => false,
            'admin' => false,
            'error' => 'Database error: ' . $e->getMessage()
        ]));
        http_response_code(500);
    }
} else {
    echo Crypto::encrypt(json_encode(['error' => 'Ungültige Request-Methode']));
    http_response_code(405);
}
