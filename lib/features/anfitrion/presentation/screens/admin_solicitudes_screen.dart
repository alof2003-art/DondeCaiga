import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../main.dart';
import '../../data/models/solicitud_anfitrion.dart';
import '../../data/repositories/solicitud_repository.dart';

class AdminSolicitudesScreen extends StatefulWidget {
  const AdminSolicitudesScreen({super.key});

  @override
  State<AdminSolicitudesScreen> createState() => _AdminSolicitudesScreenState();
}

class _AdminSolicitudesScreenState extends State<AdminSolicitudesScreen> {
  late final SolicitudRepository _solicitudRepository;
  List<SolicitudAnfitrion> _solicitudes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _solicitudRepository = SolicitudRepository(supabase);
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() => _isLoading = true);
    try {
      final solicitudes = await _solicitudRepository
          .obtenerSolicitudesPendientes();
      if (mounted) {
        setState(() {
          _solicitudes = solicitudes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar solicitudes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _aprobarSolicitud(SolicitudAnfitrion solicitud) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar Solicitud'),
        content: Text(
          '¿Aprobar la solicitud de ${solicitud.nombreUsuario}?\n\n'
          'El usuario se convertirá en anfitrión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final adminId = supabase.auth.currentUser!.id;
      await _solicitudRepository.aprobarSolicitud(
        solicitudId: solicitud.id,
        adminId: adminId,
        usuarioId: solicitud.usuarioId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Solicitud aprobada!'),
          backgroundColor: Colors.green,
        ),
      );

      _cargarSolicitudes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rechazarSolicitud(SolicitudAnfitrion solicitud) async {
    final comentarioController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Rechazar la solicitud de ${solicitud.nombreUsuario}?'),
            const SizedBox(height: 16),
            TextField(
              controller: comentarioController,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final adminId = supabase.auth.currentUser!.id;
      await _solicitudRepository.rechazarSolicitud(
        solicitudId: solicitud.id,
        adminId: adminId,
        comentario: comentarioController.text.trim().isEmpty
            ? null
            : comentarioController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud rechazada'),
          backgroundColor: Colors.orange,
        ),
      );

      _cargarSolicitudes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _verFoto(String url, String titulo) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(titulo),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('Descargar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes Pendientes'),
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _solicitudes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay solicitudes pendientes',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargarSolicitudes,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _solicitudes.length,
                itemBuilder: (context, index) {
                  final solicitud = _solicitudes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre y email
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF4DB6AC),
                                child: Text(
                                  solicitud.nombreUsuario?[0].toUpperCase() ??
                                      'U',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      solicitud.nombreUsuario ?? 'Usuario',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      solicitud.emailUsuario ?? '',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Mensaje
                          if (solicitud.mensaje != null &&
                              solicitud.mensaje!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                solicitud.mensaje!,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Botones para ver fotos
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _verFoto(
                                    solicitud.fotoSelfieUrl,
                                    'Foto Selfie',
                                  ),
                                  icon: const Icon(Icons.person),
                                  label: const Text('Ver Selfie'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _verFoto(
                                    solicitud.fotoPropiedadUrl,
                                    'Foto Propiedad',
                                  ),
                                  icon: const Icon(Icons.home_work),
                                  label: const Text('Ver Propiedad'),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Botones de acción
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _rechazarSolicitud(solicitud),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Rechazar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _aprobarSolicitud(solicitud),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Aprobar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
