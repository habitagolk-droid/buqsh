import 'package:flutter/material.dart';

const Color kBaqshPrimary = Color(0xFF0C4A40);
const Color kBaqshSecondary = Color(0xFF278D5B);
const Color kBaqshDark = Color(0xFF1E1E1E);

class LayeredServiceIcon extends StatelessWidget {
  const LayeredServiceIcon({
    super.key,
    required this.kind,
    this.small = false,
  });

  final int kind;
  final bool small;

  const LayeredServiceIcon.wallet({super.key, this.small = false}) : kind = 0;
  const LayeredServiceIcon.transfer({super.key, this.small = false}) : kind = 1;
  const LayeredServiceIcon.topup({super.key, this.small = false}) : kind = 2;
  const LayeredServiceIcon.bills({super.key, this.small = false}) : kind = 4;
  const LayeredServiceIcon.exchange({super.key, this.small = false}) : kind = 5;
  const LayeredServiceIcon.cards({super.key, this.small = false}) : kind = 6;
  const LayeredServiceIcon.zakat({super.key, this.small = false}) : kind = 7;
  const LayeredServiceIcon.savings({super.key, this.small = false}) : kind = 8;
  const LayeredServiceIcon.more({super.key, this.small = false}) : kind = 9;

  @override
  Widget build(BuildContext context) {
    final size = small ? 20.0 : 30.0;
    final darkBackground = kind == 0 || kind == 5;

    return SizedBox(
      width: size + 10,
      height: size + 10,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size + 10,
            height: size + 10,
            decoration: BoxDecoration(
              color: darkBackground
                  ? kBaqshPrimary
                  : kBaqshSecondary.withOpacity(.3),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: kBaqshDark, width: 2),
            ),
          ),
          Container(
            width: size + 2,
            height: size + 2,
            decoration: BoxDecoration(
              color: darkBackground
                  ? kBaqshSecondary
                  : Colors.white.withOpacity(.9),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          CustomPaint(
            size: Size(size, size),
            painter: _ServiceGlyphPainter(kind, dark: darkBackground),
          ),
        ],
      ),
    );
  }
}

class _ServiceGlyphPainter extends CustomPainter {
  _ServiceGlyphPainter(this.kind, {required this.dark});

  final int kind;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final front = Paint()
      ..color = dark ? Colors.white : kBaqshPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = dark ? Colors.white : kBaqshPrimary
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    switch (kind % 10) {
      case 0:
        final wallet = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .12, h * .28, w * .76, h * .50),
          const Radius.circular(4),
        );
        canvas.drawRRect(wallet, front);
        canvas.drawLine(Offset(w * .12, h * .44), Offset(w * .88, h * .44), front);
        canvas.drawCircle(Offset(w * .68, h * .61), 1.8, fill);
        break;
      case 1:
        canvas.drawLine(Offset(w * .15, h * .35), Offset(w * .85, h * .35), front);
        canvas.drawLine(Offset(w * .65, h * .20), Offset(w * .85, h * .35), front);
        canvas.drawLine(Offset(w * .65, h * .50), Offset(w * .85, h * .35), front);
        canvas.drawLine(Offset(w * .15, h * .65), Offset(w * .85, h * .65), front);
        canvas.drawLine(Offset(w * .15, h * .65), Offset(w * .35, h * .50), front);
        canvas.drawLine(Offset(w * .15, h * .65), Offset(w * .35, h * .80), front);
        break;
      case 2:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .30, h * .10, w * .40, h * .72),
            const Radius.circular(5),
          ),
          front,
        );
        canvas.drawLine(Offset(w * .44, h * .72), Offset(w * .56, h * .72), front);
        canvas.drawCircle(Offset(w * .50, h * .20), 1.4, fill);
        canvas.drawLine(Offset(w * .38, h * .38), Offset(w * .62, h * .38), front);
        canvas.drawLine(Offset(w * .38, h * .50), Offset(w * .62, h * .50), front);
        break;
      case 3:
      case 4:
        final bill = Path()
          ..moveTo(w * .28, h * .08)
          ..lineTo(w * .72, h * .08)
          ..lineTo(w * .72, h * .85)
          ..lineTo(w * .62, h * .75)
          ..lineTo(w * .52, h * .85)
          ..lineTo(w * .42, h * .75)
          ..lineTo(w * .32, h * .85)
          ..lineTo(w * .28, h * .85)
          ..close();
        canvas.drawPath(bill, front);
        canvas.drawLine(Offset(w * .38, h * .32), Offset(w * .62, h * .32), front);
        canvas.drawLine(Offset(w * .38, h * .46), Offset(w * .62, h * .46), front);
        break;
      case 5:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .10, h * .30, w * .80, h * .42),
            const Radius.circular(4),
          ),
          front,
        );
        canvas.drawCircle(Offset(w * .50, h * .51), w * .12, front);
        canvas.drawLine(Offset(w * .10, h * .30), Offset(w * .20, h * .20), front);
        canvas.drawLine(Offset(w * .90, h * .30), Offset(w * .80, h * .20), front);
        break;
      case 6:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .12, h * .26, w * .76, h * .50),
            const Radius.circular(4),
          ),
          front,
        );
        canvas.drawLine(Offset(w * .12, h * .40), Offset(w * .88, h * .40), front);
        canvas.drawLine(Offset(w * .22, h * .60), Offset(w * .44, h * .60), front);
        break;
      case 7:
        final heart = Path()
          ..moveTo(w * .50, h * .78)
          ..cubicTo(w * .18, h * .55, w * .18, h * .55, w * .22, h * .34)
          ..cubicTo(w * .25, h * .22, w * .25, h * .22, w * .38, h * .24)
          ..cubicTo(w * .46, h * .25, w * .46, h * .25, w * .50, h * .34)
          ..cubicTo(w * .54, h * .25, w * .54, h * .25, w * .62, h * .24)
          ..cubicTo(w * .75, h * .22, w * .75, h * .22, w * .78, h * .34)
          ..cubicTo(w * .82, h * .55, w * .82, h * .55, w * .50, h * .78)
          ..close();
        canvas.drawPath(heart, front);
        break;
      case 8:
        canvas.drawCircle(Offset(w * .46, h * .54), w * .28, front);
        canvas.drawLine(Offset(w * .70, h * .42), Offset(w * .82, h * .32), front);
        canvas.drawLine(Offset(w * .72, h * .52), Offset(w * .84, h * .52), front);
        canvas.drawCircle(Offset(w * .38, h * .50), 1.5, fill);
        canvas.drawLine(Offset(w * .46, h * .26), Offset(w * .46, h * .34), front);
        break;
      default:
        for (var row = 0; row < 2; row++) {
          for (var column = 0; column < 2; column++) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(
                  w * (.20 + column * .32),
                  h * (.20 + row * .32),
                  w * .24,
                  h * .24,
                ),
                const Radius.circular(3),
              ),
              front,
            );
          }
        }
        break;
    }

    final outline = Paint()
      ..color = kBaqshDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(w * .5, h * .5), w * .47, outline);
  }

  @override
  bool shouldRepaint(covariant _ServiceGlyphPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.dark != dark;
}
