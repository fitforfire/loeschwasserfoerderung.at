import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

//Root Widget for External-Link
class ExternalLink extends StatelessWidget {
  //Variables
  final String url;
  final String text;

  //Constructor
  const ExternalLink({super.key, required this.url, required this.text});

  //Build the Widget
  @override
  Widget build(BuildContext context) {
    //Handle Tap on URL/Link
    return GestureDetector(
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(url))) {
          //Open URL
          await launchUrl(Uri.parse(url));
        } else {
          //Handle Problem with URL
          throw "$url konnte leider nicht geöffnet werden";
        }
      },
      //Show Tooltip when hovering over URL/Link
      child: Tooltip(
        //Show Tooltip Message
        message: "Öffnet die Website: $url",
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //Display URL
            Text(text,
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center),
            //Space between Icon & Text
            SizedBox(width: 5),
            //Show Link Icon
            Icon(
              Icons.open_in_new,
              size: 12,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
