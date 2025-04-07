<?php
// Set CORS headers
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: https://löschwasserförderung.at');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');

// Include required scripts
require './phpMailer/src/Exception.php';
require './phpMailer/src/SMTP.php';
require './phpMailer/src/PHPMailer.php';
require_once 'crypto.php';

// Import PHPMailer
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

// Ensure request is POST
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Decrypt the input data
    $encryptedInput = file_get_contents('php://input');
    $decryptedInput = Crypto::decrypt($encryptedInput);
    $inputData = json_decode($decryptedInput, true);

    // Validate required input data
    if (!isset($inputData['from'], $inputData['subject'], $inputData['message'])) {
        echo Crypto::encrypt(json_encode(['error' => 'Fehlende Eingabedaten']));
        http_response_code(400);
        exit();
    }

    // Variables
    $domainEmail = 'support@xn--lschwasserfrderung-d3bk.at';
    $from = $inputData['from'];
    $subject = $inputData['subject'];
    $body = htmlspecialchars($inputData['message']);

    //Create PHPMailer instance
    $mail = new PHPMailer(true);

    try {
        // SMTP settings
        $mail->isSMTP();
        $mail->Host = '<<<HOST>>>';
        $mail->SMTPAuth = true;
        $mail->Username = $domainEmail;
        $mail->Password = '<<<PASSWORD>>>';
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port = <<<PORT>>>;

        // Set email headers
        $mail->setFrom($domainEmail, 'Support Formular');
        $mail->addReplyTo($from);
        $mail->addAddress($domainEmail);

        // Set email content
        $mail->isHTML(true);
        $mail->CharSet = 'UTF-8';
        $mail->Subject = $subject;
        $mail->Body = 'Nachricht von: ' . htmlspecialchars($from) . '<br><br>' . $body;

        // Send email
        $mail->send();
        echo Crypto::encrypt(json_encode(['message' => 'Nachricht erfolgreich gesendet']));
        http_response_code(200);
    } catch (Exception $e) {
        echo Crypto::encrypt(json_encode(['error' => 'Fehler beim Senden der E-Mail: ' . $mail->ErrorInfo]));
        http_response_code(500);
    }
} else {
    echo Crypto::encrypt(json_encode(['error' => 'Ungültige Request-Methode']));
    http_response_code(405);
}
