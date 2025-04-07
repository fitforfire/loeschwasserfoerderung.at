import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:loeschwasserfoerderung/crypto.dart';
import 'package:loeschwasserfoerderung/token_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// UserCredentials Class
class UserCredentials {
  // Variables
  static final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  //Save Username and Password to Storage (after User Login)
  Future<void> save(String? username, String? password) async {
    if (username != null) {
      await secureStorage.write(key: 'username', value: username);
    }
    if (password != null) {
      await secureStorage.write(key: 'password', value: password);
    }
  }

  //Load Username and Password from secure Storage (at start of App)
  static Future<void> loadTokens() async {
    String? username = await secureStorage.read(key: 'username');
    String? password = await secureStorage.read(key: 'password');

    //Get Tokens from API
    final url = "https://xn--lschwasserfrderung-d3bk.at/api/checkUser.php";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: await Crypto.encrypt(json.encode({
          'username': username,
          'password': password,
        })),
      );

      //Process Response
      final data = json.decode(await Crypto.decrypt(response.body) ?? "");
      if (response.statusCode == 200) {
        if (data.containsKey("dbToken")) {
          await SecureTokenStorage.saveToken(data["dbToken"]);
        }
      }
    } catch (ignored) {}
  }

  //Delete Username and Password (after User Logout)
  Future<void> delete() async {
    await secureStorage.delete(key: 'username');
    await secureStorage.delete(key: 'password');
  }

  //Check if userLoggedInBefore() {
  static Future<bool> userLoggedInBefore() async {
    String? username = await secureStorage.read(key: 'username');
    String? password = await secureStorage.read(key: 'password');

    return username != null && password != null;
  }

  //Check if User is logged in
  static Future<bool> userExists() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      String? username = await secureStorage.read(key: 'username');
      String? password = await secureStorage.read(key: 'password');

      if (username == null || password == null) {
        return false;
      }

      //Check, if User exists
      final url = "https://xn--lschwasserfrderung-d3bk.at/api/existsUser.php";
      final response = await http.post(
        Uri.parse(url),
        body: await Crypto.encrypt(json.encode({
          'username': username,
          'password': password,
        })),
      );

      // Check if the response is successful and contains the correct data
      if (response.statusCode == 200) {
        final data = json.decode(await Crypto.decrypt(response.body) ?? "");
        await prefs.setBool("isAdmin", data["admin"]);
        return true;
      } else {
        return false;
      }
    } catch (ex) {
      return false;
    }
  }
}
