import 'package:flutter/material.dart';
import 'package:tinta/core/ui/theme3material/theme.dart';
import '../viewmodels/auth_viewmodel.dart';

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
      widget.onRegisterSuccess();
    } else if (state == AuthState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.viewModel.errorMessage ?? 'Error al registrar')),
      );
      widget.viewModel.resetState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -100,
            left: -80,
            child: _Blob(color: MaterialTheme.warmGold.withOpacity(0.12), size: 300),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _Blob(color: colorScheme.primary.withOpacity(0.14), size: 260),
          ),
          Positioned(
            top: 260,
            right: -30,
            child: _Blob(color: MaterialTheme.peach.withOpacity(0.08), size: 170),
          ),

          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _DotGridPainter(dotColor: colorScheme.onSurface)),
            ),
          ),

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

                    // Botón atrás
                    GestureDetector(
                      onTap: widget.onNavigateToLogin,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
                        ),
                        child: Icon(Icons.arrow_back_rounded,
                            color: colorScheme.onSurface, size: 20),
                      ),
                    ),

                    const SizedBox(height: 32),

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

                    const SizedBox(height: 36),

                    // Encabezado
                    Text(
                      'Crea tu\ncuenta',
                      style: textTheme.displaySmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Empieza tu aventura lectora hoy 📚',
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Tarjeta oscura ────────────────────────────
                    _DarkCard(
                      child: Column(
                        children: [
                          // Nombre completo
                          _TintaField(
                            controller: _nameController,
                            label: 'Nombre completo',
                            icon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            onTap: _scrollToButton,
                          ),

                          const SizedBox(height: 16),

                          // Email
                          _TintaField(
                            controller: _emailController,
                            label: 'Correo electrónico',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            onTap: _scrollToButton,
                          ),

                          const SizedBox(height: 16),

                          // Contraseña
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
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requerido';
                              if (v.length < 8) return 'Mínimo 8 caracteres';
                              final hasLetter = v.contains(RegExp(r'[a-zA-Z]'));
                              final hasDigit = v.contains(RegExp(r'[0-9]'));
                              if (!hasLetter || !hasDigit) {
                                return 'Debe tener al menos una letra y un número';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),

                          const SizedBox(height: 16),

                          // Indicador de fortaleza de contraseña (UI)
                          _PasswordStrengthIndicator(
                              password: _passwordController.text),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Términos y condiciones (UI)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 4),
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Al crear tu cuenta aceptas los Términos de uso y la Política de privacidad de Tinta.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Botón crear cuenta ───────────────────────
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
                                widget.viewModel.register(
                                  _nameController.text,
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
                              'Crear cuenta',
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

                    // ── Ir a Login ───────────────────────────────
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '¿Ya tienes cuenta? ',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onNavigateToLogin,
                            child: Text(
                              'Inicia sesión',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Widget: indicador visual de fortaleza de contraseña
// ─────────────────────────────────────────────────────────────────────────────

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const _PasswordStrengthIndicator({required this.password});

  /// Evalúa fortaleza según las reglas reales de la API:
  /// - mínimo 8 caracteres
  /// - al menos una letra
  /// - al menos un dígito
  int get _strength {
    if (password.isEmpty) return 0;

    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));

    if (password.length < 8 || !hasLetter || !hasDigit) return 1;
    if (password.length < 12) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final level = _strength;
    final labels = ['', 'Débil', 'Regular', 'Fuerte'];
    final colors = [
      Colors.transparent,
      colorScheme.error,
      MaterialTheme.warmGold,
      colorScheme.primary,
    ];

    return Row(
      children: [
        ...List.generate(3, (i) {
          final active = i < level;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: active
                    ? colors[level]
                    : colorScheme.onSurface.withOpacity(0.10),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: 10),
        Text(
          level > 0 ? labels[level] : '',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: level > 0 ? colors[level] : Colors.transparent,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets de apoyo (mismos que Login, para que quede idéntico)
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
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;

  const _TintaField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mutedColor = colorScheme.onSurface.withOpacity(0.6);

    return TextFormField(
      controller: controller,
      onTap: onTap,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
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