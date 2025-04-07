<?php
// Set CORS headers
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: https://löschwasserförderung.at');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');

// Include required scripts
require_once "db_connection.php";
require_once "crypto.php";

// Ensure request is POST
if ($_SERVER["REQUEST_METHOD"] !== "POST") {
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

    // Validate input
    if (empty($username) || empty($password) || empty($newUsername) || empty($newPassword)) {
        echo Crypto::encrypt(json_encode(["error" => "Fehlende Eingabedaten"]));
        http_response_code(400);
        exit();
    }

    // Check if the user exists
    $stmt = $conn->prepare("SELECT username FROM Login WHERE username = ? AND password = ?");
    $stmt->bind_param("ss", $username, $password);
    $stmt->execute();
    $stmt->store_result();

    // incorrect user credentials
    if ($stmt->num_rows !== 1) {
        $stmt->close();
        echo Crypto::encrypt(json_encode(["error" => "Ungültiger Benutzername oder Passwort"]));
        http_response_code(404);
        exit();
    }

    //Close query
    $stmt->close();

    // Convert isAmdi nto integer
    $isAdmin = ($isAdmin === "true") ? 1 : 0;

    // Update user query
    $stmt = $conn->prepare("UPDATE Login SET username = ?, password = ?, admin = ? WHERE username = ? AND password = ?");
    $stmt->bind_param("ssisi", $newUsername, $newPassword, $isAdmin, $username, $password);

    //Execute query
    if ($stmt->execute() && $stmt->affected_rows > 0) {
        $stmt->close();
        echo Crypto::encrypt(json_encode(["success" => "Benutzer erfolgreich aktualisiert"]));
        http_response_code(200);
        exit();
    }

    // Close query and database connection
    $stmt->close();
    $conn->close();
    echo Crypto::encrypt(json_encode(["error" => "Keine Änderungen vorgenommen oder Benutzer nicht gefunden"]));
    http_response_code(400);
} else {
    echo Crypto::encrypt(json_encode(["error" => "Ungültige Request-Methode"]));
    http_response_code(405);
}
