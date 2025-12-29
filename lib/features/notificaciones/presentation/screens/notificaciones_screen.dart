import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notificaciones_provider.dart';
import '../widgets/notificacion_card.dart';
import '../widgets/filtro_notificaciones.dart';
import '../widgets/test_notifications_widget.dart';
import '../../data/models/notificacion.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Cargar notificaciones al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificacionesProvider>().cargarNotificaciones();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todas', icon: Icon(Icons.notifications)),
            Tab(text: 'Por Tipo', icon: Icon(Icons.category)),
            Tab(text: 'Test FCM', icon: Icon(Icons.bug_report)),
          ],
        ),
        actions: [
          // Filtro
          IconButton(
            onPressed: _mostrarFiltro,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar',
          ),

          // Marcar todas como leídas
          Consumer<NotificacionesProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: provider.hayNotificacionesNoLeidas
                    ? () => _marcarTodasComoLeidas(provider)
                    : null,
                icon: const Icon(Icons.mark_email_read),
                tooltip: 'Marcar todas como leídas',
              );
            },
          ),

          // Menú de opciones
          PopupMenuButton<String>(
            onSelected: _manejarOpcionMenu,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refrescar',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refrescar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'configuracion',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Configuración'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVistaTodasLasNotificaciones(),
          _buildVistaPorTipo(),
          _buildVistaTestFCM(),
        ],
      ),
    );
  }

  Widget _buildVistaTodasLasNotificaciones() {
    return Consumer<NotificacionesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar notificaciones',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.cargarNotificaciones(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (provider.notificaciones.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No tienes notificaciones',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Cuando recibas notificaciones aparecerán aquí',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.refrescar,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.notificaciones.length,
            itemBuilder: (context, index) {
              final notificacion = provider.notificaciones[index];
              return NotificacionCard(
                notificacion: notificacion,
                onTap: () {
                  // Opcional: realizar alguna acción adicional
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVistaPorTipo() {
    return Consumer<NotificacionesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.notificacionesAgrupadas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay notificaciones agrupadas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.refrescar,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.notificacionesAgrupadas.length,
            itemBuilder: (context, index) {
              final entry = provider.notificacionesAgrupadas.entries.elementAt(
                index,
              );
              final tipo = entry.key;
              final notificaciones = entry.value;

              return ExpansionTile(
                leading: Icon(_getIconoTipo(tipo), color: _getColorTipo(tipo)),
                title: Text(tipo.titulo),
                subtitle: Text('${notificaciones.length} notificaciones'),
                trailing: notificaciones.any((n) => !n.leida)
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          notificaciones
                              .where((n) => !n.leida)
                              .length
                              .toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
                children: notificaciones.map((notificacion) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: NotificacionCard(notificacion: notificacion),
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }

  /// 🧪 VISTA DE TEST FCM
  Widget _buildVistaTestFCM() {
    return const SingleChildScrollView(child: TestNotificationsWidget());
  }

  void _mostrarFiltro() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FiltroNotificacionesWidget(
        filtroActual: context.read<NotificacionesProvider>().filtroActual,
        onFiltroAplicado: (filtro) {
          context.read<NotificacionesProvider>().aplicarFiltro(filtro);
        },
      ),
    );
  }

  void _marcarTodasComoLeidas(NotificacionesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar todas como leídas'),
        content: const Text(
          '¿Estás seguro de que quieres marcar todas las notificaciones como leídas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.marcarTodasComoLeidas();
              Navigator.pop(context);
            },
            child: const Text('Marcar todas'),
          ),
        ],
      ),
    );
  }

  void _manejarOpcionMenu(String opcion) {
    final provider = context.read<NotificacionesProvider>();

    switch (opcion) {
      case 'refrescar':
        provider.refrescar();
        break;
      case 'configuracion':
        _mostrarConfiguracion();
        break;
    }
  }

  void _mostrarConfiguracion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de Notificaciones'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.notifications_active),
              title: Text('Notificaciones Push'),
              subtitle: Text('Recibir notificaciones en el dispositivo'),
              trailing: Switch(value: true, onChanged: null),
            ),
            ListTile(
              leading: Icon(Icons.vibration),
              title: Text('Vibración'),
              subtitle: Text('Vibrar al recibir notificaciones'),
              trailing: Switch(value: true, onChanged: null),
            ),
            ListTile(
              leading: Icon(Icons.volume_up),
              title: Text('Sonido'),
              subtitle: Text('Reproducir sonido de notificación'),
              trailing: Switch(value: true, onChanged: null),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  IconData _getIconoTipo(TipoNotificacion tipo) {
    switch (tipo) {
      case TipoNotificacion.solicitudReserva:
        return Icons.home;
      case TipoNotificacion.reservaAceptada:
        return Icons.check_circle;
      case TipoNotificacion.reservaRechazada:
        return Icons.cancel;
      case TipoNotificacion.nuevaResena:
        return Icons.star;
      case TipoNotificacion.solicitudAnfitrion:
        return Icons.person_add;
      case TipoNotificacion.anfitrionAceptado:
        return Icons.verified_user;
      case TipoNotificacion.anfitrionRechazado:
        return Icons.person_remove;
      case TipoNotificacion.nuevoMensaje:
        return Icons.message;
      case TipoNotificacion.llegadaHuesped:
        return Icons.login;
      case TipoNotificacion.finEstadia:
        return Icons.logout;
      case TipoNotificacion.recordatorioCheckin:
        return Icons.schedule;
      case TipoNotificacion.recordatorioCheckout:
        return Icons.schedule_send;
      case TipoNotificacion.general:
        return Icons.info;
    }
  }

  Color _getColorTipo(TipoNotificacion tipo) {
    switch (tipo) {
      case TipoNotificacion.solicitudReserva:
        return Colors.blue;
      case TipoNotificacion.reservaAceptada:
      case TipoNotificacion.anfitrionAceptado:
        return Colors.green;
      case TipoNotificacion.reservaRechazada:
      case TipoNotificacion.anfitrionRechazado:
        return Colors.red;
      case TipoNotificacion.nuevaResena:
        return Colors.amber;
      case TipoNotificacion.solicitudAnfitrion:
        return Colors.purple;
      case TipoNotificacion.nuevoMensaje:
        return Colors.teal;
      case TipoNotificacion.llegadaHuesped:
        return Colors.indigo;
      case TipoNotificacion.finEstadia:
        return Colors.orange;
      case TipoNotificacion.recordatorioCheckin:
      case TipoNotificacion.recordatorioCheckout:
        return Colors.brown;
      case TipoNotificacion.general:
        return Colors.grey;
    }
  }
}
