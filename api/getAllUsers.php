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
    try {
            // Prepare and execute query to fetch all users
            $stmt = $conn->prepare("SELECT username, password, admin FROM Login");
            $stmt->execute();
            $result = $stmt->get_result();

            // Check if any users exist
            if ($result->num_rows > 0) {
                $users = [];
                while ($user_data = $result->fetch_assoc()) {
                    // Store User credentials in Array
                    $users[] = [
                        'username' => $user_data['username'],
                        'password' => $user_data['password'],
                        'admin' => $user_data['admin']
                    ];
                }

                // Send encrypted response with all users
                echo Crypto::encrypt(json_encode(['users' => $users]));
                http_response_code(200);
            } else {
                // No users found
                echo Crypto::encrypt(json_encode(['error' => 'Keine Benutzer gefunden']));
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