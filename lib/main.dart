import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:loeschwasserfoerderung/search_location_marker.dart';
import 'package:loeschwasserfoerderung/support_notificator.dart';
import 'package:loeschwasserfoerderung/token_handler.dart';
import 'package:loeschwasserfoerderung/water_intake_information_dialog.dart';
import 'package:loeschwasserfoerderung/water_intake_point_markers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'error_dialog.dart';
import 'impressum.dart';
import 'login.dart';
import 'not_logged_in.dart';
import 'location_search_page.dart';
import 'rest_bar_widget.dart';
import 'support_dashboard.dart';
import 'user_credentials.dart';
import 'loading_screen.dart';
import 'logout.dart';
import 'settings.dart';

//Main
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await dotenv.load(fileName: "assets/config/.env_web");
  } else {
    await dotenv.load(fileName: "assets/config/.env");
  }
  runApp(const MyApp());
}

//Root Widget for Application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //Build the Homepage
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false, home: MyHomePage());
  }
}

//Root Widget for Home-Page
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  //Create State
  @override
  State<MyHomePage> createState() => MyHomePageState();
}

//State for Home-Page
class MyHomePageState extends State<MyHomePage> {
  //Define variables
  final MapController mapController = MapController();
  Distance distance = const Distance();
  double reloadTurn = 0.0;
  double zoomLevel = 17.0;
  LatLng currentPosition = const LatLng(47.6298967054189, 13.140870797983313);
  double currentZoom = 0.0;
  bool waterIntakePoints = true;
  int mode = 3;
  LatLng? startPoint;
  LatLng? endPoint;
  LatLng startMapPosition = const LatLng(47.6298967054189, 13.140870797983313);
  List<List<LatLng>> lineList = [];
  List<List<LatLng>> tsList = [];
  List<int> modeLineList = [];
  LatLng? startLocation;
  final double tolerance = 20.0;
  List<LatLng> pointListFree = [];
  List<LatLng> pointListRecord = [];
  List<LatLng> pointListHybrid = [];
  List<LatLng> partPointListHybrid = [];
  List<List<dynamic>> waterIntakePointsInformationList = [];
  List<dynamic> relayLineInformations = [];
  LatLng? userLocation;
  StreamSubscription<Position>? userlocationStreamSubscription;
  Timer? pathRecoveryAutoClick;
  Timer? waterIntakePointsTimer;
  bool isEndpoint = false;
  bool startIsLocationOn = false;
  double lengthPressureLoss = 100;
  double reserveHoseLength = 10;
  double maxPressureLoss = 8;
  bool initialLoad = true;
  bool errorPumpModeSnap = false;
  int numberOfTS = 0;
  double heightMeters = 0.0;
  int numberOfHoses = 0;
  double numberOfNeededBar = 8;
  LatLngBounds? bounds;
  MapCamera? hydrantwaterIntakePointCalledCamera;
  late StreamController<LatLng> locationStreamController;
  Key mapKey = UniqueKey();
  List<DateTime> showPopUpList = List.generate(6, (_) => DateTime.now());
  int minUserMoveDif = 15;
  ValueNotifier<double> mapHeadingNotifier = ValueNotifier<double>(0.0);
  bool gpsPermissionGranted = false;
  bool startGPSDenied = false;
  double remainingBarToNextPump = 8;
  bool loggedIn = false;
  bool isAdmin = false;
  bool loadingScreenShown = false;
  LatLng? foundPosition;

  //Initializer
  @override
  void initState() {
    super.initState();
    locationStreamController = StreamController<LatLng>();
    startUserLocationUpdates(true);
    loadSettings();
  }

  //Disposer
  @override
  void dispose() {
    SecureTokenStorage.deleteToken();
    locationStreamController.close();
    mapHeadingNotifier.dispose();
    waterIntakePointsTimer?.cancel();
    super.dispose();
  }

  //LoadSettings (Load needed Values from SharedPreferences & Secure Storage)
  Future<void> loadSettings() async {
    //Check if UserData changed, if User logged in before
    if (initialLoad) {
      if (await UserCredentials.userLoggedInBefore()) {
        loggedIn = await UserCredentials.userExists();
        final prefs = await SharedPreferences.getInstance();
        isAdmin = prefs.getBool("isAdmin") ?? false;

        if (loggedIn) {
          await UserCredentials.loadTokens();
        } else {
          ErrorDialog.show(context,
              "Benutzer existiert nicht mehr oder die Anmeldedaten haben sich geändert");
        }
      }
    }

    setState(() {
      mapKey = UniqueKey();
    });

    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool("popupAtTS") == null) {
      prefs.setBool("popupAtTS", true);
    }

    startMapPosition = userLocation ?? startMapPosition;

    zoomLevel = prefs.getDouble("zoomLevel") ?? zoomLevel;

