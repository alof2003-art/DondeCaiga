import 'package:flutter/material.dart';
import '../../data/models/filtro_explorar.dart';

class FiltrosExplorarDialog extends StatefulWidget {
  final FiltroExplorar filtroInicial;
  final Function(FiltroExplorar) onFiltroAplicado;

  const FiltrosExplorarDialog({
    super.key,
    required this.filtroInicial,
    required this.onFiltroAplicado,
  });

  @override
  State<FiltrosExplorarDialog> createState() => _FiltrosExplorarDialogState();
}

class _FiltrosExplorarDialogState extends State<FiltrosExplorarDialog> {
  late FiltroExplorar _filtroTemporal;

  @override
  void initState() {
    super.initState();
    _filtroTemporal = widget.filtroInicial;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: screenWidth * 0.9,
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: screenHeight * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header fijo
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Contenido scrolleable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ordenamiento
                    _buildSeccionOrdenamiento(),
                    const SizedBox(height: 20),

                    // Características
                    _buildSeccionCaracteristicas(),
                    const SizedBox(height: 20),

                    // Calificación
                    _buildSeccionCalificacion(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Botones fijos en la parte inferior
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: _buildBotones(),
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
        const Text(
          'Ordenar por',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: OrdenExplorar.values.map((orden) {
            final isSelected = _filtroTemporal.orden == orden;
            return FilterChip(
              label: Text(orden.nombre),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filtroTemporal = _filtroTemporal.copyWith(
                    orden: selected ? orden : null,
                    limpiarOrden: !selected,
                  );
                });
              },
              backgroundColor: Colors.grey[100],
              selectedColor: const Color(0xFF4DB6AC).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFF4DB6AC),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF4DB6AC) : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? const Color(0xFF4DB6AC) : Colors.grey[300]!,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSeccionCaracteristicas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Características',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // Solo con garaje
        _buildCheckboxCompacto(
          'Solo con garaje',
          'Incluyen estacionamiento',
          _filtroTemporal.soloConGaraje ?? false,
          (value) {
            setState(() {
              _filtroTemporal = _filtroTemporal.copyWith(
                soloConGaraje: value,
                limpiarGaraje: value == false,
              );
            });
          },
        ),

        const SizedBox(height: 8),

        // Solo nuevos (menos de 1 mes)
        _buildCheckboxCompacto(
          'Solo nuevos',
          'Agregadas en el último mes',
          _filtroTemporal.soloNuevos ?? false,
          (value) {
            setState(() {
              _filtroTemporal = _filtroTemporal.copyWith(
                soloNuevos: value,
                limpiarNuevos: value == false,
              );
            });
          },
        ),

        const SizedBox(height: 16),

        // Habitaciones mínimas
        _buildSliderCompacto(
          'Habitaciones mínimas',
          _filtroTemporal.habitacionesMinimas?.toDouble() ?? 1.0,
          1.0,
          6.0,
          (value) {
            setState(() {
              _filtroTemporal = _filtroTemporal.copyWith(
                habitacionesMinimas: value.round(),
              );
            });
          },
          (value) => '${value.round()} hab.',
        ),

        const SizedBox(height: 12),

        // Baños mínimos
        _buildSliderCompacto(
          'Baños mínimos',
          _filtroTemporal.banosMinimos?.toDouble() ?? 1.0,
          1.0,
          4.0,
          (value) {
            setState(() {
              _filtroTemporal = _filtroTemporal.copyWith(
                banosMinimos: value.round(),
              );
            });
          },
          (value) => '${value.round()} baño${value.round() > 1 ? 's' : ''}',
        ),
      ],
    );
  }

  Widget _buildSeccionCalificacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calificación mínima',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildSliderCompacto(
          '',
          _filtroTemporal.calificacionMinima ?? 1.0,
          1.0,
          5.0,
          (value) {
            setState(() {
              _filtroTemporal = _filtroTemporal.copyWith(
                calificacionMinima: value,
              );
            });
          },
          (value) => '${value.toStringAsFixed(1)} ⭐',
          showTitle: false,
        ),
      ],
    );
  }

  Widget _buildBotones() {
    return Row(
      children: [
        // Limpiar filtros
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _filtroTemporal = FiltroExplorar.vacio();
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4DB6AC)),
              foregroundColor: const Color(0xFF4DB6AC),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Limpiar'),
          ),
        ),

        const SizedBox(width: 12),

        // Aplicar filtros
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () {
              widget.onFiltroAplicado(_filtroTemporal);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DB6AC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              _filtroTemporal.tienesFiltrosAplicados
                  ? 'Aplicar (${_filtroTemporal.numeroFiltrosActivos})'
                  : 'Aplicar',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxCompacto(
    String titulo,
    String subtitulo,
    bool valor,
    Function(bool?) onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!valor),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Checkbox(
              value: valor,
              onChanged: onChanged,
              activeColor: const Color(0xFF4DB6AC),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderCompacto(
    String title,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    String Function(double) labelFormatter, {
    bool showTitle = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle && title.isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: (max - min).round(),
                  onChanged: onChanged,
                  activeColor: const Color(0xFF4DB6AC),
                  inactiveColor: Colors.grey[300],
                ),
              ),
            ),
            Container(
              width: 70,
              alignment: Alignment.centerRight,
              child: Text(
                labelFormatter(value),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4DB6AC),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
