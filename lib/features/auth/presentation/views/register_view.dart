import 'package:flutter/material.dart';
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
  bool _obscurePassword = true;

  // ── Paleta Tinta ──────────────────────────────────────────────
  static const _mintPrimary    = Color(0xFF3DBF7A);
  static const _deepGreen      = Color(0xFF1A4D2E);
  static const _warmGold       = Color(0xFFF5C842);
  static const _peach          = Color(0xFFFFBF9B);
  static const _offWhite       = Color(0xFFF2F5EF);
  static const _darkText       = Color(0xFF1A2B1F);

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
    super.dispose();
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
    return Scaffold(
      backgroundColor: _offWhite,
      body: Stack(
        children: [
          // ── Blobs decorativos ────────────────────────────────
          Positioned(
            top: -100,
            left: -80,
            child: _Blob(color: _warmGold.withOpacity(0.15), size: 300),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _Blob(color: _mintPrimary.withOpacity(0.16), size: 260),
          ),
          Positioned(
            top: 260,
            right: -30,
            child: _Blob(color: _peach.withOpacity(0.14), size: 170),
          ),

          // ── Grilla de puntos ─────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
          ),

          // ── Contenido ────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _darkText.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back_rounded,
                            color: _darkText, size: 20),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Logo / wordmark
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _mintPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.auto_stories_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'tinta',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                            color: _deepGreen,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // Encabezado
                    Text(
                      'Crea tu\ncuenta',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontWeight: FontWeight.w800,
                        fontSize: 36,
                        height: 1.15,
                        color: _darkText,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Empieza tu aventura lectora hoy 📚',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 15,
                        color: _darkText.withOpacity(0.55),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Tarjeta neumórfica ───────────────────────
                    _NeumorphicCard(
                      child: Column(
                        children: [
                          // Nombre completo
                          _TintaField(
                            controller: _nameController,
                            label: 'Nombre completo',
                            icon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),

                          const SizedBox(height: 16),

                          // Email
                          _TintaField(
                            controller: _emailController,
                            label: 'Correo electrónico',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),

                          const SizedBox(height: 16),

                          // Contraseña
                          _TintaField(
                            controller: _passwordController,
                            label: 'Contraseña',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _darkText.withOpacity(0.4),
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
                            size: 14, color: _darkText.withOpacity(0.35)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Al crear tu cuenta aceptas los Términos de uso y la Política de privacidad de Tinta.',
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 12,
                              color: _darkText.withOpacity(0.40),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Botón crear cuenta ───────────────────────
                    ListenableBuilder(
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
                              backgroundColor: _mintPrimary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                              _mintPrimary.withOpacity(0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                                : const Text(
                              'Crear cuenta',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Separador ────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: _darkText.withOpacity(0.12),
                                thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('o',
                              style: TextStyle(
                                  fontFamily: 'DMSans',
                                  color: _darkText.withOpacity(0.35),
                                  fontSize: 13)),
                        ),
                        Expanded(
                            child: Divider(
                                color: _darkText.withOpacity(0.12),
                                thickness: 1)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Continuar con Google (UI) ────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {}, // UI only
                        icon: const Icon(Icons.g_mobiledata_rounded,
                            size: 24, color: Color(0xFF4285F4)),
                        label: Text(
                          'Continuar con Google',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: _darkText,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: _darkText.withOpacity(0.15), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Ir a Login ───────────────────────────────
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '¿Ya tienes cuenta? ',
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 14,
                              color: _darkText.withOpacity(0.55),
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onNavigateToLogin,
                            child: Text(
                              'Inicia sesión',
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _mintPrimary,
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
// Widget: indicador visual de fortaleza de contraseña (UI only)
// ─────────────────────────────────────────────────────────────────────────────

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  static const _mintPrimary = Color(0xFF3DBF7A);
  static const _warmGold    = Color(0xFFF5C842);
  static const _coral       = Color(0xFFFF7E7E);
  static const _darkText    = Color(0xFF1A2B1F);

  const _PasswordStrengthIndicator({required this.password});

  /// Evalúa fortaleza según las reglas reales de la API:
  /// - mínimo 8 caracteres
  /// - al menos una letra
  /// - al menos un dígito
  int get _strength {
    if (password.isEmpty) return 0;

    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));

    // No cumple requisitos mínimos
    if (password.length < 8 || !hasLetter || !hasDigit) return 1;

    // Cumple mínimos pero corta
    if (password.length < 12) return 2;

    // Cumple mínimos y es larga
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final level = _strength;
    final labels = ['', 'Débil', 'Regular', 'Fuerte'];
    final colors = [Colors.transparent, _coral, _warmGold, _mintPrimary];

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
                    : _darkText.withOpacity(0.10),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: 10),
        Text(
          level > 0 ? labels[level] : '',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: level > 0 ? colors[level] : Colors.transparent,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets de apoyo compartidos
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
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 28.0;
    final paint = Paint()
      ..color = const Color(0xFF1A2B1F).withOpacity(0.055)
      ..strokeCap = StrokeCap.round;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}

class _NeumorphicCard extends StatelessWidget {
  final Widget child;
  const _NeumorphicCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5EF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: const Color(0xFF1A2B1F).withOpacity(0.10),
            offset: const Offset(6, 6),
            blurRadius: 14,
          ),
        ],
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
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'DMSans',
        fontSize: 15,
        color: Color(0xFF1A2B1F),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 14,
          color: const Color(0xFF1A2B1F).withOpacity(0.45),
        ),
        prefixIcon: Icon(icon,
            size: 20, color: const Color(0xFF1A2B1F).withOpacity(0.4)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFECF0E9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
          const BorderSide(color: Color(0xFF3DBF7A), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
          const BorderSide(color: Color(0xFFFF7E7E), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
          const BorderSide(color: Color(0xFFFF7E7E), width: 1.5),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}