import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/reserva_chat_info.dart';
import '../../../chat/presentation/screens/chat_conversacion_screen.dart';
import '../../../reservas/data/models/reserva.dart';
import '../../../explorar/presentation/screens/detalle_propiedad_screen.dart';
import '../../../perfil/presentation/widgets/boton_ver_perfil.dart';
import '../../../resenas/presentation/widgets/boton_resenar_viajero.dart';

class ReservaCardAnfitrion extends StatefulWidget {
  final ReservaChatInfo reserva;
  final bool esVigente;

  const ReservaCardAnfitrion({
    super.key,
    required this.reserva,
    required this.esVigente,
  });

  @override
  State<ReservaCardAnfitrion> createState() => _ReservaCardAnfitrionState();
}

class _ReservaCardAnfitrionState extends State<ReservaCardAnfitrion> {
  bool _codigoVisible = false;

  // Helper getters para acceso más fácil
  ReservaChatInfo get reserva => widget.reserva;
  bool get esVigente => widget.esVigente;

  @override
  Widget build(BuildContext context) {
    final colorPrincipal = esVigente
        ? const Color(0xFF4CAF50)
        : const Color(0xFF81C784);
    final colorFondo = esVigente
        ? const Color(0xFFE8F5E8)
        : const Color(0xFFF1F8E9);

    return Card(
      elevation: esVigente ? 4 : 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorPrincipal.withValues(alpha: esVigente ? 0.3 : 0.2),
          width: esVigente ? 2 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colorFondo,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con información del huésped
              _buildHeaderHuesped(colorPrincipal),

              const SizedBox(height: 12),

              // Información de la propiedad
              _buildInfoPropiedad(colorPrincipal),

              const SizedBox(height: 12),

              // Fechas y duración
              _buildInfoFechas(colorPrincipal),

              const SizedBox(height: 12),

              // Código de verificación
              if (reserva.codigoVerificacion != null)
                _buildCodigoVerificacion(colorPrincipal),

              if (reserva.codigoVerificacion != null)
                const SizedBox(height: 12),

              // Estado y acciones
              _buildEstadoYAcciones(context, colorPrincipal),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderHuesped(Color colorPrincipal) {
    return Row(
      children: [
        // Avatar del huésped clickeable
        BotonVerPerfil.icono(
          userId: reserva.viajeroId,
          nombreUsuario: reserva.nombreViajero,
          fotoUsuario: reserva.fotoViajero,
        ),

        const SizedBox(width: 12),

        // Información del huésped
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre del huésped clickeable
              BotonVerPerfil.texto(
                userId: reserva.viajeroId,
                nombreUsuario: reserva.nombreViajero ?? 'Huésped',
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber[700]),
                  const SizedBox(width: 4),
                  Text(
                    '5.0', // TODO: Agregar calificación a modelo
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF424242), // NEGRO FIJO como en Mis Viajes
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Indicador de estado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: esVigente ? colorPrincipal : Colors.grey[400],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            esVigente ? 'Vigente' : 'Completada',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPropiedad(Color colorPrincipal) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorPrincipal.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.home, color: colorPrincipal, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) => GestureDetector(
                    onTap: () => _verDetallesPropiedad(context),
                    child: Text(
                      reserva.tituloPropiedad ?? 'Propiedad',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorPrincipal,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ciudad', // TODO: Agregar ciudad a modelo
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF424242), // NEGRO FIJO como en Mis Viajes
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoFechas(Color colorPrincipal) {
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorPrincipal.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Fechas de check-in y check-out
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.login, color: colorPrincipal, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Check-in',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(
                              0xFF424242,
                            ), // NEGRO FIJO como en Mis Viajes
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatoFecha.format(reserva.fechaInicio),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(
                          0xFF424242,
                        ), // NEGRO FIJO como en Mis Viajes
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.logout, color: colorPrincipal, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Check-out',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(
                              0xFF424242,
                            ), // NEGRO FIJO como en Mis Viajes
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatoFecha.format(reserva.fechaFin),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(
                          0xFF424242,
                        ), // NEGRO FIJO como en Mis Viajes
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Duración y tiempo restante/transcurrido
          Row(
            children: [
              Icon(Icons.schedule, color: colorPrincipal, size: 16),
              const SizedBox(width: 4),
              Text(
                '${reserva.duracionDias} ${reserva.duracionDias == 1 ? 'día' : 'días'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF424242), // NEGRO FIJO como en Mis Viajes
                ),
              ),
              const Spacer(),
              if (esVigente && reserva.diasRestantes != null)
                Text(
                  reserva.diasRestantes! > 0
                      ? '${reserva.diasRestantes} días restantes'
                      : 'En curso',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorPrincipal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (!esVigente)
                Text(
                  _calcularTiempoTranscurrido(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF424242), // NEGRO FIJO como en Mis Viajes
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoYAcciones(BuildContext context, Color colorPrincipal) {
    // Calcular si debe mostrar el botón de chat
    final mostrarChat = _deberMostrarBotonChat();

    return Row(
      children: [
        // Botón de reseñar viajero (solo para reservas completadas)
        if (!esVigente) ...[
          BotonResenarViajero(
            reservaId: reserva.id,
            viajeroId: reserva.viajeroId,
            nombreViajero: reserva.nombreViajero ?? 'Viajero',
            fotoViajero: reserva.fotoViajero,
            tituloPropiedad: reserva.tituloPropiedad ?? 'Propiedad',
          ),
          const SizedBox(width: 8),
        ],

        // Espacio para mantener el layout
        const Expanded(child: SizedBox()),

        // Botón de chat (con lógica de tiempo)
        if (mostrarChat) ...[
          ElevatedButton.icon(
            onPressed: () => _abrirChat(context),
            icon: const Icon(Icons.chat, size: 16),
            label: const Text('Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorPrincipal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: esVigente ? 2 : 1,
            ),
          ),
        ] else if (!esVigente) ...[
          // Mensaje explicativo cuando el chat ya no está disponible
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Chat no disponible',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Determina si debe mostrar el botón de chat basándose en el tiempo transcurrido
  bool _deberMostrarBotonChat() {
    // Para reservas vigentes, siempre mostrar chat
    if (esVigente) {
      return true;
    }

    // Para reservas pasadas, solo mostrar si han pasado menos de 5 días
    final ahora = DateTime.now();
    final diferencia = ahora.difference(reserva.fechaFin);

    // Mostrar chat solo si han pasado menos de 5 días desde el fin de la reserva
    return diferencia.inDays < 5;
  }

  Widget _buildCodigoVerificacion(Color colorPrincipal) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Código:',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _codigoVisible
                  ? (reserva.codigoVerificacion ?? '------')
                  : '• • • • • •',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.blue,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _codigoVisible = !_codigoVisible;
              });
            },
            icon: Icon(
              _codigoVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.blue,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  String _calcularTiempoTranscurrido() {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(reserva.fechaFin);

    if (diferencia.inDays > 30) {
      final meses = (diferencia.inDays / 30).floor();
      return 'Hace $meses ${meses == 1 ? 'mes' : 'meses'}';
    } else if (diferencia.inDays > 0) {
      return 'Hace ${diferencia.inDays} ${diferencia.inDays == 1 ? 'día' : 'días'}';
    } else {
      return 'Reciente';
    }
  }

  void _verDetallesPropiedad(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetallePropiedadScreen(propiedadId: reserva.propiedadId),
      ),
    );
  }

  void _abrirChat(BuildContext context) {
    // Crear objeto Reserva para la navegación al chat
    final reservaChat = Reserva(
      id: reserva.id,
      viajeroId: reserva.viajeroId,
      propiedadId: reserva.propiedadId,
      fechaInicio: reserva.fechaInicio,
      fechaFin: reserva.fechaFin,
      estado: 'confirmada', // Las reservas en chat están confirmadas
      createdAt: DateTime.now(), // Valor por defecto
      updatedAt: DateTime.now(), // Valor por defecto
      tituloPropiedad: reserva.tituloPropiedad,
      codigoVerificacion: reserva.codigoVerificacion,
      anfitrionId: reserva.anfitrionId,
      nombreAnfitrion: reserva.nombreAnfitrion,
      fotoAnfitrion: reserva.fotoAnfitrion,
      nombreViajero: reserva.nombreViajero,
      fotoViajero: reserva.fotoViajero,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatConversacionScreen(reserva: reservaChat),
      ),
    );
  }
}
