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

// Set CORS headers
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');

// Include required scripts
require_once "db_connection.php";
require_once "crypto.php";

// Ensure request is POST
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Decrypt input data from request
    $encryptedInput = file_get_contents("php://input");
    $decryptedInput = Crypto::decrypt($encryptedInput);
    $inputData = json_decode($decryptedInput, true);

    // Extract input variables
    $username = $inputData["username"] ?? "";
    $password = $inputData["password"] ?? "";

    // Validate input data
    if (empty($username) || empty($password)) {
        http_response_code(400);
        echo Crypto::encrypt(json_encode(['error' => 'Fehlende Eingabedaten']));
        exit();
    }

    // Check if user exists
    $stmt = $conn->prepare("SELECT password FROM Login WHERE username = ?");
    $stmt->bind_param("s", $username);
    $stmt->execute();
    $result = $stmt->get_result();
    $user_data = $result->fetch_assoc();

    if ($user_data) {
        $stmt->close();
        $stmt = $conn->prepare("DELETE FROM Login WHERE username = ?");
        $stmt->bind_param("s", $username);

        if ($stmt->execute()) {
            http_response_code(200);
            echo Crypto::encrypt(json_encode(['success' => 'Benutzer erfolgreich gelöscht']));
        } else {
            http_response_code(500);
            echo Crypto::encrypt(json_encode(['error' => 'Benutzer löschen fehlgeschlagen']));
        }
    } else {
        http_response_code(401);
        echo Crypto::encrypt(json_encode(['error' => 'Ungültiger Benutzername oder Passwort']));
    }

    // Close database connection
    $stmt->close();
    $conn->close();

} else {
    echo Crypto::encrypt(json_encode(['error' => 'Ungültige Request-Methode']));
    http_response_code(405);
}
