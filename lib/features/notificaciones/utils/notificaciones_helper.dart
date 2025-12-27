import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/notificacion.dart';
import '../data/repositories/notificaciones_repository.dart';
import '../presentation/providers/notificaciones_provider.dart';
import '../services/push_notifications_service.dart';

/// Helper class para crear y manejar notificaciones desde cualquier parte de la app
class NotificacionesHelper {
  static final NotificacionesRepository _repository =
      NotificacionesRepository();
  static final PushNotificationsService _pushService =
      PushNotificationsService();

  /// Crear notificación de nueva reserva
  static Future<void> crearNotificacionNuevaReserva({
    required String anfitrionId,
    required String viajeroNombre,
    required String propiedadNombre,
    required String reservaId,
    BuildContext? context,
  }) async {
    try {
      await _repository.crearNotificacion(
        usuarioId: anfitrionId,
        tipo: TipoNotificacion.solicitudReserva,
        titulo: 'Nueva solicitud de reserva',
        mensaje:
            '$viajeroNombre quiere reservar tu propiedad "$propiedadNombre"',
        datos: {
          'reserva_id': reservaId,
          'viajero_nombre': viajeroNombre,
          'propiedad_nombre': propiedadNombre,
        },
      );

      // Actualizar contador si el contexto está disponible
      if (context != null && context.mounted) {
        context.read<NotificacionesProvider>().actualizarContadorNoLeidas();
      }

      debugPrint('✅ Notificación de nueva reserva creada');
    } catch (e) {
      debugPrint('❌ Error al crear notificación de nueva reserva: $e');
    }
  }

  /// Crear notificación de decisión de reserva (aceptada/rechazada)
  static Future<void> crearNotificacionDecisionReserva({
    required String viajeroId,
    required bool aceptada,
    required String propiedadNombre,
    required String reservaId,
    String? comentario,
    BuildContext? context,
  }) async {
    try {
      final tipo = aceptada
          ? TipoNotificacion.reservaAceptada
          : TipoNotificacion.reservaRechazada;

      final titulo = aceptada ? 'Reserva aceptada' : 'Reserva rechazada';

      final mensaje = aceptada
          ? 'Tu reserva para "$propiedadNombre" ha sido aceptada'
          : 'Tu reserva para "$propiedadNombre" ha sido rechazada';

      await _repository.crearNotificacion(
        usuarioId: viajeroId,
        tipo: tipo,
        titulo: titulo,
        mensaje: mensaje,
        datos: {
          'reserva_id': reservaId,
          'propiedad_nombre': propiedadNombre,
          'aceptada': aceptada,
          if (comentario != null) 'comentario': comentario,
        },
      );

      // Mostrar notificación push
      await _pushService.showLocalNotification(
        title: titulo,
        body: mensaje,
        payload: {'tipo': tipo.name, 'reserva_id': reservaId},
      );

      if (context != null && context.mounted) {
        context.read<NotificacionesProvider>().actualizarContadorNoLeidas();
      }

      debugPrint('✅ Notificación de decisión de reserva creada');
    } catch (e) {
      debugPrint('❌ Error al crear notificación de decisión de reserva: $e');
    }
  }

