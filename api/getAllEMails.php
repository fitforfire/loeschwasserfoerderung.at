<?php
// List of allowed domains
$allowed_origins = [
    "https://löschwasserförderung.at",
    "https://xn--lschwasserfrderung-d3bk.at"
];

// Get the origin of the request
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';

// If the origin is in the allowed list, set CORS header
if (in_array($origin, $allowed_origins)) {
    header("Access-Control-Allow-Origin: $origin");
}

// Set CORS headers
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');

// Include crypto script
require_once "crypto.php";
require_once "email_connection.php";

// Recursive function to fetch email body
function getBody($inbox, $emailNumber, $structure = false, $partNumber = false) {
    if (!$structure) {
        $structure = imap_fetchstructure($inbox, $emailNumber);
    }

    if ($structure) {
        if ($structure->type == 0) { // text
            $partNumber = $partNumber ? $partNumber : 1;
            $text = imap_fetchbody($inbox, $emailNumber, $partNumber);

            switch ($structure->encoding) {
                case 3: $text = base64_decode($text); break;
                case 4: $text = quoted_printable_decode($text); break;
            }

            $charset = 'ISO-8859-1';
            if (isset($structure->parameters)) {
                foreach ($structure->parameters as $param) {
                    if (strtolower($param->attribute) === 'charset') {
                        $charset = $param->value;
                    }
                }
            }
            $text = mb_convert_encoding($text, 'UTF-8', $charset);

            return $text;
        } elseif ($structure->type == 1 && isset($structure->parts)) { // multipart
            foreach ($structure->parts as $index => $subStruct) {
                $data = getBody(
                    $inbox,
                    $emailNumber,
                    $subStruct,
                    $partNumber ? $partNumber . '.' . ($index + 1) : ($index + 1)
                );
                if ($data) return $data;
            }
        }
    }
    return '';
}

// Ensure request is POST
if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    $encryptedInput = file_get_contents('php://input');
    $decryptedInput = Crypto::decrypt($encryptedInput);
    $data = json_decode($decryptedInput, true);

    if (!$inbox) {
        echo Crypto::encrypt(json_encode([
            'error' => 'Verbindung zum WebMail Server fehlgeschlagen: ' . imap_last_error()
        ]));
        http_response_code(500);
        exit;
    }

    $emails = imap_search($inbox, 'ALL');
    $response = ['emails' => []];

    setlocale(LC_TIME, 'de_DE.UTF-8');

    if ($emails) {
        foreach ($emails as $emailNumber) {
            $overview = imap_fetch_overview($inbox, $emailNumber, 0);

            $subject = isset($overview[0]->subject) ? imap_utf8($overview[0]->subject) : '';
            $message = getBody($inbox, $emailNumber);

            $message = html_entity_decode($message, ENT_QUOTES | ENT_HTML5, 'UTF-8');
            $message = preg_replace('/<br\s*\/?>/i', "\n", $message);
            $message = preg_replace('/<\/p>/i', "\n", $message);
            $message = preg_replace_callback('/<a [^>]*href=["\']([^"\']+)["\'][^>]*>(.*?)<\/a>/i', function($matches) {
                return trim($matches[2]) . ' (' . $matches[1] . ')';
            }, $message);
            $message = strip_tags($message);
            $message = preg_replace("/(\r\n|\r|\n){2,}/", "\n", $message);
            $message = trim($message);

            // Get sender email address from body if needed
            $fromEmail = $overview[0]->from ?? '';
            $replyToEmail = '';

            if (strpos($fromEmail, 'support@löschwasserförderung.at') === false) {
                if (preg_match('/<(.+)>/', $fromEmail, $matches)) {
                    $replyToEmail = $matches[1];
                } else {
                    $replyToEmail = $fromEmail;
                }
            }

            // Extract email address from message body if present
            if (preg_match('/Nachricht von:\s*([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/', $message, $matches)) {
                $replyToEmail = $matches[1];
                $message = preg_replace('/Nachricht von:\s*' . preg_quote($matches[1], '/') . '\s*(\n|\r\n|\r)*/', '', $message);
            }

            $formattedDate = strftime('%A, %d. %B %Y, %H:%M', strtotime($overview[0]->date));

            $emailData = [
                'subject' => $subject,
                'replyTo' => $replyToEmail,
                'message' => $message,
                'id' => $emailNumber,
                'date' => $formattedDate
            ];

            $response['emails'][] = $emailData;
        }
    } else {
        $response = ['message' => 'Keine Emails gefunden'];
    }

    imap_close($inbox);

    echo Crypto::encrypt(json_encode($response));
    http_response_code(200);

} else {
    echo Crypto::encrypt(json_encode(['error' => 'Ungültige Request-Methode']));
    http_response_code(405);
}
