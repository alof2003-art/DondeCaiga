import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:donde_caigav2/main.dart';
import 'package:donde_caigav2/features/reservas/data/models/reserva.dart';
import 'package:donde_caigav2/features/chat/data/models/mensaje.dart';
import 'package:donde_caigav2/features/chat/data/repositories/mensaje_repository.dart';
import '../../../perfil/presentation/widgets/boton_ver_perfil.dart';

class ChatConversacionScreen extends StatefulWidget {
  final Reserva reserva;

  const ChatConversacionScreen({super.key, required this.reserva});

  @override
  State<ChatConversacionScreen> createState() => _ChatConversacionScreenState();
}

class _ChatConversacionScreenState extends State<ChatConversacionScreen> {
  late final MensajeRepository _mensajeRepository;
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Mensaje> _mensajes = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _codigoVisible = false;

  @override
  void initState() {
    super.initState();
    _mensajeRepository = MensajeRepository(supabase);
    _cargarMensajes();
    _suscribirseAMensajes();
  }

  Future<void> _cargarMensajes() async {
    setState(() => _isLoading = true);

    try {
      final mensajes = await _mensajeRepository.obtenerMensajes(
        widget.reserva.id,
      );
      if (mounted) {
        setState(() {
          _mensajes = mensajes;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _suscribirseAMensajes() {
    _mensajeRepository.suscribirseAMensajes(widget.reserva.id, (nuevoMensaje) {
      if (mounted) {
        setState(() {
          _mensajes.add(nuevoMensaje);
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      await _mensajeRepository.enviarMensaje(
        reservaId: widget.reserva.id,
        remitenteId: user.id,
        mensaje: texto,
      );

      _mensajeController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    // Determinar quién es el otro usuario
    final esViajero = user?.id == widget.reserva.viajeroId;
    final otroUsuarioId = esViajero
        ? widget.reserva.anfitrionId
        : widget.reserva.viajeroId;
    final nombreOtroUsuario = esViajero
        ? widget.reserva.nombreAnfitrion
        : widget.reserva.nombreViajero;
    final fotoOtroUsuario = esViajero
        ? widget.reserva.fotoAnfitrion
        : widget.reserva.fotoViajero;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Avatar del otro usuario clickeable
            BotonVerPerfil.icono(
              userId: otroUsuarioId ?? '',
              nombreUsuario: nombreOtroUsuario,
              fotoUsuario: fotoOtroUsuario,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del otro usuario clickeable
                  BotonVerPerfil.texto(
                    userId: otroUsuarioId ?? '',
                    nombreUsuario: nombreOtroUsuario ?? 'Usuario',
                  ),
                  Text(
                    '${DateFormat('dd/MM').format(widget.reserva.fechaInicio)} - ${DateFormat('dd/MM').format(widget.reserva.fechaFin)}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Código de Verificación en el header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Código:',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _codigoVisible
                      ? (widget.reserva.codigoVerificacion ?? '------')
                      : '• • • • • •',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _codigoVisible = !_codigoVisible;
                    });
                  },
                  icon: Icon(
                    _codigoVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          // Lista de mensajes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _mensajes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 60,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay mensajes',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Envía el primer mensaje',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(), // Física más suave
                    cacheExtent: 200, // Cache para mejor rendimiento
                    reverse: true, // Mensajes más recientes abajo
                    itemCount: _mensajes.length,
                    itemBuilder: (context, index) {
                      final mensaje = _mensajes[index];
                      final esMio = mensaje.remitenteId == user?.id;

                      return _MensajeBubble(mensaje: mensaje, esMio: esMio);
                    },
                  ),
          ),

          // Input de mensaje
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mensajeController,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF4DB6AC),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : IconButton(
                            onPressed: _enviarMensaje,
                            icon: const Icon(Icons.send, color: Colors.white),
                            padding: EdgeInsets.zero,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MensajeBubble extends StatelessWidget {
  final Mensaje mensaje;
  final bool esMio;

  const _MensajeBubble({required this.mensaje, required this.esMio});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: esMio
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: esMio ? const Color(0xFF4DB6AC) : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(esMio ? 16 : 4),
                bottomRight: Radius.circular(esMio ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mensaje.mensaje,
                  style: TextStyle(
                    color: esMio ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(mensaje.createdAt),
                  style: TextStyle(
                    color: esMio ? Colors.white70 : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
