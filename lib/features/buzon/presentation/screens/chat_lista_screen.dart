import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:donde_caigav2/main.dart';
import 'package:donde_caigav2/features/reservas/data/models/reserva.dart';
import 'package:donde_caigav2/features/reservas/data/repositories/reserva_repository.dart';
import 'package:donde_caigav2/features/chat/presentation/screens/chat_conversacion_screen.dart';

class ChatListaScreen extends StatefulWidget {
  const ChatListaScreen({super.key});

  @override
  State<ChatListaScreen> createState() => _ChatListaScreenState();
}

class _ChatListaScreenState extends State<ChatListaScreen> {
  late final ReservaRepository _reservaRepository;
  List<Reserva> _reservas = [];
  bool _isLoading = true;
  final Map<String, bool> _codigosVisibles = {};

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
        // Obtener reservas confirmadas del viajero
        final reservasViajero = await _reservaRepository.obtenerReservasViajero(
          user.id,
        );

        // Obtener reservas confirmadas del anfitrión
        final reservasAnfitrion = await _reservaRepository
            .obtenerReservasAnfitrion(user.id);

        // Combinar ambas listas
        final todasReservas = [...reservasViajero, ...reservasAnfitrion];

        if (mounted) {
          setState(() {
            _reservas = todasReservas;
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

  void _toggleCodigoVisible(String reservaId) {
    setState(() {
      _codigosVisibles[reservaId] = !(_codigosVisibles[reservaId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reservas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes chats activos',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tus reservas confirmadas aparecerán aquí',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargarReservas,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _reservas.length,
                itemBuilder: (context, index) {
                  final reserva = _reservas[index];
                  return _ReservaCard(
                    reserva: reserva,
                    codigoVisible: _codigosVisibles[reserva.id] ?? false,
                    onToggleCodigo: () => _toggleCodigoVisible(reserva.id),
                  );
                },
              ),
            ),
    );
  }
}

class _ReservaCard extends StatelessWidget {
  final Reserva reserva;
  final bool codigoVisible;
  final VoidCallback onToggleCodigo;

  const _ReservaCard({
    required this.reserva,
    required this.codigoVisible,
    required this.onToggleCodigo,
  });

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final esViajero = user?.id == reserva.viajeroId;
    final otroUsuario = esViajero
        ? (reserva.nombreAnfitrion ?? 'Anfitrión')
        : (reserva.nombreViajero ?? 'Viajero');
    final rolOtroUsuario = esViajero ? 'Anfitrión' : 'Viajero';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Propiedad y Estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4DB6AC).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.home,
                    color: Color(0xFF4DB6AC),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$rolOtroUsuario: $otroUsuario • ${DateFormat('dd/MM/yyyy').format(reserva.fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(reserva.fechaFin)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Text(
                    'ACEPTADA',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Código de Verificación
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Código de Verificación',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        codigoVisible
                            ? (reserva.codigoVerificacion ?? '------')
                            : '• • • • • •',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: onToggleCodigo,
                        icon: Icon(
                          codigoVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Muestra este código al anfitrión al llegar',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Botón de Chat
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatConversacionScreen(reserva: reserva),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble, size: 20),
                label: const Text('Abrir Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4DB6AC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
