import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:loeschwasserfoerderung/crypto.dart';

//Class for handling the Token securely
class SecureTokenStorage {
  static const storage = FlutterSecureStorage();

  // Save Token securely
  static Future<void> saveToken(String token) async {
    await storage.write(key: "dbToken", value: token);
  }

  // Load and Decrypt Token
  static Future<String?> getToken() async {
    final encryptedToken = await storage.read(key: "dbToken");
    if (encryptedToken == null) return null;

    return await Crypto.decrypt(encryptedToken);
  }

  // Remove Token securely
  static Future<void> deleteToken() async {
    await storage.delete(key: "dbToken");
  }
}
