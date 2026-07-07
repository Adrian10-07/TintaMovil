import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'core/ui/theme3material/theme.dart';

import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/home/presentation/viewmodels/home_viewmodel.dart';
import 'features/user/presentation/viewmodels/user_viewmodel.dart';
import 'features/knowledge_base/data/datasources/knowledge_base_prefs.dart';
import 'features/knowledge_base/presentation/viewmodels/knowledge_base_survey_viewmodel.dart';

import 'features/auth/presentation/views/login_view.dart';
import 'features/auth/presentation/views/register_view.dart';
import 'features/home/presentation/views/home_view.dart';
import 'features/home/presentation/views/book_detail_view.dart';
import 'features/reader/presentation/views/reader_view.dart';
import 'features/user/presentation/views/user_view.dart';
import 'features/knowledge_base/presentation/views/knowledge_base_survey_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  runApp(const TintaApp());
}

/// Se llama tras login o registro exitoso. Decide si el usuario debe pasar
/// primero por la encuesta de bases de conocimiento o ir directo a Home:
///   - Cuenta recién creada → siempre pasa por la encuesta.
///   - Cuenta existente → solo si nunca la contestó en este dispositivo.
Future<void> _afterAuthSuccess(
    BuildContext ctx, {
      bool isNewAccount = false,
    }) async {
  final userVm = sl<UserViewModel>();
  if (userVm.profile == null) {
    await userVm.loadProfile();
  }
  final userId = userVm.profile?.id;

  if (!ctx.mounted) return;

  if (userId == null) {
    // No se pudo confirmar el usuario; ir a Home de todas formas
    // en vez de dejar a la persona atorada en una pantalla en blanco.
    Navigator.pushReplacementNamed(ctx, '/home');
    return;
  }

  final alreadyCompleted =
  isNewAccount ? false : await KnowledgeBasePrefs.isSurveyCompleted(userId);

  if (!ctx.mounted) return;

  if (alreadyCompleted) {
    Navigator.pushReplacementNamed(ctx, '/home');
  } else {
    Navigator.pushReplacementNamed(ctx, '/kb-survey', arguments: userId);
  }
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
                    onLoginSuccess: () => _afterAuthSuccess(ctx),
                  ),
                ),
              ),
              '/register': (_) => ChangeNotifierProvider<AuthViewModel>(
                create: (_) => sl<AuthViewModel>(),
                child: Builder(
                  builder: (ctx) => RegisterView(
                    viewModel: ctx.read<AuthViewModel>(),
                    onNavigateToLogin: () => Navigator.pop(ctx),
                    onRegisterSuccess: () =>
                        _afterAuthSuccess(ctx, isNewAccount: true),
                  ),
                ),
              ),
              '/kb-survey': (ctx) {
                final userId =
                ModalRoute.of(ctx)!.settings.arguments as String;
                return ChangeNotifierProvider<KnowledgeBaseSurveyViewModel>(
                  create: (_) => sl<KnowledgeBaseSurveyViewModel>(),
                  child: Builder(
                    builder: (innerCtx) => KnowledgeBaseSurveyView(
                      viewModel: innerCtx.read<KnowledgeBaseSurveyViewModel>(),
                      userId: userId,
                      onDone: () =>
                          Navigator.pushReplacementNamed(innerCtx, '/home'),
                    ),
                  ),
                );
              },
              '/home': (ctx) => HomeView(
                viewModel: ctx.read<HomeViewModel>(),
                defaultQuery:'',
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