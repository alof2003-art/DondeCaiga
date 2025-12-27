import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resena.dart';

class ResenaRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener reseñas de una propiedad
  Future<List<Resena>> obtenerResenasPorPropiedad(String propiedadId) async {
    try {
      final response = await _supabase
          .from('resenas')
          .select('''
            *,
            viajero:users_profiles!viajero_id(
              nombre,
              foto_perfil_url
            )
          ''')
          .eq('propiedad_id', propiedadId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final viajero = json['viajero'];
        return Resena.fromJson({
          ...json,
          'nombre_viajero': viajero?['nombre'],
          'foto_perfil_viajero': viajero?['foto_perfil_url'],
        });
      }).toList();
    } catch (e) {
      print('Error al obtener reseñas: $e');
      rethrow;
    }
  }

  // Verificar si el usuario puede dejar reseña (tiene reserva confirmada o completada)
  Future<bool> puedeDejarResena(String viajeroId, String propiedadId) async {
    try {
      // Verificar si ya dejó reseña
      final resenaExistente = await _supabase
          .from('resenas')
          .select('id')
          .eq('viajero_id', viajeroId)
          .eq('propiedad_id', propiedadId)
          .maybeSingle();

      if (resenaExistente != null) {
        return false; // Ya dejó reseña
      }

      // Verificar si tiene reserva confirmada o completada
      final reserva = await _supabase
          .from('reservas')
          .select('id')
          .eq('viajero_id', viajeroId)
          .eq('propiedad_id', propiedadId)
          .inFilter('estado', ['confirmada', 'completada'])
          .maybeSingle();

      return reserva != null;
    } catch (e) {
      print('Error al verificar si puede dejar reseña: $e');
      return false;
    }
  }

  // Obtener reserva del usuario para una propiedad (para asociar la reseña)
  Future<String?> obtenerReservaId(String viajeroId, String propiedadId) async {
    try {
      final reserva = await _supabase
          .from('reservas')
          .select('id')
          .eq('viajero_id', viajeroId)
          .eq('propiedad_id', propiedadId)
          .inFilter('estado', ['confirmada', 'completada'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return reserva?['id'] as String?;
    } catch (e) {
      print('Error al obtener reserva: $e');
      return null;
    }
  }

  // Crear reseña
  Future<void> crearResena({
    required String propiedadId,
    required String viajeroId,
    String? reservaId,
    required double calificacion,
    String? comentario,
  }) async {
    try {
      await _supabase.from('resenas').insert({
        'propiedad_id': propiedadId,
        'viajero_id': viajeroId,
        'reserva_id': reservaId,
        'calificacion': calificacion,
        'comentario': comentario,
      });
    } catch (e) {
      print('Error al crear reseña: $e');
      rethrow;
    }
  }

  // Obtener promedio de calificaciones de una propiedad
  Future<double> obtenerPromedioCalificacion(String propiedadId) async {
    try {
      final response = await _supabase
          .from('resenas')
          .select('calificacion')
          .eq('propiedad_id', propiedadId);

      if (response.isEmpty) return 0.0;

      final calificaciones = (response as List)
          .map((r) => (r['calificacion'] as num).toDouble())
          .toList();

      final suma = calificaciones.reduce((a, b) => a + b);
      return suma / calificaciones.length;
    } catch (e) {
      print('Error al obtener promedio: $e');
      return 0.0;
    }
  }

  // Obtener cantidad de reseñas de una propiedad
  Future<int> obtenerCantidadResenas(String propiedadId) async {
    try {
      final response = await _supabase
          .from('resenas')
          .select('id')
          .eq('propiedad_id', propiedadId);

      return (response as List).length;
    } catch (e) {
      print('Error al obtener cantidad de reseñas: $e');
      return 0;
    }
  }
}
