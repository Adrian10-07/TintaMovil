import 'package:flutter/material.dart';
import '../components/auth_background.dart';
import '../components/auth_palette.dart';
import '../components/auth_primary_button.dart';
import '../components/auth_wordmark.dart';
import '../components/dark_card.dart';
import '../components/password_strength_indicator.dart';
import '../components/tinta_dark_field.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Pantalla de registro.

class RegisterView extends StatefulWidget {
  final AuthViewModel viewModel;
  final VoidCallback onNavigateToLogin;
  final VoidCallback onRegisterSuccess;

  const RegisterView({
    Key? key,
    required this.viewModel,
    required this.onNavigateToLogin,
    required this.onRegisterSuccess,
  }) : super(key: key);

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  final _buttonKey = GlobalKey();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChange);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChange);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToButton() {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final ctx = _buttonKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  void _onViewModelChange() {
    final state = widget.viewModel.state;
    if (state == AuthState.success) {
      widget.onRegisterSuccess();
    } else if (state == AuthState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.errorMessage ?? 'Error al registrar'),
        ),
      );
      widget.viewModel.resetState();
    }
  }

  // Validación centralizada
  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Requerido';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    final hasLetter = v.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = v.contains(RegExp(r'[0-9]'));
    if (!hasLetter || !hasDigit) {
      return 'Debe tener al menos una letra y un número';
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.viewModel.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AuthPalette.pureBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AuthBackground.register(),
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _BackButton(onTap: widget.onNavigateToLogin),
                    const SizedBox(height: 32),
                    const AuthWordmark(),
                    const SizedBox(height: 36),
                    Text(
                      'Crea tu\ncuenta',
                      style: textTheme.displaySmall?.copyWith(
                        color: AuthPalette.lightText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Empieza tu aventura lectora hoy 📚',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AuthPalette.mutedText,
                      ),
                    ),
                    const SizedBox(height: 32),
                    DarkCard(
                      child: Column(
                        children: [
                          TintaDarkField(
                            controller: _nameController,
                            label: 'Nombre completo',
                            icon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            onTap: _scrollToButton,
                          ),
                          const SizedBox(height: 16),
                          TintaDarkField(
                            controller: _emailController,
                            label: 'Correo electrónico',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            onTap: _scrollToButton,
                          ),
                          const SizedBox(height: 16),
                          TintaDarkField(
                            controller: _passwordController,
                            label: 'Contraseña',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            onTap: _scrollToButton,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AuthPalette.mutedText,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: _validatePassword,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          //indicador compartido y le pasamos
                          // trackColor claro para que se vea sobre el
                          // fondo negro de la tarjeta.
                          PasswordStrengthIndicator(
                            password: _passwordController.text,
                            trackColor: AuthPalette.lightText.withOpacity(0.10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TermsNotice(),
                    const SizedBox(height: 28),
                    ListenableBuilder(
                      key: _buttonKey,
                      listenable: widget.viewModel,
                      builder: (context, _) => AuthPrimaryButton(
                        isLoading: widget.viewModel.state == AuthState.loading,
                        label: 'Crear cuenta',
                        onPressed: _submit,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _SwitchAuthRow(
                      leading: '¿Ya tienes cuenta? ',
                      linkLabel: 'Inicia sesión',
                      onTap: widget.onNavigateToLogin,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widgets internos (solo para este view)


class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AuthPalette.cardBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AuthPalette.lightText,
          size: 20,
        ),
      ),
    );
  }
}

class _TermsNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 4),
        Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: AuthPalette.mutedText.withOpacity(0.7),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Al crear tu cuenta aceptas los Términos de uso y la Política de privacidad de Tinta.',
            style: textTheme.bodySmall?.copyWith(
              color: AuthPalette.mutedText.withOpacity(0.75),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _SwitchAuthRow extends StatelessWidget {
  final String leading;
  final String linkLabel;
  final VoidCallback onTap;

  const _SwitchAuthRow({
    required this.leading,
    required this.linkLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            leading,
            style: textTheme.bodyMedium?.copyWith(color: AuthPalette.mutedText),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              linkLabel,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AuthPalette.mintPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
