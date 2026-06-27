import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'core/ui/theme3material/theme.dart';

import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/home/presentation/viewmodels/home_viewmodel.dart';
import 'features/user/presentation/viewmodels/user_viewmodel.dart';

import 'features/auth/presentation/views/login_view.dart';
import 'features/auth/presentation/views/register_view.dart';
import 'features/home/presentation/views/home_view.dart';
import 'features/home/presentation/views/book_detail_view.dart';
import 'features/reader/presentation/views/reader_view.dart';
import 'features/user/presentation/views/user_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  setupServiceLocator();
  runApp(const TintaApp());
}

class TintaApp extends StatelessWidget {
  const TintaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserViewModel>(create: (_) => sl<UserViewModel>()),
        ChangeNotifierProvider<HomeViewModel>(create: (_) => sl<HomeViewModel>()),
      ],
      child: Builder(
        builder: (context) {
          final theme = MaterialTheme(Theme.of(context).textTheme);
          return MaterialApp(
            title: 'Tinta',
            debugShowCheckedModeBanner: false,
            theme: theme.light(),
            darkTheme: theme.dark(),
            themeMode: ThemeMode.system,
            initialRoute: '/login',
            routes: {
              '/login': (_) => ChangeNotifierProvider<AuthViewModel>(
                create: (_) => sl<AuthViewModel>(),
                child: Builder(
                  builder: (ctx) => LoginView(
                    viewModel: ctx.read<AuthViewModel>(),
                    onNavigateToRegister: () => Navigator.pushNamed(ctx, '/register'),
                    onLoginSuccess: () => Navigator.pushReplacementNamed(ctx, '/home'),
                  ),
                ),
              ),
              '/register': (_) => ChangeNotifierProvider<AuthViewModel>(
                create: (_) => sl<AuthViewModel>(),
                child: Builder(
                  builder: (ctx) => RegisterView(
                    viewModel: ctx.read<AuthViewModel>(),
                    onNavigateToLogin: () => Navigator.pop(ctx),
                    onRegisterSuccess: () => Navigator.pushReplacementNamed(ctx, '/home'),
                  ),
                ),
              ),
              '/home': (ctx) => HomeView(
                viewModel: ctx.read<HomeViewModel>(),
                defaultQuery: 'Ingeniería de software',
              ),
              '/book-detail': (_) => const BookDetailView(),
              '/reader': (_) => const ReaderView(),
              '/user': (_) => const UserView(),
            },
          );
        },
      ),
    );
  }
}