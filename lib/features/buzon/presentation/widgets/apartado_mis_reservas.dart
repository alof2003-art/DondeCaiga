import 'package:flutter/material.dart';
import '../../data/models/chat_apartado.dart';
import '../../data/models/reserva_chat_info.dart';
import '../../data/models/filtro_chat.dart';
import 'reserva_card_anfitrion.dart';
import '../../../../main.dart';
import '../../../../core/config/performance_config.dart';

class ApartadoMisReservas extends StatelessWidget {
  final ChatApartado? apartado;
  final bool isLoading;
  final bool esAnfitrion;
  final VoidCallback onRefresh;
  final FiltroChat?
  filtroActivo; // Nuevo parámetro para saber qué filtros están activos

  const ApartadoMisReservas({
    super.key,
    required this.apartado,
    required this.isLoading,
    required this.esAnfitrion,
    required this.onRefresh,
    this.filtroActivo, // Opcional
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4CAF50), // Verde para reservas
        ),
      );
    }

    if (!esAnfitrion) {
      return _buildNoAnfitrionMessage(context);
    }

    if (apartado == null) {
      return _buildErrorMessage(context);
    }

    final reservasVigentes = apartado!.reservasVigentes;
    final reservasPasadas = apartado!.reservasPasadas;

    if (reservasVigentes.isEmpty && reservasPasadas.isEmpty) {
      return _buildSinReservasMessage(context);
    }

    return _buildOptimizedScrollView(
      context,
      reservasVigentes,
      reservasPasadas,
    );
  }

  Widget _buildOptimizedScrollView(
    BuildContext context,
    List<dynamic> reservasVigentes,
    List<dynamic> reservasPasadas,
  ) {
    // Determinar qué secciones mostrar basándose en los filtros activos
    final mostrarVigentes = _deberMostrarSeccionVigentes(reservasVigentes);
    final mostrarPasadas = _deberMostrarSeccionPasadas(reservasPasadas);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF4CAF50),
      child: CustomScrollView(
        physics: PerformanceConfig.optimizedScrollPhysics,
        cacheExtent: PerformanceConfig.defaultCacheExtent,
        slivers: [
          // Sección de reservas vigentes (solo si debe mostrarse)
          if (mostrarVigentes) ...[
            SliverToBoxAdapter(
              child: _buildSeccionHeader(
                'Reservas Vigentes',
                reservasVigentes.length,
                const Color(0xFF4CAF50),
              ),
            ),

            // Contenido de reservas vigentes
            if (reservasVigentes.isNotEmpty) ...[
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final user = supabase.auth.currentUser;
                  if (user == null) return Container();

                  final reservaInfo = ReservaChatInfo.fromReserva(
                    reservasVigentes[index],
                    usuarioActualId: user.id,
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ReservaCardAnfitrion(
                      reserva: reservaInfo,
                      esVigente: true,
                    ),
                  );
                }, childCount: reservasVigentes.length),
              ),
            ] else ...[
              // Mensaje cuando no hay reservas vigentes
              SliverToBoxAdapter(
                child: _buildMensajeSinReservasVigentes(context),
              ),
            ],
          ],

          // Separador (solo si ambas secciones se muestran)
          if (mostrarVigentes && mostrarPasadas)
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Sección de reservas pasadas (solo si debe mostrarse)
          if (mostrarPasadas) ...[
            SliverToBoxAdapter(
              child: _buildSeccionHeader(
                'Reservas Pasadas',
                reservasPasadas.length,
                const Color(0xFF81C784), // Verde más claro para pasadas
              ),
            ),

            // Contenido de reservas pasadas
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
                    child: ReservaCardAnfitrion(
                      reserva: reservaInfo,
                      esVigente: false,
                    ),
                  );
                }, childCount: reservasPasadas.length),
              ),
            ] else ...[
              // Mensaje cuando no hay reservas pasadas
              SliverToBoxAdapter(
                child: _buildMensajeSinReservasPasadas(context),
              ),
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
          Icon(Icons.business, color: color, size: 20),
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

  Widget _buildNoAnfitrionMessage(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 80,
              color: const Color(0xFF757575),
            ),
            const SizedBox(height: 24),
            Text(
              'Conviértete en Anfitrión',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Para ver reservas en tus propiedades, ve a la pantalla "Anfitrión" y solicita convertirte en anfitrión.',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF424242),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinReservasMessage(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF4CAF50),
      child: CustomScrollView(
        slivers: [
          // Sección de reservas vigentes (siempre mostrar)
          SliverToBoxAdapter(
            child: _buildSeccionHeader(
              'Reservas Vigentes',
              0,
              const Color(0xFF4CAF50),
            ),
          ),

          // Mensaje cuando no hay reservas vigentes
          SliverToBoxAdapter(child: _buildMensajeSinReservasVigentes(context)),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Sección de reservas pasadas (siempre mostrar)
          SliverToBoxAdapter(
            child: _buildSeccionHeader(
              'Reservas Pasadas',
              0,
              const Color(0xFF81C784),
            ),
          ),

          // Mensaje cuando no hay reservas pasadas
          SliverToBoxAdapter(child: _buildMensajeSinReservasPasadas(context)),

          // Espacio adicional al final
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildMensajeSinReservasVigentes(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: const Color(0xFF757575),
          ),
          const SizedBox(height: 16),
          Text(
            'Todavía no se registran reservas',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando tengas reservas vigentes, aparecerán aquí',
            style: const TextStyle(fontSize: 14, color: Color(0xFF424242)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMensajeSinReservasPasadas(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF81C784).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.history, size: 48, color: const Color(0xFF757575)),
          const SizedBox(height: 16),
          Text(
            'Todavía no se registran reservas',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando completes reservas, aparecerán aquí',
            style: const TextStyle(fontSize: 14, color: Color(0xFF424242)),
            textAlign: TextAlign.center,
          ),
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
            Icon(Icons.error_outline, size: 80, color: const Color(0xFF757575)),
            const SizedBox(height: 24),
            Text(
              'Error al Cargar',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Hubo un problema al cargar tus reservas. Intenta nuevamente.',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF424242),
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
                backgroundColor: const Color(0xFF4CAF50),
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
