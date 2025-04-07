<?php
// Set CORS headers
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: https://löschwasserförderung.at');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');

//Include required scripts
require './phpMailer/src/Exception.php';
require './phpMailer/src/SMTP.php';
require './phpMailer/src/PHPMailer.php';
require_once 'crypto.php';

// Import PHPMailer
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

// Ensure request is POST
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Decrypt incoming data
    $encryptedInputData = file_get_contents('php://input');
    $decryptedInputData = Crypto::decrypt($encryptedInputData);
    $inputData = json_decode($decryptedInputData, true);

    // Check if required fields are provided
    if (isset($inputData['subject']) && isset($inputData['message']) && isset($inputData['to'])) {
        $domainEmail = 'support@xn--lschwasserfrderung-d3bk.at';
        $from = 'support@löschwasserförderung.at';
        $subject = 'Antwort auf Ihre Supportanfrage "' . htmlspecialchars($inputData['subject']) . '" von löschwasserförderung.at';
        $body = htmlspecialchars($inputData['message']);
        $to = filter_var($inputData['to'], FILTER_VALIDATE_EMAIL);

        $mail = new PHPMailer(true);

        try {
            // SMTP settings
            $mail->isSMTP();
            $mail->Host = '<<<HOST>>>';
            $mail->SMTPAuth = true;
            $mail->Username = $domainEmail;
            $mail->Password = '<<<PASSWORD>>>';
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
            $mail->Port = <<<POST>>>;

            // Set email headers
            $mail->setFrom($domainEmail, 'Löschwasserförderung.at Support');
            $mail->addReplyTo($from);
            $mail->addAddress($to);

            // Email content
            $mail->isHTML(true);
            $mail->CharSet = 'UTF-8';
            $mail->Subject = $subject;

            // Set email body (greeting, Status and signature)
            $mail->Body = '
                <p>Sehr geehrte Damen/Herren,</p>
                <p>Der Status Ihrer Supportmeldung an Löschwasserförderung.at ist:</p>
                <p>' . nl2br($body) . '</p>
                <div style="font-family: Arial, sans-serif; color: #ffffff; background-color: #1b6ec1; padding: 20px;">
                    <p style="margin: 0; font-size: 16px; font-weight: bold;">Mit freundlichen Grüßen,<br />Support von 
                    <a href="https://www.löschwasserförderung.at" target="_blank" rel="nofollow noopener" style="color: #ffffff; text-decoration: none;">Löschwasserförderung.at</a></p>
                    <p style="margin: 0; font-size: 14px; font-style: italic; color: #b0b0b0;">Ein Projekt von 
                    <a href="https://www.team122.at" target="_blank" rel="nofollow noopener" style="color: #b0b0b0; text-decoration: none;">Team122.at</a></p>
                    <div style="margin-top: 15px;">
                        <p style="margin: 0; font-size: 14px;">Telefon: 
                        <a href="tel:+436604122122" target="_blank" rel="nofollow noopener" style="color: #ffffff; text-decoration: none;">+43 6604 122 122</a></p>
                        <p style="margin: 5px 0 0; font-size: 14px;">E-Mail: 
                        <a href="mailto:support@löschwasserförderung.at" target="_blank" rel="nofollow noopener" style="color: #ffffff; text-decoration: none;">support@löschwasserförderung.at</a></p>
                        <p style="margin: 5px 0 0; font-size: 14px;">Website: 
                        <a href="https://www.löschwasserförderung.at" target="_blank" rel="nofollow noopener" style="color: #ffffff; text-decoration: none;">www.löschwasserförderung.at</a></p>
                    </div>
                    <div style="margin-top: 20px; font-size: 12px; color: #b0b0b0;">
                        <p style="margin: 0;">&copy; 
                        <a href="https://www.löschwasserförderung.at" target="_blank" rel="nofollow noopener" style="color: #b0b0b0; text-decoration: none;">Löschwasserförderung.at</a> – ein Projekt des gemeinnützigen Vereins 
                        <a href="https://www.team122.at" target="_blank" rel="nofollow noopener" style="color: #b0b0b0; text-decoration: none;">Team122.at</a></p>
                        <p style="margin: 0;">
                        <a href="https://www.team122.at" target="_blank" rel="nofollow noopener" style="color: #b0b0b0; text-decoration: none;">www.team122.at</a></p>
                    </div>
                    <div style="margin-top: 10px; font-size: 12px; color: #b0b0b0; border-top: 1px solid #B0B0B0; padding-top: 10px;">
                        <p style="margin: 0;">Hinweis: Diese E-Mail und eventuelle Anhänge enthalten vertrauliche Informationen und sind ausschließlich für den angegebenen Empfänger bestimmt. Sollten Sie diese Nachricht irrtümlich erhalten haben, informieren Sie uns bitte umgehend und löschen Sie sie.</p>
                    </div>
                </div>
            ';

            // Send email
            $mail->send();

            // Encrypt and send success response
            echo Crypto::encrypt(json_encode(["message" => "Nachricht erfolgreich gesendet"]));
            http_response_code(200);
        } catch (Exception $e) {
            // Encrypt and send error response
            echo Crypto::encrypt(json_encode(["message" => "Fehler beim Senden der Nachricht: " . $mail->ErrorInfo]));
            http_response_code(500);
        }
    } else {
        echo Crypto::encrypt(json_encode(["message" => "Fehlende Eingabedaten"]));
        http_response_code(400);
    }
} else {
    echo Crypto::encrypt(json_encode(["message" => "Ungültige Request Methode"]));
    http_response_code(405);
}
