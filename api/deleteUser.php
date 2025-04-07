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
    $stmt = $conn->prepare("SELECT username FROM Login WHERE username = ? AND password = ?");
    $stmt->bind_param("ss", $username, $password);
    $stmt->execute();
    $stmt->store_result();

    if ($stmt->num_rows === 1) {
        // Close query and prepare delete query
        $stmt->close();
        $stmt = $conn->prepare("DELETE FROM Login WHERE username = ? AND password = ?");
        $stmt->bind_param("ss", $username, $password);

        // Check if executed right or error
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
