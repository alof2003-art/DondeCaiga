import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:donde_caigav2/features/explorar/presentation/screens/explorar_screen.dart';
import 'package:donde_caigav2/features/anfitrion/presentation/screens/anfitrion_screen.dart';
import 'package:donde_caigav2/features/buzon/presentation/screens/chat_lista_screen.dart';
import 'package:donde_caigav2/features/notificaciones/presentation/screens/notificaciones_screen.dart';
import 'package:donde_caigav2/features/perfil/presentation/screens/perfil_screen.dart';
import 'package:donde_caigav2/features/notificaciones/presentation/providers/notificaciones_provider.dart';
import 'package:donde_caigav2/features/notificaciones/services/notifications_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _notificationsInitialized = false;

  final List<Widget> _screens = const [
    ExplorarScreen(),
    AnfitrionScreen(),
    ChatListaScreen(),
    NotificacionesScreen(),
    PerfilScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) return;

    try {
      debugPrint('🔔 MainScreen: Inicializando servicio de notificaciones...');

      // Inicializar servicio de notificaciones
      final notificationsService = NotificationsService();
      await notificationsService.initialize();

      // Obtener información de debug
      final debugInfo = await notificationsService.getTokenDebugInfo();
      debugPrint('🔍 MainScreen DEBUG INFO: $debugInfo');

      _notificationsInitialized = true;
      debugPrint('✅ MainScreen: Servicio de notificaciones inicializado');
    } catch (e) {
      debugPrint('❌ MainScreen: Error al inicializar notificaciones: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Consumer<NotificacionesProvider>(
        builder: (context, notificacionesProvider, child) {
          final notificacionesNoLeidas =
              notificacionesProvider.cantidadNoLeidas;

          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF4DB6AC),
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Explorar',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_work),
                label: 'Anfitrión',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (notificacionesNoLeidas > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            notificacionesNoLeidas > 99
                                ? '99+'
                                : '$notificacionesNoLeidas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Notificaciones',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Perfil',
              ),
            ],
          );
        },
      ),
    );
  }
}
