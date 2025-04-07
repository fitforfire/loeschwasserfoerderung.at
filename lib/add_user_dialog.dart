import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'support_user.dart';
import 'error_dialog.dart';

// Root Widget for LoadingScreen-Page
class AddUserDialog extends StatefulWidget {
  // Variables
  final Function(User) onUserAdded;

  // Constructor
  const AddUserDialog({super.key, required this.onUserAdded});

  //Create State
  @override
  AddUserDialogState createState() => AddUserDialogState();
}

//State for Switch-Widget
class AddUserDialogState extends State<AddUserDialog> {
  // Variables
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  FocusNode passwordFocusNode = FocusNode();
  bool isAdmin = false;

  // Build the Widget
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: const Text("Neuen Benutzer hinzufügen"),
        contentPadding: const EdgeInsets.all(16.0),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: "Benutzername",
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(passwordFocusNode);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                focusNode: passwordFocusNode,
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: "Passwort",
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: isAdmin,
                    onChanged: (bool? newValue) {
                      setState(() {
                        isAdmin = newValue ?? false;
                      });
                    },
                  ),
                  const Text("Admin-Rechte"),
                ],
              ),
            ],
          ),
        ),
        actionsPadding:
            const EdgeInsets.only(bottom: 20.0, left: 16.0, right: 16.0),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  child:
                      const Text("Abbrechen", overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (usernameController.text.isNotEmpty &&
                        passwordController.text.isNotEmpty) {
                      final newUser = User(
                        username: usernameController.text,
                        password: sha512
                            .convert(utf8.encode(passwordController.text))
                            .toString(),
                        expanded: false,
                        isAdmin: isAdmin,
                      );
                      widget.onUserAdded(newUser);
                      Navigator.of(context).pop();
                    } else {
                      ErrorDialog.show(
                          context, "Bitte füllen Sie alle Felder aus.");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  child:
                      const Text("Hinzufügen", overflow: TextOverflow.ellipsis),
                ),
              )
            ],
          )
        ]);
  }
}
