<?php
// Set CORS headers
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: https://löschwasserförderung.at');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');

// Include required script
require_once 'crypto.php';

// Ensure request is POST
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Decrypt input data
    $encryptedInput = file_get_contents('php://input');
    $decryptedInput = Crypto::decrypt($encryptedInput);
    $data = json_decode($decryptedInput, true);

    // Variables
    $mailServer = '{<<<ADDRESS>>>}INBOX';
    $username = '<<<USERNAME>>>';
    $password = '<<<PASSWORD>>>';

    // Connect to WebMail server
    $inbox = imap_open($mailServer, $username, $password) or die(
        Crypto::encrypt(json_encode(['error' => 'Verbindung zum WebMail Server fehlgeschlagen: ' . imap_last_error()]))
    );

    //Get Emails from WebMail server
    $emails = imap_search($inbox, 'ALL');
    $response = ['emails' => []];

    //Locale german with UTF-8 character encoding
    setlocale(LC_TIME, 'de_DE.UTF-8');

    // format gotten emails right
    if ($emails) {
        foreach ($emails as $emailNumber) {
            $overview = imap_fetch_overview($inbox, $emailNumber, 0);

            //Subject
            $subject = imap_utf8($overview[0]->subject);

            $structure = imap_fetchstructure($inbox, $emailNumber);
            $message = '';

            // Decode email body
            if ($structure->encoding == 3) {
                $message = base64_decode(imap_fetchbody($inbox, $emailNumber, 1));
            } elseif ($structure->encoding == 4) {
                $message = quoted_printable_decode(imap_fetchbody($inbox, $emailNumber, 1));
            } else {
                $message = imap_fetchbody($inbox, $emailNumber, 1);
            }

            // Convert HTML entities (replace double line breaks)
            $message = html_entity_decode($message, ENT_QUOTES, 'UTF-8');
            if (!preg_match("/<br\s*\/?>/i", $message)) {
                $message = nl2br($message);
            }
            $message = str_replace(['<br />', '<br>'], "\n", $message);

            //Get sender Email address
            $fromEmail = $overview[0]->from ?? '';
            $replyToEmail = '';

            // Ge t replyToEmail address
            if (strpos($fromEmail, 'support@löschwasserförderung.at') === false) {
                $message = str_replace("\r\n", "\n", $message);
                $message = preg_replace("/\n\s*\n/", "\n", $message);

                if (preg_match('/<(.+)>/', $fromEmail, $matches)) {
                    $replyToEmail = $matches[1];
                } else {
                    $replyToEmail = $fromEmail;
                }
            }
            // Extract body of Email
            if (preg_match('/Nachricht von:\s*([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/', $message, $matches)) {
                $replyToEmail = $matches[1];
                $message = preg_replace('/Nachricht von:\s*' . $matches[1] . '\s*(\n|\r\n|\r)*/', '', $message);
            }

            // Format date
            $formattedDate = strftime('%A, %d. %B %Y, %H:%M', strtotime($overview[0]->date));

            // Combine data to JSON Format
            $emailData = [
                'subject' => $subject,
                'replyTo' => $replyToEmail,
                'message' => $message,
                'id' => $emailNumber,
                'date' => $formattedDate,
            ];

            // Add email data to response
            $response['emails'][] = $emailData;
        }
    } else {
        $response = ['message' => 'Keine Emails gefunden'];
    }

    // Close connection to WebMail server
    imap_close($inbox);

    // Encrypt and send response
    echo Crypto::encrypt(json_encode($response));
} else {
    echo Crypto::encrypt(json_encode(['error' => 'Ungültige Request-Methode']));
    http_response_code(405);
}