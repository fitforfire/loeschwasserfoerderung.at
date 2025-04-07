import 'package:flutter/material.dart';

// Root Widget for Error Dialog
class SuccessDialog extends StatelessWidget {
  //Variables
  final String message;

  //Constructor
  const SuccessDialog({super.key, required this.message});

  //Build the Widget
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Erfolgreich"),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("OK"),
        ),
      ],
    );
  }

  // To make it use the right Context and still be a 1 liner
  static void show(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (_) => SuccessDialog(message: message),
    );
  }
}
