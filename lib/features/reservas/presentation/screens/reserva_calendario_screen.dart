import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:donde_caigav2/main.dart';
import 'package:donde_caigav2/features/propiedades/data/models/propiedad.dart';
import 'package:donde_caigav2/features/reservas/data/repositories/reserva_repository.dart';

class ReservaCalendarioScreen extends StatefulWidget {
  final Propiedad propiedad;

  const ReservaCalendarioScreen({super.key, required this.propiedad});

  @override
  State<ReservaCalendarioScreen> createState() =>
      _ReservaCalendarioScreenState();
}

class _ReservaCalendarioScreenState extends State<ReservaCalendarioScreen> {
  late final ReservaRepository _reservaRepository;

  DateTime _focusedDay = DateTime.now();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  List<DateTime> _fechasOcupadas = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _reservaRepository = ReservaRepository(supabase);
    _cargarFechasOcupadas();
  }

  Future<void> _cargarFechasOcupadas() async {
    setState(() => _isLoading = true);

    try {
      final fechas = await _reservaRepository.obtenerFechasOcupadas(
        widget.propiedad.id,
      );
      setState(() {
        _fechasOcupadas = fechas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  bool _esFechaOcupada(DateTime fecha) {
    return _fechasOcupadas.any(
      (ocupada) =>
          ocupada.year == fecha.year &&
          ocupada.month == fecha.month &&
          ocupada.day == fecha.day,
    );
  }

  bool _esFechaSeleccionable(DateTime fecha) {
    final hoy = DateTime.now();
    final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);

    if (fechaSinHora.isBefore(hoySinHora)) {
      return false;
    }

    if (_esFechaOcupada(fecha)) {
      return false;
    }

    return true;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // Verificar si la fecha está ocupada
    if (_esFechaOcupada(selectedDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta fecha ya está reservada. Por favor selecciona otra fecha.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return; // No permitir selección
    }

    // Verificar si es seleccionable (fecha pasada)
    if (!_esFechaSeleccionable(selectedDay)) {
      return;
    }

    setState(() {
      _focusedDay = focusedDay;

      if (_fechaInicio == null || (_fechaInicio != null && _fechaFin != null)) {
        _fechaInicio = selectedDay;
        _fechaFin = null;
      } else if (selectedDay.isBefore(_fechaInicio!)) {
        _fechaInicio = selectedDay;
        _fechaFin = null;
      } else {
        bool hayFechasOcupadas = false;
        for (
          var fecha = _fechaInicio!;
          fecha.isBefore(selectedDay) || fecha.isAtSameMomentAs(selectedDay);
          fecha = fecha.add(const Duration(days: 1))
        ) {
          if (_esFechaOcupada(fecha)) {
            hayFechasOcupadas = true;
            break;
          }
        }

        if (hayFechasOcupadas) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hay fechas ocupadas en el rango seleccionado'),
              backgroundColor: Colors.orange,
            ),
          );
          _fechaInicio = selectedDay;
          _fechaFin = null;
        } else {
          _fechaFin = selectedDay;
        }
      }
    });
  }

  Future<void> _crearReserva() async {
    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona las fechas de inicio y fin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // PASO 1: Verificar si el usuario tiene reservas activas
      final tieneReservasActivas = await _reservaRepository
          .verificarReservasActivas(user.id);

      if (tieneReservasActivas) {
        throw Exception(
          'Ya tienes una reserva activa. Completa tu reserva actual antes de crear una nueva.',
        );
      }

      // PASO 2: Verificar disponibilidad de fechas
      final disponible = await _reservaRepository.verificarDisponibilidad(
        propiedadId: widget.propiedad.id,
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin!,
      );

      if (!disponible) {
        throw Exception(
          'Las fechas seleccionadas no están disponibles. Por favor selecciona otras fechas.',
        );
      }

      // PASO 3: Crear reserva
      await _reservaRepository.crearReserva(
        propiedadId: widget.propiedad.id,
        viajeroId: user.id,
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Reserva creada! Espera la confirmación del anfitrión',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final duracion = _fechaInicio != null && _fechaFin != null
        ? _fechaFin!.difference(_fechaInicio!).inDays + 1
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservar Alojamiento'),
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.propiedad.fotoPrincipalUrl != null
                            ? Image.network(
                                widget.propiedad.fotoPrincipalUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.home),
                                  );
                                },
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.home),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.propiedad.titulo,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.propiedad.ciudad != null)
                              Text(
                                widget.propiedad.ciudad!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Selecciona las fechas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TableCalendar(
                          firstDay: DateTime.now(),
                          lastDay: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) {
                            if (_fechaInicio != null && _fechaFin != null) {
                              return day.isAfter(
                                    _fechaInicio!.subtract(
                                      const Duration(days: 1),
                                    ),
                                  ) &&
                                  day.isBefore(
                                    _fechaFin!.add(const Duration(days: 1)),
                                  );
                            }
                            return isSameDay(_fechaInicio, day);
                          },
                          onDaySelected: _onDaySelected,
                          calendarBuilders: CalendarBuilders(
                            // Builder para días deshabilitados (fechas ocupadas)
                            disabledBuilder: (context, day, focusedDay) {
                              // Solo aplicar estilo rojo si está ocupada
                              // (no a fechas pasadas)
                              if (_esFechaOcupada(day)) {
                                return Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${day.day}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return null; // Usar estilo por defecto para fechas pasadas
                            },
                          ),
                          calendarStyle: const CalendarStyle(
                            selectedDecoration: BoxDecoration(
                              color: Color(0xFF4DB6AC),
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: Color(0xFF80CBC4),
                              shape: BoxShape.circle,
                            ),
                          ),
                          enabledDayPredicate: _esFechaSeleccionable,
                        ),

                        if (_fechaInicio != null)
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Inicio',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(_fechaInicio!),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.grey[600],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Fin',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _fechaFin != null
                                              ? DateFormat(
                                                  'dd/MM/yyyy',
                                                ).format(_fechaFin!)
                                              : 'Selecciona',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: _fechaFin != null
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: _fechaFin != null
                                                ? Colors.black
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (duracion > 0) ...[
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Duración',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        '$duracion ${duracion == 1 ? 'día' : 'días'}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4DB6AC),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

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
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isCreating ||
                                _fechaInicio == null ||
                                _fechaFin == null
                            ? null
                            : _crearReserva,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4DB6AC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isCreating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                duracion > 0
                                    ? 'Confirmar Reserva ($duracion ${duracion == 1 ? 'día' : 'días'})'
                                    : 'Selecciona las fechas',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
