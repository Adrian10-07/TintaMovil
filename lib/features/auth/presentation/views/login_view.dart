import 'package:flutter/material.dart';
import '../components/auth_background.dart';
import '../components/auth_palette.dart';
import '../components/auth_primary_button.dart';
import '../components/auth_wordmark.dart';
import '../components/dark_card.dart';
import '../components/tinta_dark_field.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Pantalla de inicio de sesión.
class LoginView extends StatefulWidget {
  final AuthViewModel viewModel;
  final VoidCallback onNavigateToRegister;
  final VoidCallback onLoginSuccess;

  const LoginView({
    Key? key,
    required this.viewModel,
    required this.onNavigateToRegister,
    required this.onLoginSuccess,
  }) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
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
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Hace scroll para que el botón "Ingresar" quede visible sobre el
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
      widget.onLoginSuccess();
    } else if (state == AuthState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.errorMessage ?? 'Error al iniciar sesión'),
        ),
      );
      widget.viewModel.resetState();
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.viewModel.login(_emailController.text, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Uso textTheme para respetar la tipografía global;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AuthPalette.pureBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AuthBackground.login(),
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    const AuthWordmark(),
                    const SizedBox(height: 48),
                    Text(
                      'Bienvenido\nde vuelta',
                      style: textTheme.displaySmall?.copyWith(
                        color: AuthPalette.lightText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Continúa tu racha de lectura 🔥',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AuthPalette.mutedText,
                      ),
                    ),
                    const SizedBox(height: 40),
                    DarkCard(
                      child: Column(
                        children: [
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
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Escuchamos solo aquí al viewmodel para reconstruir el
                    // botón — así no repintamos todo el árbol al cambiar el
                    // estado de carga.
                    ListenableBuilder(
                      key: _buttonKey,
                      listenable: widget.viewModel,
                      builder: (context, _) => AuthPrimaryButton(
                        isLoading: widget.viewModel.state == AuthState.loading,
                        label: 'Ingresar',
                        onPressed: _submit,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _SwitchAuthRow(
                      leading: '¿No tienes cuenta? ',
                      linkLabel: 'Regístrate',
                      onTap: widget.onNavigateToRegister,
                    ),
                    const SizedBox(height: 32),
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
