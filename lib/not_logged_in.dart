import 'package:flutter/material.dart';

//Root Widget for NotLoggedIn-Layer
class NotLoggedInLayer extends StatelessWidget {
  //Constructor
  const NotLoggedInLayer({super.key});

  //Build the Widget
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10.0,
      left: 10.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          "Nicht eingeloggt!",
          style: const TextStyle(color: Colors.white, fontSize: 16.0),
        ),
      ),
    );
  }
}
