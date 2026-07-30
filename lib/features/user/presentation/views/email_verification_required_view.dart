import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_viewmodel.dart';


class EmailVerificationRequiredView extends StatefulWidget {
  final VoidCallback onVerified;

  const EmailVerificationRequiredView({Key? key, required this.onVerified})
      : super(key: key);

  @override
  State<EmailVerificationRequiredView> createState() =>
      _EmailVerificationRequiredViewState();
}

class _EmailVerificationRequiredViewState
    extends State<EmailVerificationRequiredView> {
  final _codeController = TextEditingController();

  bool _codeRequested = false;
  String? _echoedCode; // Respaldo visible en la app, por si el correo tarda.
  String? _feedback;
  bool _feedbackIsError = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final vm = context.read<UserViewModel>();
    final code = await vm.requestVerificationCode();

    if (!mounted) return;
    setState(() {
      _codeRequested = true;
      _echoedCode = code;
      _feedbackIsError = false;
      _feedback = code != null
          ? null
          : 'Te mandamos un código de 6 dígitos a tu correo — revisa tu bandeja (y spam).';
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() {
        _feedbackIsError = true;
        _feedback = 'El código son 6 dígitos.';
      });
      return;
    }

    final vm = context.read<UserViewModel>();
    final ok = await vm.verifyEmailCode(code);

    if (!mounted) return;

    if (ok) {
      widget.onVerified();
    } else {
      setState(() {
        _feedbackIsError = true;
        _feedback =
        'Código incorrecto o vencido (dura 15 minutos). Pide uno nuevo si hace falta.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final vm = context.watch<UserViewModel>();
    final email = vm.profile?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_unread_rounded,
                  size: 40,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Verifica tu correo para entrar al Club',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Club es la parte social de Tinta (miembros, publicaciones, '
                    'discusiones), así que primero necesitamos confirmar que '
                    'de verdad eres tú con un código de 6 dígitos.'
                    '${email.isNotEmpty ? '\n\nSe manda a: $email' : ''}',
                textAlign: TextAlign.center,
                // bodyMedium del tema — antes iba TextStyle vacío con solo color.
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 28),
              if (_feedback != null)
                _FeedbackBanner(
                  text: _feedback!,
                  isError: _feedbackIsError,
                ),
              if (_echoedCode != null) _EchoedCodeCard(code: _echoedCode!),
              if (!_codeRequested)
                _SendCodeButton(
                  loading: vm.isRequestingCode,
                  onPressed: _requestCode,
                )
              else ..._CodeEntrySection.buildChildren(
                controller: _codeController,
                verifying: vm.isVerifyingCode,
                onVerify: _verifyCode,
                onResend: _requestCode,
                resending: vm.isRequestingCode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner de feedback (verde éxito / rojo error).
///
/// Lo extraje del inline para respetar SRP y quitar el fontSize hardcodeado.
class _FeedbackBanner extends StatelessWidget {
  final String text;
  final bool isError;

  const _FeedbackBanner({required this.text, required this.isError});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final base = isError ? colorScheme.errorContainer : colorScheme.primaryContainer;
    final fg = isError ? colorScheme.error : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: base.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        // bodySmall del tema — antes fontSize: 12.5 hardcodeado.
        style: textTheme.bodySmall?.copyWith(color: fg),
      ),
    );
  }
}

/// Tarjeta que muestra el código de respaldo (por si el correo tarda).
class _EchoedCodeCard extends StatelessWidget {
  final String code;
  const _EchoedCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.tertiary.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            'Por si el correo tarda, aquí tienes tu código',
            // labelSmall del tema — antes fontSize: 10.5 hardcodeado.
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            code,

            style: textTheme.headlineMedium?.copyWith(
              letterSpacing: 6,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón para pedir el código por primera vez.
class _SendCodeButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const _SendCodeButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.email_rounded, size: 18),
        label: const Text('Enviar código de verificación'),
      ),
    );
  }
}

/// Bloque de entrada del código + botones "verificar" y "reenviar".

class _CodeEntrySection {
  static List<Widget> buildChildren({
    required TextEditingController controller,
    required bool verifying,
    required VoidCallback onVerify,
    required VoidCallback onResend,
    required bool resending,
  }) {
    return [
      _CodeInput(controller: controller),
      const SizedBox(height: 14),
      _VerifyButton(loading: verifying, onPressed: onVerify),
      const SizedBox(height: 10),
      _ResendButton(loading: resending, onPressed: onResend),
    ];
  }
}

class _CodeInput extends StatelessWidget {
  final TextEditingController controller;
  const _CodeInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      // titleLarge (22/w700) con letterSpacing para el input del código —
      // antes hardcodeaba fontSize: 22 fuera del tema.
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        letterSpacing: 8,
      ),
      decoration: const InputDecoration(
        counterText: '',
        hintText: '••••••',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const _VerifyButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.check_circle_outline_rounded, size: 18),
        label: const Text('Verificar código'),
      ),
    );
  }
}

class _ResendButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const _ResendButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: loading ? null : onPressed,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Pedir un código nuevo'),
      ),
    );
  }
}