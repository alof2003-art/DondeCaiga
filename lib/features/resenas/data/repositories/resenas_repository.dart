import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resena.dart';

class ResenasRepository {
  final SupabaseClient _supabase;

  ResenasRepository(this._supabase);

  /// Obtener reseñas recibidas por un usuario (como anfitrión)
  Future<List<Resena>> getResenasRecibidas(String userId) async {
    try {
      final response = await _supabase
          .from('resenas')
          .select('''
            *,
            propiedades!inner(
              id,
              titulo,
              anfitrion_id,
              users_profiles!propiedades_anfitrion_id_fkey(
                nombre,
                foto_perfil_url
              )
            ),
            users_profiles!resenas_viajero_id_fkey(
              nombre,
              foto_perfil_url
            )
          ''')
          .eq('propiedades.anfitrion_id', userId)
          .order('created_at', ascending: false);

      return response.map<Resena>((json) {
        final propiedad = json['propiedades'] as Map<String, dynamic>;
        final viajero = json['users_profiles'] as Map<String, dynamic>?;
        // final anfitrion = propiedad['users_profiles'] as Map<String, dynamic>?; // No usado

        return Resena(
          id: json['id'] as String,
          reservaId: json['reserva_id'] as String? ?? '',
          viajeroId: json['viajero_id'] as String,
          anfitrionId: propiedad['anfitrion_id'] as String,
          propiedadId: json['propiedad_id'] as String,
          calificacion: json['calificacion'] as int,
          comentario: json['comentario'] as String?,
          fechaCreacion: DateTime.parse(json['created_at'] as String),
          nombreViajero: viajero?['nombre'] as String? ?? 'Usuario',
          fotoViajero: viajero?['foto_perfil_url'] as String?,
          tituloPropiedad: propiedad['titulo'] as String? ?? 'Propiedad',
        );
      }).toList();
    } catch (e) {
      // En caso de error, devolver lista vacía
      return <Resena>[];
    }
  }

  /// Obtener reseñas hechas por un usuario (como viajero)
  Future<List<Resena>> getResenasHechas(String userId) async {
    try {
      final response = await _supabase
          .from('resenas')
          .select('''
            *,
            propiedades(
              id,
              titulo,
              anfitrion_id,
              users_profiles!propiedades_anfitrion_id_fkey(
                nombre,
                foto_perfil_url
              )
            )
          ''')
          .eq('viajero_id', userId)
          .order('created_at', ascending: false);

      return response.map<Resena>((json) {
        final propiedad = json['propiedades'] as Map<String, dynamic>?;
        final anfitrion = propiedad?['users_profiles'] as Map<String, dynamic>?;

        return Resena(
          id: json['id'] as String,
          reservaId: json['reserva_id'] as String? ?? '',
          viajeroId: json['viajero_id'] as String,
          anfitrionId: propiedad?['anfitrion_id'] as String? ?? '',
          propiedadId: json['propiedad_id'] as String,
          calificacion: json['calificacion'] as int,
          comentario: json['comentario'] as String?,
          fechaCreacion: DateTime.parse(json['created_at'] as String),
          nombreViajero: anfitrion?['nombre'] as String? ?? 'Anfitrión',
          fotoViajero: anfitrion?['foto_perfil_url'] as String?,
          tituloPropiedad: propiedad?['titulo'] as String? ?? 'Propiedad',
        );
      }).toList();
    } catch (e) {
      // En caso de error, devolver lista vacía
      return <Resena>[];
    }
  }

  /// Obtener estadísticas de reseñas de un usuario
  Future<Map<String, dynamic>> getEstadisticasResenas(String userId) async {
    try {
      // Obtener reseñas recibidas para calcular promedio
      final resenasRecibidas = await getResenasRecibidas(userId);

      if (resenasRecibidas.isEmpty) {
        return {
          'totalResenas': 0,
          'promedioCalificacion': 0.0,
          'distribucionCalificaciones': <int, int>{
            1: 0,
            2: 0,
            3: 0,
            4: 0,
            5: 0,
          },
        };
      }

      // Calcular promedio
      final totalCalificacion = resenasRecibidas
          .map((r) => r.calificacion)
          .reduce((a, b) => a + b);
      final promedio = totalCalificacion / resenasRecibidas.length;

      // Calcular distribución de calificaciones
      final distribucion = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final resena in resenasRecibidas) {
        distribucion[resena.calificacion] =
            (distribucion[resena.calificacion] ?? 0) + 1;
      }

      return {
        'totalResenas': resenasRecibidas.length,
        'promedioCalificacion': promedio,
        'distribucionCalificaciones': distribucion,
      };
    } catch (e) {
      // En caso de error, devolver estadísticas vacías
      return {
        'totalResenas': 0,
        'promedioCalificacion': 0.0,
        'distribucionCalificaciones': <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }

  /// Obtener reseñas de una propiedad específica
  Future<List<Resena>> getResenasPorPropiedad(String propiedadId) async {
    try {
      final response = await _supabase
          .from('resenas')
          .select('''
            *,
            users_profiles!resenas_viajero_id_fkey(
              nombre,
              foto_perfil_url
            ),
            propiedades(titulo)
          ''')
          .eq('propiedad_id', propiedadId)
          .order('created_at', ascending: false);

      return response.map<Resena>((json) {
        final viajero = json['users_profiles'] as Map<String, dynamic>?;
        final propiedad = json['propiedades'] as Map<String, dynamic>?;

        return Resena(
          id: json['id'] as String,
          reservaId: json['reserva_id'] as String? ?? '',
          viajeroId: json['viajero_id'] as String,
          anfitrionId: '', // Se puede obtener de la propiedad si es necesario
          propiedadId: json['propiedad_id'] as String,
          calificacion: json['calificacion'] as int,
          comentario: json['comentario'] as String?,
          fechaCreacion: DateTime.parse(json['created_at'] as String),
          nombreViajero: viajero?['nombre'] as String? ?? 'Usuario',
          fotoViajero: viajero?['foto_perfil_url'] as String?,
          tituloPropiedad: propiedad?['titulo'] as String? ?? 'Propiedad',
        );
      }).toList();
    } catch (e) {
      return <Resena>[];
    }
  }
}
