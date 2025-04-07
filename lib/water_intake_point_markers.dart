import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:loeschwasserfoerderung/water_intake_custom_marker.dart';

class WaterIntakePointMarkersLayer extends StatefulWidget {
  final List<List<dynamic>> waterIntakePointsInformationList;

  const WaterIntakePointMarkersLayer(
      {super.key, required this.waterIntakePointsInformationList});

  @override
  WaterIntakePointMarkersLayerState createState() =>
      WaterIntakePointMarkersLayerState();
}

class WaterIntakePointMarkersLayerState
    extends State<WaterIntakePointMarkersLayer> {
  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: widget.waterIntakePointsInformationList.map((point) {
        String imagePath = "assets/hydrant_logos/ueberflurhydrant.png";

        switch (point[0]) {
          case 0:
            imagePath = "assets/hydrant_logos/ueberflurhydrant.png";
            break;
          case 1:
            imagePath =
                "assets/hydrant_logos/unterflurhydrantUndSchachthydrant.png";
            break;
          case 2:
            imagePath = "assets/hydrant_logos/saugstelle.png";
            break;
          case 3:
            imagePath = "assets/hydrant_logos/loeschwasserbehaelter.png";
            break;
          case 4:
            imagePath =
                "assets/hydrant_logos/loeschwasserteichUndNaturteichUndSchwimmbad.png";
            break;
          case 5:
            imagePath = "assets/hydrant_logos/loeschwasserbrunnen.png";
            break;
          default:
            imagePath = "assets/hydrant_logos/ueberflurhydrant.png";
        }

        return Marker(
            width: 40.0,
            height: 50.0,
            point: LatLng(point[1], point[2]),
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(40, 50),
                    painter: CustomWaterIntakeMarker(Colors.blue),
                  ),
                  Image.asset(imagePath,
                      width: 24, height: 24, fit: BoxFit.cover)
                ],
              ),
            ));
      }).toList(),
    );
  }
}
