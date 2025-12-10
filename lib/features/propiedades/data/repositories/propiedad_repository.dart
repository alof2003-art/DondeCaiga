import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/propiedad.dart';

class PropiedadRepository {
  final SupabaseClient _supabase;

  PropiedadRepository(this._supabase);

  /// Crear una nueva propiedad
  Future<String> crearPropiedad({
    required String anfitrionId,
    required String titulo,
    String? descripcion,
    required String direccion,
    String? ciudad,
    String? pais,
    double? latitud,
    double? longitud,
    required int capacidadPersonas,
    int? numeroHabitaciones,
    int? numeroBanos,
    bool tieneGaraje = false,
    String? fotoPrincipalUrl,
  }) async {
    final response = await _supabase
        .from('propiedades')
        .insert({
          'anfitrion_id': anfitrionId,
          'titulo': titulo,
          'descripcion': descripcion,
          'direccion': direccion,
          'ciudad': ciudad,
          'pais': pais,
          'latitud': latitud,
          'longitud': longitud,
          'capacidad_personas': capacidadPersonas,
          'numero_habitaciones': numeroHabitaciones,
          'numero_banos': numeroBanos,
          'tiene_garaje': tieneGaraje,
          'foto_principal_url': fotoPrincipalUrl,
          'estado': 'activo',
        })
        .select()
        .single();

    return response['id'] as String;
  }

  /// Obtener todas las propiedades activas (para Explorar)
  Future<List<Propiedad>> obtenerPropiedadesActivas() async {
    final response = await _supabase.rpc('get_propiedades_con_calificaciones');

    return (response as List).map((json) {
      final propiedad = Map<String, dynamic>.from(json);
      return Propiedad.fromJson(propiedad);
    }).toList();
  }

  /// Obtener propiedades de un anfitrión específico
  Future<List<Propiedad>> obtenerPropiedadesAnfitrion(
    String anfitrionId,
  ) async {
    final response = await _supabase
        .from('propiedades')
        .select()
        .eq('anfitrion_id', anfitrionId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Propiedad.fromJson(json)).toList();
  }

  /// Obtener una propiedad por ID
  Future<Propiedad?> obtenerPropiedad(String propiedadId) async {
    try {
      final response = await _supabase
          .from('propiedades')
          .select('''
            *,
            users_profiles!propiedades_anfitrion_id_fkey(nombre, foto_perfil_url)
          ''')
          .eq('id', propiedadId)
          .single();

      final propiedad = Map<String, dynamic>.from(response);
      final anfitrion = response['users_profiles'];

      if (anfitrion != null) {
        propiedad['nombre_anfitrion'] = anfitrion['nombre'];
        propiedad['foto_anfitrion'] = anfitrion['foto_perfil_url'];
      }

      return Propiedad.fromJson(propiedad);
    } catch (e) {
      return null;
    }
  }

  /// Obtener una propiedad por ID (lanza excepción si no existe)
  Future<Propiedad> obtenerPropiedadPorId(String propiedadId) async {
    final response = await _supabase
        .from('propiedades')
        .select('''
          *,
          users_profiles!propiedades_anfitrion_id_fkey(nombre, foto_perfil_url)
        ''')
        .eq('id', propiedadId)
        .single();

    final propiedad = Map<String, dynamic>.from(response);
    final anfitrion = response['users_profiles'];

    if (anfitrion != null) {
      propiedad['nombre_anfitrion'] = anfitrion['nombre'];
      propiedad['foto_anfitrion'] = anfitrion['foto_perfil_url'];
    }

    return Propiedad.fromJson(propiedad);
  }

  /// Actualizar propiedad
  Future<void> actualizarPropiedad(
    String propiedadId,
    Map<String, dynamic> updates,
  ) async {
    await _supabase.from('propiedades').update(updates).eq('id', propiedadId);
  }

  /// Eliminar propiedad (cambiar estado a inactivo)
  Future<void> eliminarPropiedad(String propiedadId) async {
    await _supabase
        .from('propiedades')
        .update({'estado': 'inactivo'})
        .eq('id', propiedadId);
  }
}
