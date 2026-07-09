import 'package:flutter/material.dart';

Widget buildGoogleLoginButton({
  required bool isLoading,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: 220,
    height: 44,
    child: OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: const _GoogleLogo(size: 18),
      label: const Text('Login Google'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color.fromARGB(255, 157, 161, 165)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _GoogleLogo extends StatelessWidget {
  final double size;

  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.18;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, -0.05, 1.35, false, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, 1.28, 1.55, false, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, 2.75, 1.20, false, paint);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, 3.82, 1.35, false, paint);

    paint.color = const Color(0xFF4285F4);
    final centerY = size.height * 0.52;
    canvas.drawLine(
      Offset(size.width * 0.52, centerY),
      Offset(size.width * 0.88, centerY),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.88, centerY),
      Offset(size.width * 0.76, size.height * 0.70),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
