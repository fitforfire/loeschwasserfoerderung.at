<?php
// List of allowed domains
$allowed_origins = [
    "https://löschwasserförderung.at",
    "https://xn--lschwasserfrderung-d3bk.at"
];

// Get the origin of the request
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';

// If the origin is in the allowed list, set the CORS header
if (in_array($origin, $allowed_origins)) {
    header("Access-Control-Allow-Origin: $origin");
}

// Cross-Origin Headers
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');

// Include required scripts
require_once "db_connection.php";
require_once "crypto.php";

// Ensure request is POST
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Get and decrypt input data
    $encryptedInput = file_get_contents("php://input");
    $decryptedInput = Crypto::decrypt($encryptedInput);
    $inputData = json_decode($decryptedInput, true);

    // Ensure username and password are provided
    if (!isset($inputData['username']) || !isset($inputData['password'])) {
        echo Crypto::encrypt(json_encode(['error' => 'Fehlende Eingabedaten']));
        http_response_code(400);
        exit;
    }

    // Variables
    $username = $inputData['username'];
    $password = $inputData['password'];

    try {
        // Prepare and execute query to find user by username
        $stmt = $conn->prepare("SELECT password FROM Login WHERE username = ?");
        $stmt->bind_param("s", $username);
        $stmt->execute();
        $result = $stmt->get_result();
        $user_data = $result->fetch_assoc();
		
        // Verify user exists and password is correct
		if ($user_data && password_verify($password, $user_data['password'])) {
            // If yes, return encrypted token

            // Get Token from Database
            $tokenStmt = $conn->prepare("SELECT token FROM Tokens WHERE id = ?");
            $tokenId = 'objectDatabase_token';
            $tokenStmt->bind_param("s", $tokenId);
            $tokenStmt->execute();
            $tokenResult = $tokenStmt->get_result();
            $tokenData = $tokenResult->fetch_assoc();

            echo Crypto::encrypt(json_encode(['dbToken' => $tokenData['token']]));
            http_response_code(200);
        } else {
            // Incorrect username or password
            echo Crypto::encrypt(json_encode(['error' => 'Ungültiger Benutzername oder Passwort']));
            http_response_code(404);
        }
    } catch (Exception $e) {
        // Database error
        echo Crypto::encrypt(json_encode(['error' => 'Datenbank error: ' . $e->getMessage()]));
        http_response_code(500);
    }
} else {
    echo Crypto::encrypt(json_encode(['error' => 'Ungültige Request-Methode']));
    http_response_code(405);
}
