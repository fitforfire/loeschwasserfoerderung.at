import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_autocompletion_field.dart';
import 'error_dialog.dart';
import 'loading_screen.dart';

// Root Widget for Search-Page
class SearchPage extends StatefulWidget {
  //Constructor
  const SearchPage({super.key});

  //Create State
  @override
  SearchPageState createState() => SearchPageState();
}

//State for Search-Page
class SearchPageState extends State<SearchPage> {
  // Variables
  String? selectedSearchType = "Address";
  Key reloadKey = UniqueKey();
  bool loadingScreenShown = false;

  // List of TextEditingControllers
  //Address
  TextEditingController stateController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController streetController = TextEditingController();
  TextEditingController housenumberController = TextEditingController();

  //Hofname
  TextEditingController farmNameController = TextEditingController();
  TextEditingController stateControllerCourt = TextEditingController();
  TextEditingController cityControllerCourt = TextEditingController();

  //Koordinaten
  double? latKoord;
  double? lngKoord;
  FocusNode latFocusNode = FocusNode();
  FocusNode lngFocusNode = FocusNode();

  //List-Variables
  List<String> searchTypes = ['Address', 'Hofname', 'Koordinaten'];

  Map<String, int> stateNumberMap = {
    'Burgenland': 1,
    'Kärnten': 2,
    'Niederösterreich': 3,
    'Oberösterreich': 4,
    'Salzburg': 5,
    'Steiermark': 6,
    'Tirol': 7,
    'Vorarlberg': 8,
    'Wien': 9,
  };
  List<String> cities = [];

  Map<String, List<String>> streets = {};

  Map<String, LatLng> streetNumbers = {};

  List<String> hofnamen = [];

