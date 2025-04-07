import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_switch.dart';

//Root Widget for Settings-Page
class SettingsPage extends StatefulWidget {
  //Constructor
  const SettingsPage({super.key});

  //Create State
  @override
  SettingsPageState createState() => SettingsPageState();
}

//State for Settings-Page
class SettingsPageState extends State<SettingsPage> {
  //Variables
  TextEditingController lengthPressureLossController = TextEditingController();
  TextEditingController reserveHoseLengthController = TextEditingController();
  TextEditingController maxPressureLossController = TextEditingController();
  FocusNode lngFocusNode = FocusNode();
  double zoomLevel = 17.0;
  bool waterIntakePoints = true;
  int mode = 3;
  final double minZoom = 10.0;
  final double maxZoom = 18.0;
  final double zoomStep = 1.0;
  double latKoord = 47.6298967054189;
  double lngKoord = 13.140870797983313;
  bool startIsLocation = false;
  bool popupAtTS = true;
  bool followUser = false;
  bool isAdmin = false;
  bool notification = true;
  double lengthPressureLoss = 100;
  double reserveHoseLength = 10;
  double maxPressureLoss = 8;
  bool settingsLoaded = false;
  int? previousMode;
  bool justActivatedGPS = false;

  //Initializer
  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  //Disposer
  @override
  void dispose() {
    lengthPressureLossController.dispose();
    reserveHoseLengthController.dispose();
    maxPressureLossController.dispose();
    super.dispose();
  }

  //LoadSettings (Load and Save the needed Values from SharedPreferences)
  Future<void> loadSettings() async {
    final permission = await Geolocator.checkPermission();
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      if (prefs.getDouble("currentZoom") != null) {
        zoomLevel = prefs.getDouble("currentZoom")!.roundToDouble();
      } else {
        zoomLevel = prefs.getDouble("zoomLevel") ?? zoomLevel;
      }

      justActivatedGPS = prefs.getBool("justActivatedGPS") ?? justActivatedGPS;

      waterIntakePoints =
          prefs.getBool("waterIntakePoints") ?? waterIntakePoints;
      mode = prefs.getInt("paintMode") ?? mode;
      latKoord = prefs.getDouble("latKoord") ?? latKoord;
      lngKoord = prefs.getDouble("lngKoord") ?? lngKoord;
      startIsLocation = prefs.getBool("startIsLocation") ?? startIsLocation;
      popupAtTS = prefs.getBool("popupAtTS") ?? popupAtTS;
      followUser = prefs.getBool("followUser") ?? followUser;
      notification = prefs.getBool("notification") ?? notification;
      isAdmin = prefs.getBool("isAdmin") ?? isAdmin;
      lengthPressureLoss =
          prefs.getDouble("lengthPressureLoss") ?? lengthPressureLoss;
      reserveHoseLength =
          prefs.getDouble("reserveHoseLength") ?? reserveHoseLength;
      maxPressureLoss = prefs.getDouble("maxPressureLoss") ?? maxPressureLoss;

      lengthPressureLossController.text = lengthPressureLoss.toString();
      reserveHoseLengthController.text = reserveHoseLength.toString();
      maxPressureLossController.text = maxPressureLoss.toString();

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        mode = 0;
      }

