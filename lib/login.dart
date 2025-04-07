import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:loeschwasserfoerderung/crypto.dart';
import 'package:loeschwasserfoerderung/token_handler.dart';
import 'package:loeschwasserfoerderung/user_credentials.dart';
import 'error_dialog.dart';
import 'support_page.dart';

// Root Widget for Login-Page
class LoginPage extends StatefulWidget {
  //Constructor
  const LoginPage({super.key});

  //Create State
  @override
  LoginPageState createState() => LoginPageState();
}

//State for Login-Page
class LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode usernameFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  //Build the App
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //NavBar
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        title: const Text("Ausloggen"),
      ),
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[800],
      //Make the Page Scrollable (if needed)
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: Column(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //Logo & Title
                  Column(
                    children: [
                      Image.asset(
                        "assets/icons/icon.png",
                        height: 60,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Löschwasserförderung",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40.0),
                  //Login-Box
                  Container(
                    width: 350,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.blue[200],
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        //Input field Username
                        TextField(
                          controller: usernameController,
                          focusNode: usernameFocusNode,
                          decoration: InputDecoration(
                            labelText: "Name der Feuerwehr",
                            labelStyle: TextStyle(color: Colors.grey[800]),
                            hintText: "Beispiel: FF-Kuchl",
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          textInputAction: TextInputAction.next,
                          onSubmitted: (value) {
                            FocusScope.of(context)
                                .requestFocus(passwordFocusNode);
                          },
                        ),
                        const SizedBox(height: 16.0),
                        //Input field Username
                        TextField(
                          controller: passwordController,
                          focusNode: passwordFocusNode,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Passwort",
                            labelStyle: TextStyle(color: Colors.grey[800]),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          textInputAction: TextInputAction.next,
                          onSubmitted: (value) {
                            login();
                          },
                        ),
                        const SizedBox(height: 24.0),
                        //Submit Button
                        ElevatedButton(
                          onPressed: () {
                            login();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32.0,
                              vertical: 12.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text(
                            "Einloggen",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  //Spacer (so Information Button isn't directly below)
                  const SizedBox(height: 20),
                ],
              ),
            ),
            //Support Formular Button
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SupportPage(),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  label: const Text("Support Formular"),
                  icon: const Icon(Icons.support_agent_outlined),
                  backgroundColor: Colors.blue[200],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Login (API Connection --> Get Tokens)
  void login() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    //Check Input Fields for Content
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bitte alle Felder ausfüllen"),
        ),
      );
      return;
    }

    //Encrypt Password (SHA 512)
    password = sha512.convert(utf8.encode(password)).toString();

    //Get Data from API
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
          UserCredentials().save(username, password);
          await SecureTokenStorage.saveToken(data["dbToken"]);
          Navigator.pop(context, true);
        }
      } else {
        ErrorDialog.show(context, data["error"]);
      }
    } catch (ex) {
      ErrorDialog.show(context, ex.toString());
    }
  }
}
