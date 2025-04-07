import 'dart:convert';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loeschwasserfoerderung/crypto.dart';
import 'package:loeschwasserfoerderung/error_dialog.dart';
import 'custom_autocompletion_field.dart';
import 'loading_screen.dart';

//Root Widget for RestBar-Layer
class SupportPage extends StatefulWidget {
  //Constructor
  const SupportPage({super.key});

  //Create State
  @override
  SupportPageState createState() => SupportPageState();
}

//State for Support-Page
class SupportPageState extends State<SupportPage> {
  //Variables
  TextEditingController subjectController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController bodyController = TextEditingController();
  FocusNode bodyFocusNode = FocusNode();
  final List<String> issues = [
    "Passwort vergessen",
    "Passwort ändern",
    "Neuen Benutzer beantragen",
    "Benutzer löschen",
    "Fehler/Problem in der Anwendung",
    "Änderungswünsche für die Anwendung",
    "Fehlende Funktion in der Anwendung",
    "Anderes (bitte kurz beschreiben)"
  ];

  //Build the Page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //NavBar
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        title: const Text("Support Formular"),
      ),
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[800],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          // Center widget ensures horizontal centering
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
                    "Support Formular",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40.0),
              //Support Container
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
                    //AutoComplete for Topic
                    CustomAutocompletionField(
                        controller: subjectController,
                        suggestions: issues,
                        label: "Wählen Sie ein Thema aus",
                        noItemFound: "Bitte selbst kurz beschreiben",
                        selectAll: true),
                    const SizedBox(height: 16),
                    //Input Field E-Mail Address
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Ihre Email-Adresse",
                        labelStyle: TextStyle(color: Colors.grey[800]),
                        hintText: "Beispiel: beispiel@gmail.com",
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(bodyFocusNode);
                      },
                    ),
                    const SizedBox(height: 16),
                    //Optional Message Field
                    TextFormField(
                      focusNode: bodyFocusNode,
                      controller: bodyController,
                      decoration: InputDecoration(
                        labelText: "Zusätzliche Nachricht (optional)",
                        labelStyle: TextStyle(color: Colors.grey[800]),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24.0),
                    //Submit button
                    ElevatedButton(
                      onPressed: sendEmail,
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
                        "Senden",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //send the Support Form Data to the API (to send it via E-Mail)
  void sendEmail() async {
    final email = emailController.text.trim();
    final subject = subjectController.text.trim();

    //Check if E-Mail Inp ut is a valid E-Mail Address
    if (EmailValidator.validate(email)) {
      //Check if topic Selected
      if (subject == "") {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bitte wählen Sie ein Thema aus")),
        );
        return;
      }

      final body = bodyController.text.trim();

      //show Loading Screen
      showLoadingScreen();

      //Send Data to API
      try {
        final response = await http.post(
          Uri.parse("https://xn--lschwasserfrderung-d3bk.at/api/sendEmail.php"),
          body: await Crypto.encrypt(json.encode({
            "from": email,
            "subject": subject,
            "message": body,
          })),
          headers: {"Content-Type": "application/json; charset=utf-8"},
        );

        final data = json.decode(await Crypto.decrypt(response.body) ?? "");

        //Show SnackBar with API response
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );

        //If E-Mail sent successfully --> reset all Fields
        if (response.statusCode == 200) {
          emailController.clear();
          bodyController.clear();
          subjectController.clear();
        } else {
          ErrorDialog.show(context, data["error"]);
        }
      } catch (ex) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kein Zugriff auf Server")),
        );
      } finally {
        hideLoadingScreen();
      }
    } else {
      hideLoadingScreen();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ungültige Email-Adresse")),
      );
    }
  }

  //ShowLoadingScreen (show the LoadingScreen-Page)
  void showLoadingScreen() {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => const LoadingScreen(),
    ));
  }

  //HideLoadingScreen (hide the LoadingScreen-Page)
  void hideLoadingScreen() {
    Navigator.of(context).pop();
  }
}
