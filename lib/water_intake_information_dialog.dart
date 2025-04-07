import 'package:flutter/material.dart';

// Root Widget for Error Dialog
class WaterIntakeInformationDialog extends StatelessWidget {
  //Variables
  final List<dynamic> waterIntakePointInformation;
  final bool loggedIn;
  final Function() onClicked;

  //Constructor
  const WaterIntakeInformationDialog(
      {super.key,
      required this.waterIntakePointInformation,
      required this.loggedIn,
      required this.onClicked});

  //Build the Widget
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        backgroundColor: Colors.white,
        elevation: 10,
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Check if WaterIntakePoint has nearer Informations
              if (waterIntakePointInformation.length > 4 &&
                  waterIntakePointInformation[4].toString().isNotEmpty) ...[
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: "Name: ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  TextSpan(
                      text: waterIntakePointInformation[3],
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black))
                ])),
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: "Status: ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  TextSpan(
                      text: waterIntakePointInformation[4],
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black))
                ])),
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: "Type: ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  TextSpan(
                      text: waterIntakePointInformation[5],
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black))
                ])),
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: "Beschreibung: \n\n",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  TextSpan(
                      text: waterIntakePointInformation[6] + "\n",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black))
                ])),
                if (waterIntakePointInformation.length > 7 &&
                    waterIntakePointInformation[7].toString().isNotEmpty) ...[
                  Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Image.network(waterIntakePointInformation[7],
                          height: 100, width: 100, fit: BoxFit.cover))
                ]
              ] else ...[
                RichText(
                  text: TextSpan(
                      text: loggedIn
                          ? "Für diese Wasserentnahmestelle sind leider keine Informationen verfügbar"
                          : "Informationen nur als eingeloggter Benutzer verfügbar",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ]
            ]),
        actions: [
          TextButton(
            onPressed: () {
              onClicked();
              Navigator.of(context).pop();
            },
            child: const Text('Startpunkt setzen',
                style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Ok', style: TextStyle(color: Colors.black)),
          )
        ]);
  }

  // To make it use the right Context and still be a 1 liner
  static void show(
      BuildContext context,
      List<dynamic> waterIntakePointInformation,
      bool loggedIn,
      Function() onClicked) async {
    showDialog<void>(
      context: context,
      builder: (_) => WaterIntakeInformationDialog(
          waterIntakePointInformation: waterIntakePointInformation,
          loggedIn: loggedIn,
          onClicked: onClicked),
    );
  }
}
