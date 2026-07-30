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
import '../../../features/clubs/data/services/club_notification_service.dart';
import '../../../features/clubs/data/services/captcha_gate_service.dart';
import '../../../features/clubs/presentation/views/club_captcha_view.dart';

/// barra de navegacion de la app
class MainTabShell extends StatefulWidget {
  const MainTabShell({Key? key}) : super(key: key);

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell>
    with WidgetsBindingObserver {
  int _index = 0;
  late final HomeViewModel _homeViewModel;
  late final ClubNotificationService _notifService;

  // Se carga una sola vez por sesión de la app; null = todavía cargando.
  bool? _captchaPassed;
  String? _captchaCheckedForUserId;

  /// Bandera para saber si el polling llegó a iniciarse.
  /// Evita reanudar polling tras `resumed` si nunca arrancó
  bool _pollingActive = false;

  @override
  void initState() {
    super.initState();
    _homeViewModel = sl<HomeViewModel>();
    _notifService = sl<ClubNotificationService>();

    // Observer de ciclo de vida de la app para pausar/reanudar el polling
    // de notificaciones cuando la app pasa a background y vuelve.
    WidgetsBinding.instance.addObserver(this);

    // Iniciar polling de notificaciones cuando el userId esté disponible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<UserViewModel>().profile?.id;
      if (userId != null) {
        _notifService.initialize(userId);
        _notifService.startPolling();
        _pollingActive = true;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifService.stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      // App en background: cortar polling para ahorrar batería/datos.
        if (_pollingActive) {
          _notifService.stopPolling();
        }
        break;
      case AppLifecycleState.resumed:
      // App vuelve al frente: reanudar polling y refrescar el badge.
        if (_pollingActive) {
          _notifService.startPolling();
          _notifService.refresh();
        } else {
          // El userId puede haberse cargado mientras la app estaba en
          // background: reintentar la inicialización.
          final userId = context.read<UserViewModel>().profile?.id;
          if (userId != null) {
            _notifService.initialize(userId);
            _notifService.startPolling();
            _pollingActive = true;
          }
        }
        break;
      case AppLifecycleState.detached:
      // App a punto de cerrarse: dispose() ya se encarga.
        break;
    }
  }

  void _onTap(int index) {
    // Si entra al tab de clubs, marcar como visto y refrescar badge.
    if (index == 3) {
      _notifService.refresh();
    }
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
      bottomNavigationBar: ListenableBuilder(
        listenable: _notifService,
        builder: (_, __) => TintaBottomNav(
          currentIndex: _index,
          onTap: _onTap,
          clubBadgeCount: _notifService.unreadCount,
        ),
      ),
    );
  }
}