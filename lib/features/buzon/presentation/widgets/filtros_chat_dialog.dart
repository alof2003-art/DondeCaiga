import 'package:flutter/material.dart';
import '../../data/models/filtro_chat.dart';
import '../../data/models/chat_apartado.dart';

class FiltrosChatDialog extends StatefulWidget {
  final FiltroChat filtroActual;
  final TipoApartado apartado;
  final Function(FiltroChat) onAplicarFiltros;

  const FiltrosChatDialog({
    super.key,
    required this.filtroActual,
    required this.apartado,
    required this.onAplicarFiltros,
  });

  @override
  State<FiltrosChatDialog> createState() => _FiltrosChatDialogState();
}

class _FiltrosChatDialogState extends State<FiltrosChatDialog> {
  late FiltroChat _filtroTemporal;
  late TextEditingController _busquedaController;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _filtroTemporal = widget.filtroActual.copyWith();
    _busquedaController = TextEditingController(
      text: _filtroTemporal.terminoBusqueda,
    );
    _fechaInicio = _filtroTemporal.fechaInicio;
    _fechaFin = _filtroTemporal.fechaFin;
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Color get _colorPrincipal {
    return widget.apartado == TipoApartado.misViajes
        ? const Color(0xFF2196F3)
        : const Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // Contenido scrolleable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Búsqueda por lugar
                    _buildSeccionBusqueda(),

                    const SizedBox(height: 20),

                    // Filtros de fecha
                    _buildSeccionFechas(),

                    const SizedBox(height: 20),

                    // Ordenamiento
                    _buildSeccionOrdenamiento(),

                    const SizedBox(height: 20),

                    // Estado de reservas
                    _buildSeccionEstado(),

                    const SizedBox(height: 20),

                    // Vista previa de resultados
                    _buildVistaPrevia(),
                  ],
                ),
              ),
            ),

            // Botones de acción
            _buildBotonesAccion(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _colorPrincipal,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.apartado.titulo,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionBusqueda() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.search, color: _colorPrincipal, size: 20),
            const SizedBox(width: 8),
            Text(
              'Buscar por lugar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _colorPrincipal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _busquedaController,
          decoration: InputDecoration(
            hintText: 'Nombre del lugar o ciudad...',
            prefixIcon: Icon(Icons.location_on, color: _colorPrincipal),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _colorPrincipal, width: 2),
            ),
          ),
          onChanged: (valor) {
            setState(() {
              _filtroTemporal = _filtroTemporal.copyWith(
                terminoBusqueda: valor,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildSeccionFechas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.date_range, color: _colorPrincipal, size: 20),
            const SizedBox(width: 8),
            Text(
              'Rango de fechas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _colorPrincipal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSelectorFecha(
                'Desde',
                _fechaInicio,
                (fecha) => setState(() {
                  _fechaInicio = fecha;
                  _filtroTemporal = _filtroTemporal.copyWith(
                    fechaInicio: fecha,
                  );
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSelectorFecha(
                'Hasta',
                _fechaFin,
                (fecha) => setState(() {
                  _fechaFin = fecha;
                  _filtroTemporal = _filtroTemporal.copyWith(fechaFin: fecha);
                }),
              ),
            ),
          ],
        ),
        if (_fechaInicio != null || _fechaFin != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _fechaInicio = null;
                _fechaFin = null;
                _filtroTemporal = _filtroTemporal.copyWith(
                  fechaInicio: null,
                  fechaFin: null,
                  limpiarFechas: true,
                );
              });
            },
            icon: const Icon(Icons.clear),
            label: const Text('Limpiar fechas'),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectorFecha(
    String etiqueta,
    DateTime? fecha,
    Function(DateTime?) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final fechaSeleccionada = await showDatePicker(
          context: context,
          initialDate: fecha ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(
                  context,
                ).colorScheme.copyWith(primary: _colorPrincipal),
              ),
              child: child!,
            );
          },
        );
        if (fechaSeleccionada != null) {
          onChanged(fechaSeleccionada);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              etiqueta,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              fecha != null
                  ? '${fecha.day}/${fecha.month}/${fecha.year}'
                  : 'Seleccionar',
              style: TextStyle(
                fontSize: 14,
                color: fecha != null
                    ? (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.87)
                          : Colors.black)
                    : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionOrdenamiento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.sort, color: _colorPrincipal, size: 20),
            const SizedBox(width: 8),
            Text(
              'Ordenar por',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _colorPrincipal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Orden por fecha
        _buildOpcionOrden(
          'Fecha más reciente',
          _filtroTemporal.ordenFecha == OrdenFecha.masReciente,
          () => setState(() {
            _filtroTemporal = _filtroTemporal.copyWith(
              ordenFecha: OrdenFecha.masReciente,
              ordenAlfabetico: false,
            );
          }),
        ),
        _buildOpcionOrden(
          'Fecha más antigua',
          _filtroTemporal.ordenFecha == OrdenFecha.masAntigua,
          () => setState(() {
            _filtroTemporal = _filtroTemporal.copyWith(
              ordenFecha: OrdenFecha.masAntigua,
              ordenAlfabetico: false,
            );
          }),
        ),

        const SizedBox(height: 8),

        // Orden alfabético
        _buildOpcionOrden(
          'Alfabético A-Z',
          _filtroTemporal.ordenAlfabetico == true,
          () => setState(() {
            _filtroTemporal = _filtroTemporal.copyWith(
              ordenAlfabetico: true,
              limpiarOrdenFecha: true,
            );
          }),
        ),
        _buildOpcionOrden(
          'Alfabético Z-A',
          _filtroTemporal.ordenAlfabetico == false,
          () => setState(() {
            _filtroTemporal = _filtroTemporal.copyWith(
              ordenAlfabetico: true,
              ascendente: false,
              limpiarOrdenFecha: true,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildOpcionOrden(
    String titulo,
    bool seleccionado,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: seleccionado ? _colorPrincipal.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: seleccionado
              ? Border.all(color: _colorPrincipal.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              seleccionado
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: seleccionado ? _colorPrincipal : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: TextStyle(
                color: seleccionado
                    ? _colorPrincipal
                    : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.87)
                          : Colors.black87),
                fontWeight: seleccionado ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionEstado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.filter_alt, color: _colorPrincipal, size: 20),
            const SizedBox(width: 8),
            Text(
              'Estado de reservas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _colorPrincipal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _buildOpcionEstado(
          'Todas las reservas',
          _filtroTemporal.estadoFiltro == null,
          () => setState(() {
            _filtroTemporal = _filtroTemporal.copyWith(
              estadoFiltro: null,
              limpiarEstado: true,
            );
          }),
        ),
        _buildOpcionEstado(
          'Solo vigentes',
          _filtroTemporal.estadoFiltro == EstadoFiltro.vigentes,
          () => setState(() {
            _filtroTemporal = _filtroTemporal.copyWith(
              estadoFiltro: EstadoFiltro.vigentes,
            );
          }),
        ),
        _buildOpcionEstado(
          'Solo pasadas',
          _filtroTemporal.estadoFiltro == EstadoFiltro.pasadas,
          () => setState(() {
            _filtroTemporal = _filtroTemporal.copyWith(
              estadoFiltro: EstadoFiltro.pasadas,
            );
          }),
        ),

        // Solo mostrar opción de reseña pendiente para viajeros
        if (widget.apartado == TipoApartado.misViajes)
          _buildOpcionEstado(
            'Pendientes de reseñar',
            _filtroTemporal.estadoFiltro == EstadoFiltro.conResenasPendientes,
            () => setState(() {
              _filtroTemporal = _filtroTemporal.copyWith(
                estadoFiltro: EstadoFiltro.conResenasPendientes,
              );
            }),
          ),
      ],
    );
  }

  Widget _buildOpcionEstado(
    String titulo,
    bool seleccionado,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: seleccionado ? _colorPrincipal.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: seleccionado
              ? Border.all(color: _colorPrincipal.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              seleccionado ? Icons.check_box : Icons.check_box_outline_blank,
              color: seleccionado ? _colorPrincipal : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: TextStyle(
                color: seleccionado
                    ? _colorPrincipal
                    : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.87)
                          : Colors.black87),
                fontWeight: seleccionado ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVistaPrevia() {
    final numeroFiltros = _filtroTemporal.numeroFiltrosActivos;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colorPrincipal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colorPrincipal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: _colorPrincipal, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filtros aplicados',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _colorPrincipal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            numeroFiltros > 0
                ? '$numeroFiltros ${numeroFiltros == 1 ? 'filtro activo' : 'filtros activos'}'
                : 'Sin filtros aplicados',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Botón limpiar
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _filtroTemporal = FiltroChat.vacio();
                  _busquedaController.clear();
                  _fechaInicio = null;
                  _fechaFin = null;
                });
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _colorPrincipal),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Limpiar',
                style: TextStyle(
                  color: _colorPrincipal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Botón aplicar
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                widget.onAplicarFiltros(_filtroTemporal);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorPrincipal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Aplicar Filtros',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
