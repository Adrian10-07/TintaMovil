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
  static const _pureBlack = Color(0xFF000000);
  static const _mintPrimary = Color(0xFF3DBF7A);
  static const _lightText = Color(0xFFE8EAE6);
  static const _mutedText = Color(0xFF9AA0A6);

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
    if (_step == _Step.captcha) {
      return ClubCaptchaView(
        userId: widget.userId,
        onPassed: _prepareReset,
      );
    }

    if (_step == _Step.preparing) {
      return Scaffold(
        backgroundColor: _pureBlack,
        body: const Center(
          child: CircularProgressIndicator(color: _mintPrimary),
        ),
      );
    }

    // _Step.newPassword
    return Scaffold(
      backgroundColor: _pureBlack,
      appBar: AppBar(
        backgroundColor: _pureBlack,
        foregroundColor: _lightText,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Nueva contraseña',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  color: _lightText,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ya confirmamos que eres tú — escribe tu nueva contraseña.',
                style: TextStyle(fontFamily: 'DMSans', fontSize: 14, color: _mutedText, height: 1.4),
              ),
              const SizedBox(height: 28),

              if (_feedback != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: (_feedbackIsError ? const Color(0xFFFF7E7E) : _mintPrimary).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _feedback!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _feedbackIsError ? const Color(0xFFFF7E7E) : _mintPrimary,
                    ),
                  ),
                ),
              ],

              TextField(
                controller: _newPasswordController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontFamily: 'DMSans', fontSize: 15, color: _lightText),
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  labelStyle: const TextStyle(fontFamily: 'DMSans', fontSize: 14, color: _mutedText),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: _mutedText),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: _mutedText, size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1C1C1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _mintPrimary, width: 1.5),
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
                    backgroundColor: _mintPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _loading
                      ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                      : const Text('Cambiar contraseña',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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