  // Build the Page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: reloadKey,
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        title: const Text("Ortssuche"),
      ),
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[800],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Support Container with the blue box
              Container(
                width: 350,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.blue[200],
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Dropdown for Search Type (Address, Courtname, Koordiantes)
                    DropdownButtonFormField<String>(
                      value: selectedSearchType,
                      decoration: InputDecoration(
                        labelText: 'Wählen Sie einen Suchtyp',
                        labelStyle: TextStyle(color: Colors.grey[800]),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: searchTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        clearFields();
                        setState(() {
                          selectedSearchType = newValue;
                        });
                      },
                    ),
                    SizedBox(height: 20),

                    //Conditional input fields based on the selected search type
                    if (selectedSearchType == 'Address') ...[
                      //Fields for Address
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomAutocompletionField(
                            controller: stateController,
                            suggestions: stateNumberMap.keys.toList(),
                            label: "Bundesland",
                            noItemFound: "Kein Bundesland gefunden!",
                            selectAll: true,
                            onChanged: (name) {
                              clearMunicipalityAndBelow();
                            },
                            onFinishedInput: () {
                              getAllCitiesAndStreetsFromState(
                                  stateNumberMap[stateController.text]!);
                            },
                          ),
                          SizedBox(height: 10),
                          CustomAutocompletionField(
                            controller: cityController,
                            suggestions: cities,
                            label: "Gemeinde",
                            noItemFound: "Keine Gemeinde gefunden!",
                            selectAll: true,
                            onChanged: (name) {
                              clearDistrictAndBelow();
                            },
                            onFinishedInput: () {
                              setState(() {
                                reloadKey = UniqueKey();
                              });
                            },
                          ),
                          SizedBox(height: 10),
                          CustomAutocompletionField(
                            controller: streetController,
                            suggestions: streets[cityController.text] ?? [],
                            label: "Straßen",
                            noItemFound: "Keine Straße gefunden!",
                            selectAll: true,
                            onChanged: (name) {
                              clearHouseNumber();
                            },
                            onFinishedInput: () {
                              getAllHouseNumbers(
                                  stateNumberMap[stateController.text]!,
                                  cityController.text,
                                  streetController.text);
                            },
                          ),
                          SizedBox(height: 10),
                          CustomAutocompletionField(
                              controller: housenumberController,
                              suggestions: streetNumbers.keys.toList(),
                              label: "Hausnummer",
                              noItemFound: "Keine Hausnummer gefunden!",
                              selectAll: true),
                        ],
                      ),
                    ],
                    if (selectedSearchType == 'Hofname') ...[
                      // Fields for Hofname
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomAutocompletionField(
                            controller: stateControllerCourt,
                            suggestions: stateNumberMap.keys.toList(),
                            label: "Bundesland",
                            noItemFound: "Kein Bundesland gefunden!",
                            selectAll: true,
                            onChanged: (name) {
                              clearMunicipalityAndBelow();
                            },
                            onFinishedInput: () {
                              getAllCitiesAndStreetsFromState(
                                  stateNumberMap[stateControllerCourt.text]!);
                            },
                          ),
                          SizedBox(height: 10),
                          CustomAutocompletionField(
                            controller: cityControllerCourt,
                            suggestions: cities,
                            label: "Ort",
                            noItemFound: "Keinen Ort gefunden!",
                            selectAll: true,
                            onFinishedInput: () {
                              getAllHofnamen(
                                  stateNumberMap[stateControllerCourt.text]!,
                                  cityControllerCourt.text);
                            },
                          ),
                          SizedBox(height: 10),
                          CustomAutocompletionField(
                              controller: farmNameController,
                              suggestions: hofnamen,
                              label: "Hofname",
                              noItemFound: "Keinen Hofnamen gefunden!",
                              selectAll: true),
                        ],
                      ),
                    ],
                    if (selectedSearchType == 'Koordinaten') ...[
                      // Fields for Koordinaten
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 140.0,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: "Lat-Koord.",
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white),
                                  onChanged: (value) {
                                    setState(() {
                                      latKoord = double.tryParse(value);
                                    });
                                  },
                                  onSubmitted: (value) {
                                    FocusScope.of(context)
                                        .requestFocus(lngFocusNode);
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
                                      filled: true,
                                      fillColor: Colors.white),
                                  onChanged: (value) {
                                    setState(() {
                                      lngKoord = double.tryParse(value);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ],
                    SizedBox(height: 20),
                    // Submit Button
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedSearchType == "Address") {
                          await setSelectedAddressLocation(
                              streetNumbers[housenumberController.text]!);
                        } else if (selectedSearchType == "Hofname") {
                          await getLocationFromHofnamen(
                              stateNumberMap[stateControllerCourt.text]!,
                              cityControllerCourt.text,
                              farmNameController.text);
                        } else if (selectedSearchType == "Koordinaten") {
                          await showLocationInMap();
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32.0,
                          vertical: 12.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        "Suchen",
                        style: TextStyle(fontSize: 16, color: Colors.white),
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

  //Dispose
  @override
  void dispose() {
    stateController.dispose();
    cityController.dispose();
    streetController.dispose();
    housenumberController.dispose();
    farmNameController.dispose();
    stateControllerCourt.dispose();
    cityControllerCourt.dispose();
    latFocusNode.dispose();
    lngFocusNode.dispose();
    super.dispose();
  }

  //Set the Koords to the SharedPreferences
  Future<void> setSelectedAddressLocation(LatLng selectedLocation) async {
    showLoadingScreen();
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setStringList("foundPosition", [
      selectedLocation.latitude.toString(),
      selectedLocation.longitude.toString()
    ]);
    hideLoadingScreen();
  }

  //Get All Cities and Streetnames from a State
  Future<void> getAllCitiesAndStreetsFromState(int stateNumber) async {
    showLoadingScreen();
    try {
      final url = "https://geocode.at/list?state=$stateNumber";
      final response = await http.get(Uri.parse(url));
      Set<String> places = {};
      Map<String, List<String>> roads = {};

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data.isNotEmpty) {
          for (Map<String, dynamic> item in data) {
            String place = item["Place"];
            String street = item["Street"];

            //Initialize the List (if empty)
            roads.putIfAbsent(place, () => []);

            //Add The Values
            places.add(place);
            roads[place]?.add(street);
          }
        } else {
          ErrorDialog.show(
              context, "Problem beim Suchen der Ortsnamen und Straßen");
        }
      } else {
        ErrorDialog.show(
            context, "Problem beim Suchen der Ortsnamen und Straßen");
      }

      setState(() {
        reloadKey = UniqueKey();
        cities = places.toList();
        streets = roads;
      });
    } catch (ex) {
      ErrorDialog.show(context, ex.toString());
    } finally {
      hideLoadingScreen();
    }
  }

  //Get All Housenumbers from a Street
  Future<void> getAllHouseNumbers(
      int stateNumber, String city, String street) async {
    showLoadingScreen();
    streetNumbers.clear();
    Map<String, LatLng> streetNo = {};
    Map<String, dynamic> houseNumbers = {};
    try {
      final url =
          "https://geocode.at/dictionary?state=$stateNumber&city=$city&street=$street";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data.isNotEmpty) {
          houseNumbers = data[city][street];

          houseNumbers.forEach((houseNumber, coord) {
            if (coord is List && coord.length == 2) {
              streetNo[houseNumber] = LatLng(coord[1], coord[0]);
            }
          });
        } else {
          ErrorDialog.show(context, "Problem beim Suchen der Hausnummern");
        }
      }

      setState(() {
        reloadKey = UniqueKey();
        streetNumbers = streetNo;
      });
    } catch (ex) {
      ErrorDialog.show(context, ex.toString());
    } finally {
      hideLoadingScreen();
    }
  }

  //Get All Hofnamen from a City
  Future<void> getAllHofnamen(int stateNumber, String city) async {
    showLoadingScreen();
    hofnamen.clear();
    List<String> hoefe = [];
    final alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("");
    try {
      for (var letter in alphabet) {
        final url =
            "https://geocode.at/hofname/autocomplete?state=$stateNumber&gemeinde=$city&hofname=$letter";
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data != null) {
            if (data.isNotEmpty) {
              hoefe.addAll(List<String>.from(data));
            }
          } else {
            ErrorDialog.show(context, "Problem beim Suchen der Hofnamen");
          }
        }
      }

      setState(() {
        reloadKey = UniqueKey();
        hofnamen = hoefe;
      });
    } catch (ex) {
      ErrorDialog.show(context, ex.toString());
    } finally {
      hideLoadingScreen();
    }
  }

  //Get Location from Hofname
  Future<void> getLocationFromHofnamen(
      int stateNumber, String city, String hofname) async {
    showLoadingScreen();
    try {
      final url =
          "https://geocode.at/hofname/geocode?state=$stateNumber&gemeinde=$city&hofname=$hofname";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data.isNotEmpty) {
          SharedPreferences preferences = await SharedPreferences.getInstance();
          preferences.setStringList("foundPosition",
              [data["lat"].toString(), data["lng"].toString()]);
        } else {
          ErrorDialog.show(
              context, "Problem beim Suchen der Position des Hofnamen");
        }
      }
    } catch (ex) {
      ErrorDialog.show(context, ex.toString());
    } finally {
      hideLoadingScreen();
    }
  }

  Future<void> showLocationInMap() async {
    showLoadingScreen();
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setStringList(
        "foundPosition", [latKoord.toString(), lngKoord.toString()]);
    hideLoadingScreen();
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

  void clearFields() {
    stateController.clear();
    clearMunicipalityAndBelow();
  }

  void clearMunicipalityAndBelow() {
    cityController.clear();
    clearDistrictAndBelow();
  }

  void clearDistrictAndBelow() {
    streetController.clear();
    clearHouseNumber();
  }

  void clearHouseNumber() {
    housenumberController.clear();
  }
}
