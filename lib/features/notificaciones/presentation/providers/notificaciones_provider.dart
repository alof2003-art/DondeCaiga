import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/notificacion.dart';
import '../../data/repositories/notificaciones_repository.dart';

class NotificacionesProvider extends ChangeNotifier {
  final NotificacionesRepository _repository = NotificacionesRepository();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Notificacion> _notificaciones = [];
  Map<TipoNotificacion, List<Notificacion>> _notificacionesAgrupadas = {};
  int _contadorNoLeidas = 0;
  bool _isLoading = false;
  String? _error;
  FiltroNotificaciones _filtroActual = const FiltroNotificaciones();
  RealtimeChannel? _subscription;

  // Getters
  List<Notificacion> get notificaciones => _notificaciones;
  Map<TipoNotificacion, List<Notificacion>> get notificacionesAgrupadas =>
      _notificacionesAgrupadas;
  int get contadorNoLeidas => _contadorNoLeidas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  FiltroNotificaciones get filtroActual => _filtroActual;
  bool get hayNotificacionesNoLeidas => _contadorNoLeidas > 0;

  // Inicializar el provider
  Future<void> inicializar() async {
    if (_supabase.auth.currentUser != null) {
      await cargarNotificaciones();
      await actualizarContadorNoLeidas();
      _suscribirseANotificaciones();
    }
  }

  // Cargar notificaciones
  Future<void> cargarNotificaciones({bool mostrarLoading = true}) async {
    if (mostrarLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _notificaciones = await _repository.obtenerNotificaciones(
        filtro: _filtroActual,
      );

      _notificacionesAgrupadas = await _repository
          .obtenerNotificacionesAgrupadas();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar contador de no leídas
  Future<void> actualizarContadorNoLeidas() async {
    try {
      _contadorNoLeidas = await _repository.contarNoLeidas();
      notifyListeners();
    } catch (e) {
      // Error silencioso para el contador
    }
  }

  // Marcar notificación como leída
  Future<void> marcarComoLeida(String notificacionId) async {
    try {
      await _repository.marcarComoLeida(notificacionId);

      // Actualizar localmente
      final index = _notificaciones.indexWhere((n) => n.id == notificacionId);
      if (index != -1) {
        _notificaciones[index] = _notificaciones[index].copyWith(leida: true);
        await actualizarContadorNoLeidas();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Marcar todas como leídas
  Future<void> marcarTodasComoLeidas() async {
    try {
      await _repository.marcarTodasComoLeidas();

      // Actualizar localmente
      _notificaciones = _notificaciones
          .map((n) => n.copyWith(leida: true))
          .toList();

      _contadorNoLeidas = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Eliminar notificación
  Future<void> eliminarNotificacion(String notificacionId) async {
    try {
      await _repository.eliminarNotificacion(notificacionId);

      // Actualizar localmente
      _notificaciones.removeWhere((n) => n.id == notificacionId);
      await actualizarContadorNoLeidas();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Aplicar filtro
  void aplicarFiltro(FiltroNotificaciones filtro) {
    _filtroActual = filtro;
    cargarNotificaciones();
  }

  // Limpiar filtro
  void limpiarFiltro() {
    _filtroActual = const FiltroNotificaciones();
    cargarNotificaciones();
  }

  // Suscribirse a notificaciones en tiempo real
  void _suscribirseANotificaciones() {
    _subscription?.unsubscribe();

    _subscription = _repository.suscribirseANotificaciones((notificacion) {
      // Agregar nueva notificación al inicio
      _notificaciones.insert(0, notificacion);
      _contadorNoLeidas++;

      // Mostrar notificación push si la app está en background
      _mostrarNotificacionPush(notificacion);

      notifyListeners();
    });
  }

  // Mostrar notificación push
  void _mostrarNotificacionPush(Notificacion notificacion) {
    // Aquí se implementaría la lógica de notificaciones push
    // Por ahora solo imprimimos en consola
    debugPrint('Nueva notificación: ${notificacion.titulo}');
  }

  // Obtener notificación por ID
  Notificacion? obtenerNotificacionPorId(String id) {
    try {
      return _notificaciones.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  // Refrescar notificaciones
  Future<void> refrescar() async {
    await cargarNotificaciones(mostrarLoading: false);
    await actualizarContadorNoLeidas();
  }

  // Limpiar datos al cerrar sesión
  void limpiar() {
    _subscription?.unsubscribe();
    _subscription = null;
    _notificaciones.clear();
    _notificacionesAgrupadas.clear();
    _contadorNoLeidas = 0;
    _isLoading = false;
    _error = null;
    _filtroActual = const FiltroNotificaciones();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}
