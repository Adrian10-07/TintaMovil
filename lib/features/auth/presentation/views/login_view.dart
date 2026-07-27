import 'package:flutter/material.dart';
import 'package:tinta/core/ui/theme3material/theme.dart';
import '../viewmodels/auth_viewmodel.dart';

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

  /// Hace scroll para que el botón de ingresar sea visible sobre el teclado.
  void _scrollToButton() {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final ctx = _buttonKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  void _onViewModelChange() {
    final state = widget.viewModel.state;
    if (state == AuthState.success) {
      widget.onLoginSuccess();
    } else if (state == AuthState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.viewModel.errorMessage ?? 'Error al iniciar sesión')),
      );
      widget.viewModel.resetState();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Todos los colores y tipografías salen del tema activo (Material 3) —
    // así esta pantalla respeta claro/oscuro/azul/super negro, en vez de
    // quedar fija a un solo diseño sin importar lo que elija el usuario
    // en Apariencia.
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Blobs decorativos de fondo ───────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: _Blob(color: colorScheme.primary.withOpacity(0.14), size: 260),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _Blob(color: MaterialTheme.warmGold.withOpacity(0.10), size: 300),
          ),
          Positioned(
            top: 200,
            left: -40,
            child: _Blob(color: MaterialTheme.peach.withOpacity(0.08), size: 180),
          ),

          // ── Grilla de puntos (cubre TODO el fondo) ──────────
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _DotGridPainter(dotColor: colorScheme.onSurface)),
            ),
          ),

          // ── Contenido scrolleable ────────────────────────────
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

                    // Logo / wordmark — usa el ícono real de la app
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(
                            'assets/icon/icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: colorScheme.primary,
                              child: Icon(Icons.auto_stories_rounded,
                                  color: colorScheme.onPrimary, size: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'tinta',
                          style: textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Encabezado
                    Text(
                      'Bienvenido\nde vuelta',
                      style: textTheme.displaySmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Continúa tu racha de lectura 🔥',
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Tarjeta ───────────────────────────────────
                    _DarkCard(
                      child: Column(
                        children: [
                          // Campo email
                          _TintaField(
                            controller: _emailController,
                            label: 'Correo electrónico',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            onTap: _scrollToButton,
                          ),

                          const SizedBox(height: 16),

                          // Campo contraseña
                          _TintaField(
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
                                color: colorScheme.onSurface.withOpacity(0.6),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),

                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Botón de ingreso ─────────────────────────
                    ListenableBuilder(
                      key: _buttonKey,
                      listenable: widget.viewModel,
                      builder: (context, _) {
                        final isLoading =
                            widget.viewModel.state == AuthState.loading;
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                              if (_formKey.currentState!.validate()) {
                                widget.viewModel.login(
                                  _emailController.text,
                                  _passwordController.text,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              disabledBackgroundColor:
                              colorScheme.primary.withOpacity(0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: isLoading
                                ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: colorScheme.onPrimary, strokeWidth: 2.5),
                            )
                                : Text(
                              'Ingresar',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onPrimary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // ── Ir a Registro ────────────────────────────
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '¿No tienes cuenta? ',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onNavigateToRegister,
                            child: Text(
                              'Regístrate',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Widgets de apoyo (internos a este archivo, no expuestos)
// ─────────────────────────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color dotColor;
  _DotGridPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 28.0;
    final paint = Paint()
      ..color = dotColor.withOpacity(0.045)
      ..strokeCap = StrokeCap.round;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.dotColor != dotColor;
}

/// Tarjeta con la superficie elevada del tema (rol M3 `surfaceContainerHigh`)
/// en vez de un negro fijo — así se adapta a cualquier tema activo.
class _DarkCard extends StatelessWidget {
  final Widget child;
  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.06)),
      ),
      child: child,
    );
  }
}

class _TintaField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;

  const _TintaField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mutedColor = colorScheme.onSurface.withOpacity(0.6);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onTap: onTap,
      style: textTheme.bodyLarge?.copyWith(
        fontSize: 15,
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: textTheme.bodyMedium?.copyWith(color: mutedColor),
        prefixIcon: Icon(icon, size: 20, color: mutedColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}