  /// Crear notificación de nueva reseña
  static Future<void> crearNotificacionNuevaResena({
    required String usuarioId,
    required String autorNombre,
    required int calificacion,
    bool esResenaPropiedad = true,
    String? propiedadNombre,
    BuildContext? context,
  }) async {
    try {
      final mensaje = esResenaPropiedad
          ? '$autorNombre te ha dejado una reseña de $calificacion estrellas en "$propiedadNombre"'
          : '$autorNombre te ha dejado una reseña de $calificacion estrellas como viajero';

      await _repository.crearNotificacion(
        usuarioId: usuarioId,
        tipo: TipoNotificacion.nuevaResena,
        titulo: 'Nueva reseña recibida',
        mensaje: mensaje,
        datos: {
          'autor_nombre': autorNombre,
          'calificacion': calificacion,
          'es_resena_propiedad': esResenaPropiedad,
          if (propiedadNombre != null) 'propiedad_nombre': propiedadNombre,
        },
      );

      // Mostrar notificación push
      await _pushService.showLocalNotification(
        title: 'Nueva reseña recibida',
        body: mensaje,
        payload: {
          'tipo': TipoNotificacion.nuevaResena.name,
          'calificacion': calificacion.toString(),
        },
      );

      if (context != null && context.mounted) {
        context.read<NotificacionesProvider>().actualizarContadorNoLeidas();
      }

      debugPrint('✅ Notificación de nueva reseña creada');
    } catch (e) {
      debugPrint('❌ Error al crear notificación de nueva reseña: $e');
    }
  }

  /// Crear notificación de nuevo mensaje
  static Future<void> crearNotificacionNuevoMensaje({
    required String receptorId,
    required String emisorNombre,
    required String chatId,
    required String mensajePreview,
    String? avatarUrl,
    BuildContext? context,
  }) async {
    try {
      final mensajeCorto = mensajePreview.length > 100
          ? '${mensajePreview.substring(0, 100)}...'
          : mensajePreview;

      await _repository.crearNotificacion(
        usuarioId: receptorId,
        tipo: TipoNotificacion.nuevoMensaje,
        titulo: 'Nuevo mensaje de $emisorNombre',
        mensaje: mensajeCorto,
        datos: {
          'chat_id': chatId,
          'emisor_nombre': emisorNombre,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        },
        imagenUrl: avatarUrl,
      );

      // Mostrar notificación push
      await _pushService.showLocalNotification(
        title: 'Nuevo mensaje de $emisorNombre',
        body: mensajeCorto,
        payload: {
          'tipo': TipoNotificacion.nuevoMensaje.name,
          'chat_id': chatId,
        },
      );

      if (context != null && context.mounted) {
        context.read<NotificacionesProvider>().actualizarContadorNoLeidas();
      }

      debugPrint('✅ Notificación de nuevo mensaje creada');
    } catch (e) {
      debugPrint('❌ Error al crear notificación de nuevo mensaje: $e');
    }
  }

  /// Crear notificación de decisión de anfitrión
  static Future<void> crearNotificacionDecisionAnfitrion({
    required String usuarioId,
    required bool aceptado,
    required String comentarioAdmin,
    BuildContext? context,
  }) async {
    try {
      final titulo = aceptado
          ? '¡Felicidades! Eres anfitrión'
          : 'Solicitud de anfitrión rechazada';

      final mensaje = aceptado
          ? 'Tu solicitud para ser anfitrión ha sido aprobada. Ya puedes publicar propiedades.'
          : 'Tu solicitud para ser anfitrión ha sido rechazada. Revisa los comentarios del administrador.';

      final tipo = aceptado
          ? TipoNotificacion.anfitrionAceptado
          : TipoNotificacion.anfitrionRechazado;

      await _repository.crearNotificacion(
        usuarioId: usuarioId,
        tipo: tipo,
        titulo: titulo,
        mensaje: mensaje,
        datos: {'aceptado': aceptado, 'comentario_admin': comentarioAdmin},
      );

      // Mostrar notificación push
      await _pushService.showLocalNotification(
        title: titulo,
        body: mensaje,
        payload: {'tipo': tipo.name, 'aceptado': aceptado.toString()},
      );

      if (context != null && context.mounted) {
        context.read<NotificacionesProvider>().actualizarContadorNoLeidas();
      }

      debugPrint('✅ Notificación de decisión de anfitrión creada');
    } catch (e) {
      debugPrint('❌ Error al crear notificación de decisión de anfitrión: $e');
    }
  }

