import 'package:flutter/material.dart';

import 'app_tokens.dart';

export 'app_tokens.dart';

ThemeData buildAppTheme() {
  const fontFallback = [
    'Noto Sans Bengali',
    'Noto Sans',
    'Hind Siliguri',
    'SolaimanLipi',
  ];

  final colorScheme = ColorScheme.fromSeed(seedColor: EpColors.brand).copyWith(
    primary: EpColors.fillPrimary,
    onPrimary: EpColors.n0,
    primaryContainer: EpColors.green50,
    onPrimaryContainer: EpColors.green800,
    secondary: EpColors.clinicalStrong,
    onSecondary: EpColors.n0,
    error: EpColors.destructiveFill,
    onError: EpColors.n0,
    surface: EpColors.surface,
    onSurface: EpColors.textPrimary,
    onSurfaceVariant: EpColors.textSecondary,
    outline: EpColors.borderDefault,
    outlineVariant: EpColors.borderSubtle,
  );

  const buttonShape = RoundedRectangleBorder(borderRadius: EpRadius.mdAll);
  const buttonText = TextStyle(
    fontSize: EpTextSize.label,
    fontWeight: FontWeight.w700,
  );
  const minButtonSize = Size(48, 48);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamilyFallback: fontFallback,
    scaffoldBackgroundColor: EpColors.background,
    dividerColor: EpColors.borderSubtle,
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: EpTextSize.display,
        fontWeight: FontWeight.w700,
        color: EpColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: EpTextSize.heading,
        fontWeight: FontWeight.w700,
        color: EpColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: EpTextSize.body,
        fontWeight: FontWeight.w700,
        color: EpColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: EpTextSize.body,
        color: EpColors.textPrimary,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        fontSize: EpTextSize.bodySmall,
        color: EpColors.textSecondary,
        height: 1.45,
      ),
      labelLarge: TextStyle(
        fontSize: EpTextSize.label,
        fontWeight: FontWeight.w700,
      ),
      bodySmall: TextStyle(
        fontSize: EpTextSize.caption,
        color: EpColors.textMuted,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: EpColors.fillPrimary,
      foregroundColor: EpColors.n0,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: EpTextSize.heading,
        fontWeight: FontWeight.w700,
        color: EpColors.n0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: EpColors.fillPrimary,
        foregroundColor: EpColors.n0,
        disabledBackgroundColor: EpColors.fillPrimaryDisabled,
        minimumSize: minButtonSize,
        padding: const EdgeInsets.symmetric(horizontal: EpSpace.s5),
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: EpColors.fillPrimary,
        minimumSize: minButtonSize,
        padding: const EdgeInsets.symmetric(horizontal: EpSpace.s5),
        side: const BorderSide(color: EpColors.fillPrimary),
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: EpColors.fillPrimary,
        minimumSize: minButtonSize,
        textStyle: buttonText,
      ),
    ),
    cardTheme: const CardThemeData(
      color: EpColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: EpRadius.mdAll,
        side: BorderSide(color: EpColors.borderSubtle),
      ),
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: EpColors.surface),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: EpColors.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(EpRadius.lg)),
      ),
    ),
  );
}
