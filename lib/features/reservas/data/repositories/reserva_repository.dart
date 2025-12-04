import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reserva.dart';

class ReservaRepository {
  final SupabaseClient _supabase;

  ReservaRepository(this._supabase);

  /// Crear una nueva reserva
  Future<String> crearReserva({
    required String propiedadId,
    required String viajeroId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final response = await _supabase
        .from('reservas')
        .insert({
          'propiedad_id': propiedadId,
          'viajero_id': viajeroId,
          'fecha_inicio': fechaInicio.toIso8601String(),
          'fecha_fin': fechaFin.toIso8601String(),
          'estado': 'pendiente',
        })
        .select()
        .single();

    return response['id'] as String;
  }

  /// Obtener fechas ocupadas de una propiedad
  Future<List<DateTime>> obtenerFechasOcupadas(String propiedadId) async {
    final response = await _supabase
        .from('reservas')
        .select('fecha_inicio, fecha_fin')
        .eq('propiedad_id', propiedadId)
        .inFilter('estado', ['pendiente', 'confirmada']);

    final List<DateTime> fechasOcupadas = [];

    for (final reserva in response as List) {
      final inicio = DateTime.parse(reserva['fecha_inicio'] as String);
      final fin = DateTime.parse(reserva['fecha_fin'] as String);

      // Agregar todas las fechas entre inicio y fin
      for (
        var fecha = inicio;
        fecha.isBefore(fin) || fecha.isAtSameMomentAs(fin);
        fecha = fecha.add(const Duration(days: 1))
      ) {
        fechasOcupadas.add(DateTime(fecha.year, fecha.month, fecha.day));
      }
    }

    return fechasOcupadas;
  }

  /// Verificar si hay conflicto de fechas
  Future<bool> verificarDisponibilidad({
    required String propiedadId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final response = await _supabase
        .from('reservas')
        .select('id')
        .eq('propiedad_id', propiedadId)
        .inFilter('estado', ['pendiente', 'confirmada'])
        .or(
          'fecha_inicio.lte.${fechaFin.toIso8601String()},fecha_fin.gte.${fechaInicio.toIso8601String()}',
        );

    return (response as List).isEmpty;
  }

  /// Obtener reservas de un viajero
  Future<List<Reserva>> obtenerReservasViajero(String viajeroId) async {
    final response = await _supabase
        .from('reservas')
        .select('''
          *,
          propiedades!reservas_propiedad_id_fkey(
            titulo,
            foto_principal_url,
            anfitrion_id,
            users_profiles!propiedades_anfitrion_id_fkey(nombre, foto_perfil_url)
          )
        ''')
        .eq('viajero_id', viajeroId)
        .eq('estado', 'confirmada')
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final reserva = Map<String, dynamic>.from(json);
      final propiedad = json['propiedades'];

      if (propiedad != null) {
        reserva['titulo_propiedad'] = propiedad['titulo'];
        reserva['foto_principal_propiedad'] = propiedad['foto_principal_url'];
        reserva['anfitrion_id'] = propiedad['anfitrion_id'];

        final anfitrion = propiedad['users_profiles'];
        if (anfitrion != null) {
          reserva['nombre_anfitrion'] = anfitrion['nombre'];
          reserva['foto_anfitrion'] = anfitrion['foto_perfil_url'];
        }
      }

      return Reserva.fromJson(reserva);
    }).toList();
  }

  /// Obtener reservas de un anfitrión (por sus propiedades)
  Future<List<Reserva>> obtenerReservasAnfitrion(String anfitrionId) async {
    // Primero obtener las propiedades del anfitrión
    final propiedadesResponse = await _supabase
        .from('propiedades')
        .select('id')
        .eq('anfitrion_id', anfitrionId);

    final propiedadIds = (propiedadesResponse as List)
        .map((p) => p['id'] as String)
        .toList();

    if (propiedadIds.isEmpty) {
      return [];
    }

    // Luego obtener las reservas de esas propiedades
    final response = await _supabase
        .from('reservas')
        .select('''
          *,
          propiedades!reservas_propiedad_id_fkey(titulo, foto_principal_url),
          users_profiles!reservas_viajero_id_fkey(nombre, foto_perfil_url)
        ''')
        .inFilter('propiedad_id', propiedadIds)
        .eq('estado', 'confirmada')
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final reserva = Map<String, dynamic>.from(json);
      final propiedad = json['propiedades'];
      final viajero = json['users_profiles'];

      if (propiedad != null) {
        reserva['titulo_propiedad'] = propiedad['titulo'];
        reserva['foto_principal_propiedad'] = propiedad['foto_principal_url'];
      }

      if (viajero != null) {
        reserva['nombre_viajero'] = viajero['nombre'];
        reserva['foto_viajero'] = viajero['foto_perfil_url'];
      }

      return Reserva.fromJson(reserva);
    }).toList();
  }

  /// Actualizar estado de una reserva
  Future<void> actualizarEstadoReserva(
    String reservaId,
    String nuevoEstado,
  ) async {
    await _supabase
        .from('reservas')
        .update({'estado': nuevoEstado})
        .eq('id', reservaId);
  }

  /// Obtener una reserva por ID
  Future<Reserva?> obtenerReserva(String reservaId) async {
    try {
      final response = await _supabase
          .from('reservas')
          .select('''
            *,
            propiedades!reservas_propiedad_id_fkey(
              titulo,
              foto_principal_url,
              anfitrion_id,
              users_profiles!propiedades_anfitrion_id_fkey(nombre, foto_perfil_url)
            ),
            users_profiles!reservas_viajero_id_fkey(nombre, foto_perfil_url)
          ''')
          .eq('id', reservaId)
          .single();

      final reserva = Map<String, dynamic>.from(response);
      final propiedad = response['propiedades'];
      final viajero = response['users_profiles'];

      if (propiedad != null) {
        reserva['titulo_propiedad'] = propiedad['titulo'];
        reserva['foto_principal_propiedad'] = propiedad['foto_principal_url'];
        reserva['anfitrion_id'] = propiedad['anfitrion_id'];

        final anfitrion = propiedad['users_profiles'];
        if (anfitrion != null) {
          reserva['nombre_anfitrion'] = anfitrion['nombre'];
          reserva['foto_anfitrion'] = anfitrion['foto_perfil_url'];
        }
      }

      if (viajero != null) {
        reserva['nombre_viajero'] = viajero['nombre'];
        reserva['foto_viajero'] = viajero['foto_perfil_url'];
      }

      return Reserva.fromJson(reserva);
    } catch (e) {
      return null;
    }
  }
}
