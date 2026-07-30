import 'package:flutter/material.dart';
import '../../../clubs/presentation/views/club_captcha_view.dart';
import '../../domain/repositories/auth_repository.dart';
import '../components/auth_palette.dart';
import '../components/auth_primary_button.dart';
import '../components/tinta_dark_field.dart';

/// Pantalla "Restablecer contraseña" — flujo simplificado:

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
  String? _code; // Se consigue solo, nunca lo escribe el usuario.

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
      _setError(
        'No se pudo identificar tu correo. Intenta de nuevo desde Perfil.',
        backToCaptcha: true,
      );
      return;
    }

    try {
      final code = await widget.authRepository.requestPasswordReset(email);
      if (!mounted) return;

      if (code == null) {
        _setError(
          'No se pudo preparar el restablecimiento automático. Intenta de nuevo en un momento.',
          backToCaptcha: true,
        );
        return;
      }

      setState(() {
        _code = code;
        _step = _Step.newPassword;
      });
    } catch (_) {
      if (!mounted) return;
      _setError(
        'No se pudo preparar el restablecimiento. Intenta de nuevo.',
        backToCaptcha: true,
      );
    }
  }

  Future<void> _confirmReset() async {
    final newPassword = _newPasswordController.text;
    final email = widget.initialEmail;
    final code = _code;

    if (newPassword.length < 8) {
      _setError('La nueva contraseña debe tener mínimo 8 caracteres.');
      return;
    }
    if (email == null || code == null) {
      _setError('Algo salió mal, intenta de nuevo desde el inicio.');
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
    } catch (_) {
      if (!mounted) return;
      _setError(
        'No se pudo cambiar la contraseña (código vencido). Intenta de nuevo desde el inicio.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Helper para setear feedback de error — centralizo el setState
  void _setError(String msg, {bool backToCaptcha = false}) {
    setState(() {
      _feedbackIsError = true;
      _feedback = msg;
      if (backToCaptcha) _step = _Step.captcha;
    });
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
      return const Scaffold(
        backgroundColor: AuthPalette.pureBlack,
        body: Center(
          child: CircularProgressIndicator(color: AuthPalette.mintPrimary),
        ),
      );
    }

    return _NewPasswordScreen(
      controller: _newPasswordController,
      obscure: _obscurePassword,
      onToggleObscure: () =>
          setState(() => _obscurePassword = !_obscurePassword),
      loading: _loading,
      feedback: _feedback,
      feedbackIsError: _feedbackIsError,
      onSubmit: _confirmReset,
    );
  }
}

/// Pantalla real de escritura de nueva contraseña.

class _NewPasswordScreen extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool loading;
  final String? feedback;
  final bool feedbackIsError;
  final VoidCallback onSubmit;

  const _NewPasswordScreen({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.loading,
    required this.feedback,
    required this.feedbackIsError,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AuthPalette.pureBlack,
      appBar: AppBar(
        backgroundColor: AuthPalette.pureBlack,
        foregroundColor: AuthPalette.lightText,
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
                  color: AuthPalette.lightText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ya confirmamos que eres tú — escribe tu nueva contraseña.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AuthPalette.mutedText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              if (feedback != null)
                _FeedbackBanner(text: feedback!, isError: feedbackIsError),
              TintaDarkField(
                controller: controller,
                label: 'Nueva contraseña',
                icon: Icons.lock_outline_rounded,
                obscureText: obscure,
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AuthPalette.mutedText,
                    size: 20,
                  ),
                  onPressed: onToggleObscure,
                ),
              ),
              const SizedBox(height: 20),
              AuthPrimaryButton(
                isLoading: loading,
                label: 'Cambiar contraseña',
                onPressed: onSubmit,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner de feedback (verde éxito / coral error).
class _FeedbackBanner extends StatelessWidget {
  final String text;
  final bool isError;
  const _FeedbackBanner({required this.text, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AuthPalette.coral : AuthPalette.mintPrimary;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}
