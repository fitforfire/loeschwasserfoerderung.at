<?php

// Set CORS headers
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: https://löschwasserförderung.at');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');

// Include required scripts
include('db_connection.php');
require_once "crypto.php";

// Ensure request is POST
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Decrypt input data from request body
    $encryptedInput = file_get_contents("php://input");
    $decryptedInput = Crypto::decrypt($encryptedInput);
    $inputData = json_decode($decryptedInput, true);

    // Extract input variables
    $user_username = $inputData['username'] ?? '';
    $user_password = $inputData['password'] ?? '';
    $isAdmin = $inputData['isAdmin'] ?? 'false';

    // Validate input data
    if (empty($user_username) || empty($user_password)) {
        echo Crypto::encrypt(json_encode(['error' => 'Benutzername und Passwort werden benötigt']));
        http_response_code(400);
        exit();
    }

    // Convert isAdmin to integer
    $isAdmin = ($isAdmin === 'true') ? 1 : 0;

    // Prepare SQL query for insertion
    $stmt = $conn->prepare("INSERT INTO Login (username, password, admin) VALUES (?, ?, ?)");
    $stmt->bind_param("ssi", $user_username, $user_password, $isAdmin);

    // Execute SQL query
    if ($stmt->execute()) {
        echo Crypto::encrypt(json_encode(['success' => 'Benutzer erfolgreich hinzugefügt']));
        http_response_code(200);
    } else {
        echo Crypto::encrypt(json_encode(['error' => 'Benutzer hinzufügen fehlgeschlagen']));
        http_response_code(500);
    }

    // Close query and database connection
    $stmt->close();
    $conn->close();
}  else {
      echo Crypto::encrypt(json_encode(['error' => 'Ungültige Request-Methode']));
      http_response_code(405);
}
