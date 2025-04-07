<?php
// Set CORS headers
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: https://löschwasserförderung.at');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');

// Include required scripts
require_once 'crypto.php';
require_once 'db_connection.php';

// Ensure request is POST
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Read and decrypt input data
    $encryptedInput = file_get_contents('php://input');
    $decryptedInput = Crypto::decrypt($encryptedInput);
    $data = json_decode($decryptedInput, true);

    // Check if required fields are provided
    if (isset($data['username']) && isset($data['password'])) {
        $username = trim($data['username']);
        $password = trim($data['password']);

        // Validate user and check if admin
        $stmt = $conn->prepare("SELECT * FROM Login WHERE username = ?");
        $stmt->bind_param("s", $username);
        $stmt->execute();

        // Get result
        $result = $stmt->get_result();
        $user_data = $result->fetch_assoc();

        if ($user_data && password_verify($password, $user_data['password']) && $user_data['admin'] === 1) {
            // Webmail server access
            $mailServer = '{<<<ADDRESS>>>}INBOX';
            $emailUsername = '<<<USERNAME>>>';
            $emailPassword = '<<<PASSWORD>>>';
            $inbox = imap_open($mailServer, $emailUsername, $emailPassword);

            if ($inbox) {
                // Search for emails
                $emails = imap_search($inbox, 'ALL');
                imap_close($inbox);

                // Check if emails are found
                if ($emails) {
                    echo Crypto::encrypt(json_encode(['success' => 'Email gefunden']));
                    http_response_code(200);
                } else {
                    echo Crypto::encrypt(json_encode(['error' => 'Keine Emails gefunden']));
                    http_response_code(404);
                }
            } else {
                echo Crypto::encrypt(json_encode(['error' => 'Verbindung zum WebMail-server fehlgeschlagen']));
                http_response_code(500);
            }
        } else {
            echo Crypto::encrypt(json_encode(['error' => 'Ungültige Zugangsdaten oder kein Admin']));
            http_response_code(403);
        }
    } else {
        echo Crypto::encrypt(json_encode(['error' => 'Fehlende Eingabedaten']));
        http_response_code(400);
    }
} else {
    echo Crypto::encrypt(json_encode(['error' => 'Ungültige Request-Methode']));
    http_response_code(405);
}
