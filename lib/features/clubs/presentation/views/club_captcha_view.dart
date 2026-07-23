import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/services/captcha_gate_service.dart';

/// CAPTCHA simple, autocontenido (no depende de ningún servicio externo
/// ni de backend): dibuja un código distorsionado con líneas de ruido
/// encima usando CustomPaint, y el usuario lo debe escribir igual.
///
/// Se muestra solo la PRIMERA vez que el usuario entra a Club — una vez
/// que lo pasa, se guarda localmente (CaptchaGateService) y no se le
/// vuelve a pedir.
class ClubCaptchaView extends StatefulWidget {
  final String userId;
  final VoidCallback onPassed;

  const ClubCaptchaView({
    Key? key,
    required this.userId,
    required this.onPassed,
  }) : super(key: key);

  @override
  State<ClubCaptchaView> createState() => _ClubCaptchaViewState();
}

class _ClubCaptchaViewState extends State<ClubCaptchaView> {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sin O/0/I/1 (se confunden)
  final _random = Random();
  final _inputController = TextEditingController();

  late String _code;
  String? _error;

  @override
  void initState() {
    super.initState();
    _code = _generateCode();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  String _generateCode() {
    return List.generate(5, (_) => _chars[_random.nextInt(_chars.length)]).join();
  }

  void _refreshCode() {
    setState(() {
      _code = _generateCode();
      _inputController.clear();
      _error = null;
    });
  }

  Future<void> _verify() async {
    final input = _inputController.text.trim().toUpperCase();

    if (input != _code) {
      setState(() => _error = 'No coincide, intenta de nuevo.');
      _refreshCode();
      return;
    }

    await CaptchaGateService.markPassed(widget.userId);
    if (mounted) widget.onPassed();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.verified_user_rounded,
                    size: 40, color: colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                'Antes de entrar al Club',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Confirma que eres una persona real escribiendo el código de abajo. Solo se pide una vez.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.65)),
              ),
              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 100),
                      painter: _CaptchaNoisePainter(seed: _code.hashCode),
                    ),
                    Text(
                      _code,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 10,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _refreshCode,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Otro código'),
                ),
              ),

              const SizedBox(height: 8),
              TextField(
                controller: _inputController,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                maxLength: 5,
                style: const TextStyle(fontSize: 20, letterSpacing: 6, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Escribe el código',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _verify,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Verificar y entrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dibuja líneas de "ruido" detrás/encima del texto del código, para que
/// no sea una imagen trivial de leer por un script (el mínimo esperado
/// de un CAPTCHA visual simple).
class _CaptchaNoisePainter extends CustomPainter {
  final int seed;
  _CaptchaNoisePainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 6; i++) {
      paint.color = Colors.primaries[random.nextInt(Colors.primaries.length)]
          .withOpacity(0.25);
      final path = Path()
        ..moveTo(random.nextDouble() * size.width, random.nextDouble() * size.height)
        ..quadraticBezierTo(
          random.nextDouble() * size.width, random.nextDouble() * size.height,
          random.nextDouble() * size.width, random.nextDouble() * size.height,
        );
      canvas.drawPath(path, paint);
    }

    final dotPaint = Paint()..color = Colors.grey.withOpacity(0.3);
    for (var i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        1.2,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CaptchaNoisePainter oldDelegate) => oldDelegate.seed != seed;
}