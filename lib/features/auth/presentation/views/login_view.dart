import 'package:flutter/material.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginView extends StatefulWidget {
  final AuthViewModel viewModel; // Inyectado vía DI o Provider
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

  @override
  void initState() {
    super.initState();
    // Escuchar cambios para navegación o mostrar errores
    widget.viewModel.addListener(_onViewModelChange);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChange);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
    // Construcción cruda, sin diseño
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión en Tinta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  if (widget.viewModel.state == AuthState.loading) {
                    return const CircularProgressIndicator();
                  }
                  return ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.viewModel.login(
                          _emailController.text,
                          _passwordController.text,
                        );
                      }
                    },
                    child: const Text('Ingresar'),
                  );
                },
              ),
              TextButton(
                onPressed: widget.onNavigateToRegister,
                child: const Text('¿No tienes cuenta? Regístrate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}