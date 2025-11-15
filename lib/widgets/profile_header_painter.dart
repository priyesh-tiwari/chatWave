import 'package:flutter/material.dart';

/// Custom painter for creating a wavy gradient header in the profile screen
class ProfileHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);

    // Create wavy bottom edge
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height - 20,
      size.width * 0.5,
      size.height - 40,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 60,
      size.width,
      size.height - 40,
    );

    path.lineTo(size.width, 0);
    path.close();

    // Define gradient
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const Gradient gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF2B5C56),
        Color(0xFF00BCD4),
      ],
    );

    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
