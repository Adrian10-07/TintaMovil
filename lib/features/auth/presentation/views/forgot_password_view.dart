import 'package:flutter/material.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../clubs/presentation/views/club_captcha_view.dart';

/// Pantalla "Restablecer contraseña" — flujo simplificado:
///   1. CAPTCHA (confirmar que eres humano).
///   2. Directo a escribir la nueva contraseña.
///
/// El código de 6 dígitos que pide el backend para autorizar el cambio
/// se sigue pidiendo y usando por dentro (requestPasswordReset +
/// confirmPasswordReset), pero ya no se le muestra al usuario ni tiene
/// que escribirlo — se maneja automáticamente en segundo plano, apoyado
/// en que el backend todavía regresa el código en la respuesta (modo
/// MVP). El usuario solo ve: CAPTCHA → nueva contraseña.
class ForgotPasswordView extends StatefulWidget {
  final AuthRepository authRepository;
  final String userId;
  final String? initialEmail;

  const ForgotPasswordView({
    Key? key,
    required this.authRepository,
    required this.userId,
    this.initialEmail,
  }) : super(key: key);

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

enum _Step { captcha, preparing, newPassword, done }

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  _Step _step = _Step.captcha;
  String? _code; // se consigue solo, nunca lo escribe el usuario

  final _newPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _feedback;
  bool _feedbackIsError = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  /// Se llama justo después de pasar el CAPTCHA: pide el código al
  /// backend por dentro, sin mostrárselo al usuario.
  Future<void> _prepareReset() async {
    setState(() {
      _step = _Step.preparing;
      _feedback = null;
    });

    final email = widget.initialEmail;
    if (email == null || email.isEmpty) {
      setState(() {
        _feedbackIsError = true;
        _feedback = 'No se pudo identificar tu correo. Intenta de nuevo desde Perfil.';
        _step = _Step.captcha;
      });
      return;
    }

    try {
      final code = await widget.authRepository.requestPasswordReset(email);
      if (!mounted) return;

      if (code == null) {
        setState(() {
          _feedbackIsError = true;
          _feedback = 'No se pudo preparar el restablecimiento automático. Intenta de nuevo en un momento.';
          _step = _Step.captcha;
        });
        return;
      }

      setState(() {
        _code = code;
        _step = _Step.newPassword;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedbackIsError = true;
        _feedback = 'No se pudo preparar el restablecimiento. Intenta de nuevo.';
        _step = _Step.captcha;
      });
    }
  }

  Future<void> _confirmReset() async {
    final newPassword = _newPasswordController.text;
    final email = widget.initialEmail;
    final code = _code;

    if (newPassword.length < 8) {
      setState(() {
        _feedbackIsError = true;
        _feedback = 'La nueva contraseña debe tener mínimo 8 caracteres.';
      });
      return;
    }
    if (email == null || code == null) {
      setState(() {
        _feedbackIsError = true;
        _feedback = 'Algo salió mal, intenta de nuevo desde el inicio.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _feedback = null;
    });

    try {
      await widget.authRepository.confirmPasswordReset(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedbackIsError = true;
        _feedback = 'No se pudo cambiar la contraseña (código vencido). Intenta de nuevo desde el inicio.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_step == _Step.captcha) {
      return ClubCaptchaView(
        userId: widget.userId,
        onPassed: _prepareReset,
      );
    }

    if (_step == _Step.preparing) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    // _Step.newPassword
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'Nueva contraseña',
                style: textTheme.headlineLarge?.copyWith(
                  color: colorScheme.onSurface,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ya confirmamos que eres tú — escribe tu nueva contraseña.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              if (_feedback != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: (_feedbackIsError ? colorScheme.error : colorScheme.primary).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _feedback!,
                    style: textTheme.bodySmall?.copyWith(
                      color: _feedbackIsError ? colorScheme.error : colorScheme.primary,
                    ),
                  ),
                ),
              ],

              TextField(
                controller: _newPasswordController,
                obscureText: _obscurePassword,
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 15,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  labelStyle: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(Icons.lock_outline_rounded,
                      size: 20, color: colorScheme.onSurface.withOpacity(0.6)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: colorScheme.onSurface.withOpacity(0.6), size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _confirmReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _loading
                      ? SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2.5),
                  )
                      : Text('Cambiar contraseña',
                      style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}