import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:donde_caigav2/main.dart';
import 'package:donde_caigav2/services/auth_service.dart';
import 'package:donde_caigav2/services/storage_service.dart';
import 'package:donde_caigav2/features/auth/data/repositories/user_repository.dart';
import 'package:donde_caigav2/features/auth/presentation/screens/login_screen.dart';
import 'package:donde_caigav2/features/anfitrion/presentation/screens/admin_solicitudes_screen.dart';
import 'package:donde_caigav2/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:donde_caigav2/core/widgets/theme_toggle_button.dart';
import 'package:donde_caigav2/core/services/theme_service.dart';
import 'package:donde_caigav2/features/resenas/data/repositories/resenas_repository.dart';
import 'package:donde_caigav2/features/resenas/presentation/widgets/seccion_resenas_perfil.dart';
import 'package:donde_caigav2/features/perfil/presentation/widgets/calificaciones_perfil_widget.dart';
import 'package:donde_caigav2/features/notificaciones/services/notifications_service.dart';
import 'configurar_perfil_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late final AuthService _authService;
  late final UserRepository _userRepository;
  late final ResenasRepository _resenasRepository;
  String? _userEmail;
  String? _userName;
  String? _fotoPerfilUrl;
  int? _userRolId;
  String? _userId;
  bool _isLoading = true;
  Map<String, dynamic> _estadisticasResenas = {};

  @override
  void initState() {
    super.initState();
    _authService = AuthService(
      supabase,
      StorageService(supabase),
      UserRepository(supabase),
    );
    _userRepository = UserRepository(supabase);
    _resenasRepository = ResenasRepository(supabase);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        // Obtener el perfil completo desde la base de datos
        final perfil = await _userRepository.getUserProfile(user.id);

        if (perfil != null && mounted) {
          // Cargar estadísticas de reseñas
          final estadisticas = await _resenasRepository
              .getEstadisticasCompletasResenas(user.id);

          // Debug: Imprimir estadísticas recibidas
          print('=== DEBUG ESTADÍSTICAS PERFIL ===');
          print('Estadísticas completas: $estadisticas');

          setState(() {
            _userId = user.id;
            _userEmail = perfil.email;
            _userName = perfil.nombre;
            _fotoPerfilUrl = perfil.fotoPerfilUrl;
            _userRolId = perfil.rolId;
            _estadisticasResenas = estadisticas;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      // Desactivar modo oscuro al cerrar sesión
      final themeService = Provider.of<ThemeService>(context, listen: false);
      await themeService.setTheme(ThemeMode.light);

      await _authService.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _debugNotifications() async {
    try {
      debugPrint('🔧 === DEBUG MANUAL DE NOTIFICACIONES MEJORADO ===');

      final notificationsService = NotificationsService();

      // PASO 1: Obtener información básica de debug
      final debugInfo = await notificationsService.getTokenDebugInfo();
      debugPrint('🔍 DEBUG INFO: $debugInfo');

      // PASO 2: Obtener estadísticas de tokens
      final stats = await notificationsService.getTokenStatistics();
      debugPrint('📈 ESTADÍSTICAS: $stats');

      // PASO 3: Obtener logs recientes del usuario
      final logs = await notificationsService.getDebugLogs(limit: 10);
      debugPrint('📋 LOGS RECIENTES (${logs.length}):');
      for (final log in logs) {
        debugPrint(
          '  ${log['timestamp_log']}: ${log['action_type']} - ${log['success'] ? '✅' : '❌'} ${log['error_message'] ?? ''}',
        );
      }

      // PASO 4: Obtener monitoreo en tiempo real
      final monitoring = await notificationsService.getRealtimeMonitoring();
      debugPrint('⏱️ MONITOREO TIEMPO REAL (${monitoring.length} usuarios):');
      for (final user in monitoring) {
        if (user['email'] == supabase.auth.currentUser?.email) {
          debugPrint(
            '  👤 TU ESTADO: ${user['token_status']} - ${user['token_length']} chars - ${user['logs_recientes']} logs recientes',
          );
        }
      }

      // PASO 5: Forzar actualización
      debugPrint('🔄 Forzando actualización de token...');
      await notificationsService.forceUpdateToken();

      // PASO 6: Verificar logs después de la actualización
      await Future.delayed(const Duration(seconds: 2));
      final logsAfter = await notificationsService.getDebugLogs(limit: 3);
      debugPrint('📋 LOGS DESPUÉS DE ACTUALIZACIÓN:');
      for (final log in logsAfter) {
        debugPrint(
          '  ${log['timestamp_log']}: ${log['action_type']} - ${log['success'] ? '✅' : '❌'}',
        );
      }

      if (mounted) {
        // Mostrar información resumida en el SnackBar
        final tokenStatus = debugInfo['token_available']
            ? 'Token OK'
            : 'Sin Token';
        final logsCount = logs.length;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔧 Debug completado: $tokenStatus, $logsCount logs - Revisa consola',
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error en debug mejorado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en debug: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navegarAConfigurarPerfil() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfigurarPerfilScreen(
          userId: userId,
          nombreActual: _userName ?? '',
          fotoActual: _fotoPerfilUrl,
        ),
      ),
    );

    // Si hubo cambios, recargar el perfil
    if (resultado == true) {
      _loadUserInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navegarAConfigurarPerfil,
            tooltip: 'Configurar perfil',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Avatar
                _isLoading
                    ? const CircularProgressIndicator()
                    : CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).primaryColor,
                        backgroundImage: _fotoPerfilUrl != null
                            ? NetworkImage(_fotoPerfilUrl!)
                            : null,
                        child: _fotoPerfilUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              )
                            : null,
                      ),
                const SizedBox(height: 24),
                // Nombre
                Text(
                  _userName ?? 'Cargando...',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Email
                Text(
                  _userEmail ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),

                // Calificaciones del usuario
                if (!_isLoading)
                  CalificacionesPerfilWidget(
                    promedioAnfitrion:
                        _estadisticasResenas['promedioRecibidas'] as double?,
                    totalResenasAnfitrion:
                        _estadisticasResenas['totalResenasRecibidas'] as int?,
                    promedioViajero:
                        _estadisticasResenas['promedioComoViajero'] as double?,
                    totalResenasViajero:
                        _estadisticasResenas['totalResenasComoViajero'] as int?,
                  ),

                const SizedBox(height: 40),

                // Botón de Admin (solo para rol_id = 3)
                if (_userRolId == 3) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ADMINISTRADOR',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminDashboardScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.dashboard),
                      label: const Text('Panel de Administración'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminSolicitudesScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.pending_actions),
                      label: const Text('Solicitudes Pendientes'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Botón de debug de notificaciones (solo en desarrollo)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _debugNotifications,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('🔧 Debug FCM Token'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Botón de cerrar sesión
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Sección de reseñas
                if (_userId != null)
                  SeccionResenasPerfil(
                    userId: _userId!,
                    resenasRepository: _resenasRepository,
                    esPerfilPropio: true,
                  ),

                const SizedBox(height: 100), // Espacio para el botón flotante
              ],
            ),
          ),
          // Botón flotante de modo oscuro
          const FloatingThemeToggle(),
        ],
      ),
    );
  }
}
