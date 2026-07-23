import 'package:flutter/material.dart';
import '../../data/services/disclaimer_service.dart';

/// Se muestra UNA sola vez, la primera vez que se abre la app en un
/// dispositivo — antes de login/registro. Explica que el contenido
/// (libros) es de dominio público y se maneja en modo local en el
/// dispositivo del usuario, y que el equipo de Tinta no se hace
/// responsable de problemas legales futuros relacionados con la
/// distribución de esos libros. El botón de continuar permanece
/// deshabilitado hasta que el usuario marque la casilla.
class DisclaimerView extends StatefulWidget {
  final VoidCallback onAccepted;

  const DisclaimerView({Key? key, required this.onAccepted}) : super(key: key);

  @override
  State<DisclaimerView> createState() => _DisclaimerViewState();
}

class _DisclaimerViewState extends State<DisclaimerView> {
  bool _checked = false;
  bool _saving = false;

  Future<void> _accept() async {
    setState(() => _saving = true);
    await DisclaimerService.markAccepted();
    if (mounted) widget.onAccepted();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 40, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Antes de empezar',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'Todo el contenido de lectura disponible en Tinta corresponde '
                        'a obras de dominio público, obtenidas de bibliotecas '
                        'digitales públicas y gratuitas. Los archivos se descargan '
                        'y se guardan de forma local en tu propio dispositivo — '
                        'Tinta no aloja ni distribuye copias de estos libros desde '
                        'sus propios servidores.\n\n'
                        'Nos esforzamos por verificar que cada título incluido '
                        'esté libre de derechos de autor en el momento de '
                        'agregarlo al catálogo. Sin embargo, el estatus de '
                        'dominio público puede variar según el país, y las leyes '
                        'de propiedad intelectual pueden cambiar con el tiempo.\n\n'
                        'Al usar Tinta, entiendes y aceptas que el equipo '
                        'desarrollador de la app no se hace responsable por '
                        'cualquier problema legal que pudiera surgir en el futuro '
                        'relacionado con la distribución, descarga o uso de los '
                        'libros disponibles a través de la aplicación.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: colorScheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setState(() => _checked = !_checked),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _checked,
                        onChanged: (v) => setState(() => _checked = v ?? false),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'He leído y acepto estos términos.',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: (_checked && !_saving) ? _accept : null,
                  child: _saving
                      ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Aceptar y continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}