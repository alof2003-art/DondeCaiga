import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/reserva_chat_info.dart';
import '../../../chat/presentation/screens/chat_conversacion_screen.dart';
import '../../../reservas/data/models/reserva.dart';
import '../../../explorar/presentation/screens/detalle_propiedad_screen.dart';
import '../../../perfil/presentation/widgets/boton_ver_perfil.dart';
import '../../../resenas/presentation/widgets/boton_resenar_propiedad.dart';

class ReservaCardViajero extends StatefulWidget {
  final ReservaChatInfo reserva;
  final bool esVigente;
  final VoidCallback? onResenaCreada;

  const ReservaCardViajero({
    super.key,
    required this.reserva,
    required this.esVigente,
    this.onResenaCreada,
  });

  @override
  State<ReservaCardViajero> createState() => _ReservaCardViajeroState();
}

class _ReservaCardViajeroState extends State<ReservaCardViajero> {
  bool _codigoVisible = false;

  // Helper getters para acceso más fácil
  ReservaChatInfo get reserva => widget.reserva;
  bool get esVigente => widget.esVigente;
  VoidCallback? get onResenaCreada => widget.onResenaCreada;

  @override
  Widget build(BuildContext context) {
    final colorPrincipal = esVigente
        ? const Color(0xFF2196F3)
        : const Color(0xFF64B5F6);
    final colorFondo = esVigente
        ? const Color(0xFFE3F2FD)
        : const Color(0xFFF3F9FF);

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
              // Header con información del lugar
              _buildHeaderLugar(colorPrincipal),

              const SizedBox(height: 12),

              // Información del anfitrión
              _buildInfoAnfitrion(colorPrincipal),

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

  Widget _buildHeaderLugar(Color colorPrincipal) {
    return Row(
      children: [
        // Icono del lugar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorPrincipal.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.location_on, color: colorPrincipal, size: 24),
        ),

        const SizedBox(width: 12),

        // Información del lugar
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
                  fontSize: 14,
                  color: Color(0xFF424242), // Color fijo como en Mis Viajes
                ),
              ),
            ],
          ),
        ),

        // Indicador de estado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: esVigente
                ? colorPrincipal
                : Theme.of(context).colorScheme.outline,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            esVigente ? 'Vigente' : 'Visitado',
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

  Widget _buildInfoAnfitrion(Color colorPrincipal) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.9,
        ), // Fondo blanco como en Mis Viajes
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorPrincipal.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Avatar del anfitrión clickeable
          BotonVerPerfil.icono(
            userId: reserva.anfitrionId ?? '',
            nombreUsuario: reserva.nombreAnfitrion,
            fotoUsuario: reserva.fotoAnfitrion,
          ),

          const SizedBox(width: 8),

          // Información del anfitrión
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del anfitrión clickeable
                BotonVerPerfil.texto(
                  userId: reserva.anfitrionId ?? '',
                  nombreUsuario:
                      'Anfitrión: ${reserva.nombreAnfitrion ?? 'Anfitrión'}',
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber[700]),
                    const SizedBox(width: 4),
                    Text(
                      '5.0', // TODO: Agregar calificación a modelo
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(
                          0xFF424242,
                        ), // Color fijo como en Mis Viajes
                      ),
                    ),
                  ],
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
        color: Colors.white.withValues(
          alpha: 0.9,
        ), // Fondo blanco como en Mis Viajes
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
                        Icon(
                          Icons.flight_land,
                          color: colorPrincipal,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Llegada',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(
                              0xFF424242,
                            ), // Color fijo como en Mis Viajes
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
                        ), // Color fijo como en Mis Viajes
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
                        Icon(
                          Icons.flight_takeoff,
                          color: colorPrincipal,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Salida',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(
                              0xFF424242,
                            ), // Color fijo como en Mis Viajes
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
                        ), // Color fijo como en Mis Viajes
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
                  color: Color(0xFF424242), // Color fijo como en Mis Viajes
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
                    color: Color(0xFF424242), // Color fijo como en Mis Viajes
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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

  Widget _buildEstadoYAcciones(BuildContext context, Color colorPrincipal) {
    return Row(
      children: [
        // Espacio para mantener el layout
        const Expanded(child: SizedBox()),

        // Botones de acción
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón de reseña (solo para reservas pasadas)
            if (!esVigente) ...[
              BotonResenarPropiedad(
                reservaId: reserva.id,
                propiedadId: reserva.propiedadId,
                tituloPropiedad: reserva.tituloPropiedad ?? 'Propiedad',
                onResenaCreada: onResenaCreada,
              ),
              const SizedBox(width: 8),
            ],

            // Botón de chat
            ElevatedButton.icon(
              onPressed: () => _abrirChat(context),
              icon: const Icon(Icons.chat, size: 16),
              label: const Text('Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrincipal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: esVigente ? 2 : 1,
              ),
            ),
          ],
        ),
      ],
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
