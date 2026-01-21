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
    // Decrypt the incoming request data
    $encryptedInput = file_get_contents("php://input");
    $decryptedInput = Crypto::decrypt($encryptedInput);
    $inputData = json_decode($decryptedInput, true);

    // Extract input values
    $username = $inputData["username"] ?? "";
    $password = $inputData["password"] ?? "";
    $newUsername = $inputData["newUsername"] ?? "";
    $newPassword = $inputData["newPassword"] ?? "";
    $isAdmin = $inputData["isAdmin"] ?? "false";

    try {
        // 1. Fetch user by username
        $stmt = $conn->prepare("SELECT password FROM Login WHERE username = ?");
        $stmt->bind_param("s", $username);
        $stmt->execute();
        $result = $stmt->get_result();
        $user_data = $result->fetch_assoc();
        $stmt->close();

        if (!$user_data || !password_verify($password, $user_data['password'])) {
            echo Crypto::encrypt(json_encode(["error" => "Ungültiger Benutzername oder Passwort"]));
            http_response_code(401);
            exit();
        }

        // 2. Hash new password
        $hashedNewPassword = password_hash($newPassword, PASSWORD_DEFAULT);

        // 3. Update user
        $stmt = $conn->prepare("UPDATE Login SET username = ?, password = ?, admin = ? WHERE username = ?");
        $stmt->bind_param("ssis", $newUsername, $hashedNewPassword, $isAdmin, $username);

        if ($stmt->execute() && $stmt->affected_rows > 0) {
            echo Crypto::encrypt(json_encode(["success" => "Benutzer erfolgreich aktualisiert"]));
            http_response_code(200);
        } else {
            echo Crypto::encrypt(json_encode(["error" => "Keine Änderungen vorgenommen oder Benutzer nicht gefunden"]));
            http_response_code(400);
        }

        $stmt->close();
        $conn->close();

    } catch (Exception $e) {
        echo Crypto::encrypt(json_encode(["error" => "Datenbankfehler: " . $e->getMessage()]));
        http_response_code(500);
    }
} else {
    echo Crypto::encrypt(json_encode(["error" => "Ungültige Request-Methode"]));
    http_response_code(405);
}