  /// Crear notificación de llegada de huésped
  static Future<void> crearNotificacionLlegadaHuesped({
    required String anfitrionId,
    required String huespedNombre,
    required String propiedadNombre,
    required String reservaId,
    BuildContext? context,
  }) async {
    try {
      await _repository.crearNotificacion(
        usuarioId: anfitrionId,
        tipo: TipoNotificacion.llegadaHuesped,
        titulo: 'Huésped ha llegado',
        mensaje: '$huespedNombre ha llegado a tu propiedad "$propiedadNombre"',
        datos: {
          'reserva_id': reservaId,
          'huesped_nombre': huespedNombre,
          'propiedad_nombre': propiedadNombre,
        },
      );

      if (context != null && context.mounted) {
        context.read<NotificacionesProvider>().actualizarContadorNoLeidas();
      }

      debugPrint('✅ Notificación de llegada de huésped creada');
    } catch (e) {
      debugPrint('❌ Error al crear notificación de llegada de huésped: $e');
    }
  }

  /// Crear notificación de fin de estadía
  static Future<void> crearNotificacionFinEstadia({
    required String anfitrionId,
    required String huespedNombre,
    required String propiedadNombre,
    required String reservaId,
    BuildContext? context,
  }) async {
    try {
      await _repository.crearNotificacion(
        usuarioId: anfitrionId,
        tipo: TipoNotificacion.finEstadia,
        titulo: 'Estadía finalizada',
        mensaje:
            'La estadía de $huespedNombre en "$propiedadNombre" ha terminado',
        datos: {
          'reserva_id': reservaId,
          'huesped_nombre': huespedNombre,
          'propiedad_nombre': propiedadNombre,
        },
      );

      if (context != null && context.mounted) {
        context.read<NotificacionesProvider>().actualizarContadorNoLeidas();
      }

      debugPrint('✅ Notificación de fin de estadía creada');
    } catch (e) {
      debugPrint('❌ Error al crear notificación de fin de estadía: $e');
    }
  }

  /// Crear notificación de recordatorio
  static Future<void> crearNotificacionRecordatorio({
    required String usuarioId,
    required TipoNotificacion
    tipo, // recordatorioCheckin o recordatorioCheckout
    required String propiedadNombre,
    required String reservaId,
    required DateTime fecha,
    BuildContext? context,
  }) async {
    try {
      final esCheckin = tipo == TipoNotificacion.recordatorioCheckin;
      final titulo = esCheckin
          ? 'Recordatorio de Check-in'
          : 'Recordatorio de Check-out';

      final mensaje = esCheckin
          ? 'Tu check-in en "$propiedadNombre" es mañana'
          : 'Tu check-out de "$propiedadNombre" es mañana';

      await _repository.crearNotificacion(
        usuarioId: usuarioId,
        tipo: tipo,
        titulo: titulo,
        mensaje: mensaje,
        datos: {
          'reserva_id': reservaId,
          'propiedad_nombre': propiedadNombre,
          'fecha': fecha.toIso8601String(),
        },
      );

      if (context != null && context.mounted) {
        context.read<NotificacionesProvider>().actualizarContadorNoLeidas();
      }

      debugPrint('✅ Notificación de recordatorio creada');
    } catch (e) {
      debugPrint('❌ Error al crear notificación de recordatorio: $e');
    }
  }

  /// Crear notificación general del sistema
  static Future<void> crearNotificacionGeneral({
    required String usuarioId,
    required String titulo,
    required String mensaje,
    Map<String, dynamic>? datos,
    String? imagenUrl,
    BuildContext? context,
  }) async {
    try {
      await _repository.crearNotificacion(
        usuarioId: usuarioId,
        tipo: TipoNotificacion.general,
        titulo: titulo,
        mensaje: mensaje,
        datos: datos,
        imagenUrl: imagenUrl,
      );

      // Mostrar notificación push
      await _pushService.showLocalNotification(
        title: titulo,
        body: mensaje,
        payload: {'tipo': TipoNotificacion.general.name, ...?datos},
      );

      if (context != null && context.mounted) {
        context.read<NotificacionesProvider>().actualizarContadorNoLeidas();
      }

      debugPrint('✅ Notificación general creada');
    } catch (e) {
      debugPrint('❌ Error al crear notificación general: $e');
    }
  }

