import 'package:flutter/material.dart';
import 'package:donde_caigav2/main.dart';
import 'package:donde_caigav2/core/widgets/custom_app_bar_header.dart';
import '../widgets/apartado_mis_viajes.dart';
import '../widgets/apartado_mis_reservas.dart';
import '../widgets/filtros_chat_dialog.dart';
import '../../data/models/chat_apartado.dart';
import '../../data/models/filtro_chat.dart';
import '../../data/models/reserva_chat_info.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/chat_filter_service.dart';
import '../../data/services/services.dart';

class ChatListaScreen extends StatefulWidget {
  const ChatListaScreen({super.key});

  @override
  State<ChatListaScreen> createState() => _ChatListaScreenState();
}

class _ChatListaScreenState extends State<ChatListaScreen>
    with TickerProviderStateMixin {
  late final ChatRepository _chatRepository;
  late final ChatFilterService _filterService;
  late final FilterStorage _persistenciaService;
  late final TabController _tabController;

  // Estado de los apartados
  ChatApartado? _apartadoMisViajes;
  ChatApartado? _apartadoMisReservas;
  bool _isLoadingViajes = true;
  bool _isLoadingReservas = true;

  // Filtros por apartado
  FiltroChat _filtroViajes = FiltroChat.vacio();
  FiltroChat _filtroReservas = FiltroChat.vacio();

  // Estado del usuario
  bool _esAnfitrion = false;

  @override
  void initState() {
    super.initState();
    _chatRepository = ChatRepository(supabase);
    _filterService = ChatFilterService();
    _persistenciaService = FilterStorage();
    _tabController = TabController(length: 2, vsync: this);

    _inicializar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    await _cargarFiltrosGuardados();
    await _verificarEsAnfitrion();
    await _cargarDatos();
  }

  Future<void> _cargarFiltrosGuardados() async {
    try {
      _filtroViajes = await _persistenciaService.cargarFiltros(
        TipoApartado.misViajes,
      );
      _filtroReservas = await _persistenciaService.cargarFiltros(
        TipoApartado.misReservas,
      );
    } catch (e) {
      // En caso de error, usar filtros vacíos
    }
  }

  Future<void> _verificarEsAnfitrion() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      _esAnfitrion = await _chatRepository.esAnfitrion(user.id);
    }
  }

  Future<void> _cargarDatos() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Cargar datos de ambos apartados en paralelo
    await Future.wait([
      _cargarDatosMisViajes(user.id),
      _cargarDatosMisReservas(user.id),
    ]);
  }

  Future<void> _cargarDatosMisViajes(String userId) async {
    setState(() => _isLoadingViajes = true);

    try {
      print('🔍 Cargando Mis Viajes para usuario: $userId');

      final reservasVigentes = await _chatRepository
          .obtenerReservasViajeroVigentes(userId);
      final reservasPasadas = await _chatRepository
          .obtenerReservasViajeroPasadas(userId);

      print(
        '✈️ Mis Viajes RAW - Vigentes: ${reservasVigentes.length}, Pasadas: ${reservasPasadas.length}',
      );

      // Aplicar filtros de manera inteligente según el tipo de filtro
      List<ReservaChatInfo> reservasVigentesFiltradas = [];
      List<ReservaChatInfo> reservasPasadasFiltradas = [];

      if (_filtroViajes.estadoFiltro == EstadoFiltro.vigentes) {
        // Solo mostrar vigentes
        reservasVigentesFiltradas = _filterService.aplicarFiltros(
          reservasVigentes,
          _filtroViajes,
        );
        reservasPasadasFiltradas = []; // Vaciar pasadas
      } else if (_filtroViajes.estadoFiltro == EstadoFiltro.pasadas) {
        // Solo mostrar pasadas
        reservasVigentesFiltradas = []; // Vaciar vigentes
        reservasPasadasFiltradas = _filterService.aplicarFiltros(
          reservasPasadas,
          _filtroViajes,
        );
      } else {
        // Mostrar ambas (sin filtro de estado o con otros filtros)
        reservasVigentesFiltradas = _filterService.aplicarFiltros(
          reservasVigentes,
          _filtroViajes,
        );
        reservasPasadasFiltradas = _filterService.aplicarFiltros(
          reservasPasadas,
          _filtroViajes,
        );
      }

      print(
        '✈️ Mis Viajes FILTRADAS - Vigentes: ${reservasVigentesFiltradas.length}, Pasadas: ${reservasPasadasFiltradas.length}',
      );

      if (mounted) {
        setState(() {
          _apartadoMisViajes = ChatApartado.misViajes(
            reservasVigentes: reservasVigentesFiltradas,
            reservasPasadas: reservasPasadasFiltradas,
          );
          _isLoadingViajes = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando Mis Viajes: $e');
      if (mounted) {
        setState(() {
          _apartadoMisViajes = ChatApartado.misViajes(
            reservasVigentes: [],
            reservasPasadas: [],
          );
          _isLoadingViajes = false;
        });
      }
    }
  }

  Future<void> _cargarDatosMisReservas(String userId) async {
    setState(() => _isLoadingReservas = true);

    try {
      print('🔍 Cargando Mis Reservas para usuario: $userId');

      final reservasVigentes = await _chatRepository
          .obtenerReservasAnfitrionVigentes(userId);
      final reservasPasadas = await _chatRepository
          .obtenerReservasAnfitrionPasadas(userId);

      print(
        '🏠 Mis Reservas RAW - Vigentes: ${reservasVigentes.length}, Pasadas: ${reservasPasadas.length}',
      );

      // Aplicar filtros de manera inteligente según el tipo de filtro
      List<ReservaChatInfo> reservasVigentesFiltradas = [];
      List<ReservaChatInfo> reservasPasadasFiltradas = [];

      if (_filtroReservas.estadoFiltro == EstadoFiltro.vigentes) {
        // Solo mostrar vigentes
        reservasVigentesFiltradas = _filterService.aplicarFiltros(
          reservasVigentes,
          _filtroReservas,
        );
        reservasPasadasFiltradas = []; // Vaciar pasadas
      } else if (_filtroReservas.estadoFiltro == EstadoFiltro.pasadas) {
        // Solo mostrar pasadas
        print(
          '🔧 FILTRO INTELIGENTE: Aplicando filtro SOLO a reservas pasadas',
        );
        reservasVigentesFiltradas = []; // Vaciar vigentes
        reservasPasadasFiltradas = _filterService.aplicarFiltros(
          reservasPasadas,
          _filtroReservas,
        );
      } else {
        // Mostrar ambas (sin filtro de estado o con otros filtros)
        reservasVigentesFiltradas = _filterService.aplicarFiltros(
          reservasVigentes,
          _filtroReservas,
        );
        reservasPasadasFiltradas = _filterService.aplicarFiltros(
          reservasPasadas,
          _filtroReservas,
        );
      }

      print(
        '🏠 Mis Reservas FILTRADAS - Vigentes: ${reservasVigentesFiltradas.length}, Pasadas: ${reservasPasadasFiltradas.length}',
      );

      if (mounted) {
        setState(() {
          _apartadoMisReservas = ChatApartado.misReservas(
            reservasVigentes: reservasVigentesFiltradas,
            reservasPasadas: reservasPasadasFiltradas,
          );
          _isLoadingReservas = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando Mis Reservas: $e');
      if (mounted) {
        setState(() {
          _apartadoMisReservas = ChatApartado.misReservas(
            reservasVigentes: [],
            reservasPasadas: [],
          );
          _isLoadingReservas = false;
        });
      }
    }
  }

  Future<void> _aplicarFiltros(TipoApartado tipo, FiltroChat filtro) async {
    print('🔧 Aplicando filtros para $tipo: ${filtro.descripcionFiltros}');

    // Guardar filtros
    await _persistenciaService.guardarFiltros(tipo, filtro);

    // Actualizar estado local
    setState(() {
      if (tipo == TipoApartado.misViajes) {
        _filtroViajes = filtro;
      } else {
        _filtroReservas = filtro;
      }
    });

    // Recargar datos con nuevos filtros
    final user = supabase.auth.currentUser;
    if (user != null) {
      if (tipo == TipoApartado.misViajes) {
        await _cargarDatosMisViajes(user.id);
      } else {
        await _cargarDatosMisReservas(user.id);
      }
    }
  }

  void _mostrarDialogoFiltros() {
    final apartadoActual = _tabController.index == 0
        ? TipoApartado.misViajes
        : TipoApartado.misReservas;

    final filtroActual = apartadoActual == TipoApartado.misViajes
        ? _filtroViajes
        : _filtroReservas;

    showDialog(
      context: context,
      builder: (context) => FiltrosChatDialog(
        filtroActual: filtroActual,
        apartado: apartadoActual,
        onAplicarFiltros: (filtro) => _aplicarFiltros(apartadoActual, filtro),
      ),
    );
  }

  Future<void> _refrescar() async {
    await _cargarDatos();
  }

  void _onResenaCreada() {
    // Callback para cuando se crea una reseña
    _refrescar();
  }

  @override
  Widget build(BuildContext context) {
    final apartadoActual = _tabController.index == 0
        ? TipoApartado.misViajes
        : TipoApartado.misReservas;

    final filtroActual = apartadoActual == TipoApartado.misViajes
        ? _filtroViajes
        : _filtroReservas;

    final tienesFiltrosActivos = filtroActual.tienesFiltrosAplicados;

    return Scaffold(
      appBar: AppBar(
        title: CustomAppBarHeader(supabase: supabase, screenTitle: 'Chat'),
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
        actions: [
          // Botón de filtros con indicador
          Stack(
            children: [
              IconButton(
                onPressed: _mostrarDialogoFiltros,
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filtros',
              ),
              if (tienesFiltrosActivos)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${filtroActual.numeroFiltrosActivos}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: Icon(TipoApartado.misViajes.icono),
              text: TipoApartado.misViajes.titulo,
            ),
            Tab(
              icon: Icon(TipoApartado.misReservas.icono),
              text: TipoApartado.misReservas.titulo,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Apartado Mis Viajes
          ApartadoMisViajes(
            apartado: _apartadoMisViajes,
            isLoading: _isLoadingViajes,
            onRefresh: _refrescar,
            onResenaCreada: _onResenaCreada,
            filtroActivo: _filtroViajes, // Pasar el filtro activo
          ),
          // Apartado Mis Reservas
          ApartadoMisReservas(
            apartado: _apartadoMisReservas,
            isLoading: _isLoadingReservas,
            esAnfitrion: _esAnfitrion,
            onRefresh: _refrescar,
            filtroActivo: _filtroReservas, // Pasar el filtro activo
          ),
        ],
      ),
    );
  }
}
