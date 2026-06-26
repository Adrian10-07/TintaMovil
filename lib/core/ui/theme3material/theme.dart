import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff1c6b50),
      surfaceTint: Color(0xff1c6b50),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffa7f2d1),
      onPrimaryContainer: Color(0xff00513b),
      secondary: Color(0xff006a6a),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff9cf1f0),
      onSecondaryContainer: Color(0xff004f4f),
      tertiary: Color(0xff3e6374),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffc2e8fc),
      onTertiaryContainer: Color(0xff254b5c),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff7fbf2),
      onSurface: Color(0xff181d17),
      onSurfaceVariant: Color(0xff3f484a),
      outline: Color(0xff6f797a),
      outlineVariant: Color(0xffbec8ca),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2d322c),
      inversePrimary: Color(0xff8bd6b5),
      primaryFixed: Color(0xffa7f2d1),
      onPrimaryFixed: Color(0xff002116),
      primaryFixedDim: Color(0xff8bd6b5),
      onPrimaryFixedVariant: Color(0xff00513b),
      secondaryFixed: Color(0xff9cf1f0),
      onSecondaryFixed: Color(0xff002020),
      secondaryFixedDim: Color(0xff80d5d4),
      onSecondaryFixedVariant: Color(0xff004f4f),
      tertiaryFixed: Color(0xffc2e8fc),
      onTertiaryFixed: Color(0xff001f2a),
      tertiaryFixedDim: Color(0xffa6cce0),
      onTertiaryFixedVariant: Color(0xff254b5c),
      surfaceDim: Color(0xffd7dbd3),
      surfaceBright: Color(0xfff7fbf2),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff1f5ec),
      surfaceContainer: Color(0xffebefe6),
      surfaceContainerHigh: Color(0xffe6e9e1),
      surfaceContainerHighest: Color(0xffe0e4db),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003f2c),
      surfaceTint: Color(0xff1c6b50),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff2e7a5f),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff003d3d),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff167979),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff123a4a),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff4d7283),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff7fbf2),
      onSurface: Color(0xff0e120d),
      onSurfaceVariant: Color(0xff2f3839),
      outline: Color(0xff4b5455),
      outlineVariant: Color(0xff656f70),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2d322c),
      inversePrimary: Color(0xff8bd6b5),
      primaryFixed: Color(0xff2e7a5f),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff0b6147),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff167979),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff005f5f),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff4d7283),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff34596a),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc4c8bf),
      surfaceBright: Color(0xfff7fbf2),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff1f5ec),
      surfaceContainer: Color(0xffe6e9e1),
      surfaceContainerHigh: Color(0xffdaded5),
      surfaceContainerHighest: Color(0xffcfd3ca),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003324),
      surfaceTint: Color(0xff1c6b50),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff00543d),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff003232),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff005252),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff033040),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff284e5e),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff7fbf2),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff252e2f),
      outlineVariant: Color(0xff414b4c),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2d322c),
      inversePrimary: Color(0xff8bd6b5),
      primaryFixed: Color(0xff00543d),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff003b29),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff005252),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff003939),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff284e5e),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff0d3747),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb6bab2),
      surfaceBright: Color(0xfff7fbf2),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeef2e9),
      surfaceContainer: Color(0xffe0e4db),
      surfaceContainerHigh: Color(0xffd2d6cd),
      surfaceContainerHighest: Color(0xffc4c8bf),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff8bd6b5),
      surfaceTint: Color(0xff8bd6b5),
      onPrimary: Color(0xff003827),
      primaryContainer: Color(0xff00513b),
      onPrimaryContainer: Color(0xffa7f2d1),
      secondary: Color(0xff80d5d4),
      onSecondary: Color(0xff003737),
      secondaryContainer: Color(0xff004f4f),
      onSecondaryContainer: Color(0xff9cf1f0),
      tertiary: Color(0xffa6cce0),
      onTertiary: Color(0xff093544),
      tertiaryContainer: Color(0xff254b5c),
      onTertiaryContainer: Color(0xffc2e8fc),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff101410),
      onSurface: Color(0xffe0e4db),
      onSurfaceVariant: Color(0xffbec8ca),
      outline: Color(0xff899294),
      outlineVariant: Color(0xff3f484a),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe0e4db),
      inversePrimary: Color(0xff1c6b50),
      primaryFixed: Color(0xffa7f2d1),
      onPrimaryFixed: Color(0xff002116),
      primaryFixedDim: Color(0xff8bd6b5),
      onPrimaryFixedVariant: Color(0xff00513b),
      secondaryFixed: Color(0xff9cf1f0),
      onSecondaryFixed: Color(0xff002020),
      secondaryFixedDim: Color(0xff80d5d4),
      onSecondaryFixedVariant: Color(0xff004f4f),
      tertiaryFixed: Color(0xffc2e8fc),
      onTertiaryFixed: Color(0xff001f2a),
      tertiaryFixedDim: Color(0xffa6cce0),
      onTertiaryFixedVariant: Color(0xff254b5c),
      surfaceDim: Color(0xff101410),
      surfaceBright: Color(0xff363a34),
      surfaceContainerLowest: Color(0xff0b0f0a),
      surfaceContainerLow: Color(0xff181d17),
      surfaceContainer: Color(0xff1c211b),
      surfaceContainerHigh: Color(0xff272b26),
      surfaceContainerHighest: Color(0xff313630),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffa0eccb),
      surfaceTint: Color(0xff8bd6b5),
      onPrimary: Color(0xff002c1e),
      primaryContainer: Color(0xff559e81),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xff96ebea),
      onSecondary: Color(0xff002b2b),
      secondaryContainer: Color(0xff479e9d),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffbce2f6),
      onTertiary: Color(0xff002938),
      tertiaryContainer: Color(0xff7196a8),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff101410),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffd4dedf),
      outline: Color(0xffaab4b5),
      outlineVariant: Color(0xff889293),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe0e4db),
      inversePrimary: Color(0xff00533c),
      primaryFixed: Color(0xffa7f2d1),
      onPrimaryFixed: Color(0xff00150d),
      primaryFixedDim: Color(0xff8bd6b5),
      onPrimaryFixedVariant: Color(0xff003f2c),
      secondaryFixed: Color(0xff9cf1f0),
      onSecondaryFixed: Color(0xff001414),
      secondaryFixedDim: Color(0xff80d5d4),
      onSecondaryFixedVariant: Color(0xff003d3d),
      tertiaryFixed: Color(0xffc2e8fc),
      onTertiaryFixed: Color(0xff00131c),
      tertiaryFixedDim: Color(0xffa6cce0),
      onTertiaryFixedVariant: Color(0xff123a4a),
      surfaceDim: Color(0xff101410),
      surfaceBright: Color(0xff41463f),
      surfaceContainerLowest: Color(0xff050805),
      surfaceContainerLow: Color(0xff1a1f19),
      surfaceContainer: Color(0xff252923),
      surfaceContainerHigh: Color(0xff2f342e),
      surfaceContainerHighest: Color(0xff3a3f39),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffb8ffdf),
      surfaceTint: Color(0xff8bd6b5),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xff87d2b2),
      onPrimaryContainer: Color(0xff000e08),
      secondary: Color(0xffaafffe),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xff7cd1d0),
      onSecondaryContainer: Color(0xff000e0e),
      tertiary: Color(0xffdef3ff),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffa2c8dc),
      onTertiaryContainer: Color(0xff000d14),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff101410),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffe8f2f3),
      outlineVariant: Color(0xffbbc4c6),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe0e4db),
      inversePrimary: Color(0xff00533c),
      primaryFixed: Color(0xffa7f2d1),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xff8bd6b5),
      onPrimaryFixedVariant: Color(0xff00150d),
      secondaryFixed: Color(0xff9cf1f0),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xff80d5d4),
      onSecondaryFixedVariant: Color(0xff001414),
      tertiaryFixed: Color(0xffc2e8fc),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffa6cce0),
      onTertiaryFixedVariant: Color(0xff00131c),
      surfaceDim: Color(0xff101410),
      surfaceBright: Color(0xff4d514b),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1c211b),
      surfaceContainer: Color(0xff2d322c),
      surfaceContainerHigh: Color(0xff383d37),
      surfaceContainerHighest: Color(0xff434842),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.background,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
