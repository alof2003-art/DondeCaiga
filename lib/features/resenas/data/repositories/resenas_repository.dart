import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resena.dart';
import '../models/resena_viajero.dart';

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
        final anfitrion = propiedad['users_profiles'] as Map<String, dynamic>?;

        return Resena(
          id: json['id'] as String,
          reservaId: json['reserva_id'] as String? ?? '',
          viajeroId: json['viajero_id'] as String,
          anfitrionId: propiedad['anfitrion_id'] as String,
          propiedadId: json['propiedad_id'] as String,
          calificacion: (json['calificacion'] as num).toDouble(),
          comentario: json['comentario'] as String?,
          fechaCreacion: DateTime.parse(json['created_at'] as String),
          nombreViajero: viajero?['nombre'] as String? ?? 'Usuario',
          fotoViajero: viajero?['foto_perfil_url'] as String?,
          tituloPropiedad: propiedad['titulo'] as String? ?? 'Propiedad',
          nombreAnfitrion: anfitrion?['nombre'] as String?,
          fotoAnfitrion: anfitrion?['foto_perfil_url'] as String?,
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
          calificacion: (json['calificacion'] as num).toDouble(),
          comentario: json['comentario'] as String?,
          fechaCreacion: DateTime.parse(json['created_at'] as String),
          nombreViajero: 'Yo', // El usuario actual es el viajero
          fotoViajero: null, // No necesitamos la foto del usuario actual
          tituloPropiedad: propiedad?['titulo'] as String? ?? 'Propiedad',
          nombreAnfitrion: anfitrion?['nombre'] as String? ?? 'Anfitrión',
          fotoAnfitrion: anfitrion?['foto_perfil_url'] as String?,
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
        final calificacionRedondeada = resena.calificacion.round();
        distribucion[calificacionRedondeada] =
            (distribucion[calificacionRedondeada] ?? 0) + 1;
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
          calificacion: (json['calificacion'] as num).toDouble(),
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

  // =====================================================
  // FUNCIONES PARA RESEÑAS DE VIAJEROS
  // =====================================================

  /// Obtener reseñas recibidas por un usuario como viajero
  Future<List<ResenaViajero>> getResenasViajerosRecibidas(String userId) async {
    try {
      final response = await _supabase
          .from('resenas_viajeros')
          .select('''
            *,
            users_profiles!resenas_viajeros_viajero_id_fkey(
              nombre,
              foto_perfil_url
            ),
            anfitrion:users_profiles!resenas_viajeros_anfitrion_id_fkey(
              nombre,
              foto_perfil_url
            ),
            reservas(
              propiedades(titulo)
            )
          ''')
          .eq('viajero_id', userId)
          .order('created_at', ascending: false);

      return response.map<ResenaViajero>((json) {
        final viajero = json['users_profiles'] as Map<String, dynamic>?;
        final anfitrion = json['anfitrion'] as Map<String, dynamic>?;
        final reserva = json['reservas'] as Map<String, dynamic>?;
        final propiedad = reserva?['propiedades'] as Map<String, dynamic>?;

        return ResenaViajero(
          id: json['id'] as String,
          reservaId: json['reserva_id'] as String,
          viajeroId: json['viajero_id'] as String,
          anfitrionId: json['anfitrion_id'] as String,
          calificacion: (json['calificacion'] as num).toDouble(),
          comentario: json['comentario'] as String?,
          aspectos: json['aspectos'] != null
              ? Map<String, int?>.from(json['aspectos'] as Map)
              : null,
          fechaCreacion: DateTime.parse(json['created_at'] as String),
          nombreViajero: viajero?['nombre'] as String? ?? 'Usuario',
          fotoViajero: viajero?['foto_perfil_url'] as String?,
          nombreAnfitrion: anfitrion?['nombre'] as String? ?? 'Anfitrión',
          fotoAnfitrion: anfitrion?['foto_perfil_url'] as String?,
          tituloPropiedad: propiedad?['titulo'] as String? ?? 'Propiedad',
        );
      }).toList();
    } catch (e) {
      return <ResenaViajero>[];
    }
  }

  /// Obtener reseñas hechas por un usuario a viajeros (como anfitrión)
  Future<List<ResenaViajero>> getResenasViajerosHechas(String userId) async {
    try {
      final response = await _supabase
          .from('resenas_viajeros')
          .select('''
            *,
            viajero:users_profiles!resenas_viajeros_viajero_id_fkey(
              nombre,
              foto_perfil_url
            ),
            users_profiles!resenas_viajeros_anfitrion_id_fkey(
              nombre,
              foto_perfil_url
            ),
            reservas(
              propiedades(titulo)
            )
          ''')
          .eq('anfitrion_id', userId)
          .order('created_at', ascending: false);

      return response.map<ResenaViajero>((json) {
        final viajero = json['viajero'] as Map<String, dynamic>?;
        final anfitrion = json['users_profiles'] as Map<String, dynamic>?;
        final reserva = json['reservas'] as Map<String, dynamic>?;
        final propiedad = reserva?['propiedades'] as Map<String, dynamic>?;

        return ResenaViajero(
          id: json['id'] as String,
          reservaId: json['reserva_id'] as String,
          viajeroId: json['viajero_id'] as String,
          anfitrionId: json['anfitrion_id'] as String,
          calificacion: (json['calificacion'] as num).toDouble(),
          comentario: json['comentario'] as String?,
          aspectos: json['aspectos'] != null
              ? Map<String, int?>.from(json['aspectos'] as Map)
              : null,
          fechaCreacion: DateTime.parse(json['created_at'] as String),
          nombreViajero: viajero?['nombre'] as String? ?? 'Usuario',
          fotoViajero: viajero?['foto_perfil_url'] as String?,
          nombreAnfitrion: anfitrion?['nombre'] as String? ?? 'Anfitrión',
          fotoAnfitrion: anfitrion?['foto_perfil_url'] as String?,
          tituloPropiedad: propiedad?['titulo'] as String? ?? 'Propiedad',
        );
      }).toList();
    } catch (e) {
      return <ResenaViajero>[];
    }
  }

  /// Crear una nueva reseña de propiedad
  Future<bool> crearResena(Resena resena) async {
    try {
      await _supabase.from('resenas').insert({
        'propiedad_id': resena.propiedadId,
        'viajero_id': resena.viajeroId,
        'reserva_id': resena.reservaId,
        'calificacion': resena.calificacion,
        'comentario': resena.comentario,
        'aspectos': resena.aspectos,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Crear una nueva reseña de viajero
  Future<bool> crearResenaViajero(ResenaViajero resena) async {
    try {
      await _supabase.from('resenas_viajeros').insert(resena.toInsertJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verificar si se puede reseñar a un viajero
  Future<bool> puedeResenarViajero(String anfitrionId, String reservaId) async {
    try {
      // Primero intentar con la función SQL
      final response = await _supabase.rpc(
        'can_review_traveler',
        params: {'anfitrion_uuid': anfitrionId, 'reserva_uuid': reservaId},
      );
      return response as bool? ?? false;
    } catch (e) {
      // Si falla la función SQL, hacer verificación manual
      try {
        // Verificar que la reserva existe y pertenece al anfitrión
        final reservaResponse = await _supabase
            .from('reservas')
            .select('''
              id,
              fecha_fin,
              estado,
              propiedades!inner(anfitrion_id)
            ''')
            .eq('id', reservaId)
            .eq('propiedades.anfitrion_id', anfitrionId)
            .maybeSingle();

        if (reservaResponse == null) return false;

        // Verificar que la reserva está completada o ya pasó
        final fechaFin = DateTime.parse(reservaResponse['fecha_fin'] as String);
        final estado = reservaResponse['estado'] as String?;
        final yaTermino = fechaFin.isBefore(DateTime.now());
        final estaCompletada = estado == 'completada';

        if (!yaTermino && !estaCompletada) return false;

        // Verificar que no existe ya una reseña
        final resenaExistente = await _supabase
            .from('resenas_viajeros')
            .select('id')
            .eq('reserva_id', reservaId)
            .eq('anfitrion_id', anfitrionId)
            .maybeSingle();

        return resenaExistente == null;
      } catch (e2) {
        return false;
      }
    }
  }

  /// Verificar si se puede reseñar una propiedad
  Future<bool> puedeResenarPropiedad(String viajeroId, String reservaId) async {
    try {
      // Primero intentar con la función SQL
      final response = await _supabase.rpc(
        'can_review_property',
        params: {'viajero_uuid': viajeroId, 'reserva_uuid': reservaId},
      );
      return response as bool? ?? false;
    } catch (e) {
      // Si falla la función SQL, hacer verificación manual
      try {
        // Verificar que la reserva existe y pertenece al viajero
        final reservaResponse = await _supabase
            .from('reservas')
            .select('id, fecha_fin, estado, viajero_id')
            .eq('id', reservaId)
            .eq('viajero_id', viajeroId)
            .maybeSingle();

        if (reservaResponse == null) return false;

        // Verificar que la reserva está completada o ya pasó
        final fechaFin = DateTime.parse(reservaResponse['fecha_fin'] as String);
        final estado = reservaResponse['estado'] as String?;
        final yaTermino = fechaFin.isBefore(DateTime.now());
        final estaCompletada = estado == 'completada';

        if (!yaTermino && !estaCompletada) return false;

        // Verificar que no existe ya una reseña
        final resenaExistente = await _supabase
            .from('resenas')
            .select('id')
            .eq('reserva_id', reservaId)
            .eq('viajero_id', viajeroId)
            .maybeSingle();

        return resenaExistente == null;
      } catch (e2) {
        return false;
      }
    }
  }

  /// Obtener estadísticas completas de reseñas de un usuario
  Future<Map<String, dynamic>> getEstadisticasCompletasResenas(
    String userId,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_user_review_statistics',
        params: {'user_uuid': userId},
      );

      if (response != null && response.isNotEmpty) {
        final stats = response[0] as Map<String, dynamic>;

        // Función helper para convertir distribución a Map<String, dynamic>
        Map<String, dynamic> convertirDistribucion(dynamic dist) {
          if (dist == null) return <String, dynamic>{};
          if (dist is Map<String, dynamic>) return dist;
          if (dist is Map) {
            final Map<String, dynamic> resultado = {};
            dist.forEach((key, value) {
              resultado[key.toString()] = value;
            });
            return resultado;
          }
          return <String, dynamic>{};
        }

        return {
          // Como anfitrión (propiedades)
          'totalResenasRecibidas': stats['total_resenas_propiedades'] ?? 0,
          'promedioRecibidas':
              (stats['calificacion_promedio_propiedades'] ?? 0.0).toDouble(),
          'distribucionPropiedades': convertirDistribucion(
            stats['distribucion_propiedades'],
          ),

          // Como viajero
          'totalResenasComoViajero': stats['total_resenas_como_viajero'] ?? 0,
          'promedioComoViajero':
              (stats['calificacion_promedio_como_viajero'] ?? 0.0).toDouble(),
          'distribucionViajero': convertirDistribucion(
            stats['distribucion_viajero'],
          ),

          // Reseñas hechas
          'totalResenasHechasPropiedades':
              stats['total_resenas_hechas_propiedades'] ?? 0,
          'totalResenasHechasViajeros':
              stats['total_resenas_hechas_viajeros'] ?? 0,
        };
      }

      return {
        'totalResenasRecibidas': 0,
        'promedioRecibidas': 0.0,
        'distribucionPropiedades': <String, dynamic>{},
        'totalResenasComoViajero': 0,
        'promedioComoViajero': 0.0,
        'distribucionViajero': <String, dynamic>{},
        'totalResenasHechasPropiedades': 0,
        'totalResenasHechasViajeros': 0,
      };
    } catch (e) {
      return {
        'totalResenasRecibidas': 0,
        'promedioRecibidas': 0.0,
        'distribucionPropiedades': <String, dynamic>{},
        'totalResenasComoViajero': 0,
        'promedioComoViajero': 0.0,
        'distribucionViajero': <String, dynamic>{},
        'totalResenasHechasPropiedades': 0,
        'totalResenasHechasViajeros': 0,
      };
    }
  }
}
