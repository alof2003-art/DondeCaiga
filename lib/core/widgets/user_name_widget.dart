import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserNameWidget extends StatefulWidget {
  final SupabaseClient supabase;

  const UserNameWidget({super.key, required this.supabase});

  @override
  State<UserNameWidget> createState() => _UserNameWidgetState();
}

class _UserNameWidgetState extends State<UserNameWidget> {
  String? _nombreUsuario;

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
  }

  Future<void> _cargarNombreUsuario() async {
    try {
      final userId = widget.supabase.auth.currentUser?.id;
      if (userId != null) {
        final response = await widget.supabase
            .from('users_profiles')
            .select('nombre')
            .eq('id', userId)
            .single();

        if (mounted) {
          setState(() {
            _nombreUsuario = response['nombre'] as String?;
          });
        }
      }
    } catch (e) {
      // Si falla, simplemente no mostramos el nombre
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_nombreUsuario == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: Text(
          _nombreUsuario!,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
