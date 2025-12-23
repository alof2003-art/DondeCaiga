import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/font_size_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'editar_perfil_screen.dart';

class ConfigurarPerfilScreen extends StatelessWidget {
  final String userId;
  final String nombreActual;
  final String? fotoActual;

  const ConfigurarPerfilScreen({
    super.key,
    required this.userId,
    required this.nombreActual,
    this.fotoActual,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Perfil'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ResponsiveWrapper(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección: Editar Perfil
              _buildSeccionHeader(
                context,
                'Información Personal',
                Icons.person,
              ),
              const SizedBox(height: 16),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Editar Perfil'),
                  subtitle: const Text('Cambiar nombre y foto de perfil'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    final resultado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditarPerfilScreen(
                          userId: userId,
                          nombreActual: nombreActual,
                          fotoActual: fotoActual,
                        ),
                      ),
                    );

                    // Si hubo cambios, regresar con resultado
                    if (resultado == true && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Sección: Tamaño de Letra
              _buildSeccionHeader(
                context,
                'Accesibilidad',
                Icons.accessibility,
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.text_fields, color: Colors.green),
                          const SizedBox(width: 12),
                          Text(
                            'Tamaño de Letra',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Consumer<FontSizeService>(
                        builder: (context, fontService, child) {
                          return Column(
                            children: [
                              // Preview del texto
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Vista Previa',
                                      style: fontService.scaleTextStyle(
                                        Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Este es un ejemplo de cómo se verá el texto con el tamaño seleccionado.',
                                      style: fontService.scaleTextStyle(
                                        Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Opciones de tamaño
                              Column(
                                children: FontSizeLevel.values.map((level) {
                                  final isSelected =
                                      fontService.currentLevel == level;
                                  return InkWell(
                                    onTap: () => fontService.setFontSize(level),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                                  .withValues(alpha: 0.1)
                                            : null,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context).dividerColor,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_unchecked,
                                            color: isSelected
                                                ? Theme.of(context).primaryColor
                                                : Theme.of(
                                                    context,
                                                  ).disabledColor,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  level.label,
                                                  style: TextStyle(
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                Text(
                                                  '${(level.scale * 100).toInt()}%',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Información adicional
              Card(
                color: Colors.blue.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Los cambios en el tamaño de letra se aplicarán inmediatamente en toda la aplicación.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionHeader(
    BuildContext context,
    String titulo,
    IconData icono,
  ) {
    return Row(
      children: [
        Icon(icono, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}
