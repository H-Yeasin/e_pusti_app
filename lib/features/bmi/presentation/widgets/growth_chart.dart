import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/bmi_models.dart';

class GrowthPoint {
  const GrowthPoint({required this.ageMonths, required this.bmi});

  final int ageMonths;
  final double bmi;
}

/// BMI at [z] SD for one age from the LMS parameters.
double bmiAtZ(Lms lms, double z) => lms.l == 0
    ? lms.m * math.exp(lms.s * z)
    : lms.m * math.pow(1 + lms.l * lms.s * z, 1 / lms.l).toDouble();

/// P2-1 (ages 5–19): the person's BMI on the WHO 2007 BMI-for-age curves.
/// Clinical palette only; no colour carries a health judgement.
class GrowthChart extends StatelessWidget {
  const GrowthChart({
    super.key,
    required this.reference,
    required this.sex,
    required this.points,
  });

  final BmiForAgeReference reference;
  final Sex sex;
  final List<GrowthPoint> points;

  static const curves = [-2.0, -1.0, 0.0, 1.0, 2.0];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ages = points.map((p) => p.ageMonths);
    final from = math.max(61, ages.reduce(math.min) - 12);
    final to = math.min(228, ages.reduce(math.max) + 12);

    final lines = <double, List<Offset>>{};
    for (final z in curves) {
      lines[z] = [
        for (var m = from; m <= to; m++)
          if (reference.lookup(sex, m) case final lms?)
            Offset(m.toDouble(), bmiAtZ(lms, z)),
      ];
    }

    return Semantics(
      label: l10n.growthChartSemantic(context.digits(points.length)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: CustomPaint(
              key: const ValueKey('growth-chart'),
              painter: _ChartPainter(
                lines: lines,
                points: [
                  for (final p in points) Offset(p.ageMonths.toDouble(), p.bmi),
                ],
                fromMonth: from.toDouble(),
                toMonth: to.toDouble(),
                yearLabel: (months) => context.digits(months ~/ 12),
              ),
            ),
          ),
          const SizedBox(height: EpSpace.s2),
          Text(
            l10n.growthChartLegend,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.lines,
    required this.points,
    required this.fromMonth,
    required this.toMonth,
    required this.yearLabel,
  });

  final Map<double, List<Offset>> lines;
  final List<Offset> points;
  final double fromMonth;
  final double toMonth;
  final String Function(int months) yearLabel;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 28.0;
    const bottom = 20.0;
    final plot = Rect.fromLTRB(left, 8, size.width - 8, size.height - bottom);

    final allY = [
      for (final l in lines.values) ...l.map((o) => o.dy),
      ...points.map((p) => p.dy),
    ];
    final minY = (allY.reduce(math.min) - 1).floorToDouble();
    final maxY = (allY.reduce(math.max) + 1).ceilToDouble();

    Offset map(Offset v) => Offset(
      plot.left + (v.dx - fromMonth) / (toMonth - fromMonth) * plot.width,
      plot.bottom - (v.dy - minY) / (maxY - minY) * plot.height,
    );

    // Normal band (−2 to +1 SD) shaded lightly.
    final low = lines[-2.0]!, high = lines[1.0]!;
    if (low.isNotEmpty && high.isNotEmpty) {
      final band = Path()..moveTo(map(low.first).dx, map(low.first).dy);
      for (final o in low) {
        band.lineTo(map(o).dx, map(o).dy);
      }
      for (final o in high.reversed) {
        band.lineTo(map(o).dx, map(o).dy);
      }
      band.close();
      canvas.drawPath(band, Paint()..color = EpColors.clinicalTint);
    }

    final grid = Paint()
      ..color = EpColors.clinicalLine
      ..strokeWidth = 1;
    final text = TextPainter(textDirection: TextDirection.ltr);
    void label(String s, Offset at) {
      text.text = TextSpan(
        text: s,
        style: const TextStyle(fontSize: 10, color: EpColors.clinicalText),
      );
      text.layout();
      text.paint(canvas, at - Offset(text.width / 2, 0));
    }

    for (var m = (fromMonth / 12).ceil() * 12; m <= toMonth; m += 12) {
      final x = map(Offset(m.toDouble(), minY)).dx;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), grid);
      label(yearLabel(m), Offset(x, plot.bottom + 4));
    }
    for (var y = minY; y <= maxY; y += 2) {
      final py = map(Offset(fromMonth, y)).dy;
      canvas.drawLine(Offset(plot.left, py), Offset(plot.right, py), grid);
      label(y.toStringAsFixed(0), Offset(left / 2, py - 6));
    }

    for (final entry in lines.entries) {
      final path = Path();
      for (var i = 0; i < entry.value.length; i++) {
        final p = map(entry.value[i]);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = entry.key == 0 ? 2 : 1
          ..color = entry.key == 0 ? EpColors.clinicalStrong : EpColors.band3,
      );
    }

    final sorted = [...points]..sort((a, b) => a.dx.compareTo(b.dx));
    final trail = Path();
    for (var i = 0; i < sorted.length; i++) {
      final p = map(sorted[i]);
      i == 0 ? trail.moveTo(p.dx, p.dy) : trail.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      trail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = EpColors.n900,
    );
    for (final p in sorted) {
      canvas.drawCircle(map(p), 4, Paint()..color = EpColors.n900);
      canvas.drawCircle(map(p), 2, Paint()..color = EpColors.n0);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.points != points || old.lines != lines;
}
