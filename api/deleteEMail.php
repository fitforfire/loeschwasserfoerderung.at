<?php

// Set CORS headers
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: https://löschwasserförderung.at');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');

// Include required scripts
require_once 'crypto.php';

// Ensure request is POST
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Decrypt input data from request
    $encryptedInput = file_get_contents('php://input');
    $decryptedInput = Crypto::decrypt($encryptedInput);
    $data = json_decode($decryptedInput, true);

    // Check if email ID is provided
    if (empty($data['id'])) {
        http_response_code(400);
        echo Crypto::encrypt(json_encode(['error' => 'Keine E-Mail ID angegeben']));
        exit();
    }

    // Variables
    $emailId = $data['id'];
    $mailServer = '{<<<ADDRESS>>>}INBOX';
    $username = '<<<USERNAME>>>';
    $password = '<<<PASSWORD>>>';

    // Connect to WebMail server
    $inbox = imap_open($mailServer, $username, $password);

    // Check connection
    if (!$inbox) {
        echo Crypto::encrypt(json_encode(['error' => 'Verbindung zum WebMail Server fehlgeschlagen: ' . imap_last_error()]));
        http_response_code(500);
        exit();
    }

    // Attempt to delete the email
    if (imap_delete($inbox, $emailId)) {
        imap_expunge($inbox);
        echo Crypto::encrypt(json_encode(['success' => 'Email erfolgreich gelöscht']));
        http_response_code(200);
    } else {
        echo Crypto::encrypt(json_encode(['error' => 'Fehler beim Löschen der Email']));
        http_response_code(500);
    }

    // Close connection to WebMail server
    imap_close($inbox);
} else {
     echo Crypto::encrypt(json_encode(['error' => 'Ungültige Request-Methode']));
     http_response_code(405);
}
