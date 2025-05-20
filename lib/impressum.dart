import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:loeschwasserfoerderung/video_player_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'external_link.dart';
import 'support_page.dart';

//Root Widget for Impressum-Page
class InfoPage extends StatefulWidget {
  //Constructor
  const InfoPage({super.key});

  //Create State
  @override
  InfoPageState createState() => InfoPageState();
}

//State for Impressum-Page
class InfoPageState extends State<InfoPage> {
  //Build the Page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //NavBar
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        title: const Text("Info"),
      ),
      resizeToAvoidBottomInset: true,
      //Body
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      //Trailer - Headline
                      const Text(
                        "Trailer",
                        style: TextStyle(fontSize: 20.0, color: Colors.deepOrange),
                        textAlign: TextAlign.center,
                      ),
                      //VideoPlayer
                      VideoPlayerWidget(videoUrl: "https://xn--lschwasserfrderung-d3bk.at/trailer.mp4", volume: 20, width: 300, height: 200),
                      const SizedBox(height: 20.0),
                      //Service & Information - Headline
                      const Text(
                        "Service und Information",
                        style: TextStyle(fontSize: 20.0, color: Colors.deepOrange),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10.0),
                      // Service & Information - E-Mail
                      Center(
                        //Tooltip when hovering over Text
                        child: Tooltip(
                          message: "E-Mail senden",
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: "E-Mail: ",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16.0,
                                  ),
                                ),
                                TextSpan(
                                  text: "support@löschwasserförderung.at",
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 16.0,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer:
                                      TapGestureRecognizer()
                                        ..onTap = () {
                                          launchUrl(
                                            Uri.parse(
                                              "mailto:support@löschwasserförderung.at",
                                            ),
                                          );
                                        },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      //Service & Information - Telephone
                      Center(
                        //Tooltip when hovering over Text
                        child: Tooltip(
                          message: "Telefon anrufen",
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: "Telefon: ",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16.0,
                                  ),
                                ),
                                TextSpan(
                                  text: "06604 122 122",
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 16.0,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer:
                                      TapGestureRecognizer()
                                        ..onTap = () {
                                          launchUrl(
                                            Uri.parse("tel:+436604122122"),
                                          );
                                        },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      //Service & Information - Support Formular
                      Center(
                        child: Tooltip(
                          message: "Support Formular öffnen",
                          child: ElevatedButton(
                            onPressed: () async {
                              ScaffoldMessenger.of(
                                context,
                              ).removeCurrentSnackBar();
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SupportPage(),
                                ),
                              );
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32.0,
                                vertical: 12.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text(
                              "Support Formular",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      //Vision - Headline
                      const Text(
                        "Vision",
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.deepOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      // Vision - Text
                      const Text(
                        "Löschwasserförderung dient zur automatisierten Berechnung der TS-Standorte entlang einer Relaisleitung",
                        style: TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20.0),
                      //Information - Headline
                      const Text(
                        "Informationen",
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.deepOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      // Information - Text
                      const Text(
                        "Die Relaisleitung kann eine maximale Länge von ca. 11 Kilometern haben",
                        style: TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10.0),
                      //Information - Text
                      const Text(
                        "Die Blickrichtung des Gerätes ist nur in der heruntergeladenen Version verfügbar (aufgrund von Internetrichtlinien)",
                        style: TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10.0),
                      //Information - Text
                      const Text(
                        "Die Vollversion (Wasserentnahmestelleninformationen) ist nur als angemeldeter Benutzer verfügbar",
                        style: TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20.0),
                      //Description - Headline
                      const Text(
                        "Beschreibung",
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.deepOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Description - Subheading
                      const Text(
                        "Start- und Endpunkt",
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.deepOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Description Startpoint - Text
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(fontSize: 12.0, color: Colors.black),
                          children: [
                            TextSpan(
                              text:
                                  "Der Startpunkt der Relaisleitung wird mit Klick auf die Karte gesetzt (ausgenommen ",
                            ),
                            TextSpan(
                              text: "Startpunkt ist Standort",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ", "),
                            TextSpan(
                              text: "GPS verfolgen",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: " und "),
                            TextSpan(
                              text: "Hybrid",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ")"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5.0),
                      //Description - StartPoint - WaterIntake
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(fontSize: 12.0, color: Colors.black),
                          children: [
                            TextSpan(
                              text:
                                  "Der Startpunkt einer Relaisleitung kann auch per Klick auf den Knopf ",
                            ),
                            TextSpan(
                              text: "Startpunkt setzen",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  " in einer Wasserentnahmestelle gesetzt werden",
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 5.0),
                      //Description Endpoint - Text
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(fontSize: 12.0, color: Colors.black),
                          children: [
                            TextSpan(
                              text:
                                  "Der Endpunkt wird mit dem zweiten Klick auf die Karte gesetzt (ausgenommen ",
                            ),
                            TextSpan(
                              text: "Startpunkt is Standort",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ", "),
                            TextSpan(
                              text: "Freihandzeichnen",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ", "),
                            TextSpan(
                              text: "GPS verfolgen",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: " und "),
                            TextSpan(
                              text: "Hybrid",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ")"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15.0),
                      //Description - Subheading
                      const Text(
                        "Löschen und Informationen",
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.deepOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Description - Text
                      const Text(
                        "Eine Relaisleitung kann mit Klick auf deren Start- oder Endpunkt gelöscht werden",
                        style: TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Description - Text
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(fontSize: 12.0, color: Colors.black),
                          children: [
                            TextSpan(text: "Im Modus "),
                            TextSpan(
                              text: "Freihandzeichnen",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  " kann ein Zwischenpunkt mit Klick auf diesen gelöscht werden",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15.0),
                      //Description - Text
                      const Text(
                        "Die Informationen der Relaisleitung können ebenfalls mit Klick auf deren Start- oder Endpunkt erneut angezeigt werden",
                        style: TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Description - Text
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(fontSize: 12.0, color: Colors.black),
                          children: [
                            TextSpan(
                              text:
                                  "Die Informationen einer Wasserentnahmestelle können mit Klick auf diese angezeigt werden (",
                            ),
                            TextSpan(
                              text: "nur für angemeldete Benutzer",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ")"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15.0),
                      //Description - Text
                      const Text(
                        "Nicht angemeldete Benutzer sehen möglicherweise nur eine eingeschränkte Anzahl an Wasserentnahmestellen",
                        style: TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15.0),
                      //Description - Subheading
                      const Text(
                        "Ortssuche",
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.deepOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Description - Text
                      const Text(
                        "Das gesuchte Addresse wird als Roter Marker auf der Karte angezeigt",
                        style: TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Description - Text
                      const Text(
                        "Der Marker kann mit Klick auf diesen gelöscht werden",
                        style: TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15.0),
                      //Description - Subheading
                      const Text(
                        "Modis",
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.deepOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Description - Text
                      const Text(
                        "In den Einstellungen kann man zwischen 5 Zeichenmodis auswählen:",
                        style: TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Description - Text
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(fontSize: 12.0, color: Colors.black),
                          children: [
                            TextSpan(text: "1.) "),
                            TextSpan(
                              text: "Entlang der Straße/Weg",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  ": Zeichnet die Relaisleitung entlang der nächstgelegenen Straße/Weg",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5.0),
                      //Description - Text
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(fontSize: 12.0, color: Colors.black),
                          children: [
                            TextSpan(text: "2.) "),
                            TextSpan(
                              text: "Gerade Linie",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  ": Zeichnet eine Gerade Linie vom Start- bis zum Endpunkt",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5.0),
                      //Description - Text
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(fontSize: 12.0, color: Colors.black),
                          children: [
                            TextSpan(text: "3.) "),
                            TextSpan(
                              text: "Freihandzeichnen",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  ": Zeichnet eine Gerade Linie mit beliebig vielen Eckpunkten",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5.0),
                      //Description - Text
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(fontSize: 12.0, color: Colors.black),
                          children: [
                            TextSpan(text: "4.) "),
                            TextSpan(
                              text: "GPS verfolgen",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  ": Zeichnet die Linie entlang der Benutzerbewegung auf",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5.0),
                      //Description - Text
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(fontSize: 12.0, color: Colors.black),
                          children: [
                            TextSpan(text: "5.) "),
                            TextSpan(
                              text: "Hybrid",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  ": Zeichnet die Linie entlang der Benutzerbewegung, Benutzer kann aber manuell Pumpen setzen",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      //Team - Headline
                      const Text(
                        "Team",
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.deepOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Team - Subheading
                      const Text(
                        "Entwicklung",
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.deepOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      //Team - Development - Name
                      const ExternalLink(
                        url: "https://stefanrautner.netlify.app",
                        text: "Stefan Rautner (FF Kuchl)",
                      ),
                      const SizedBox(height: 15.0),
                      const Text(
                        "Projektuntersützung",
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.deepOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Team - Development-support - Name
                      const ExternalLink(
                        url: "https://www.florian-bischof.at",
                        text: "Florian Bischof (FF Kennelbach)",
                      ),
                      const SizedBox(height: 5.0),
                      //Team - Development-support - Name
                      const ExternalLink(
                        url: "https://www.shofer.at/",
                        text: "Stefan Hofer (FF Saalfelden)",
                      ),
                      const SizedBox(height: 5.0),
                      //Team - Development-support - Name<
                      const ExternalLink(
                        url: "https://voetter.info/",
                        text: "Stefan Vötter (FF Kuchl)",
                      ),
                      const SizedBox(height: 15.0),
                      const Text(
                        "Trailer",
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.deepOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Team - Trailer - Name
                      const Text(
                        "Felix Aigner (FF Kuchl)",
                        style: TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Team - Trailer - Name
                      const Text(
                        "Pierre Aigner (FF Kuchl)",
                        style: TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Team - Trailer - Name
                      const Text(
                        "Pascal Herbst (FF Kuchl)",
                        style: TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Team - Trailer - Name
                      const Text(
                        "Tobias Höllbacher (FF Kuchl)",
                        style: TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Team - Trailer - Name
                      const Text(
                        "Felix Schwaiger (FF Kuchl)",
                        style: TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Team - Trailer - Name
                      const Text(
                        "Jakob Volleritsch (FF Kuchl)",
                        style: TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20.0),
                      //Sources - Headline
                      const Text(
                        "Datenquelle",
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.deepOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Sources - Map
                      const ExternalLink(
                        url: "https://www.openstreetmap.org",
                        text: "Karte",
                      ),
                      const SizedBox(height: 10.0),
                      //Sources - Elevation
                      const ExternalLink(
                        url: "https://elevation.geocode.at",
                        text: "Berechnung Relaisleitung",
                      ),
                      const SizedBox(height: 10.0),
                      //Sources - Routing
                      const ExternalLink(
                        url: "https://routing.openstreetmap.de",
                        text: "Routenberechnung",
                      ),
                      const SizedBox(height: 10.0),
                      //Sources - Hydrants
                      const ExternalLink(
                        url:
                            "https://www.overpass-api.de" /*"https://www.objektdatenbank.at"*/,
                        text: "Wasserentnahmestellen",
                      ),
                      const SizedBox(height: 10.0),
                      //Sources - Locations
                      const ExternalLink(
                        url: "https://www.geocode.at",
                        text: "Address- und Hofnamensuche",
                      ),
                      const SizedBox(height: 10.0),
                      //Missing Hydrants - Headline
                      const Text(
                        "Fehlende Wasserentnahmestellen?",
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.deepOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Missing Hydrants - Text
                      const ExternalLink(
                        url: "https://www.osmhydrant.org/beta",
                        text:
                            "Bitte hier einfügen (https://www.osmhydrant.org/beta)",
                      ),
                      const SizedBox(height: 20.0),
                      //Version - Headline
                      const Text(
                        "Version",
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.deepOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5.0),
                      //Version - Text
                      Text(
                        "1.31.57",
                        style: TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
