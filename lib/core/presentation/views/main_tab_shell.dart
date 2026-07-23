import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../di/service_locator.dart';
import '../../../features/home/presentation/views/home_view.dart';
import '../../../features/home/presentation/viewmodels/home_viewmodel.dart';
import '../../../features/home/presentation/components/tinta_bottom_nav.dart';
import '../../../features/recommendations/presentation/views/recommendations_view.dart';
import '../../../features/recommendations/presentation/views/upload_book_view.dart';
import '../../../features/user/presentation/views/user_view.dart';
import '../../../features/user/presentation/viewmodels/user_viewmodel.dart';
import '../../../features/clubs/presentation/views/clubs_list_view.dart';
import '../../../features/clubs/data/services/captcha_gate_service.dart';
import '../../../features/clubs/presentation/views/club_captcha_view.dart';

/// Shell raíz de la app tras el login.
///
/// Contiene la barra inferior PERMANENTE (Home / Explorar / Estudio /
/// Club / Yo) y cambia entre pestañas con un [IndexedStack] en vez de
/// apilar rutas con Navigator — por eso la barra nunca desaparece al
/// cambiar de pestaña, no hace falta botón "back" entre ellas, y cada
/// pestaña conserva su estado (scroll, formularios, etc.) al volver.
///
/// La barra SÍ desaparece cuando se abre una pantalla de detalle real
/// (lector de EPUB, visor de PDF, detalle de libro) porque esas se abren
/// con Navigator.push por ENCIMA de este shell, cubriéndolo entero.
class MainTabShell extends StatefulWidget {
  const MainTabShell({Key? key}) : super(key: key);

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell> {
  int _index = 0;
  late final HomeViewModel _homeViewModel;

  // Se carga una sola vez por sesión de la app; null = todavía cargando.
  bool? _captchaPassed;
  String? _captchaCheckedForUserId;

  @override
  void initState() {
    super.initState();
    _homeViewModel = sl<HomeViewModel>();
  }

  void _onTap(int index) {
    setState(() => _index = index);
  }

  Future<void> _loadCaptchaStatus(String userId) async {
    _captchaCheckedForUserId = userId;
    final passed = await CaptchaGateService.hasPassed(userId);
    if (mounted && _captchaCheckedForUserId == userId) {
      setState(() => _captchaPassed = passed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<UserViewModel>().profile?.id ?? '';

    if (userId.isNotEmpty && _captchaCheckedForUserId != userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadCaptchaStatus(userId));
    }

    Widget clubTab;
    if (userId.isEmpty || _captchaPassed == null) {
      clubTab = const Center(child: CircularProgressIndicator());
    } else if (_captchaPassed == true) {
      clubTab = const ClubsListView(embedded: true);
    } else {
      clubTab = ClubCaptchaView(
        userId: userId,
        onPassed: () => setState(() => _captchaPassed = true),
      );
    }

    final tabs = <Widget>[
      HomeView(viewModel: _homeViewModel, defaultQuery: '', embedded: true),
      const RecommendationsView(embedded: true),
      UploadBookView(userId: userId, embedded: true),
      clubTab,
      const UserView(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: TintaBottomNav(
        currentIndex: _index,
        onTap: _onTap,
      ),
    );
  }
}