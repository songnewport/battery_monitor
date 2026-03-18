import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';

class SparklineCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<double> values;
  final String rightValue;

  const SparklineCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.values,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.panelAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTextStyles.sectionTitle),
              const Spacer(),
              Text(rightValue, style: AppTextStyles.body),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.caption),
          const SizedBox(height: 16),
          SizedBox(
            height: 96,
            child: CustomPaint(
              painter: _SparklinePainter(values),
              size: const Size(double.infinity, 96),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;

  _SparklinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), bg);
    }

    if (values.length < 2) return;

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final norm = (values[i] - minV) / span;
      final y = size.height - (norm * (size.height - 8)) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x6659AFFF),
          Color(0x0059AFFF),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final line = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.icon, AppColors.accent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, line);

    final last = values.last;
    final lastNorm = (last - minV) / span;
    final cx = size.width;
    final cy = size.height - (lastNorm * (size.height - 8)) - 4;

    canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = AppColors.primaryText);
    canvas.drawCircle(Offset(cx, cy), 3, Paint()..color = AppColors.accent);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
