import 'package:flutter/material.dart';

//Root Widget for LoadingScreen-Page
class LoadingScreen extends StatelessWidget {
  //Constructor
  const LoadingScreen({super.key});

  //Build the Page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
