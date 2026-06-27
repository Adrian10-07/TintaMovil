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

  // ═══════════════════════════════════════════════════════════════════════════
  // TIPOGRAFÍA TINTA
  // Plus Jakarta Sans (display, headline, title) + DM Sans (body, label)
  // ═══════════════════════════════════════════════════════════════════════════

  static TextTheme get tintaTextTheme {
    return const TextTheme(
      // ── Display: títulos hero ─────────────────────────────────────
      displayLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w800,
        fontSize: 57,
        height: 1.12,
        letterSpacing: -0.8,
      ),
      displayMedium: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w800,
        fontSize: 45,
        height: 1.15,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w800,
        fontSize: 36,
        height: 1.22,
        letterSpacing: -0.3,
      ),

      // ── Headline: secciones ───────────────────────────────────────
      headlineLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w800,
        fontSize: 32,
        height: 1.25,
        letterSpacing: -0.2,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w800,
        fontSize: 28,
        height: 1.29,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
        fontSize: 24,
        height: 1.33,
      ),

      // ── Title: cards, componentes ─────────────────────────────────
      titleLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
        fontSize: 22,
        height: 1.27,
      ),
      titleMedium: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
        fontSize: 16,
        height: 1.5,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
        fontSize: 14,
        height: 1.43,
        letterSpacing: 0.1,
      ),

      // ── Body: cuerpo de texto legible ─────────────────────────────
      bodyLarge: TextStyle(
        fontFamily: 'DMSans',
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.5,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'DMSans',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.57,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontFamily: 'DMSans',
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.67,
        letterSpacing: 0.4,
      ),

      // ── Label: botones, badges ────────────────────────────────────
      labelLarge: TextStyle(
        fontFamily: 'DMSans',
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.43,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: 'DMSans',
        fontWeight: FontWeight.w600,
        fontSize: 12,
        height: 1.67,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontFamily: 'DMSans',
        fontWeight: FontWeight.w600,
        fontSize: 11,
        height: 1.82,
        letterSpacing: 0.5,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  ThemeData light() => theme(lightScheme());

  ThemeData dark() => theme(darkScheme());

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME CONSTRUCTOR — Aplica tipografía + estilos de componentes
  // ═══════════════════════════════════════════════════════════════════════════

  ThemeData theme(ColorScheme colorScheme) {
    final tt = tintaTextTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      textTheme: tt,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,

      // ── AppBar ──────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: tt.headlineMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),

      // ── ElevatedButton ──────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withOpacity(0.38),
          disabledForegroundColor: colorScheme.onPrimary.withOpacity(0.38),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: tt.labelLarge?.copyWith(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),

      // ── TextButton ──────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: tt.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // ── OutlinedButton ──────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: tt.labelLarge,
        ),
      ),

      // ── InputDecoration (TextFormField) ─────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        labelStyle: tt.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
        hintStyle: tt.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.35),
        ),
        errorStyle: tt.bodySmall?.copyWith(color: colorScheme.error),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),

      // ── Card ────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── Chip ────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelStyle: tt.labelSmall,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      ),

      // ── NavigationBar (Material 3) ──────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        indicatorColor: colorScheme.primaryContainer,
        height: 70,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tt.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            );
          }
          return tt.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return IconThemeData(
            color: colorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
      ),

      // ── Dialog ──────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: tt.headlineSmall,
        contentTextStyle: tt.bodyMedium,
      ),

      // ── SnackBar ────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: tt.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── ProgressIndicator ───────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearMinHeight: 5,
        linearTrackColor: colorScheme.primaryContainer,
      ),

      // ── Divider ─────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withOpacity(0.5),
        thickness: 1,
        space: 1,
      ),

      // ── FloatingActionButton ────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.tertiary,
        foregroundColor: colorScheme.onTertiary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── IconButton ──────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES EXTRA TINTA (no cubiertos por Material 3 ColorScheme)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Colores semánticos adicionales de la paleta Tinta
  static const warmGold = Color(0xFFF5C842);
  static const peach = Color(0xFFFFBF9B);
  static const coral = Color(0xFFFF7E7E);
  static const violet = Color(0xFF6B5BF7);
  static const amber = Color(0xFFE8924A);

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS — Decoraciones Memphis-moderno
  // ═══════════════════════════════════════════════════════════════════════════

  /// Decoración neumórfica suave (sombra doble) para tarjetas
  static BoxDecoration neumorphicDecoration(ColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: colorScheme.brightness == Brightness.light
              ? Colors.white.withOpacity(0.85)
              : Colors.white.withOpacity(0.05),
          offset: const Offset(-6, -6),
          blurRadius: 12,
        ),
        BoxShadow(
          color: colorScheme.shadow.withOpacity(
            colorScheme.brightness == Brightness.light ? 0.10 : 0.30,
          ),
          offset: const Offset(6, 6),
          blurRadius: 14,
        ),
      ],
    );
  }

  /// Gradiente forestal para tarjetas oscuras (racha, etc.)
  static LinearGradient forestGradient(ColorScheme colorScheme) {
    return LinearGradient(
      colors: [
        colorScheme.onPrimaryContainer,
        colorScheme.primary,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Gradiente para avatar
  static const avatarGradient = LinearGradient(
    colors: [violet, Color(0xFF1c6b50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  List<ExtendedColor> get extendedColors => [];
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter — Grilla de puntos decorativa
// ─────────────────────────────────────────────────────────────────────────────

class DotGridPainter extends CustomPainter {
  final Color color;
  final double spacing;

  DotGridPainter({
    required this.color,
    this.spacing = 28.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DotGridPainter old) =>
      old.color != color || old.spacing != spacing;
}

// ─────────────────────────────────────────────────────────────────────────────
// Extended Color support (Material Theme Builder)
// ─────────────────────────────────────────────────────────────────────────────

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