import 'package:flutter/material.dart';
import '../../../../core/settings/app_settings_controller.dart';
import '../../../../core/localization/app_strings.dart';

/// Pantalla "Apariencia" — elegir tema (Claro/Oscuro/Azul/Súper negro)
/// y tamaño de texto. Cambia [AppSettingsController], que ya está
/// escuchado por MaterialApp en main.dart, así que el cambio se ve al
/// instante en toda la app sin reiniciar.
class AppearanceSettingsView extends StatelessWidget {
  final AppSettingsController controller;
  const AppearanceSettingsView({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final t = AppStrings.of(context);

        return Scaffold(
          appBar: AppBar(title: Text(t.appearance)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(t.theme, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...AppThemeOption.values.map((option) => _ThemeTile(
                option: option,
                language: controller.language,
                selected: controller.theme == option,
                onTap: () => controller.setTheme(option),
              )),
              const SizedBox(height: 24),
              Text(t.textSize, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Container(
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
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  t.previewText,
                  style: TextStyle(
                    fontSize: 14 * controller.textSize.scaleFactor,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
                  Text(option.label(language), style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    option.description(language),
                    style: TextStyle(
                      fontSize: 12,
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