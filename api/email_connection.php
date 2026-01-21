<?php

// Prevent direct access from browser
if (basename($_SERVER['PHP_SELF']) === basename(__FILE__)) {
    http_response_code(403);
    die("Access forbidden.");
}

// Email connection variables
$mailHost = '<<HOST>>';
$mailServer = '{<<HOST>>:<<PORT>>/imap/ssl}INBOX';
$mailPort = <<PORT>>;
$emailUsername = '<<EMAIL_USERNAME>>';
$emailPassword = '<<EMAIL_PASSWORD>>';

// Try to open IMAP inbox connection
$inbox = imap_open($mailServer, $emailUsername, $emailPassword);

// Handle connection error correctly
if ($inbox === false) {
    error_log('IMAP Connection Error: ' . imap_last_error());
    $inbox = null;
}