    currentZoom = prefs.getDouble("currentZoom") ?? zoomLevel;
    double currentLat =
        prefs.getDouble("currentLat") ?? startMapPosition.latitude;
    double currentLng =
        prefs.getDouble("currentLng") ?? startMapPosition.longitude;
    currentPosition = LatLng(currentLat, currentLng);
  }

  //SaveSettings (Save needed Values to SharedPreferences)
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble("currentLat", currentPosition.latitude);
    prefs.setDouble("currentLng", currentPosition.longitude);
    prefs.setDouble("currentZoom", currentZoom);
  }

  //CheckPopup (check for Distance to TS - for Popup)
  Future<void> checkPopup(LatLng currentUserLocation) async {
    if (numberOfNeededBar != 0.0 || heightMeters != 0.0) {
      double numberOfRemainingBar = maxPressureLoss - numberOfNeededBar;
      double metersVertPerMeterHorizon = heightMeters / (numberOfHoses * 20);
      double verticalBarLossPerMeter = metersVertPerMeterHorizon * 1 / 10;
      double barLossPerMeter = verticalBarLossPerMeter + 0.01;
      double remainingMeters = numberOfRemainingBar / barLossPerMeter;

      DateTime currentTime = DateTime.now();

      if (remainingMeters < 520 &&
          remainingMeters > 480 &&
          currentTime.difference(showPopUpList[0]).inSeconds >= 5) {
        showPopup("TS in ca. 500 m setzen - weiterfahren");
        showPopUpList[0] = DateTime.now();
      } else if (remainingMeters < 270 &&
          remainingMeters > 230 &&
          currentTime.difference(showPopUpList[1]).inSeconds >= 5) {
        showPopup("TS in ca. 250 m setzen - weiterfahren");
        showPopUpList[1] = DateTime.now();
      } else if (remainingMeters < 120 &&
          remainingMeters > 80 &&
          currentTime.difference(showPopUpList[2]).inSeconds >= 5) {
        showPopup("TS in ca. 100 m setzen - weiterfahren");
        showPopUpList[2] = DateTime.now();
      } else if (remainingMeters < 70 &&
          remainingMeters > 30 &&
          currentTime.difference(showPopUpList[3]).inSeconds >= 5) {
        showPopup("TS in ca. 50 m setzen - weiterfahren");
        showPopUpList[3] = DateTime.now();
      } else if (remainingMeters < 35 &&
          remainingMeters > 15 &&
          currentTime.difference(showPopUpList[4]).inSeconds >= 5) {
        showPopup("TS in ca. 25 m setzen");
        showPopUpList[4] = DateTime.now();
      } else if ((remainingMeters <= 15 ||
              (tsList.isNotEmpty &&
                  tsList.last.isNotEmpty &&
                  isPointNearPoint(
                      currentUserLocation, tsList.last.last, 15))) &&
          currentTime.difference(showPopUpList[5]).inSeconds >= 5) {
        showPopupWithSound();
        showPopUpList = List.generate(6, (_) => DateTime.now());
      } else if (tsList.isNotEmpty) {
        if (isPointNearPoint(currentUserLocation, tsList.last.last, 15) &&
            currentTime.difference(showPopUpList[5]).inSeconds >= 5) {
          showPopupWithSound();
          showPopUpList = List.generate(6, (_) => DateTime.now());
        }
      }
    }
  }

  //startUserLocationUpdates (get the GPS-Permission (else go into restricted mode) & load the userLocation and update it every 10 meters)
  Future<void> startUserLocationUpdates(bool askUserLocation) async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (askUserLocation) {
      if (permission == LocationPermission.deniedForever) {
        Geolocator.openAppSettings();
      }

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        await Geolocator.requestPermission();
        permission = await Geolocator.checkPermission();
      }

      //Check/Wait for the GPS-Permission from the User
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        showGPSInformationDialog();
        gpsPermissionGranted = false;
      }
    }

    //UserLocation given (initialize userLocationStreamSubscriber)
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      gpsPermissionGranted = true;
      LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.best, distanceFilter: minUserMoveDif);

      userlocationStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) async {
        final prefs = await SharedPreferences.getInstance();
        LatLng newLocation = LatLng(position.latitude, position.longitude);

        if (userLocation == null || startGPSDenied) {
          if (startGPSDenied) {
            prefs.setInt("paintMode", 3);
            mode = 3;
            startGPSDenied = false;
          }
          locationStreamController.add(newLocation);
          mapController.move(newLocation, currentZoom);
        } else if (distance.as(LengthUnit.Meter, newLocation, userLocation!) >=
            minUserMoveDif) {
          locationStreamController.add(newLocation);

          if (prefs.getBool("followUser") == true || mode == 3 || mode == 4) {
            mapController.move(newLocation, currentZoom);
          }

          if (prefs.getBool("popupAtTS") == true) {
            checkPopup(newLocation);
          }
        }
      });
    } else {
      startGPSDenied = true;
      locationStreamController.add(startMapPosition);
      mode = 0;
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt("paintMode", 0);
    }
  }

  //LoadLines (create GUI-Element for the RelayLines)
  List<Polyline> loadLines() {
    return lineList.map((line) {
      return Polyline(points: line, color: Colors.blue, strokeWidth: 4.0);
    }).toList();
  }

  //LoadTSLocations (create GUI-Element for the TSLocations)
  List<Marker> loadTSLocations() {
    return tsList
        .map((tsLine) {
          return tsLine.map((tsLocation) {
            return Marker(
              width: 30.0,
              height: 30.0,
              point: tsLocation,
              child: const Icon(
                Icons.repeat_on,
                color: Colors.red,
                size: 20.0,
              ),
            );
          }).toList();
        })
        .expand((markers) => markers)
        .toList();
  }

  //LoadStartLocation (create GUI-Element for the StartLocation of the RelayLine)
  CircleMarker loadStartLocation() {
    return CircleMarker(point: startLocation!, color: Colors.blue, radius: 8.0);
  }

  //GetTSLocations (get a List of all Pumps in the RelayLine)
  Future<List<LatLng>> getTSLocations(List<LatLng> line) async {
    List<LatLng> tsLocations = [];
    List<double> latKoords = [];
    List<double> lngKoords = [];

    for (LatLng koord in line) {
      latKoords.add(koord.latitude);
      lngKoords.add(koord.longitude);
    }

    BaseOptions options = BaseOptions(receiveTimeout: Duration(seconds: 5000));

    final url =
        'https://elevation.geocode.at/elevation_schlauchleitung.php?lat=$latKoords&lng=$lngKoords&bar_grenze=$maxPressureLoss&reibung=$lengthPressureLoss&reserve=$reserveHoseLength';
    final response = await Dio(options)
        .get(url, options: Options(responseType: ResponseType.json));

    if (!response.data.toString().trim().startsWith("Problem") &&
        !response.data.toString().startsWith('{"Fehler')) {
      final decodedResponse = json.decode(response.data)[0];

      List<double> latKoords = List<double>.from(decodedResponse["p_lat"]
          .map((item) => double.tryParse(item.toString()) ?? 0.0));
      List<double> lngKoords = List<double>.from(decodedResponse["p_lng"]
          .map((item) => double.tryParse(item.toString()) ?? 0.0));
      numberOfTS = latKoords.length - 1;
      heightMeters = double.parse(
          (decodedResponse["p_H"].last - decodedResponse["p_H"][0])
              .toStringAsFixed(2));
      numberOfHoses = decodedResponse["p_schlauch_nr"].last;
      numberOfNeededBar = decodedResponse["p_bar"].last;
      while (numberOfNeededBar > maxPressureLoss) {
        numberOfNeededBar -= maxPressureLoss;
      }

      for (int i = 0; i < latKoords.length; i++) {
        tsLocations.add(LatLng(latKoords[i], lngKoords[i]));
      }
      tsLocations.removeLast();

      remainingBarToNextPump = maxPressureLoss - numberOfNeededBar;

      errorPumpModeSnap = false;

      //Add one extra Hose (if last calculatedPosition & userLocation ar between 10 & 15 meters from each other) in mode 3 ("GPS verfolgen")
      //--> If Pump placed 3 Hoses ago, not enough reserve to reach extra 15 meters (userLocation just updates every 15 meters)
      if (mode == 3 || mode == 4) {
        Position currentPosition = await Geolocator.getCurrentPosition();
        if (distance.as(LengthUnit.Meter, line.last,
                LatLng(currentPosition.latitude, currentPosition.longitude)) >=
            10) {
          numberOfHoses += 1;
        }
      }
    } else {
      errorPumpModeSnap = true;
      hideLoadingScreen();
      ErrorDialog.show(context,
          response.data.substring(11, response.data.toString().length - 2));
    }
    return tsLocations;
  }

  //isPointNearLine (Check if User-Click is near a RelayLine)
  bool isPointNearLine(LatLng point, List<LatLng> line, double tolerance) {
    for (LatLng linePoint in line) {
      if (distance.as(LengthUnit.Meter, point, linePoint) <= tolerance) {
        return true;
      }
    }
    return false;
  }

  //isPointNearLine (Check if User-Click is near a RelayLine)
  bool isPointNearPoint(LatLng pressedPoint, LatLng point, double tolerance) {
    if (distance.as(LengthUnit.Meter, pressedPoint, point) <= tolerance) {
      return true;
    } else {
      return false;
    }
  }

  //deleteLine (Delete the RelayLine)
  Future<void> deleteLine(int removeIndex) async {
    bool shouldDelete = (await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  title: const Text("Informationen & Löschen"),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                            text: TextSpan(children: [
                          TextSpan(
                              text: "Anzahl an benötigten Pumpen: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: "$numberOfTS"),
                        ])),
                        RichText(
                            text: TextSpan(children: [
                          TextSpan(
                              text: "Anzahl an benötigten B-Schläuchen: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: "$numberOfHoses"),
                        ])),
                        RichText(
                            text: TextSpan(children: [
                          TextSpan(
                              text: "Höhenmeter entlang der Schlauchleitung: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: "$heightMeters\n"),
                        ])),
                        const Text("Wollen Sie diese Relaisleitung löschen?")
                      ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Nein")),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Ja")),
                  ]);
            })) ??
        false;

    if (shouldDelete) {
      setState(() {
        lineList.removeAt(removeIndex);
        tsList.removeAt(removeIndex);
        modeLineList.removeAt(removeIndex);
        relayLineInformations.removeAt(removeIndex);
      });
    }
  }

  //deletePoint (delete a point from a mode 2 (Freihandzeichnen) relayline)
  Future<void> deletePoint(int lineIndex, LatLng pointToDelete) async {
    bool shouldDelete = (await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  title: const Text("Zwischenpunkt Löschen"),
                  content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Wollen Sie diesen Zwischenpunkt wirklich löschen?"),
                      ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Nein")),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Ja")),
                  ]);
            })) ??
        false;

    if (shouldDelete) {
      for (LatLng point in lineList[lineIndex]) {
        if (distance.as(LengthUnit.Meter, point, pointToDelete) <= tolerance) {
          List<LatLng> tmpList = lineList[lineIndex];
          tmpList.remove(point);
          List<LatLng> tmpTSList = await compute(getTSLocations, tmpList);

          setState(() {
            lineList[lineIndex].remove(point);
            tsList[lineIndex]
                .replaceRange(0, tsList[lineIndex].length, tmpTSList);
          });
          showInformationDialog(lineIndex);
          break;
        }
      }
    }
  }

  //ShowLoadingScreen (show the LoadingScreen-Page)
  void showLoadingScreen() {
    loadingScreenShown = true;
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => const LoadingScreen(),
    ));
  }

  //HideLoadingScreen (hide the LoadingScreen-Page)
  void hideLoadingScreen() {
    if (loadingScreenShown) {
      Navigator.of(context).pop();
    }
  }

  //showPopUp (Show the Popup for future TSLocations)
  Future<void> showPopup(String message) async {
    //if other Dialog is opened, close it
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text("INFO"),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                )
              ]);
        });
  }

  //showPopupWithSound (Show the Popup for TSLocation on UserLocation with Notification-Sound)
  Future<void> showPopupWithSound() async {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    AudioPlayer player = AudioPlayer();
    await player.play(AssetSource("sounds/notification.mp3"));

    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text("STOP"),
              content: const Text("HIER TS SETZEN"),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("OK"))
              ]);
        }).then((_) {
      player.stop();
      player.dispose();
    });
  }

  //ShowInformationDialog (show the InformationDialog after completing a RelayLine)
  Future<void> showInformationDialog(int? updateIndex) async {
    if (updateIndex != null) {
      relayLineInformations[updateIndex]["numberOfTS"] = numberOfTS;
      relayLineInformations[updateIndex]["numberOfHoses"] = numberOfHoses;
      relayLineInformations[updateIndex]["heightMeters"] = heightMeters;
    } else {
      relayLineInformations.add({
        "numberOfTS": numberOfTS,
        "numberOfHoses": numberOfHoses,
        "heightMeters": heightMeters
      });
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: const Text("Informationen"),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                      text: TextSpan(children: [
                    TextSpan(
                        text: "Anzahl an benötigten Pumpen: ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: "$numberOfTS")
                  ])),
                  RichText(
                      text: TextSpan(children: [
                    TextSpan(
                        text: "Anzahl an benötigten B-Schläuchen: ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: "$numberOfHoses"),
                  ])),
                  RichText(
                      text: TextSpan(children: [
                    TextSpan(
                        text: "Höhenmeter entlang der Schlauchleitung: ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: "$heightMeters"),
                  ]))
                ]),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"))
            ]);
      },
    );
  }

  //showEndpointSnackBar (show the SnackBar on the Bottom to ask the User if the Point is the End of the RelayLine)
  Future<bool> showEndPointSnackBar(int mode) async {
    final Completer<bool> completer = Completer<bool>();

    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    final snackBar = SnackBar(
        content:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Expanded(
              child: Text("Ist das der Endpunkt Ihrer Relaisleitung?",
                  style: TextStyle(color: Colors.white))),
          Row(children: [
            TextButton(
                onPressed: () {
                  if (!completer.isCompleted) {
                    completer.complete(true);
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  }
                },
                child: const Text("Ja", style: TextStyle(color: Colors.green))),
            TextButton(
                onPressed: () {
                  if (!completer.isCompleted) {
                    completer.complete(false);
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  }
                },
                child: const Text("Nein", style: TextStyle(color: Colors.red)))
          ])
        ]),
        backgroundColor: Colors.black87,
        duration: const Duration(days: 1));

    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((_) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    return completer.future;
  }

  //ShowStartSnackBar (show the Information SnackBar to tell the User how to start a RelayLine)
  Future<bool> showStartSnackBar() async {
    final Completer<bool> completer = Completer<bool>();

    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    const snackBar = SnackBar(
        content: Text(
            "Starten Sie die Berechnung mit Klick auf ihren gewünschten Startpunkt",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        duration: Duration());

    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    return completer.future;
  }

  //ShowStartSnackBar (show the Information SnackBar to tell the User how to start a RelayLine)
  Future<bool> showStartGPSFollowing() async {
    final Completer<bool> completer = Completer<bool>();

    // Remove any current SnackBars before showing a new one
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    // Create the SnackBar
    final snackBar = SnackBar(
        content:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Expanded(
              child: Text('Starten Sie die Berechnung mit Klick auf "Starten"',
                  style: TextStyle(color: Colors.white))),
          Row(children: [
            TextButton(
                onPressed: () {
                  if (!completer.isCompleted) {
                    completer.complete(true);
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  }
                },
                style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.green)),
                child: const Text("Starten",
                    style: TextStyle(color: Colors.black)))
          ])
        ]),
        backgroundColor: Colors.black87,
        duration: const Duration(days: 1));

    // Show the SnackBar
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    // Return the future when tapped
    return completer.future;
  }

  //showStartCalculationSnackBar (show the Information SnackBar to tell the User when the StartPoint for the RelayLine is set)
  Future<bool> showStartedCalculationSnackBar() async {
    final Completer<bool> completer = Completer<bool>();

    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    const snackBar = SnackBar(
        content: Text("Die Berechnung wurde gestartet",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        duration: Duration(seconds: 5));

    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    return completer.future;
  }

  //CalculateKoordWithSnappingToStreet (calculate the Koords for the RelayLine for mode 0)
  Future<List<LatLng>> calculateKoordsWithSnappingToStreet(
      List<LatLng?> tmpList) async {
    LatLng startPoint = tmpList[0]!;
    LatLng endPoint = tmpList[1]!;

    List<LatLng> koordList = [];
    try {
      final url =
          "https://routing.openstreetmap.de/routed-foot/route/v1/driving/${startPoint.longitude},${startPoint.latitude};${endPoint.longitude},${endPoint.latitude}?overview=full&alternatives=true&steps=false&geometries=geojson";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["routes"] != null && data["routes"].isNotEmpty) {
          final route = data["routes"][0];
          final geometry = route["geometry"];
          final List<dynamic> coordinates = geometry["coordinates"];
          koordList =
              coordinates.map((koord) => LatLng(koord[1], koord[0])).toList();
        }
      }
      return koordList;
    } catch (ex) {
      return koordList;
    }
  }

  //getWaterIntakePoints (load all available WaterIntakePoints in the current view of the user)
  Future<void> getWaterIntakePoints(List<dynamic> tmpList) async {
    LatLngBounds bounds = tmpList[0];
    double currentZoom = tmpList[1];
    if (currentZoom >= 15) {
      final boundBox =
          [bounds.south, bounds.west, bounds.north, bounds.east].join(',');
      List<List<dynamic>> waterIntakePointsList = [];

      //TODO: Implement Objektdatenbank and make if right again and make Types right (line 938-973)
      if (!loggedIn || true) {
        try {
          final url =
              'https://overpass-api.de/api/interpreter?data=[out:json][timeout:25]; '
              '(node["emergency"~"fire_hydrant|suction_point|water_tank|fire_water_pond"]($boundBox);); '
              'out geom;';
          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);

            List<dynamic> elements = data["elements"];
            for (dynamic element in elements) {
              if (element.isNotEmpty) {
                List<dynamic> waterIntakePoint = [];
                final type = element["tags"]["emergency"];
                if (type == "fire_hydrant") {
                  final exactType = element["tags"]["fire_hydrant:type"];
                  if (exactType == "pillar") {
                    waterIntakePoint.add(0);
                  } else {
                    waterIntakePoint.add(1);
                  }
                } else if (type == "water_tank") {
                  waterIntakePoint.add(3);
                } else if (type == "suction_point") {
                  waterIntakePoint.add(2);
                } else if (type == "fire_water_pond") {
                  waterIntakePoint.add(4);
                } else {
                  waterIntakePoint.add(5);
                }
                waterIntakePoint.add(element["lat"]);
                waterIntakePoint.add(element["lon"]);
                waterIntakePoint.add("overpass");
                waterIntakePointsList.add(waterIntakePoint);
              }
            }
          }
        } catch (ex) {
          ErrorDialog.show(
              context, "Problem beim Laden der Wasserentnahmestellen");
        }
      } else {
        try {
          String token = await SecureTokenStorage.getToken() ?? "";
          final url =
              'https://objektdatenbank.at/api/layer/<LAYER-ID>?bbox=$boundBox';

          final response = await http.post(
            Uri.parse(url),
            headers: {"authorization": "Token $token"},
          );

          if (response.statusCode == 200) {
            Map<String, dynamic> responseData = json.decode(response.body);
            for (var feature in responseData['features']) {
              final geometry = feature['geometry'];
              final properties = feature['properties'];

              List<dynamic> waterIntakePoint = [];
              if (properties["Type"] == "Hydrant") {
                //Überflurhydrant
                waterIntakePoint.add(0);
              } else if (properties["Type"] == "UnderfloorHydrant") {
                //Unterflurhydrant und Schachthydrant
                waterIntakePoint.add(1);
              } else if (properties["Type"] == "SuctionPoint") {
                //Saugstelle
                waterIntakePoint.add(2);
              } else if (properties["Type"] == "Basin") {
                //Löschwasserbehälter
                waterIntakePoint.add(3);
              } else if (properties["Type"] == "Pond") {
                //Löschwasserteich und Naturteich und Schwimmbad
                waterIntakePoint.add(4);
              } else if (properties["Type"] == "Well") {
                //Löschwasserbrunnen
                waterIntakePoint.add(5);
              }
              waterIntakePoint.add(double.parse(geometry["coordinates"][1]));
              waterIntakePoint.add(double.parse(geometry["coordinates"][0]));
              waterIntakePoint.add(properties["Name"]);
              waterIntakePoint.add(properties["Status"]);
              waterIntakePoint.add(properties["Type"]);
              waterIntakePoint.add(properties["Text"]);
              waterIntakePoint.add(properties["Image"]);

              waterIntakePointsList.removeWhere((e) =>
                e[0] == waterIntakePoint[0] &&
                e[3] == "overpass" &&
                (e[1] - waterIntakePoint[1]).abs() < 0.005 &&
                (e[2] - waterIntakePoint[2]).abs() < 0.005);

              waterIntakePointsList.add(waterIntakePoint);
            }
          } else {
            ErrorDialog.show(
                context, "Problem beim Laden der Wasserentnahmestellen");
          }
        } catch (ex) {
          ErrorDialog.show(
              context, "Problem beim Laden der Wasserentnahmestellen");
        }
      }

      if (waterIntakePointsList.isNotEmpty) {
        setState(() {
          waterIntakePointsInformationList = waterIntakePointsList;
        });
      }
    }
  }

  //showRequestGPSDialog (show restricted Mode information Dialog, if the GPS-Permission is not given)
  Future<void> showGPSInformationDialog() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Theme(
              data: Theme.of(context).copyWith(
                  dialogTheme: DialogThemeData(backgroundColor: Colors.white)),
              child: Container(
                  color: Colors.red,
                  child: AlertDialog(
                      title: const Text("Eingeschränkter Modus"),
                      content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                                "Es können folgende Funktionen ohne GPS nicht verwendet werden:",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text("- Benutzerstandort anzeigen"),
                            Text("- Startpunkt ist Standort"),
                            Text("- Benutzer im Mittelpunkt"),
                            Text("- Modus \"GPS verfolgen\""),
                            Text("- Modus \"Hybrid\"")
                          ]),
                      actions: <Widget>[
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Verstanden"))
                      ])));
        });
  }

  // Show Start and Endpoints as custom Symbols (for better visualisation)
  List<Marker> loadStartAndEndMarkers() {
    List<Marker> markers = [];
    bool mode3Painted = false;
    bool mode4Painted = false;

    for (int i = 0; i < lineList.length; i++) {
      if (!mode3Painted &&
          mode == 3 &&
          modeLineList.last != 3 &&
          pointListRecord.isNotEmpty) {
        mode3Painted = true;
        i -= 1;
        markers.add(startPointMarker(i));
      } else if (!mode4Painted &&
          mode == 4 &&
          modeLineList.last != 4 &&
          pointListHybrid.isNotEmpty) {
        mode4Painted = true;
        i -= 1;
        markers.add(startPointMarker(i));
      } else {
        // startpoint as Waterdrop
        if (lineList[i].isNotEmpty) {
          markers.add(startPointMarker(i));
          // endpoint as Flame
          if (modeLineList[i] != 2 ||
              (modeLineList[i] == 2 && pointListFree.isEmpty)) {
            if (lineList[i].length > 1) {
              markers.add(Marker(
                  width: 30.0,
                  height: 30.0,
                  point: lineList[i].last,
                  child: Icon(Icons.local_fire_department,
                      color: Colors.red, size: 30)));
            }
          }
        }
      }
    }
    return markers;
  }

  Marker startPointMarker(int index) {
    return Marker(
        width: 30.0,
        height: 30.0,
        point: lineList[index].first,
        child: Icon(Icons.water_drop, color: Colors.blue, size: 30));
  }

  Future<void> startModeThreeOrFour() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    pathRecoveryAutoClick =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      //if List is empty add the StartPoint, else add a partEndPoint (if User moved more then 15 meters)
      if ((mode == 3 && pointListRecord.isEmpty) ||
          (mode == 4 && partPointListHybrid.isEmpty)) {
        if (mode == 3) {
          pointListRecord.add(userLocation!);
        } else if (mode == 4) {
          partPointListHybrid.add(userLocation!);
        }

        //Update GUI (add the StartPoint of the RelayLine)
        setState(() {
          startLocation = userLocation!;
        });

        //show the StartedCalculationSnackBar
        showStartedCalculationSnackBar();

        //show the set Pump Popup with Sound
        if (prefs.getBool("popupAtTS") == true) {
          showPopupWithSound();
        }
      } else if ((mode == 3 &&
              distance.as(
                      LengthUnit.Meter, pointListRecord.last, userLocation!) >=
                  minUserMoveDif) ||
          ((mode == 4 &&
              distance.as(LengthUnit.Meter, partPointListHybrid.last,
                      userLocation!) >=
                  minUserMoveDif))) {
        if (mode == 3) {
          pointListRecord.add(userLocation!);
        } else if (mode == 4) {
          partPointListHybrid.add(userLocation!);
        }

        //Update GUI (remove the StartPoint of the RelayLine)
        if (startLocation != null) {
          setState(() {
            startLocation = null;
          });
        }

        List<LatLng> tmpList = [];
        List<LatLng> tmpPumpCalculationList = [];
        if (mode == 3) {
          tmpPumpCalculationList = tmpList = pointListRecord;
        } else if (mode == 4) {
          for (LatLng point in partPointListHybrid) {
            if (!pointListHybrid.contains(point)) {
              pointListHybrid.add(point);
            }
          }
          tmpPumpCalculationList = partPointListHybrid;
          tmpList = pointListHybrid;
        }

        //calculate the pumpLocations
        List<LatLng> pumpLocations = [];
        if (kIsWeb) {
          pumpLocations = await compute(getTSLocations, tmpPumpCalculationList);
        } else {
          pumpLocations = await getTSLocations(tmpPumpCalculationList);
        }

        if (pumpLocations.isNotEmpty) {
          //Update the GUI (check if the RelayLine is already shown, if yes update it)
          bool inList = false;
          for (int i = 0; i < lineList.length; i++) {
            if (mode == 3) {
              if (tmpList.length >= lineList[i].length) {
                if (listEquals(
                    lineList[i], tmpList.sublist(0, lineList[i].length))) {
                  if (!listEquals(lineList[i], tmpList)) {
                    setState(() {
                      lineList[i] = tmpList;
                      tsList[i] = pumpLocations;
                    });
                    inList = true;
                    break;
                  }
                }
              }
            } else if (mode == 4) {
              if (lineList[i].last == tmpList.first) {
                setState(() {
                  lineList[i].addAll(tmpList);
                  tsList[i] = pumpLocations;
                });
                inList = true;
                break;
              }
            }
          }

          //if the RelayLine is not already shown, add it
          if (!inList) {
            setState(() {
              lineList.add(tmpList);
              tsList.add(pumpLocations);
              modeLineList.add(mode);
            });
          }
        }
      }
    });
  }

  //Build the Page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
            title: LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Row(children: [
                  Image.asset("assets/icons/icon.png", height: 40),
                  const Spacer(),
                  //Reload
                  AnimatedRotation(
                      turns: reloadTurn,
                      duration: const Duration(seconds: 1),
                      child: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Karte neu laden'),
                              content: const Text('Möchtest du die Karte wirklich neu laden? Alle Daten werden zurückgesetzt'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Abbrechen'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Ja, neu laden'),
                                ),
                              ],
                            ),
                          ).then((confirm) {
                            if(confirm == true) {
                              setState(() {
                                mapKey = UniqueKey();
                                mapController.move(userLocation!, zoomLevel);
                                mapController.rotate(0.0);
                                mapHeadingNotifier.value = 0.0;
                                lineList = [];
                                tsList = [];
                                modeLineList = [];
                                startLocation = null;
                                pointListFree = [];
                                pointListRecord = [];
                                partPointListHybrid = [];
                                pointListHybrid = [];
                                foundPosition = null;
                              });

                              reloadTurn += 1.0;
                              startPoint = null;
                              endPoint = null;

                              pathRecoveryAutoClick?.cancel();
                              pathRecoveryAutoClick = null;
                            }
                          });
                        },
                      )),
                  //Compass
                  ValueListenableBuilder<double>(
                      valueListenable: mapHeadingNotifier,
                      builder: (context, mapHeading, child) {
                        return AnimatedRotation(
                            turns: (360 + mapHeading) / 360,
                            duration: const Duration(milliseconds: 20),
                            child: IconButton(
                                icon: const Icon(Icons.navigation),
                                onPressed: () {
                                  mapController.rotate(0);
                                  mapHeadingNotifier.value = 0.0;
                                }));
                      }),
                  //Locator
                  IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: () async {
                        final permission = await Geolocator.checkPermission();
                        if (permission == LocationPermission.denied ||
                            permission == LocationPermission.deniedForever) {
                          await startUserLocationUpdates(true);
                        } else if (userLocation != null) {
                          mapController.move(userLocation!, currentZoom);
                        }
                      })
                ]);
              } else {
                return Row(children: [
                  Image.asset("assets/icons/icon.png", height: 40),
                  const SizedBox(width: 8),
                  const Spacer(),
                  //Reload
                  AnimatedRotation(
                      turns: reloadTurn,
                      duration: const Duration(seconds: 1),
                      child: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Karte neu laden'),
                              content: const Text('Möchtest du die Karte wirklich neu laden? Alle Daten werden zurückgesetzt'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Abbrechen'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Ja, neu laden'),
                                ),
                              ],
                            ),
                          ).then((confirm) {
                            if(confirm == true) {
                              setState(() {
                                mapKey = UniqueKey();
                                mapController.move(userLocation!, zoomLevel);
                                mapController.rotate(0.0);
                                mapHeadingNotifier.value = 0.0;
                                lineList = [];
                                tsList = [];
                                modeLineList = [];
                                startLocation = null;
                                pointListFree = [];
                                pointListRecord = [];
                                partPointListHybrid = [];
                                pointListHybrid = [];
                                foundPosition = null;
                              });

                              reloadTurn += 1.0;
                              startPoint = null;
                              endPoint = null;

                              pathRecoveryAutoClick?.cancel();
                              pathRecoveryAutoClick = null;
                            }
                          });
                        },
                      )),
                  //Compass
                  ValueListenableBuilder<double>(
                      valueListenable: mapHeadingNotifier,
                      builder: (context, mapHeading, child) {
                        return AnimatedRotation(
                            turns: (360 + mapHeading) / 360,
                            duration: const Duration(milliseconds: 20),
                            child: IconButton(
                                icon: const Icon(Icons.navigation),
                                onPressed: () {
                                  mapController.rotate(0);
                                  mapHeadingNotifier.value = 0.0;
                                }));
                      }),
                  //Locator
                  IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: () async {
                        final permission = await Geolocator.checkPermission();
                        if (permission == LocationPermission.denied ||
                            permission == LocationPermission.deniedForever) {
                          await startUserLocationUpdates(true);
                        } else if (userLocation != null) {
                          mapController.move(userLocation!, currentZoom);
                        }
                      }),
                  //Search
                  IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        SharedPreferences preferences =
                            await SharedPreferences.getInstance();
                        preferences.setStringList("foundPosition", []);
                        await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SearchPage()))
                            .then((_) async {
                          await Future.delayed(Duration(seconds: 1));
                          SharedPreferences preferences =
                              await SharedPreferences.getInstance();
                          List<String>? foundPositionKoords =
                              preferences.getStringList("foundPosition");
                          if (foundPositionKoords != null &&
                              foundPositionKoords.isNotEmpty) {
                            foundPosition = LatLng(
                                double.parse(foundPositionKoords[0]),
                                double.parse(foundPositionKoords[1]));
                            setState(() {
                              mapKey = UniqueKey();
                            });
                            await Future.delayed(Duration(milliseconds: 10));
                            mapController.move(foundPosition!, currentZoom);
                          }
                        });
                      }),
                  //Info
                  IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () async {
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const InfoPage()));
                        setState(() {
                          mapKey = UniqueKey();
                        });
                      }),
                  //Settings
                  IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () async {
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        saveSettings();
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingsPage()));
                        final prefs = await SharedPreferences.getInstance();
                        int? tempMode = prefs.getInt("paintMode");
                        if (tempMode != null) {
                          mode = tempMode;
                        }
                        await Future.delayed(Duration(milliseconds: 500));
                        if (prefs.getBool("justActivatedGPS") == true) {
                          await startUserLocationUpdates(false);
                          await Future.delayed(Duration(milliseconds: 500));
                        }
                        setState(() {
                          mapKey = UniqueKey();
                        });
                      }),
                  //Login/Logout
                  IconButton(
                      icon: Icon(loggedIn ? Icons.logout : Icons.login,
                          color: Colors.white),
                      onPressed: () async {
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        bool? cameFromLogin = false;
                        if (loggedIn) {
                          cameFromLogin = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LogoutPage(),
                              ));
                        } else {
                          cameFromLogin = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ));
                        }
                        loggedIn = await UserCredentials.userExists();
                        final prefs = await SharedPreferences.getInstance();
                        setState(() {
                          isAdmin = prefs.getBool("isAdmin") ?? false;
                        });
                        if (cameFromLogin!) {
                          if (loggedIn) {
                            await UserCredentials.loadTokens();
                          } else {
                            ErrorDialog.show(context,
                                "Benutzer existiert nicht mehr oder die Anmeldedaten haben sich geändert");
                          }
                        }
                        setState(() {
                          mapKey = UniqueKey();
                        });
                      }),
                  //Dashboard
                  if (isAdmin)
                    IconButton(
                        icon: const Icon(Icons.dashboard),
                        onPressed: () async {
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DashboardPage(),
                              ));
                          setState(() {
                            mapKey = UniqueKey();
                          });
                        })
                ]);
              }
            })),
        endDrawer: MediaQuery.of(context).size.width < 650
            ? Drawer(
                width: 200,
                child: Container(
                  color: Colors.grey[800],
                  child: ListView(
                    children: [
                      //Infos
                      ListTile(
                        title: Text('Informationen',
                            style: TextStyle(color: Colors.white)),
                        leading:
                            const Icon(Icons.info_outline, color: Colors.white),
                        onTap: () async {
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InfoPage(),
                            ),
                          );
                          setState(() {
                            mapKey = UniqueKey();
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                      //Search
                      ListTile(
                        title: Text('Ortssuche',
                            style: TextStyle(color: Colors.white)),
                        leading: const Icon(Icons.search, color: Colors.white),
                        onTap: () async {
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          SharedPreferences preferences =
                              await SharedPreferences.getInstance();
                          preferences.setStringList("foundPosition", []);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchPage(),
                            ),
                          ).then((_) async {
                            await Future.delayed(Duration(seconds: 1));
                            SharedPreferences preferences =
                                await SharedPreferences.getInstance();
                            List<String>? foundPositionKoords =
                                preferences.getStringList("foundPosition");
                            if (foundPositionKoords != null &&
                                foundPositionKoords.isNotEmpty) {
                              foundPosition = LatLng(
                                  double.parse(foundPositionKoords[0]),
                                  double.parse(foundPositionKoords[1]));
                              setState(() {
                                mapKey = UniqueKey();
                              });
                              await Future.delayed(Duration(milliseconds: 10));
                              mapController.move(foundPosition!, currentZoom);
                            }
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                      //Settings
                      ListTile(
                        title: Text('Einstellungen',
                            style: TextStyle(color: Colors.white)),
                        leading:
                            const Icon(Icons.settings, color: Colors.white),
                        onTap: () async {
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          saveSettings();
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(),
                            ),
                          );
                          final prefs = await SharedPreferences.getInstance();
                          int? tempMode = prefs.getInt("paintMode");
                          if (tempMode != null) {
                            mode = tempMode;
                          }
                          await Future.delayed(Duration(milliseconds: 500));
                          if (prefs.getBool("justActivatedGPS") == true) {
                            await startUserLocationUpdates(false);
                            await Future.delayed(Duration(milliseconds: 500));
                          }
                          setState(() {
                            mapKey = UniqueKey();
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                      //Login/Logout
                      ListTile(
                        title: Text(
                          loggedIn ? 'Logout' : 'Login',
                          style: TextStyle(color: Colors.white),
                        ),
                        leading: Icon(
                          loggedIn ? Icons.logout : Icons.login,
                          color: Colors.white,
                        ),
                        onTap: () async {
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          bool? cameFromLogin = false;
                          if (loggedIn) {
                            cameFromLogin = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LogoutPage(),
                              ),
                            );
                          } else {
                            cameFromLogin = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ),
                            );
                          }
                          loggedIn = await UserCredentials.userExists();
                          final prefs = await SharedPreferences.getInstance();
                          setState(() {
                            isAdmin = prefs.getBool("isAdmin") ?? false;
                          });
                          if (cameFromLogin!) {
                            if (loggedIn) {
                              await UserCredentials.loadTokens();
                            } else {
                              ErrorDialog.show(context,
                                  "Benutzer existiert nicht mehr oder die Anmeldedaten haben sich geändert");
                            }
                          }
                          setState(() {
                            mapKey = UniqueKey();
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                      //Support Dashboard
                      if (isAdmin) ...[
                        ListTile(
                          title: Text('Dashboard',
                              style: TextStyle(color: Colors.white)),
                          leading:
                              const Icon(Icons.dashboard, color: Colors.white),
                          onTap: () async {
                            ScaffoldMessenger.of(context)
                                .removeCurrentSnackBar();
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DashboardPage(),
                              ),
                            );
                            setState(() {
                              mapKey = UniqueKey();
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                      ]
                    ],
                  ),
                ),
              )
            : null,
        //Body
        body: StreamBuilder<LatLng>(
            stream: locationStreamController.stream,
            initialData: LatLng(47.6298967054189, 13.140870797983313),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                userLocation = snapshot.data;

                //FlutterMap
                return FlutterMap(
                    key: mapKey,
                    mapController: mapController,
                    options: MapOptions(
                      minZoom: 10.0,
                      maxZoom: 18.0,
                      initialCenter: startMapPosition,
                      initialZoom: zoomLevel,
                      onPositionChanged: (position, bool _) async {
                        currentZoom = position.zoom;
                        currentPosition = position.center;
                        mapHeadingNotifier.value = position.rotation;
                        if (currentZoom < 15 &&
                            waterIntakePointsInformationList.isNotEmpty) {
                          setState(() {
                            waterIntakePointsInformationList = [];
                          });
                        }
                      },
                      //onMapReady (is called when Map is finished with Loading)
                      onMapReady: () async {
                        //Get instance of Settings
                        final prefs = await SharedPreferences.getInstance();

                        //Request Notification Permission ans initialize Background Logic
                        bool notification =
                            prefs.getBool("notification") ?? true;
                        if (isAdmin && notification) {
                          await BackgroundService.requestPopUpNotification();
                        } else {
                          BackgroundService.stopBackgroundService();
                        }

                        //Set MapLocation to UserLocation (if initialLoad or changed to mode 3 or mode 4)
                        if (userLocation != null &&
                            (initialLoad ||
                                prefs.getInt("paintMode") == 3 ||
                                prefs.getInt("paintMode") == 4)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            mapController.move(userLocation!, zoomLevel);
                          });
                        }

                        //Check if InitialLoad (if yes, then display the StartSnackBar)
                        if (initialLoad) {
                          showStartSnackBar();
                          initialLoad = false;
                        }

                        //Check if mode changed away from Mode 3, if true that stop line
                        if (mode != 3 && pathRecoveryAutoClick != null) {
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          pathRecoveryAutoClick?.cancel();
                          pathRecoveryAutoClick = null;
                          if (startLocation != null) {
                            setState(() {
                              startLocation = null;
                            });
                          }
                          pointListRecord = [];
                        }

                        //Get the current Settings
                        mode = prefs.getInt("paintMode") ?? mode;
                        waterIntakePoints =
                            prefs.getBool("waterIntakePoints") ??
                                waterIntakePoints;
                        lengthPressureLoss =
                            prefs.getDouble("lengthPressureLoss") ?? 100;
                        reserveHoseLength =
                            prefs.getDouble("reserveHoseLength") ?? 10;
                        maxPressureLoss =
                            prefs.getDouble("maxPressureLoss") ?? 8;
                        remainingBarToNextPump = maxPressureLoss;

                        //get and set WaterIntakePoints
                        if (!waterIntakePoints) {
                          waterIntakePointsTimer?.cancel();
                          waterIntakePointsTimer = null;
                          if (waterIntakePointsInformationList.isNotEmpty) {
                            setState(() {
                              waterIntakePointsInformationList = [];
                            });
                          }
                        } else {
                          waterIntakePointsTimer ??= Timer.periodic(
                              const Duration(seconds: 5), (Timer t) async {
                            if (hydrantwaterIntakePointCalledCamera == null ||
                                hydrantwaterIntakePointCalledCamera
                                        ?.visibleBounds !=
                                    mapController.camera.visibleBounds) {
                              List<dynamic> tmpList = [];
                              tmpList.add(mapController.camera.visibleBounds);
                              tmpList.add(mapController.camera.zoom);
                              if (kIsWeb) {
                                await compute(getWaterIntakePoints, tmpList);
                              } else {
                                await getWaterIntakePoints(tmpList);
                              }
                              hydrantwaterIntakePointCalledCamera =
                                  mapController.camera;
                            }
                          });
                        }

                        //Check if StartLocation == UserLocation (Setting) (if yes, set startLocation to UserLocation)
                        if (prefs.getBool("startIsLocation") ?? false) {
                          bool setStartLocation = false;
                          startIsLocationOn = true;

                          if (mode == 0 || mode == 1) {
                            if (startPoint == null) {
                              startPoint = userLocation;
                              setStartLocation = true;
                            }
                          } else if (mode == 2) {
                            if (pointListFree.isEmpty) {
                              pointListFree.add(userLocation!);
                              setStartLocation = true;
                            }
                          } else if (mode == 3 || mode == 4) {
                            if (startLocation != null) {
                              setState(() {
                                startLocation = null;
                              });
                            }
                          }

                          if (setStartLocation) {
                            showStartedCalculationSnackBar();
                            setState(() {
                              startLocation = userLocation;
                            });
                          }
                        } else if (startIsLocationOn) {
                          startIsLocationOn = false;
                          if (startLocation != null) {
                            setState(() {
                              startLocation = null;
                            });
                            if (mode == 0 || mode == 1) {
                              startPoint = null;
                            } else if (mode == 2) {
                              pointListFree = [];
                            }
                          }
                        }

                        if (prefs.getDouble("zoomLevel") != null &&
                            zoomLevel != prefs.getDouble("zoomLevel")) {
                          zoomLevel = prefs.getDouble("zoomLevel")!;
                          mapController.move(userLocation!, zoomLevel);
                        }

                        //Check if mode == 3 or mode == 4 (if yes, then show special start SnackBar)
                        if ((mode == 3 || mode == 4) &&
                            pathRecoveryAutoClick == null) {
                          if (await showStartGPSFollowing()) {
                            await startModeThreeOrFour();
                          }
                        }
                      },
                      //OnTap (when User pressed on the Map)
                      onTap: (tapPosition, latlng) async {
                        //Check if User clicked on RelayLine
                        int? clickedLineIndex;
                        bool middlePointDelete = false;
                        bool clickedFirstOrLastPoint = false;
                        int? clickedOnWaterIntakePoint;

                        for (int i = 0;
                            i < waterIntakePointsInformationList.length;
                            i++) {
                          if (isPointNearPoint(
                              latlng,
                              LatLng(waterIntakePointsInformationList[i][1],
                                  waterIntakePointsInformationList[i][2]),
                              tolerance * 2)) {
                            clickedOnWaterIntakePoint = i;
                          }
                        }

                        for (int i = 0; i < lineList.length; i++) {
                          if (isPointNearLine(latlng, lineList[i], tolerance)) {
                            clickedLineIndex = i;
                            if (distance.as(LengthUnit.Meter, lineList[i].first,
                                        latlng) <=
                                    tolerance ||
                                distance.as(LengthUnit.Meter, lineList[i].last,
                                        latlng) <=
                                    tolerance) {
                              clickedFirstOrLastPoint = true;
                            }
                            if (modeLineList[i] != 0 &&
                                modeLineList[i] != 3 &&
                                modeLineList[i] != 4) {
                              middlePointDelete = true;
                            }
                            break;
                          }
                        }

                        // If Clicked on WaterIntakePoint, then show WaterIntakePoint Informations
                        // else if Clicked on Line, then DeleteLine
                        // else if StartPoint == null set StartPoint & show startedCalculationSnackBar
                        // else set the EndPoint & remove SnackBar & show Loading-Page
                        // else add a Pump to the Hybridlist
                        if (clickedOnWaterIntakePoint != null) {
                          WaterIntakeInformationDialog.show(
                              context,
                              waterIntakePointsInformationList[
                                  clickedOnWaterIntakePoint],
                              loggedIn, () async {
                            LatLng location = LatLng(
                                waterIntakePointsInformationList[
                                    clickedOnWaterIntakePoint!][1],
                                waterIntakePointsInformationList[
                                    clickedOnWaterIntakePoint][2]);
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            if (mode == 0 || mode == 1) {
                              startPoint = location;
                            } else if (mode == 2) {
                              pointListFree = [];
                              pointListFree.add(location);
                            } else if (mode == 3) {
                              setState(() {
                                pointListRecord = [];
                                pointListRecord.add(location);
                                startLocation = location;
                              });
                              showStartedCalculationSnackBar();
                              if (prefs.getBool("popupAtTS") == true) {
                                showPopupWithSound();
                              }
                              if (ScaffoldMessenger.of(context).mounted) {
                                ScaffoldMessenger.of(context)
                                    .removeCurrentSnackBar();
                              }
                              await startModeThreeOrFour();
                            } else if (mode == 4) {
                              setState(() {
                                pointListHybrid = [];
                                partPointListHybrid = [];
                                partPointListHybrid.add(location);
                                startLocation = location;
                              });
                              showStartedCalculationSnackBar();
                              if (prefs.getBool("popupAtTS") == true) {
                                showPopupWithSound();
                              }
                              if (ScaffoldMessenger.of(context).mounted) {
                                ScaffoldMessenger.of(context)
                                    .removeCurrentSnackBar();
                              }
                              await startModeThreeOrFour();
                            }
                          });
                        } else if (clickedLineIndex != null &&
                            clickedFirstOrLastPoint &&
                            relayLineInformations.isNotEmpty) {
                          await deleteLine(clickedLineIndex);
                        } else if (clickedLineIndex != null &&
                            middlePointDelete) {
                          await deletePoint(clickedLineIndex, latlng);
                        } else if (mode == 0 || mode == 1) {
                          if (startPoint == null) {
                            startPoint = latlng;
                            setState(() {
                              startLocation = startPoint;
                            });
                            showStartedCalculationSnackBar();
                          } else if (endPoint == null) {
                            endPoint = latlng;
                            ScaffoldMessenger.of(context)
                                .removeCurrentSnackBar();
                            showLoadingScreen();
                          }

                          //If startPoint & EndPoint have a Value
                          if (startPoint != null && endPoint != null) {
                            bool serverError = false;
                            List<LatLng> listOfLineKoords = [];
                            List<LatLng> pumpLocations = [];
                            listOfLineKoords.add(startPoint!);

                            //if mode == 0 (snappingToStreet)
                            if (mode == 0) {
                              List<LatLng?> tmpList = [];
                              tmpList.add(startPoint);
                              tmpList.add(endPoint);
                              List<LatLng> koordList = await compute(
                                  calculateKoordsWithSnappingToStreet, tmpList);
                              if (koordList.length <= 1) {
                                serverError = true;
                              }
                              listOfLineKoords.addAll(koordList);
                              //if mode == 1 (straight Line, so no need for calculation of Points in between)
                            }

                            listOfLineKoords.add(endPoint!);

                            //Check for ServerError (error in the Routing-API)
                            //if there is no Error, then calculate the PumpLocations
                            if (serverError) {
                              listOfLineKoords = [];
                              hideLoadingScreen();
                              ErrorDialog.show(context,
                                  "Verbindung zur Schnitstelle für die Straßen-Routen-Berechnung fehlgeschlagen");
                            } else {
                              pumpLocations = await compute(
                                  getTSLocations, listOfLineKoords);

                              if (pumpLocations.isNotEmpty &&
                                  !errorPumpModeSnap) {
                                //Hide LoadingScreen and show InformationDialog
                                hideLoadingScreen();
                                showInformationDialog(null);
                              }
                            }

                            //Reset the Values
                            startPoint = null;
                            endPoint = null;
                            //Update GUI (remove the StartPoint of the RelayLine)
                            setState(() {
                              mapKey = UniqueKey();
                              startLocation = null;
                              if (!serverError &&
                                  !errorPumpModeSnap &&
                                  pumpLocations.isNotEmpty) {
                                lineList.add(listOfLineKoords);
                                tsList.add(pumpLocations);
                                modeLineList.add(mode);
                              }
                            });
                          }
                          //if mode == 2 (freehandPainting)
                        } else if (mode == 2) {
                          //if the List is empty, set the StartLocation
                          if (pointListFree.isEmpty) {
                            pointListFree.add(latlng);
                            //Update GUI (add the StartPoint of the RelayLine)
                            setState(() {
                              startLocation = latlng;
                            });
                            showStartedCalculationSnackBar();
                            //else set the EndPoint of the partLine & calculate the Koords in between the Start and PartEndPoint
                          } else {
                            pointListFree.add(latlng);
                            //Update GUI (remove the StartPoint of the RelayLine)
                            if (startLocation != null) {
                              setState(() {
                                startLocation = null;
                              });
                            }
                          }

                          //calculate the pumpLocations
                          List<LatLng> pumpLocations = [];
                          if (pointListFree.length >= 2) {
                            pumpLocations =
                                await compute(getTSLocations, pointListFree);
                          }

                          if (pumpLocations.isNotEmpty) {
                            //Update the GUI (check if the RelayLine is already shown, if yes update it, else add it)
                            bool inList = false;

                            for (int i = 0; i < lineList.length; i++) {
                              if (pointListFree.length >= lineList[i].length) {
                                if (listEquals(
                                    lineList[i],
                                    pointListFree.sublist(
                                        0, lineList[i].length))) {
                                  setState(() {
                                    lineList[i] = pointListFree;
                                    tsList[i] = pumpLocations;
                                  });
                                  inList = true;
                                  break;
                                }
                              }
                            }

                            if (!inList) {
                              setState(() {
                                lineList.add(pointListFree);
                                tsList.add(pumpLocations);
                                modeLineList.add(mode);
                              });
                            }

                            bool endPoint = false;

                            //Hide the LoadingScreen & show the EndpointSnackBar
                            if (pointListFree.length > 1) {
                              endPoint = await showEndPointSnackBar(mode);
                            }

                            //if the Point is the EndPoint, reset all values & remove the pumpLocations from the visitedList
                            if (endPoint) {
                              setState(() {
                                mapKey = UniqueKey();
                              });
                              showInformationDialog(null);
                              pointListFree = [];
                            }
                          }
                        } else if (mode == 4) {
                          if (tsList.isNotEmpty && tsList.last.isNotEmpty) {
                            pointListHybrid.add(latlng);
                            partPointListHybrid = [];
                            partPointListHybrid.add(latlng);

                            setState(() {
                              tsList.last.add(latlng);
                            });
                          } else {
                            ErrorDialog.show(context,
                                "Pumpe setzen nicht möglich!\nSie müssen sich erst ca. 15 Meter bewegen um die Berechnung zu starten.");
                          }
                        }
                      },
                    ),
                    children: [
                      //Layer for the Map
                      TileLayer(
                        tileProvider: CancellableNetworkTileProvider(),
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      ),
                      //Layer for the RelayLines
                      PolylineLayer(polylines: loadLines()),
                      //Layer for the PumpLocations
                      MarkerLayer(markers: loadTSLocations()),
                      //if waterIntakePoints is true, then show the markers for the waterIntakePoints
                      if (waterIntakePoints &&
                          waterIntakePointsInformationList.isNotEmpty) ...[
                        WaterIntakePointMarkersLayer(
                            waterIntakePointsInformationList:
                                waterIntakePointsInformationList)
                      ],
                      //if startLocation of RelayLine is not null, then add a dot at the Location
                      if (startLocation != null) ...[
                        CircleLayer(circles: [loadStartLocation()]),
                      ],
                      //if userLocation is not null
                      if (userLocation != null && gpsPermissionGranted) ...[
                        //add a MarkerLayer for the userLocation
                        CurrentLocationLayer(
                          style: LocationMarkerStyle(
                            markerDirection: MarkerDirection.heading,
                          ),
                        ),
                      ],
                      //shows Start- and Endpoint markers
                      MarkerLayer(markers: loadStartAndEndMarkers()),
                      //show remaining Bar to next pump
                      RestBarLayer(
                          remainingBarToNextPump: remainingBarToNextPump),
                      if (!loggedIn) ...[
                        NotLoggedInLayer(),
                      ],
                      if (foundPosition != null) ...[
                        SearchLocationMarkerLayer(
                            foundPosition: foundPosition,
                            onDelete: () {
                              setState(() {
                                foundPosition = null;
                              });
                            })
                      ]
                    ]);
                //if the Map isn't loaded completely, show a Loading Indicator
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }));
  }
}
