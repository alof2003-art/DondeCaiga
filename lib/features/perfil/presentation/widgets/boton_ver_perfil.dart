import 'package:flutter/material.dart';
import '../screens/ver_perfil_usuario_screen.dart';
import '../../../../core/theme/app_theme.dart';

class BotonVerPerfil extends StatelessWidget {
  final String userId;
  final String? nombreUsuario;
  final String? fotoUsuario;
  final bool esIcono;
  final bool esTexto;

  const BotonVerPerfil({
    super.key,
    required this.userId,
    this.nombreUsuario,
    this.fotoUsuario,
    this.esIcono = false,
    this.esTexto = false,
  });

  // Constructor para mostrar como ícono
  const BotonVerPerfil.icono({
    super.key,
    required this.userId,
    this.nombreUsuario,
    this.fotoUsuario,
  }) : esIcono = true,
       esTexto = false;

  // Constructor para mostrar como texto/nombre
  const BotonVerPerfil.texto({
    super.key,
    required this.userId,
    required this.nombreUsuario,
    this.fotoUsuario,
  }) : esIcono = false,
       esTexto = true;

  // Constructor para mostrar como botón completo
  const BotonVerPerfil.boton({
    super.key,
    required this.userId,
    this.nombreUsuario,
    this.fotoUsuario,
  }) : esIcono = false,
       esTexto = false;

  void _abrirPerfil(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerPerfilUsuarioScreen(
          userId: userId,
          nombreUsuario: nombreUsuario,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (esIcono) {
      return GestureDetector(
        onTap: () => _abrirPerfil(context),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
          backgroundImage: fotoUsuario != null
              ? NetworkImage(fotoUsuario!)
              : null,
          child: fotoUsuario == null
              ? Icon(
                  Icons.person,
                  size: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                )
              : null,
        ),
      );
    }

    if (esTexto) {
      return GestureDetector(
        onTap: () => _abrirPerfil(context),
        child: Text(
          nombreUsuario ?? 'Usuario',
          style: TextStyle(
            color: isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }

    // Botón completo
    return ElevatedButton.icon(
      onPressed: () => _abrirPerfil(context),
      icon: const Icon(Icons.person, size: 18),
      label: const Text('Ver Perfil'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
        foregroundColor: isDark ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
