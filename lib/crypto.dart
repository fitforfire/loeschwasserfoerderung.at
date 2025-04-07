import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

//Class for Encrypting/Decrypting
class Crypto {
  static const storage = FlutterSecureStorage();

  // Fetch environment variables
  static final String keyString = dotenv.env['ENCRYPTION_KEY']!;
  static final String ivString = dotenv.env['ENCRYPTION_IV']!;

  static final Key encryptionKey =
      Key.fromUtf8(keyString.substring(0, 32)); // AES-256 Key
  static final IV iv = IV.fromUtf8(ivString.substring(0, 16)); // 16-byte IV

  static final encrypter = Encrypter(AES(encryptionKey, mode: AESMode.cbc));

  //Encrypt
  static Future<String?> encrypt(String data) async {
    if (data.isEmpty) return null;
    final encrypted = encrypter.encrypt(data, iv: iv);
    return encrypted.base64;
  }

  //Decrypt
  static Future<String?> decrypt(String data) async {
    if (data.isEmpty) return null;
    final decrypted = encrypter.decrypt(Encrypted.fromBase64(data), iv: iv);
    return decrypted;
  }
}
