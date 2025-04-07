<?php

// Prevent direct access from browser
if (basename($_SERVER['PHP_SELF']) === basename(__FILE__)) {
    http_response_code(403);
    die("Access forbidden.");
}

// AES-256-CBC encryption
class Crypto {
    private static $key = '<<<32_BIT_SECRET_KEY>>>'; // 32-byte KEY
    private static $iv  = '<<<16_BIT_IV>>>'; // 16-byte IV

    // Encrypt
    public static function encrypt($data): string {
        $encrypted = openssl_encrypt($data, 'AES-256-CBC', self::$key, OPENSSL_RAW_DATA, self::$iv);
        return base64_encode($encrypted); // Encode in base64 (make safe ot transmission)
    }

    // Decrypt
    public static function decrypt($data) {
        $decoded = base64_decode($data); // Decode from base64
        return openssl_decrypt($decoded, 'AES-256-CBC', self::$key, OPENSSL_RAW_DATA, self::$iv);
    }
}
