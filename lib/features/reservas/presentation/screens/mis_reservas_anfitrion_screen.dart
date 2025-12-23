import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:donde_caigav2/main.dart';
import 'package:donde_caigav2/features/reservas/data/models/reserva.dart';
import 'package:donde_caigav2/features/reservas/data/repositories/reserva_repository.dart';

class MisReservasAnfitrionScreen extends StatefulWidget {
  const MisReservasAnfitrionScreen({super.key});

  @override
  State<MisReservasAnfitrionScreen> createState() =>
      _MisReservasAnfitrionScreenState();
}

class _MisReservasAnfitrionScreenState
    extends State<MisReservasAnfitrionScreen> {
  late final ReservaRepository _reservaRepository;
  List<Reserva> _reservas = [];
  bool _isLoading = true;
  String _filtroEstado = 'todas'; // todas, pendiente, confirmada

  @override
  void initState() {
    super.initState();
    _reservaRepository = ReservaRepository(supabase);
    _cargarReservas();
  }

  Future<void> _cargarReservas() async {
    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final reservas = await _reservaRepository.obtenerReservasAnfitrion(
          user.id,
        );
        if (mounted) {
          setState(() {
            _reservas = reservas;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar reservas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Reserva> get _reservasFiltradas {
    if (_filtroEstado == 'todas') {
      return _reservas;
    }
    return _reservas.where((r) => r.estado == _filtroEstado).toList();
  }

  Future<void> _aprobarReserva(Reserva reserva) async {
    try {
      await _reservaRepository.actualizarEstadoReserva(
        reserva.id,
        'confirmada',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Reserva aprobada!'),
          backgroundColor: Colors.green,
        ),
      );

      _cargarReservas();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rechazarReserva(Reserva reserva) async {
    // Confirmar rechazo
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Reserva'),
        content: const Text('¿Estás seguro de rechazar esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _reservaRepository.actualizarEstadoReserva(reserva.id, 'rechazada');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva rechazada'),
          backgroundColor: Colors.orange,
        ),
      );

      _cargarReservas();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservas'),
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: _FiltroChip(
                    label: 'Todas',
                    isSelected: _filtroEstado == 'todas',
                    onTap: () => setState(() => _filtroEstado = 'todas'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FiltroChip(
                    label: 'Pendientes',
                    isSelected: _filtroEstado == 'pendiente',
                    onTap: () => setState(() => _filtroEstado = 'pendiente'),
                    count: _reservas.where((r) => r.esPendiente).length,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FiltroChip(
                    label: 'Confirmadas',
                    isSelected: _filtroEstado == 'confirmada',
                    onTap: () => setState(() => _filtroEstado = 'confirmada'),
                  ),
                ),
              ],
            ),
          ),

          // Lista de reservas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reservasFiltradas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 80,
                          color: const Color(0xFF757575),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filtroEstado == 'todas'
                              ? 'No tienes reservas'
                              : 'No hay reservas ${_filtroEstado}s',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarReservas,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics:
                          const BouncingScrollPhysics(), // Física más suave
                      cacheExtent: 200, // Cache para mejor rendimiento
                      itemCount: _reservasFiltradas.length,
                      itemBuilder: (context, index) {
                        final reserva = _reservasFiltradas[index];
                        return _ReservaCard(
                          reserva: reserva,
                          onAprobar: () => _aprobarReserva(reserva),
                          onRechazar: () => _rechazarReserva(reserva),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  const _FiltroChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4DB6AC) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF4DB6AC) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF424242),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFF4DB6AC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF4DB6AC) : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReservaCard extends StatelessWidget {
  final Reserva reserva;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  const _ReservaCard({
    required this.reserva,
    required this.onAprobar,
    required this.onRechazar,
  });

  Color _getEstadoColor() {
    switch (reserva.estado) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmada':
        return Colors.green;
      case 'rechazada':
        return Colors.red;
      case 'completada':
        return Colors.blue;
      case 'cancelada':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoTexto() {
    switch (reserva.estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'confirmada':
        return 'Confirmada';
      case 'rechazada':
        return 'Rechazada';
      case 'completada':
        return 'Completada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return reserva.estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Propiedad y Estado
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reserva.tituloPropiedad ?? 'Propiedad',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getEstadoColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getEstadoColor()),
                  ),
                  child: Text(
                    _getEstadoTexto(),
                    style: TextStyle(
                      color: _getEstadoColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Información del viajero
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: reserva.fotoViajero != null
                      ? NetworkImage(reserva.fotoViajero!)
                      : null,
                  child: reserva.fotoViajero == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Viajero',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                      Text(
                        reserva.nombreViajero ?? 'Usuario',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Fechas
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inicio',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(reserva.fechaInicio),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: const Color(0xFF757575)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Fin',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(reserva.fechaFin),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Duración
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: const Color(0xFF757575),
                ),
                const SizedBox(width: 4),
                Text(
                  '${reserva.duracionDias} ${reserva.duracionDias == 1 ? 'día' : 'días'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF424242),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            // Botones de acción (solo para pendientes)
            if (reserva.esPendiente) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRechazar,
                      icon: const Icon(Icons.close),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAprobar,
                      icon: const Icon(Icons.check),
                      label: const Text('Aprobar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