      previousMode = mode;
    });
    settingsLoaded = true;
    saveSettings();
  }

  //ask the User for the GPS-Permission
  Future<bool> askUserForGPSLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

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
      return false;
    } else if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      justActivatedGPS = true;
      return true;
    } else {
      return false;
    }
  }

  //showRequestGPSDialog (show restricted Mode information Dialog, if the GPS-Permission is not given)
  Future<void> showGPSInformationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Theme(
          data: Theme.of(context).copyWith(dialogBackgroundColor: Colors.white),
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
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text("- Benutzerstandort anzeigen"),
                  Text("- Startpunkt ist Standort"),
                  Text("- Modus \"GPS verfolgen\""),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //SaveSettings (Save needed Values to SharedPreferences)
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("zoomLevel", zoomLevel);
    await prefs.setBool("justActivatedGPS", justActivatedGPS);
    await prefs.setBool("waterIntakePoints", waterIntakePoints);
    await prefs.setInt("paintMode", mode);
    await prefs.setDouble("latKoord", latKoord);
    await prefs.setDouble("lngKoord", lngKoord);
    await prefs.setBool("startIsLocation", startIsLocation);
    await prefs.setBool("popupAtTS", popupAtTS);
    await prefs.setDouble("lengthPressureLoss", lengthPressureLoss);
    await prefs.setDouble("reserveHoseLength", reserveHoseLength);
    await prefs.setDouble("maxPressureLoss", maxPressureLoss);
    await prefs.setBool("followUser", followUser);
    await prefs.setBool("notification", notification);
  }

  //GenerateDropdownItems (Generate the Dropdown-Zoom-Values)
  List<DropdownMenuItem<double>> generateZoomDropdownItems() {
    List<DropdownMenuItem<double>> items = [];
    for (double possibleZoomLevel = minZoom;
        possibleZoomLevel <= maxZoom;
        possibleZoomLevel += zoomStep) {
      items.add(DropdownMenuItem<double>(
        value: possibleZoomLevel,
        child: Text(possibleZoomLevel.toStringAsFixed(0)),
      ));
    }
    return items;
  }

  //Build the Page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //NavBar
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        title: const Text("Benutzereinstellungen"),
      ),
      resizeToAvoidBottomInset: true,
      //Body
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              //Zoom - Headline
              const Text("Zoom-Level", style: TextStyle(fontSize: 16.0)),
              const SizedBox(height: 5.0),
              //Zoom - Dropdown
              Center(
                child: SizedBox(
                  width: 150.0,
                  child: DropdownButtonFormField<double>(
                    isExpanded: true,
                    value: zoomLevel,
                    onChanged: (double? newValue) {
                      if (newValue != null) {
                        setState(() {
                          zoomLevel = newValue;
                        });
                        saveSettings();
                      }
                    },
                    items: generateZoomDropdownItems(),
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40.0),
              //Modus - Headline
              const Text("Linienmodus", style: TextStyle(fontSize: 16.0)),
              const SizedBox(height: 5.0),
              //Modus - Dropdown
              Center(
                child: SizedBox(
                  width: 200.0,
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: mode,
                    onChanged: (int? newValue) async {
                      if (newValue != null) {
                        setState(() {
                          mode = newValue;
                          previousMode ??= mode;
                        });
                        if (newValue == 3 || newValue == 4) {
                          final permission = await Geolocator.checkPermission();
                          bool gpsPermission = false;
                          if (permission == LocationPermission.denied ||
                              permission == LocationPermission.deniedForever) {
                            gpsPermission = await askUserForGPSLocation();
                          } else if (permission == LocationPermission.always ||
                              permission == LocationPermission.whileInUse) {
                            gpsPermission = true;
                          }
                          if (!gpsPermission) {
                            setState(() {
                              mode = previousMode!;
                            });
                          }
                        }
                        saveSettings();
                      }
                    },
                    items: const [
                      DropdownMenuItem<int>(
                        value: 0,
                        child: Text("Entlang der Straße/Weg"),
                      ),
                      DropdownMenuItem<int>(
                        value: 1,
                        child: Text("Gerade Linie"),
                      ),
                      DropdownMenuItem<int>(
                          value: 2, child: Text("Freihandzeichnen")),
                      DropdownMenuItem<int>(
                          value: 3, child: Text("GPS verfolgen")),
                      DropdownMenuItem<int>(value: 4, child: Text("Hybrid"))
                    ],
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40.0),
              //Water-Intake-Points - Headline
              const Text("Wasserentnahmestellen",
                  style: TextStyle(fontSize: 16.0)),
              const SizedBox(height: 5.0),
              //Water-Intake-Points - Switch
              if (settingsLoaded) ...[
                Center(
                  child: SizedBox(
                    width: 200.0,
                    child: CustomAnimatedSwitch(
                      value: waterIntakePoints,
                      onChanged: (bool value) {
                        setState(() {
                          waterIntakePoints = value;
                        });
                        saveSettings();
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40.0),
              //Popup - Headline
              const Text("Popup, wenn TS-Standort erreicht",
                  style: TextStyle(fontSize: 16.0)),
              const SizedBox(height: 5.0),
              //Popup - Switch
              if (settingsLoaded) ...[
                Center(
                  child: SizedBox(
                    width: 200.0,
                    child: CustomAnimatedSwitch(
                      value: popupAtTS,
                      onChanged: (bool value) {
                        setState(() {
                          popupAtTS = value;
                        });
                        saveSettings();
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40.0),
              //StartLocation - Headline
              const Text("Startpunkt ist Standort",
                  style: TextStyle(fontSize: 16.0)),
              const SizedBox(height: 5.0),
              //StartLocation - Switch
              if (settingsLoaded) ...[
                Center(
                  child: SizedBox(
                    width: 200.0,
                    child: CustomAnimatedSwitch(
                      value: startIsLocation,
                      onChanged: (bool value) async {
                        final permission = await Geolocator.checkPermission();
                        bool gpsPermission = false;
                        if (permission == LocationPermission.denied ||
                            permission == LocationPermission.deniedForever) {
                          gpsPermission = await askUserForGPSLocation();
                        } else if (permission == LocationPermission.always ||
                            permission == LocationPermission.whileInUse) {
                          gpsPermission = true;
                        }
                        if (gpsPermission) {
                          setState(() {
                            startIsLocation = value;
                          });
                          saveSettings();
                        }
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40.0),
              //FollowUser - Headline
              const Text("Benutzer in Mittelpunkt",
                  style: TextStyle(fontSize: 16.0)),
              const SizedBox(height: 5.0),
              //FollowUser - Switch
              if (settingsLoaded) ...[
                Center(
                  child: SizedBox(
                    width: 200.0,
                    child: CustomAnimatedSwitch(
                      value: followUser,
                      onChanged: (bool value) {
                        setState(() {
                          followUser = value;
                        });
                        saveSettings();
                      },
                    ),
                  ),
                ),
              ],
              if (settingsLoaded && isAdmin) ...[
                const SizedBox(height: 40.0),
                //FollowUser - Headline
                const Text("Supportbenachrichtigung",
                    style: TextStyle(fontSize: 16.0)),
                const SizedBox(height: 5.0),
                //FollowUser - Switch
                Center(
                  child: SizedBox(
                    width: 200.0,
                    child: CustomAnimatedSwitch(
                      value: notification,
                      onChanged: (bool value) {
                        setState(() {
                          notification = value;
                        });
                        saveSettings();
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40.0),
              //StartPosition - Headline
              const Text("Anfangsposition, wenn Benutzer nicht gefunden",
                  style: TextStyle(fontSize: 16.0)),
              const SizedBox(height: 5.0),
              //StartPosition - Inputfields
              Center(
                child: Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: 140.0,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Lat-Koord.",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            latKoord =
                                double.tryParse(value) ?? 47.6298967054189;
                          });
                          saveSettings();
                        },
                        onSubmitted: (value) {
                          FocusScope.of(context).requestFocus(lngFocusNode);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 140.0,
                      child: TextField(
                        focusNode: lngFocusNode,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Lng-Koord.",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            lngKoord =
                                double.tryParse(value) ?? 13.140870797983313;
                          });
                          saveSettings();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40.0),
              //Settings - Headline
              const Text("Einstellungen für TS-Berechnung",
                  style: TextStyle(fontSize: 16.0)),
              const SizedBox(height: 5.0),
              //Settings - Inputfields
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 300.0,
                      child: TextField(
                        controller: maxPressureLossController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText:
                              "Maximaler Druckverlust bis zu nächster TS (in bar)",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            maxPressureLoss = double.tryParse(value) ?? 8;
                          });
                          saveSettings();
                        },
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    SizedBox(
                      width: 300.0,
                      child: TextField(
                        controller: lengthPressureLossController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText:
                              "Ebene Leitungslänge die 1 bar Druckverlust verursacht (in m)",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            lengthPressureLoss = double.tryParse(value) ?? 100;
                          });
                          saveSettings();
                        },
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    SizedBox(
                      width: 300.0,
                      child: TextField(
                        controller: reserveHoseLengthController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Schlauchreserve (in %)",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            reserveHoseLength = double.tryParse(value) ?? 10;
                          });
                          saveSettings();
                        },
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
}
