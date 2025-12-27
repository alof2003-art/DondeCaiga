import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../resenas/data/repositories/resenas_repository.dart';
import '../../../resenas/presentation/widgets/seccion_resenas_perfil.dart';
import '../../../resenas/presentation/widgets/titulo_compacto_widget.dart';
import '../../../explorar/presentation/screens/detalle_propiedad_screen.dart';
import '../widgets/calificaciones_perfil_widget.dart';

class VerPerfilUsuarioScreen extends StatefulWidget {
  final String userId;
  final String? nombreUsuario;

  const VerPerfilUsuarioScreen({
    super.key,
    required this.userId,
    this.nombreUsuario,
  });

  @override
  State<VerPerfilUsuarioScreen> createState() => _VerPerfilUsuarioScreenState();
}

class _VerPerfilUsuarioScreenState extends State<VerPerfilUsuarioScreen> {
  final _supabase = Supabase.instance.client;
  late final ResenasRepository _resenasRepository;

  Map<String, dynamic>? _perfilUsuario;
  List<Map<String, dynamic>> _propiedadesUsuario = [];
  Map<String, dynamic> _estadisticasResenas = {};
  bool _isLoading = true;
  bool _isLoadingPropiedades = true;

  @override
  void initState() {
    super.initState();
    _resenasRepository = ResenasRepository(_supabase);
    _cargarPerfilUsuario();
    _cargarPropiedadesUsuario();
    _cargarEstadisticasResenas();
  }

  Future<void> _cargarPerfilUsuario() async {
    try {
      final response = await _supabase
          .from('users_profiles')
          .select('*')
          .eq('id', widget.userId)
          .single();

      if (mounted) {
        setState(() {
          _perfilUsuario = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar el perfil del usuario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cargarPropiedadesUsuario() async {
    try {
      final response = await _supabase
          .from('propiedades')
          .select('''
            *,
            fotos_propiedades(url_foto)
          ''')
          .eq('anfitrion_id', widget.userId)
          .eq('estado', 'activo')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _propiedadesUsuario = List<Map<String, dynamic>>.from(response);
          _isLoadingPropiedades = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPropiedades = false);
      }
    }
  }

  Future<void> _cargarEstadisticasResenas() async {
    try {
      final estadisticas = await _resenasRepository
          .getEstadisticasCompletasResenas(widget.userId);
      if (mounted) {
        setState(() {
          _estadisticasResenas = estadisticas;
        });
      }
    } catch (e) {
      // En caso de error, mantener estadísticas vacías
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(widget.nombreUsuario ?? 'Perfil de Usuario'),
        backgroundColor: isDark
            ? AppTheme.primaryDarkColor
            : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header del perfil
                  _buildHeaderPerfil(),

                  const SizedBox(height: 24),

                  // Propiedades del usuario
                  _buildSeccionPropiedades(),

                  const SizedBox(height: 24),

                  // Reseñas del usuario
                  SeccionResenasPerfil(
                    userId: widget.userId,
                    resenasRepository: _resenasRepository,
                    esPerfilPropio: false,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderPerfil() {
    if (_perfilUsuario == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nombre = _perfilUsuario!['nombre'] as String? ?? 'Usuario';
    final email = _perfilUsuario!['email'] as String? ?? '';
    final fotoUrl = _perfilUsuario!['foto_perfil_url'] as String?;
    final fechaCreacion = _perfilUsuario!['created_at'] as String?;

    DateTime? fechaRegistro;
    if (fechaCreacion != null) {
      fechaRegistro = DateTime.parse(fechaCreacion);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Foto de perfil
          CircleAvatar(
            radius: 50,
            backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
            backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
            child: fotoUrl == null
                ? Icon(
                    Icons.person,
                    size: 50,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  )
                : null,
          ),

          const SizedBox(height: 16),

          // Nombre
          Text(
            nombre,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          // Títulos compactos
          _buildTitulosCompactos(),

          const SizedBox(height: 8),

          // Email (parcialmente oculto)
          Text(
            _ocultarEmail(email),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),

          // Calificaciones del usuario
          CalificacionesPerfilWidget(
            promedioAnfitrion:
                _estadisticasResenas['promedioRecibidas'] as double?,
            totalResenasAnfitrion:
                _estadisticasResenas['totalResenasRecibidas'] as int?,
            promedioViajero:
                _estadisticasResenas['promedioComoViajero'] as double?,
            totalResenasViajero:
                _estadisticasResenas['totalResenasComoViajero'] as int?,
          ),

          if (fechaRegistro != null) ...[
            const SizedBox(height: 8),
            Text(
              'Miembro desde ${_formatearFechaRegistro(fechaRegistro)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTitulosCompactos() {
    final promedioAnfitrion =
        _estadisticasResenas['promedioRecibidas'] as double? ?? 0.0;
    final totalAnfitrion =
        _estadisticasResenas['totalResenasRecibidas'] as int? ?? 0;
    final promedioViajero =
        _estadisticasResenas['promedioComoViajero'] as double? ?? 0.0;
    final totalViajero =
        _estadisticasResenas['totalResenasComoViajero'] as int? ?? 0;

    final titulosWidgets = <Widget>[];

    // Título de anfitrión
    if (totalAnfitrion > 0) {
      titulosWidgets.add(
        TituloCompactoWidget(
          promedio: promedioAnfitrion,
          totalResenas: totalAnfitrion,
          tipo: 'anfitrion',
        ),
      );
    }

    // Título de viajero
    if (totalViajero > 0) {
      titulosWidgets.add(
        TituloCompactoWidget(
          promedio: promedioViajero,
          totalResenas: totalViajero,
          tipo: 'viajero',
        ),
      );
    }

    if (titulosWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: titulosWidgets,
    );
  }

  Widget _buildSeccionPropiedades() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.home,
                color: isDark
                    ? AppTheme.primaryDarkColor
                    : AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Propiedades (${_propiedadesUsuario.length})',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (_isLoadingPropiedades)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_propiedadesUsuario.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.home_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Este usuario no tiene propiedades publicadas',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _propiedadesUsuario.length,
              itemBuilder: (context, index) {
                final propiedad = _propiedadesUsuario[index];
                return _buildTarjetaPropiedad(propiedad);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTarjetaPropiedad(Map<String, dynamic> propiedad) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titulo = propiedad['titulo'] as String? ?? 'Sin título';
    final ciudad = propiedad['ciudad'] as String? ?? 'Sin ubicación';
    final capacidad = propiedad['capacidad_personas'] as int? ?? 0;
    final fotoUrl = propiedad['foto_principal_url'] as String?;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetallePropiedadScreen(propiedadId: propiedad['id'] as String),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
              child: fotoUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        fotoUrl,
                        width: double.infinity,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.home,
                          size: 40,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                    )
                  : Icon(
                      Icons.home,
                      size: 40,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
            ),

            // Información
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ciudad,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$capacidad personas',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ocultarEmail(String email) {
    if (email.isEmpty) return '';

    final partes = email.split('@');
    if (partes.length != 2) return email;

    final usuario = partes[0];
    final dominio = partes[1];

    if (usuario.length <= 2) return email;

    final usuarioOculto =
        '${usuario.substring(0, 2)}${'*' * (usuario.length - 2)}';
    return '$usuarioOculto@$dominio';
  }

  String _formatearFechaRegistro(DateTime fecha) {
    final meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${meses[fecha.month - 1]} ${fecha.year}';
  }
}
