import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/rekan_theme.dart';

/// Handcrafted multi-tone flat vector illustrations for academic categories.
/// Clean Lemon Green + Cobalt Blue geometry (zero cartoon faces, zero AI slop).
class CategoryVectorArt extends StatelessWidget {
  const CategoryVectorArt({
    super.key,
    required this.categoryId,
    this.size = 38,
  });

  final String categoryId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CategoryArtPainter(categoryId),
      ),
    );
  }
}

class _CategoryArtPainter extends CustomPainter {
  _CategoryArtPainter(this.id);

  final String id;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (id) {
      case 'study':
        final cover = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.12, h * 0.18, w * 0.76, h * 0.66),
          Radius.circular(w * 0.10),
        );
        canvas.drawRRect(cover, Paint()..color = RekanPalette.blue);

        final leftPage = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.17, h * 0.22, w * 0.31, h * 0.56),
          Radius.circular(w * 0.05),
        );
        final rightPage = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.52, h * 0.22, w * 0.31, h * 0.56),
          Radius.circular(w * 0.05),
        );
        final white = Paint()..color = Colors.white;
        canvas.drawRRect(leftPage, white);
        canvas.drawRRect(rightPage, white);

        final ribbon = Path()
          ..moveTo(w * 0.62, h * 0.12)
          ..lineTo(w * 0.75, h * 0.12)
          ..lineTo(w * 0.75, h * 0.44)
          ..lineTo(w * 0.685, h * 0.36)
          ..lineTo(w * 0.62, h * 0.44)
          ..close();
        canvas.drawPath(ribbon, Paint()..color = RekanPalette.lemon);

        final linePaint = Paint()
          ..color = RekanPalette.blueSoft
          ..strokeWidth = w * 0.055
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(w * 0.23, h * 0.38),
          Offset(w * 0.42, h * 0.38),
          linePaint,
        );
        canvas.drawLine(
          Offset(w * 0.23, h * 0.52),
          Offset(w * 0.42, h * 0.52),
          linePaint,
        );
        break;

      case 'lomba':
        final handlePaint = Paint()
          ..color = RekanPalette.lemonVivid
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.075;
        canvas.drawArc(
          Rect.fromLTWH(w * 0.14, h * 0.24, w * 0.22, h * 0.24),
          math.pi * 0.5,
          math.pi,
          false,
          handlePaint,
        );
        canvas.drawArc(
          Rect.fromLTWH(w * 0.64, h * 0.24, w * 0.22, h * 0.24),
          -math.pi * 0.5,
          math.pi,
          false,
          handlePaint,
        );
        final cupPath = Path()
          ..moveTo(w * 0.26, h * 0.18)
          ..lineTo(w * 0.74, h * 0.18)
          ..lineTo(w * 0.68, h * 0.52)
          ..quadraticBezierTo(w * 0.50, h * 0.68, w * 0.32, h * 0.52)
          ..close();
        canvas.drawPath(cupPath, Paint()..color = RekanPalette.lemon);
        canvas.drawRect(
          Rect.fromLTWH(w * 0.45, h * 0.58, w * 0.10, h * 0.16),
          Paint()..color = RekanPalette.lemonDark,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.28, h * 0.72, w * 0.44, h * 0.13),
            Radius.circular(w * 0.05),
          ),
          Paint()..color = RekanPalette.blue,
        );
        break;

      case 'riset':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.18, h * 0.14, w * 0.48, h * 0.62),
            Radius.circular(w * 0.08),
          ),
          Paint()..color = RekanPalette.blueSoft,
        );
        final barPaint = Paint()
          ..color = RekanPalette.blue
          ..strokeWidth = w * 0.055
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(w * 0.28, h * 0.30),
          Offset(w * 0.54, h * 0.30),
          barPaint,
        );
        canvas.drawLine(
          Offset(w * 0.28, h * 0.44),
          Offset(w * 0.48, h * 0.44),
          barPaint,
        );
        canvas.drawLine(
          Offset(w * 0.66, h * 0.66),
          Offset(w * 0.84, h * 0.84),
          Paint()
            ..color = RekanPalette.lemonInk
            ..strokeWidth = w * 0.10
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          Offset(w * 0.56, h * 0.56),
          w * 0.18,
          Paint()..color = RekanPalette.lemon,
        );
        canvas.drawCircle(
          Offset(w * 0.56, h * 0.56),
          w * 0.11,
          Paint()..color = Colors.white,
        );
        break;

      default:
        final r = Radius.circular(w * 0.08);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.16, h * 0.16, w * 0.29, h * 0.29),
            r,
          ),
          Paint()..color = RekanPalette.lemonVivid,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.55, h * 0.16, w * 0.29, h * 0.29),
            r,
          ),
          Paint()..color = RekanPalette.blue,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.16, h * 0.55, w * 0.29, h * 0.29),
            r,
          ),
          Paint()..color = RekanPalette.blueSoft,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.55, h * 0.55, w * 0.29, h * 0.29),
            r,
          ),
          Paint()..color = RekanPalette.lemon,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryArtPainter oldDelegate) =>
      oldDelegate.id != id;
}

/// Crisp custom vector badge for Bento Cards.
class BentoVectorEmblem extends StatelessWidget {
  const BentoVectorEmblem({
    super.key,
    required this.kind,
    this.size = 44,
  });

  final String kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BentoEmblemPainter(kind)),
    );
  }
}

class _BentoEmblemPainter extends CustomPainter {
  _BentoEmblemPainter(this.kind);

  final String kind;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (kind == 'bolt') {
      final path = Path()
        ..moveTo(w * 0.56, h * 0.08)
        ..lineTo(w * 0.18, h * 0.54)
        ..lineTo(w * 0.46, h * 0.54)
        ..lineTo(w * 0.38, h * 0.92)
        ..lineTo(w * 0.82, h * 0.42)
        ..lineTo(w * 0.52, h * 0.42)
        ..close();
      canvas.drawPath(path, Paint()..color = RekanPalette.lemon);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.22, h * 0.14, w * 0.62, h * 0.52),
          Radius.circular(w * 0.10),
        ),
        Paint()..color = RekanPalette.blue,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.12, h * 0.30, w * 0.62, h * 0.54),
          Radius.circular(w * 0.10),
        ),
        Paint()..color = RekanPalette.lemonVivid,
      );
      canvas.drawLine(
        Offset(w * 0.24, h * 0.50),
        Offset(w * 0.60, h * 0.50),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(w * 0.24, h * 0.65),
        Offset(w * 0.50, h * 0.65),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BentoEmblemPainter oldDelegate) =>
      oldDelegate.kind != kind;
}
