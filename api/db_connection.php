<?php

// Prevent direct access from browser
if (basename($_SERVER['PHP_SELF']) === basename(__FILE__)) {
    http_response_code(403);
    die("Access forbidden.");
}

// Database connection variables
$host = '<<HOST>>';
$database = '<<DATABASE>>';
$dbUser = '<<DB_USER>>';
$dbPass = '<<DB_PASS>>';

// Create connection to database
$conn = new mysqli($host, $dbUser, $dbPass, $database);

// Check connection
if ($conn->connect_error) {
    die(json_encode(["error" => "DB Connection Error: " . $conn->connect_error]));
}

// Set UTF-8 character encoding
$conn->set_charset("utf8mb4");
