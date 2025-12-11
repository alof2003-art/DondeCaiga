import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomAppBarHeader extends StatefulWidget {
  final SupabaseClient supabase;
  final String screenTitle;

  const CustomAppBarHeader({
    super.key,
    required this.supabase,
    required this.screenTitle,
  });

  @override
  State<CustomAppBarHeader> createState() => _CustomAppBarHeaderState();
}

class _CustomAppBarHeaderState extends State<CustomAppBarHeader> {
  String? _nombreUsuario;
  String? _rolUsuario;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final userId = widget.supabase.auth.currentUser?.id;
      if (userId != null) {
        // Obtener datos del usuario con su rol
        final response = await widget.supabase
            .from('users_profiles')
            .select('nombre, rol_id')
            .eq('id', userId)
            .single();

        if (mounted) {
          final rolId = response['rol_id'] as int?;
          String rolTexto = 'usuario';

          // Mapear rol_id a texto
          switch (rolId) {
            case 1:
              rolTexto = 'viajero';
              break;
            case 2:
              rolTexto = 'anfitrión';
              break;
            case 3:
              rolTexto = 'admin';
              break;
          }

          setState(() {
            _nombreUsuario = response['nombre'] as String?;
            _rolUsuario = rolTexto;
          });
        }
      }
    } catch (e) {
      // Si falla, simplemente no mostramos los datos
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_nombreUsuario == null || _rolUsuario == null) {
      // Fallback mientras carga o si falla
      return Text(
        widget.screenTitle,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nombre del usuario con rol
        Text(
          '${_nombreUsuario!.toUpperCase()} ($_rolUsuario)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        // Título de la pantalla
        Text(
          widget.screenTitle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
