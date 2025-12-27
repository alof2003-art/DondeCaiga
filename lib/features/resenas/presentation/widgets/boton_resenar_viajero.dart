import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/resenas_repository.dart';
import '../screens/crear_resena_viajero_screen.dart';
import '../../../../core/theme/app_theme.dart';

class BotonResenarViajero extends StatefulWidget {
  final String reservaId;
  final String viajeroId;
  final String nombreViajero;
  final String? fotoViajero;
  final String tituloPropiedad;
  final VoidCallback? onResenaCreada;

  const BotonResenarViajero({
    super.key,
    required this.reservaId,
    required this.viajeroId,
    required this.nombreViajero,
    this.fotoViajero,
    required this.tituloPropiedad,
    this.onResenaCreada,
  });

  @override
  State<BotonResenarViajero> createState() => _BotonResenarViajeroState();
}

class _BotonResenarViajeroState extends State<BotonResenarViajero> {
  final _resenasRepository = ResenasRepository(Supabase.instance.client);
  bool _puedeResenar = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verificarSiPuedeResenar();
  }

  Future<void> _verificarSiPuedeResenar() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final puedeResenar = await _resenasRepository.puedeResenarViajero(
        currentUser.id,
        widget.reservaId,
      );

      if (mounted) {
        setState(() {
          _puedeResenar = puedeResenar;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _abrirPantallaResena() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CrearResenaViajeroScreen(
          reservaId: widget.reservaId,
          viajeroId: widget.viajeroId,
          nombreViajero: widget.nombreViajero,
          fotoViajero: widget.fotoViajero,
          tituloPropiedad: widget.tituloPropiedad,
        ),
      ),
    );

    if (resultado == true) {
      // Reseña creada exitosamente
      setState(() {
        _puedeResenar = false;
      });

      if (widget.onResenaCreada != null) {
        widget.onResenaCreada!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (!_puedeResenar) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ElevatedButton.icon(
      onPressed: _abrirPantallaResena,
      icon: const Icon(Icons.rate_review, size: 16),
      label: const Text('Reseñar Viajero'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark
            ? AppTheme.primaryDarkColor
            : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
