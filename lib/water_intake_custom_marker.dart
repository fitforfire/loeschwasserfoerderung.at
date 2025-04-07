import 'package:flutter/material.dart';

//Class for the WaterDrop Marker of a WaterIntakePoint
class CustomWaterIntakeMarker extends CustomPainter {
  final Color color;

  CustomWaterIntakeMarker(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;

    final Path path = Path();

    //Waterdrop Form
    path.moveTo(size.width / 2, size.height);
    path.quadraticBezierTo(
        size.width, size.height * 0.6, size.width * 0.75, size.height * 0.35);
    path.arcToPoint(
      Offset(size.width * 0.25, size.height * 0.35),
      radius: Radius.circular(size.width * 0.4),
      clockwise: false,
    );
    path.quadraticBezierTo(0, size.height * 0.6, size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
