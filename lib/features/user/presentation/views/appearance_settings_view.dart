import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/settings/app_settings_controller.dart';

/// Pantalla de apariencia: elegir tema (light/dark/blue/superBlack) y

class AppearanceSettingsView extends StatelessWidget {
  final AppSettingsController controller;

  const AppearanceSettingsView({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = AppStrings.of(context);

        return Scaffold(
          appBar: AppBar(title: Text(t.appearance)),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              Text(t.theme, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...AppThemeOption.values.map(
                    (option) => _ThemeTile(
                  option: option,
                  language: controller.language,
                  selected: controller.theme == option,
                  onTap: () => controller.setTheme(option),
                ),
              ),
              const SizedBox(height: 24),
              Text(t.textSize, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              _TextSizeSelector(controller: controller),
              const SizedBox(height: 12),
              _TextSizePreview(controller: controller, previewText: t.previewText),
            ],
          ),
        );
      },
    );
  }
}

/// Selector radio de tamaño del texto.
///
/// El `fontSize: 14 * scaleFactor` es intencional — así el usuario ve el
/// tamaño relativo de cada opción antes de aplicarlo.
class _TextSizeSelector extends StatelessWidget {
  final AppSettingsController controller;

  const _TextSizeSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: AppTextSize.values.map((size) {
          return RadioListTile<AppTextSize>(
            contentPadding: EdgeInsets.zero,
            title: Text(
              size.label(controller.language),
              // Tamaño relativo a propósito — es lo que muestra la
              // funcionalidad del control.
              style: TextStyle(fontSize: 14 * size.scaleFactor),
            ),
            value: size,
            groupValue: controller.textSize,
            onChanged: (v) {
              if (v != null) controller.setTextSize(v);
            },
          );
        }).toList(),
      ),
    );
  }
}

/// Texto de preview que refleja el tamaño elegido.
class _TextSizePreview extends StatelessWidget {
  final AppSettingsController controller;
  final String previewText;

  const _TextSizePreview({
    required this.controller,
    required this.previewText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        previewText,
        // Tamaño relativo — necesito el scaleFactor para que el preview
        // refleje la selección del usuario.
        style: TextStyle(
          fontSize: 14 * controller.textSize.scaleFactor,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }
}

/// Tile de cada opción de tema (con borde resaltado al estar activa).
class _ThemeTile extends StatelessWidget {
  final AppThemeOption option;
  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.option,
    required this.language,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Icon(option.icon, color: colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // titleSmall del tema — antes fontWeight w700 inline.
                  Text(
                    option.label(language),
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  // labelMedium del tema — antes fontSize: 12 hardcodeado.
                  Text(
                    option.description(language),
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}