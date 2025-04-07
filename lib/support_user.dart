import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loeschwasserfoerderung/crypto.dart';
import 'error_dialog.dart';

//User Class for Dashboard
class User {
  //Variables
  String username;
  String password;
  String? newUsername;
  String? newPassword;
  bool isAdmin;
  bool expanded;

  //Constructor
  User(
      {required this.username,
      required this.password,
      this.newUsername,
      this.newPassword,
      required this.isAdmin,
      required this.expanded});

  // Factory method to create a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      password: json['password'],
      isAdmin: json['admin'] == 1 ? true : false,
      expanded: false,
    );
  }

  //Delete user from the API (Database)
  Future<bool> deleteUser(BuildContext context) async {
    //Get Data from API
    final url = "https://xn--lschwasserfrderung-d3bk.at/api/deleteUser.php";
    try {
      final response = await http.post(
        Uri.parse(url),
        body: await Crypto.encrypt(
            json.encode({'username': username, 'password': password})),
      );

      final data = json.decode(await Crypto.decrypt(response.body) ?? "");
      if (response.statusCode == 200) {
        return true;
      } else {
        ErrorDialog.show(context, data["error"]);
        return false;
      }
    } catch (ex) {
      ErrorDialog.show(context, ex.toString());
      return false;
    }
  }

  //Update user in the API (Database)
  Future<void> updateUser(BuildContext context) async {
    newUsername ??= username;
    newPassword ??= password;
    //Get Data from API
    final url = "https://xn--lschwasserfrderung-d3bk.at/api/updateUser.php";
    try {
      final response = await http.post(
        Uri.parse(url),
        body: await Crypto.encrypt(json.encode({
          'username': username,
          'password': password,
          'newUsername': newUsername,
          'newPassword': newPassword,
          'isAdmin': isAdmin.toString()
        })),
      );

      final data = json.decode(await Crypto.decrypt(response.body) ?? "");
      if (response.statusCode == 200) {
        username = newUsername!;
        password = newPassword!;
      } else {
        ErrorDialog.show(context, data["error"]);
      }
    } catch (ex) {
      ErrorDialog.show(context, ex.toString());
    }
  }

  // Generate a Password and encrypt with SHA512
  void generateNewPassword(BuildContext context) {
    final random = Random();
    const allChars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=[]{}|;:,.<>?/~';

    // Generate 12 Character password
    final password =
        List.generate(12, (index) => allChars[random.nextInt(allChars.length)])
            .join();

    final hashedPassword = encryptPassword(password);

    // Update the password for the user
    newPassword = hashedPassword;

    // Show the generated password in an AlertDialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Neues Passwort'),
          content: Text(
            'Das neue Passwort lautet: $password',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Schließen'),
            ),
          ],
        );
      },
    );
  }

  //Encrypt Password
  String encryptPassword(String password) {
    // Encrypt the password using SHA-512
    final bytes = utf8.encode(password);
    final digest = sha512.convert(bytes);
    return digest.toString();
  }
}
