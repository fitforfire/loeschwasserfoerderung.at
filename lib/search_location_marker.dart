import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SearchLocationMarkerLayer extends StatefulWidget {
  final LatLng? foundPosition;
  final Function() onDelete;

  const SearchLocationMarkerLayer(
      {super.key, required this.foundPosition, required this.onDelete});

  @override
  SearchLocationMarkerLayerState createState() =>
      SearchLocationMarkerLayerState();
}

class SearchLocationMarkerLayerState extends State<SearchLocationMarkerLayer> {
  @override
  Widget build(BuildContext context) {
    return MarkerLayer(markers: [
      Marker(
          width: 40.0,
          height: 40.0,
          point: widget.foundPosition!,
          child: Transform.translate(
              offset: const Offset(0, -15),
              child: GestureDetector(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Positionsanzeige löschen"),
                            content: const Text(
                                "Wollen Sie diese Positionsanzeige löschen?"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text("Abbrechen"),
                              ),
                              TextButton(
                                onPressed: () {
                                  widget.onDelete();
                                  Navigator.of(context).pop();
                                },
                                child: const Text("Löschen"),
                              ),
                            ],
                          );
                        });
                  },
                  child: const Icon(
                    Icons.place,
                    color: Colors.red,
                    size: 40,
                  ))))
    ]);
  }
}
