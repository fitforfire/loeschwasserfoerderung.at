<?php

// Prevent direct access from browser
if (basename($_SERVER['PHP_SELF']) === basename(__FILE__)) {
    http_response_code(403);
    die("Access forbidden.");
}

// Database connection variables
$host     = '<<<HOST>>>';
$database = '<<<DB>>>';
$dbUser   = '<<<USER>>>';
$dbPass   = '<<<PASSWORD>>>';

// Create connection to database
$conn = new mysqli($host, $dbUser, $dbPass, $database);

// Check connection
if ($conn->connect_error) {
    die(json_encode(["error" => "Datenbankverbindungs error: " . $conn->connect_error]));
}

// Set UTF-8 character encoding
$conn->set_charset("utf8mb4");
