import 'package:flutter/material.dart';
import '../../data/models/notificacion.dart';

class FiltroNotificacionesWidget extends StatefulWidget {
  final FiltroNotificaciones filtroActual;
  final Function(FiltroNotificaciones) onFiltroAplicado;

  const FiltroNotificacionesWidget({
    super.key,
    required this.filtroActual,
    required this.onFiltroAplicado,
  });

  @override
  State<FiltroNotificacionesWidget> createState() =>
      _FiltroNotificacionesWidgetState();
}

class _FiltroNotificacionesWidgetState
    extends State<FiltroNotificacionesWidget> {
  late Set<TipoNotificacion> _tiposSeleccionados;
  late bool _soloNoLeidas;

  @override
  void initState() {
    super.initState();
    _tiposSeleccionados = Set.from(widget.filtroActual.tiposSeleccionados);
    _soloNoLeidas = widget.filtroActual.soloNoLeidas;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtrar notificaciones',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Solo no leídas
          SwitchListTile(
            title: const Text('Solo no leídas'),
            subtitle: const Text('Mostrar únicamente notificaciones sin leer'),
            value: _soloNoLeidas,
            onChanged: (value) {
              setState(() {
                _soloNoLeidas = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // Tipos de notificación
          Text(
            'Tipos de notificación',
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 8),

          // Lista de tipos
          ...TipoNotificacion.values.map(
            (tipo) => CheckboxListTile(
              title: Text(tipo.titulo),
              subtitle: Text(tipo.descripcion),
              value: _tiposSeleccionados.contains(tipo),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _tiposSeleccionados.add(tipo);
                  } else {
                    _tiposSeleccionados.remove(tipo);
                  }
                });
              },
              secondary: Icon(_getIconoTipo(tipo), color: _getColorTipo(tipo)),
            ),
          ),

          const SizedBox(height: 24),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _limpiarFiltros,
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _aplicarFiltros,
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _limpiarFiltros() {
    setState(() {
      _tiposSeleccionados.clear();
      _soloNoLeidas = false;
    });
  }

  void _aplicarFiltros() {
    final filtro = widget.filtroActual.copyWith(
      tiposSeleccionados: _tiposSeleccionados,
      soloNoLeidas: _soloNoLeidas,
    );

    widget.onFiltroAplicado(filtro);
    Navigator.pop(context);
  }

  IconData _getIconoTipo(TipoNotificacion tipo) {
    switch (tipo) {
      case TipoNotificacion.solicitudReserva:
        return Icons.home;
      case TipoNotificacion.reservaAceptada:
        return Icons.check_circle;
      case TipoNotificacion.reservaRechazada:
        return Icons.cancel;
      case TipoNotificacion.nuevaResena:
        return Icons.star;
      case TipoNotificacion.solicitudAnfitrion:
        return Icons.person_add;
      case TipoNotificacion.anfitrionAceptado:
        return Icons.verified_user;
      case TipoNotificacion.anfitrionRechazado:
        return Icons.person_remove;
      case TipoNotificacion.nuevoMensaje:
        return Icons.message;
      case TipoNotificacion.llegadaHuesped:
        return Icons.login;
      case TipoNotificacion.finEstadia:
        return Icons.logout;
      case TipoNotificacion.recordatorioCheckin:
        return Icons.schedule;
      case TipoNotificacion.recordatorioCheckout:
        return Icons.schedule_send;
      case TipoNotificacion.general:
        return Icons.info;
    }
  }

  Color _getColorTipo(TipoNotificacion tipo) {
    switch (tipo) {
      case TipoNotificacion.solicitudReserva:
        return Colors.blue;
      case TipoNotificacion.reservaAceptada:
      case TipoNotificacion.anfitrionAceptado:
        return Colors.green;
      case TipoNotificacion.reservaRechazada:
      case TipoNotificacion.anfitrionRechazado:
        return Colors.red;
      case TipoNotificacion.nuevaResena:
        return Colors.amber;
      case TipoNotificacion.solicitudAnfitrion:
        return Colors.purple;
      case TipoNotificacion.nuevoMensaje:
        return Colors.teal;
      case TipoNotificacion.llegadaHuesped:
        return Colors.indigo;
      case TipoNotificacion.finEstadia:
        return Colors.orange;
      case TipoNotificacion.recordatorioCheckin:
      case TipoNotificacion.recordatorioCheckout:
        return Colors.brown;
      case TipoNotificacion.general:
        return Colors.grey;
    }
  }
}
