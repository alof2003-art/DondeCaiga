import 'package:flutter/material.dart';
import '../../data/models/chat_apartado.dart';
import '../../data/models/reserva_chat_info.dart';
import '../../data/models/filtro_chat.dart';
import 'reserva_card_viajero.dart';
import '../../../../main.dart';
import '../../../../core/config/performance_config.dart';

class ApartadoMisViajes extends StatelessWidget {
  final ChatApartado? apartado;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback? onResenaCreada;
  final FiltroChat?
  filtroActivo; // Nuevo parámetro para saber qué filtros están activos

  const ApartadoMisViajes({
    super.key,
    required this.apartado,
    required this.isLoading,
    required this.onRefresh,
    this.onResenaCreada,
    this.filtroActivo, // Opcional
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2196F3), // Azul para viajes
        ),
      );
    }

    if (apartado == null) {
      return _buildErrorMessage(context);
    }

    final reservasVigentes = apartado!.reservasVigentes;
    final reservasPasadas = apartado!.reservasPasadas;

    if (reservasVigentes.isEmpty && reservasPasadas.isEmpty) {
      return _buildSinViajesMessage(context);
    }

    // Determinar qué secciones mostrar basándose en los filtros activos
    final mostrarVigentes = _deberMostrarSeccionVigentes(reservasVigentes);
    final mostrarPasadas = _deberMostrarSeccionPasadas(reservasPasadas);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF2196F3),
      child: CustomScrollView(
        physics: PerformanceConfig.optimizedScrollPhysics, // Física optimizada
        cacheExtent: PerformanceConfig.defaultCacheExtent, // Cache optimizado
        slivers: [
          // Sección de reserva vigente (destacada) - solo si debe mostrarse
          if (mostrarVigentes && reservasVigentes.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSeccionReservaVigente(reservasVigentes.first),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],

          // Sección de lugares visitados (solo si debe mostrarse)
          if (mostrarPasadas) ...[
            SliverToBoxAdapter(
              child: _buildSeccionHeader(
                'Lugares Visitados',
                reservasPasadas.length,
                const Color(0xFF2196F3),
              ),
            ),

            // Contenido de lugares visitados
            if (reservasPasadas.isNotEmpty) ...[
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final user = supabase.auth.currentUser;
                  if (user == null) return Container();

                  final reservaInfo = ReservaChatInfo.fromReserva(
                    reservasPasadas[index],
                    usuarioActualId: user.id,
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ReservaCardViajero(
                      reserva: reservaInfo,
                      esVigente: false,
                      onResenaCreada: onResenaCreada,
                    ),
                  );
                }, childCount: reservasPasadas.length),
              ),
            ] else ...[
              // Mensaje cuando no hay viajes pasados
              SliverToBoxAdapter(child: _buildMensajeSinViajes(context)),
            ],
          ],

          // Espacio adicional al final
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  /// Determina si debe mostrar la sección de reservas vigentes
  bool _deberMostrarSeccionVigentes(List<dynamic> reservasVigentes) {
    // Si no hay filtro activo, siempre mostrar
    if (filtroActivo == null || !filtroActivo!.tienesFiltrosAplicados) {
      return true;
    }

    // Si el filtro es específicamente "Solo pasadas", no mostrar vigentes
    if (filtroActivo!.estadoFiltro == EstadoFiltro.pasadas) {
      return false;
    }

    // En cualquier otro caso, mostrar si hay contenido o si no es filtro de estado
    return true;
  }

  /// Determina si debe mostrar la sección de reservas pasadas
  bool _deberMostrarSeccionPasadas(List<dynamic> reservasPasadas) {
    // Si no hay filtro activo, siempre mostrar
    if (filtroActivo == null || !filtroActivo!.tienesFiltrosAplicados) {
      return true;
    }

    // Si el filtro es específicamente "Solo vigentes", no mostrar pasadas
    if (filtroActivo!.estadoFiltro == EstadoFiltro.vigentes) {
      return false;
    }

    // En cualquier otro caso, mostrar si hay contenido o si no es filtro de estado
    return true;
  }

  Widget _buildSeccionReservaVigente(dynamic reserva) {
    final user = supabase.auth.currentUser;
    if (user == null) return Container();

    final reservaInfo = ReservaChatInfo.fromReserva(
      reserva,
      usuarioActualId: user.id,
    );
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header especial para reserva vigente
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF2196F3), const Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.flight_takeoff, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tu Próximo Viaje',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        reservaInfo.diasRestantes != null &&
                                reservaInfo.diasRestantes! > 0
                            ? '${reservaInfo.diasRestantes} días restantes'
                            : 'En curso',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
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
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'VIGENTE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tarjeta de la reserva vigente
          Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: ReservaCardViajero(
              reserva: reservaInfo,
              esVigente: true,
              onResenaCreada: onResenaCreada,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionHeader(String titulo, int cantidad, Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.place, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$cantidad',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMensajeSinViajes(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.luggage_outlined,
            size: 48,
            color: const Color(
              0xFF757575,
            ), // Gris medio que se ve bien en ambos modos
          ),
          const SizedBox(height: 16),
          Text(
            'Todavía no se registran viajes',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(
                0xFF424242,
              ), // Gris oscuro que se ve bien en ambos modos
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando completes tus primeros viajes, aparecerán aquí',
            style: const TextStyle(
              fontSize: 14,
              color: Color(
                0xFF424242,
              ), // Gris oscuro que se ve bien en ambos modos
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSinViajesMessage(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF2196F3),
      child: CustomScrollView(
        physics: PerformanceConfig.optimizedScrollPhysics, // Física optimizada
        cacheExtent: PerformanceConfig.defaultCacheExtent, // Cache optimizado
        slivers: [
          // Sección de lugares visitados (siempre mostrar)
          SliverToBoxAdapter(
            child: _buildSeccionHeader(
              'Lugares Visitados',
              0,
              const Color(0xFF2196F3),
            ),
          ),

          // Mensaje cuando no hay viajes
          SliverToBoxAdapter(child: _buildMensajeSinViajes(context)),

          // Espacio adicional al final
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: const Color(
                0xFF757575,
              ), // Gris medio que se ve bien en ambos modos
            ),
            const SizedBox(height: 24),
            Text(
              'Error al Cargar',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(
                  0xFF424242,
                ), // Gris oscuro que se ve bien en ambos modos
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Hubo un problema al cargar tus viajes. Intenta nuevamente.',
              style: const TextStyle(
                fontSize: 16,
                color: Color(
                  0xFF424242,
                ), // Gris oscuro que se ve bien en ambos modos
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
