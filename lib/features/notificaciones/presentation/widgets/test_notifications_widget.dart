import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firebase_notifications_service.dart';

/// 🧪 WIDGET DE PRUEBA PARA NOTIFICACIONES
class TestNotificationsWidget extends StatefulWidget {
  const TestNotificationsWidget({super.key});

  @override
  State<TestNotificationsWidget> createState() =>
      _TestNotificationsWidgetState();
}

class _TestNotificationsWidgetState extends State<TestNotificationsWidget> {
  final _service = FirebaseNotificationsService();
  String? _currentToken;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _loadTokenAndPermissions();
  }

  Future<void> _loadTokenAndPermissions() async {
    final token = await _service.getCurrentToken();
    final permissions = await _service.areNotificationsEnabled();

    setState(() {
      _currentToken = token;
      _permissionsGranted = permissions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Test de Notificaciones Firebase',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Estado de permisos
            _buildStatusRow(
              'Permisos concedidos',
              _permissionsGranted,
              Icons.security,
            ),

            // Estado del servicio
            _buildStatusRow(
              'Servicio inicializado',
              _service.isInitialized,
              Icons.settings,
            ),

            // Token FCM
            const SizedBox(height: 16),
            Text(
              'Token FCM:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _currentToken != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentToken!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _currentToken!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Token copiado al portapapeles'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copiar Token'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Token no disponible',
                      style: TextStyle(color: Colors.red),
                    ),
            ),

            const SizedBox(height: 16),

            // Botón de actualizar
            ElevatedButton.icon(
              onPressed: _loadTokenAndPermissions,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Actualizar Estado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Instrucciones
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Cómo probar:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Copia el token FCM\n'
                    '2. Ve a Firebase Console > Messaging\n'
                    '3. Crea "Nueva campaña"\n'
                    '4. Selecciona "Enviar mensaje de prueba"\n'
                    '5. Pega el token y envía',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: status ? Colors.green : Colors.red),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
        ],
      ),
    );
  }
}
