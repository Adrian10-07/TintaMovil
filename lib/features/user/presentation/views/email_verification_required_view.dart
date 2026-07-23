import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_viewmodel.dart';

/// Se muestra en vez del contenido de "Club" cuando el usuario todavía
/// no verificó su correo.
///
/// El backend (POST /auth/verification/request y /verify) usa un código
/// de 6 dígitos, no un link mágico por correo. El código se manda por
/// correo real (Gmail SMTP), y también se sigue regresando en la
/// respuesta del request como respaldo (por si el correo tarda) — esta
/// pantalla lo muestra directo en la app además de avisar que se mandó.
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
  String? _echoedCode; // respaldo visible en la app, por si el correo tarda
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
        _feedback = 'Código incorrecto o vencido (dura 15 minutos). Pide uno nuevo si hace falta.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                child: Icon(Icons.mark_email_unread_rounded,
                    size: 40, color: colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                'Verifica tu correo para entrar al Club',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Club es la parte social de Tinta (miembros, publicaciones, '
                    'discusiones), así que primero necesitamos confirmar que '
                    'de verdad eres tú con un código de 6 dígitos.'
                    '${email.isNotEmpty ? '\n\nSe manda a: $email' : ''}',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.65)),
              ),
              const SizedBox(height: 28),

              if (_feedback != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: (_feedbackIsError ? colorScheme.errorContainer : colorScheme.primaryContainer)
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _feedback!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _feedbackIsError ? colorScheme.error : colorScheme.primary,
                    ),
                  ),
                ),
              ],

              if (_echoedCode != null) ...[
                Container(
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
                        style: TextStyle(fontSize: 10.5, color: colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _echoedCode!,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 6,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (!_codeRequested) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: vm.isRequestingCode ? null : _requestCode,
                    icon: vm.isRequestingCode
                        ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.email_rounded, size: 18),
                    label: const Text('Enviar código de verificación'),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: vm.isVerifyingCode ? null : _verifyCode,
                    icon: vm.isVerifyingCode
                        ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text('Verificar código'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: vm.isRequestingCode ? null : _requestCode,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Pedir un código nuevo'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}