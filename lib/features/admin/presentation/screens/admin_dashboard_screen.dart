import 'package:flutter/material.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/models/admin_stats.dart';

import '../../../auth/data/models/user_profile.dart';
import '../widgets/user_action_dialog.dart';
import '../widgets/confirmation_dialog.dart';
import '../../../perfil/presentation/widgets/boton_ver_perfil.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/widgets/custom_app_bar_header.dart';
import '../../../../main.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminRepository _adminRepository = AdminRepository();

  AdminStats? _stats;
  List<UserProfile> _usuarios = [];
  List<UserProfile> _usuariosFiltrados = [];
  bool _isLoading = true;
  String? _error;

  // Filtros y búsqueda
  final TextEditingController _searchController = TextEditingController();
  int? _filtroRol;
  String? _filtroEstado;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchController.addListener(_aplicarFiltros);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _adminRepository.obtenerEstadisticas();
      final usuarios = await _adminRepository.obtenerUsuariosGestionables();

      setState(() {
        _stats = stats;
        _usuarios = usuarios;
        _usuariosFiltrados = usuarios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _obtenerNombreRol(int rolId) {
    switch (rolId) {
      case 1:
        return 'Viajero';
      case 2:
        return 'Anfitrión';
      case 3:
        return 'Administrador';
      default:
        return 'Desconocido';
    }
  }

  Color _obtenerColorRol(int rolId) {
    switch (rolId) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _obtenerIconoRol(int rolId) {
    switch (rolId) {
      case 1:
        return Icons.luggage;
      case 2:
        return Icons.home;
      case 3:
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  void _aplicarFiltros() {
    setState(() {
      _usuariosFiltrados = _usuarios.where((usuario) {
        // Filtro de búsqueda
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch =
            searchQuery.isEmpty ||
            usuario.nombre.toLowerCase().contains(searchQuery) ||
            usuario.email.toLowerCase().contains(searchQuery);

        // Filtro de rol
        final matchesRole = _filtroRol == null || usuario.rolId == _filtroRol;

        // Filtro de estado
        final matchesStatus =
            _filtroEstado == null || usuario.estadoCuenta == _filtroEstado;

        return matchesSearch && matchesRole && matchesStatus;
      }).toList();
    });
  }

  String _getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id ?? '';
  }

  Future<void> _mostrarMensaje(String mensaje, {bool esError = false}) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomAppBarHeader(
          supabase: supabase,
          screenTitle: 'Panel de Administración',
        ),
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _cargarDatos,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección de Estadísticas
                    _buildEstadisticas(),

                    const SizedBox(height: 16),

                    // Sección de Lista de Usuarios
                    _buildListaUsuarios(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEstadisticas() {
    if (_stats == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4DB6AC),
            const Color(0xFF4DB6AC).withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text(
                'Estadísticas del Sistema',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Grid de estadísticas
          LayoutBuilder(
            builder: (context, constraints) {
              // Calcular aspect ratio dinámicamente basado en el ancho disponible
              final cardWidth = (constraints.maxWidth - 12) / 2;
              final cardHeight = 80.0;
              final aspectRatio = cardWidth / cardHeight;

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: aspectRatio.clamp(1.5, 3.0),
                children: [
                  _buildStatCard(
                    'Total Usuarios',
                    _stats!.totalUsuarios.toString(),
                    Icons.people,
                    Colors.white,
                  ),
                  _buildStatCard(
                    'Viajeros',
                    _stats!.totalViajeros.toString(),
                    Icons.luggage,
                    Colors.blue.shade100,
                  ),
                  _buildStatCard(
                    'Anfitriones',
                    _stats!.totalAnfitriones.toString(),
                    Icons.home,
                    Colors.green.shade100,
                  ),
                  _buildStatCard(
                    'Alojamientos',
                    _stats!.totalAlojamientos.toString(),
                    Icons.apartment,
                    Colors.purple.shade100,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4DB6AC)),
          const SizedBox(height: 2),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4DB6AC),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaUsuarios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado con contador
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.people, color: Color(0xFF4DB6AC)),
              const SizedBox(width: 8),
              const Text(
                'Gestión de Usuarios',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${_usuariosFiltrados.length} de ${_usuarios.length}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Filtros
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Filtro por rol
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _filtroRol,
                  decoration: InputDecoration(
                    labelText: 'Filtrar por rol',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Todos los roles'),
                    ),
                    DropdownMenuItem(value: 1, child: Text('Viajeros')),
                    DropdownMenuItem(value: 2, child: Text('Anfitriones')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filtroRol = value;
                    });
                    _aplicarFiltros();
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Filtro por estado
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _filtroEstado,
                  decoration: InputDecoration(
                    labelText: 'Filtrar por estado',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Todos los estados'),
                    ),
                    DropdownMenuItem(value: 'activo', child: Text('Activos')),
                    DropdownMenuItem(
                      value: 'bloqueado',
                      child: Text('Bloqueados'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filtroEstado = value;
                    });
                    _aplicarFiltros();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Lista de usuarios
        if (_usuariosFiltrados.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No se encontraron usuarios')),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _usuariosFiltrados.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final usuario = _usuariosFiltrados[index];
              return _buildUsuarioCard(usuario);
            },
          ),
      ],
    );
  }

  Widget _buildUsuarioCard(UserProfile usuario) {
    final nombreRol = _obtenerNombreRol(usuario.rolId);
    final colorRol = _obtenerColorRol(usuario.rolId);
    final iconoRol = _obtenerIconoRol(usuario.rolId);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: colorRol.withValues(alpha: 0.2),
        backgroundImage: usuario.fotoPerfilUrl != null
            ? NetworkImage(usuario.fotoPerfilUrl!)
            : null,
        child: usuario.fotoPerfilUrl == null
            ? Icon(iconoRol, color: colorRol)
            : null,
      ),
      title: Text(
        usuario.nombre,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.email, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  usuario.email,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorRol.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconoRol, size: 14, color: colorRol),
                const SizedBox(width: 4),
                Text(
                  nombreRol,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorRol,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: () {
        // Aquí podrías agregar navegación a detalle del usuario
        _mostrarDetalleUsuario(usuario);
      },
    );
  }

  void _mostrarDetalleUsuario(UserProfile usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _obtenerColorRol(
                usuario.rolId,
              ).withValues(alpha: 0.2),
              backgroundImage: usuario.fotoPerfilUrl != null
                  ? NetworkImage(usuario.fotoPerfilUrl!)
                  : null,
              child: usuario.fotoPerfilUrl == null
                  ? Icon(
                      _obtenerIconoRol(usuario.rolId),
                      color: _obtenerColorRol(usuario.rolId),
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(usuario.nombre)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetalleItem('Email', usuario.email),
            _buildDetalleItem('Teléfono', usuario.telefono ?? 'No registrado'),
            _buildDetalleItem('Rol', _obtenerNombreRol(usuario.rolId)),
            _buildDetalleItem('Estado', usuario.estadoCuenta),
            _buildDetalleItem(
              'Email verificado',
              usuario.emailVerified ? 'Sí' : 'No',
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Botones de acción
            const Text(
              'Acciones Administrativas:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            // Botón Ver Perfil
            SizedBox(
              width: double.infinity,
              child: BotonVerPerfil.boton(
                userId: usuario.id,
                nombreUsuario: usuario.nombre,
                fotoUsuario: usuario.fotoPerfilUrl,
              ),
            ),

            const SizedBox(height: 8),

            // Botón degradar anfitrión
            if (usuario.rolId == 2 && usuario.estadoCuenta == 'activo')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmarDegradacion(usuario),
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text('Degradar a Viajero'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Botón bloquear/desbloquear
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: usuario.estadoCuenta == 'activo'
                    ? () => _confirmarBloqueo(usuario)
                    : () => _confirmarDesbloqueo(usuario),
                icon: Icon(
                  usuario.estadoCuenta == 'activo'
                      ? Icons.block
                      : Icons.check_circle,
                ),
                label: Text(
                  usuario.estadoCuenta == 'activo'
                      ? 'Bloquear Cuenta'
                      : 'Desbloquear Cuenta',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: usuario.estadoCuenta == 'activo'
                      ? Colors.red
                      : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Botón eliminar cuenta
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmarEliminacion(usuario),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Eliminar Cuenta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                ),
              ),
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

  Widget _buildDetalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // ============================================
  // MÉTODOS DE CONFIRMACIÓN Y ACCIONES
  // ============================================

  Future<void> _confirmarDegradacion(UserProfile usuario) async {
    Navigator.pop(context); // Cerrar diálogo de detalle

    String? reason;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => UserActionDialog(
        user: usuario,
        actionType: UserActionType.degradeRole,
        onConfirm: (String? dialogReason) {
          reason = dialogReason;
          Navigator.of(context).pop(true);
        },
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirmed == true && reason != null) {
      await _ejecutarDegradacion(usuario.id, reason!);
    }
  }

  Future<void> _confirmarBloqueo(UserProfile usuario) async {
    Navigator.pop(context); // Cerrar diálogo de detalle

    String? reason;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => UserActionDialog(
        user: usuario,
        actionType: UserActionType.blockAccount,
        onConfirm: (String? dialogReason) {
          reason = dialogReason;
          Navigator.of(context).pop(true);
        },
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirmed == true && reason != null) {
      await _ejecutarBloqueo(usuario.id, reason!);
    }
  }

  Future<void> _confirmarDesbloqueo(UserProfile usuario) async {
    Navigator.pop(context); // Cerrar diálogo de detalle

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Desbloquear Cuenta',
        message:
            '¿Estás seguro de que deseas desbloquear la cuenta de ${usuario.nombre}?\n\n'
            'El usuario podrá volver a acceder a la aplicación.',
        confirmText: 'Desbloquear',
        confirmColor: Colors.green,
        icon: Icons.check_circle,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirmed == true) {
      await _ejecutarDesbloqueo(usuario.id);
    }
  }

  Future<void> _confirmarEliminacion(UserProfile usuario) async {
    Navigator.pop(context); // Cerrar diálogo de detalle

    String? reason;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => UserActionDialog(
        user: usuario,
        actionType: UserActionType.deleteAccount,
        onConfirm: (String? dialogReason) {
          reason = dialogReason;
          Navigator.of(context).pop(true);
        },
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirmed == true && reason != null) {
      await _ejecutarEliminacion(usuario.id, reason!);
    }
  }

  // ============================================
  // MÉTODOS DE EJECUCIÓN DE ACCIONES
  // ============================================

  Future<void> _ejecutarDegradacion(String userId, String reason) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _adminRepository.degradarAnfitrionAViajero(
        userId,
        _getCurrentUserId(),
        reason,
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga

        if (result.success) {
          await _mostrarMensaje(result.message);
          await _cargarDatos(); // Recargar datos
        } else {
          await _mostrarMensaje(result.message, esError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga
        await _mostrarMensaje('Error inesperado: $e', esError: true);
      }
    }
  }

  Future<void> _ejecutarBloqueo(String userId, String reason) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _adminRepository.bloquearCuentaUsuario(
        userId,
        reason,
        _getCurrentUserId(),
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga

        if (result.success) {
          await _mostrarMensaje(result.message);
          await _cargarDatos(); // Recargar datos
        } else {
          await _mostrarMensaje(result.message, esError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga
        await _mostrarMensaje('Error inesperado: $e', esError: true);
      }
    }
  }

  Future<void> _ejecutarDesbloqueo(String userId) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _adminRepository.desbloquearCuentaUsuario(
        userId,
        _getCurrentUserId(),
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga

        if (result.success) {
          await _mostrarMensaje(result.message);
          await _cargarDatos(); // Recargar datos
        } else {
          await _mostrarMensaje(result.message, esError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga
        await _mostrarMensaje('Error inesperado: $e', esError: true);
      }
    }
  }

  Future<void> _ejecutarEliminacion(String userId, String reason) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _adminRepository.eliminarCuentaUsuario(
        userId,
        reason,
        _getCurrentUserId(),
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga

        if (result.success) {
          await _mostrarMensaje(result.message);
          await _cargarDatos(); // Recargar datos
        } else {
          await _mostrarMensaje(result.message, esError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga
        await _mostrarMensaje('Error inesperado: $e', esError: true);
      }
    }
  }
}
