import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Core
import 'core/di/service_locator.dart';

// Features
import 'features/auth/presentation/views/login_view.dart';
import 'features/auth/presentation/views/register_view.dart';
import 'features/home/presentation/views/home_view.dart';

Future<void> main() async {
  // Asegura que los bindings de Flutter estén inicializados antes de inyectar dependencias
  WidgetsFlutterBinding.ensureInitialized();

  // Cargamos las variables de entorno desde el archivo .env
  await dotenv.load(fileName: ".env");

  // Inicializamos nuestro inyector de dependencias (GetIt)
  setupServiceLocator();

  runApp(const TintaApp());
}

class TintaApp extends StatelessWidget {
  const TintaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tinta',
      // Aquí puedes agregar tu configuración de theme de core/ui/theme
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Navegación nativa simple para pruebas (reemplazable por go_router luego)
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginView(
          // Pedimos el ViewModel al Service Locator
          viewModel: sl(),
          onNavigateToRegister: () {
            Navigator.pushNamed(context, '/register');
          },
          onLoginSuccess: () {
            // Al loguearse, reemplazamos la ruta para no poder volver al login
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
        '/register': (context) => RegisterView(
          viewModel: sl(),
          onNavigateToLogin: () {
            Navigator.pop(context);
          },
          onRegisterSuccess: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
        '/home': (context) => HomeView(
          viewModel: sl(),
          // Query por defecto para ver resultados de la API inmediatamente
          defaultQuery: 'Ingeniería de software',
        ),
      },
    );
  }
}