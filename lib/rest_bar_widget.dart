import 'package:flutter/material.dart';

//Root Widget for RestBar-Layer
class RestBarLayer extends StatelessWidget {
  //variable
  final double remainingBarToNextPump;

  //Constructor
  const RestBarLayer({super.key, required this.remainingBarToNextPump});

  //Build the Widget
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10.0,
      right: 10.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          "Restbar: ${remainingBarToNextPump.toStringAsFixed(2)} bar",
          style: const TextStyle(color: Colors.white, fontSize: 16.0),
        ),
      ),
    );
  }
}