  /// Marcar notificación como leída
  static Future<void> marcarComoLeida(
    String notificacionId, [
    BuildContext? context,
  ]) async {
    try {
      await _repository.marcarComoLeida(notificacionId);

      if (context != null && context.mounted) {
        context.read<NotificacionesProvider>().marcarComoLeida(notificacionId);
      }

      debugPrint('✅ Notificación marcada como leída');
    } catch (e) {
      debugPrint('❌ Error al marcar notificación como leída: $e');
    }
  }

  /// Obtener contador de notificaciones no leídas
  static Future<int> obtenerContadorNoLeidas() async {
    try {
      return await _repository.contarNoLeidas();
    } catch (e) {
      debugPrint('❌ Error al obtener contador de no leídas: $e');
      return 0;
    }
  }

  /// Inicializar notificaciones para un usuario
  static Future<void> inicializarParaUsuario(BuildContext context) async {
    try {
      // Inicializar el servicio de push notifications y pedir permisos
      final pushService = PushNotificationsService();

      // Verificar si ya está inicializado
      if (!pushService.isInitialized) {
        await pushService.initialize();
      }

      // Pedir permisos explícitamente
      debugPrint('🔔 Solicitando permisos de notificación...');
      final hasPermissions = await pushService.areNotificationsEnabled();

      if (!hasPermissions) {
        debugPrint('⚠️ Permisos no concedidos, solicitando...');
        final granted = await pushService.requestPermissions();
        debugPrint('🔔 Permisos ${granted ? "concedidos" : "denegados"}');
      } else {
        debugPrint('✅ Permisos ya concedidos');
      }

      // Actualizar token FCM en Supabase
      await pushService.updateTokenInSupabase();

      // Inicializar provider de notificaciones
      await context.read<NotificacionesProvider>().inicializar();

      debugPrint('✅ Notificaciones inicializadas para el usuario');
    } catch (e) {
      debugPrint('❌ Error al inicializar notificaciones: $e');
    }
  }

  /// Limpiar notificaciones al cerrar sesión
  static void limpiarNotificaciones(BuildContext context) {
    try {
      context.read<NotificacionesProvider>().limpiar();
      debugPrint('✅ Notificaciones limpiadas');
    } catch (e) {
      debugPrint('❌ Error al limpiar notificaciones: $e');
    }
  }
}

/// Extension para facilitar el uso desde widgets
extension NotificacionesContext on BuildContext {
  /// Acceso rápido al provider de notificaciones
  NotificacionesProvider get notificaciones => read<NotificacionesProvider>();

  /// Acceso rápido al provider de notificaciones (watch)
  NotificacionesProvider get watchNotificaciones =>
      watch<NotificacionesProvider>();

  /// Crear notificación de nueva reserva
  Future<void> notificarNuevaReserva({
    required String anfitrionId,
    required String viajeroNombre,
    required String propiedadNombre,
    required String reservaId,
  }) => NotificacionesHelper.crearNotificacionNuevaReserva(
    anfitrionId: anfitrionId,
    viajeroNombre: viajeroNombre,
    propiedadNombre: propiedadNombre,
    reservaId: reservaId,
    context: this,
  );

  /// Crear notificación de nuevo mensaje
  Future<void> notificarNuevoMensaje({
    required String receptorId,
    required String emisorNombre,
    required String chatId,
    required String mensajePreview,
    String? avatarUrl,
  }) => NotificacionesHelper.crearNotificacionNuevoMensaje(
    receptorId: receptorId,
    emisorNombre: emisorNombre,
    chatId: chatId,
    mensajePreview: mensajePreview,
    avatarUrl: avatarUrl,
    context: this,
  );
}
