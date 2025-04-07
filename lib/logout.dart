import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support_page.dart';

import 'user_credentials.dart';

//Root Widget for Logout-Page
class LogoutPage extends StatefulWidget {
  //Constructor
  const LogoutPage({super.key});

  //Create State
  @override
  LogoutPageState createState() => LogoutPageState();
}

//State for Logout-Page
class LogoutPageState extends State<LogoutPage> {
  //Variable
  FlutterSecureStorage storage = FlutterSecureStorage();

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
      resizeToAvoidBottomInset: true,
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
                  // Logo & Title
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
                  // Logout Button
                  ElevatedButton(
                    onPressed: () {
                      logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32.0,
                        vertical: 12.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      "Ausloggen",
                      style: TextStyle(fontSize: 16, color: Colors.white),
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

  //Logout (Delete Userdata and Tokens locally)
  void logout() async {
    await storage.delete(key: "token");
    UserCredentials userCredentials = UserCredentials();
    await userCredentials.delete();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("isAdmin");
    prefs.remove("username");
    prefs.remove("password");
    Navigator.pop(context, false);
  }
}
