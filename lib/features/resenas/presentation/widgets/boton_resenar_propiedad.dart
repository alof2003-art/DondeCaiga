import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/resenas_repository.dart';
import '../screens/crear_resena_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../reservas/data/models/reserva.dart';

class BotonResenarPropiedad extends StatefulWidget {
  final String reservaId;
  final String propiedadId;
  final String tituloPropiedad;
  final VoidCallback? onResenaCreada;

  const BotonResenarPropiedad({
    super.key,
    required this.reservaId,
    required this.propiedadId,
    required this.tituloPropiedad,
    this.onResenaCreada,
  });

  @override
  State<BotonResenarPropiedad> createState() => _BotonResenarPropiedadState();
}

class _BotonResenarPropiedadState extends State<BotonResenarPropiedad> {
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

      final puedeResenar = await _resenasRepository.puedeResenarPropiedad(
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
    // Crear objeto Reserva básico para la pantalla
    final reserva = Reserva(
      id: widget.reservaId,
      propiedadId: widget.propiedadId,
      viajeroId: Supabase.instance.client.auth.currentUser?.id ?? '',
      fechaInicio: DateTime.now(),
      fechaFin: DateTime.now(),
      estado: 'completada',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tituloPropiedad: widget.tituloPropiedad,
    );

    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CrearResenaScreen(reserva: reserva),
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

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _abrirPantallaResena,
        icon: const Icon(Icons.rate_review, size: 18),
        label: const Text('Reseñar Propiedad'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark
              ? AppTheme.primaryDarkColor
              : AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
