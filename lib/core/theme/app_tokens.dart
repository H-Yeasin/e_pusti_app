import 'package:flutter/widgets.dart';

/// Design tokens from the e-Pushti design system (wireframe V4).
///
/// Every colour, spacing, radius and duration used by the app should come
/// from here. Feature code must not declare `Color(0x…)` literals.
abstract final class EpColors {
  // Brand green scale.
  static const green50 = Color(0xFFEFFCEE);
  static const green100 = Color(0xFFDEF7DB);
  static const green200 = Color(0xFFBBEAB7);
  static const green300 = Color(0xFF8CD688);
  static const green400 = Color(0xFF57BF54);
  static const green500 = Color(0xFF03AC13);
  static const green600 = Color(0xFF19871B);
  static const green700 = Color(0xFF176718);
  static const green800 = Color(0xFF0E4C0F);
  static const green900 = Color(0xFF073407);

  // Neutral scale.
  static const n0 = Color(0xFFFFFFFF);
  static const n50 = Color(0xFFF6F9F6);
  static const n100 = Color(0xFFEEF1ED);
  static const n200 = Color(0xFFDADFDA);
  static const n300 = Color(0xFFC0C6C0);
  static const n400 = Color(0xFFA4AAA4);
  static const n500 = Color(0xFF8F958F);
  static const n600 = Color(0xFF707770);
  static const n700 = Color(0xFF545A54);
  static const n800 = Color(0xFF3E423E);
  static const n900 = Color(0xFF292D29);

  // Clinical palette: the only colours allowed to carry a health reading.
  static const clinicalTint = Color(0xFFF2F7F9);
  static const clinicalLine = Color(0xFFE1EAEE);
  static const clinicalGraphic = Color(0xFF6A8C9B);
  static const clinicalText = Color(0xFF577684);
  static const clinicalStrong = Color(0xFF415B67);
  static const band1 = Color(0xFFE1EAEE);
  static const band2 = Color(0xFFB6C9D1);
  static const band3 = Color(0xFF6A8C9B);

  // Destructive / error.
  static const destructiveTint = Color(0xFFFFF3EE);
  static const destructiveLine = Color(0xFFFFE3DA);
  static const destructiveGraphic = Color(0xFFE8573B);
  static const destructiveFill = Color(0xFFC6452B);
  static const destructiveText = Color(0xFFC6452B);
  static const destructiveStrong = Color(0xFF9D321E);

  /// Partner red. Legal only inside a confirmed partner creative
  /// (see `AdSlot`); never use it for app chrome.
  static const partnerRed = Color(0xFFB21935);

  // Semantic aliases.
  static const brand = green500;
  static const fillPrimary = green600;
  static const fillPrimaryPressed = green800;
  static const fillPrimaryDisabled = n200;
  static const focusRing = green700;
  static const borderSubtle = n200;
  static const borderDefault = n300;
  static const borderStrong = n600;
  static const borderSelected = green600;
  static const surface = n0;
  static const background = n50;
  static const textPrimary = n900;
  static const textSecondary = n700;
  static const textMuted = n600;
}

abstract final class EpSpace {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s10 = 40.0;
  static const s12 = 48.0;

  /// Horizontal screen gutter.
  static const gutter = s4;
  static const cardPadding = s4;
}

abstract final class EpRadius {
  static const sm = 6.0;
  static const md = 10.0;
  static const lg = 14.0;
  static const pill = 999.0;

  static const smAll = BorderRadius.all(Radius.circular(sm));
  static const mdAll = BorderRadius.all(Radius.circular(md));
  static const lgAll = BorderRadius.all(Radius.circular(lg));
}

abstract final class EpTextSize {
  static const display = 34.0;
  static const heading = 19.0;
  static const bodyLarge = 18.0;
  static const body = 16.0;
  static const bodySmall = 15.0;
  static const label = 14.0;
  static const caption = 13.0;
}

abstract final class EpMotion {
  static const instant = Duration(milliseconds: 80);
  static const fast = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 280);
  static const standard = Cubic(0.2, 0, 0.2, 1);
  static const exit = Cubic(0.4, 0, 1, 1);
}

abstract final class EpElevation {
  static const level1 = [
    BoxShadow(color: Color(0x14292D29), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const level2 = [
    BoxShadow(color: Color(0x1A292D29), offset: Offset(0, 2), blurRadius: 6),
  ];
}
