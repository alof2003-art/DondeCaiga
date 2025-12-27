# 🔗 EJEMPLO DE INTEGRACIÓN - SISTEMA DE NOTIFICACIONES

## 📋 CÓMO USAR EL SISTEMA EN TU APP

### 1. 🚀 INICIALIZACIÓN

#### En `main.dart` (Ya implementado)
```dart
Future<void> main() async {
  // ... otras inicializaciones
  
  // Inicializar notificaciones push
  final pushService = PushNotificationsService();
  await pushService.initialize();
  
  // Crear provider de notificaciones
  final notificacionesProvider = NotificacionesProvider();
  
  runApp(MyApp(notificacionesProvider: notificacionesProvider));
}
```

#### En login/logout
```dart
// Al hacer login exitoso
await context.read<NotificacionesProvider>().inicializar();

// Al hacer logout
context.read<NotificacionesProvider>().limpiar();
```

---

### 2. 🏠 INTEGRACIÓN EN RESERVAS

#### Crear nueva reserva
```dart
// En tu ReservasRepository o donde manejes las reservas
class ReservasRepository {
  Future<void> crearReserva({
    required String propiedadId,
    required String viajeroId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    BuildContext? context,
  }) async {
    try {
      // 1. Crear la reserva en la base de datos
      final reserva = await supabase.from('reservas').insert({
        'propiedad_id': propiedadId,
        'viajero_id': viajeroId,
        'fecha_inicio': fechaInicio.toIso8601String(),
        'fecha_fin': fechaFin.toIso8601String(),
        'estado': 'pendiente',
      }).select().single();

      // 2. Obtener datos para la notificación
      final propiedad = await supabase
          .from('propiedades')
          .select('nombre, usuario_id')
          .eq('id', propiedadId)
          .single();

      final viajero = await supabase
          .from('profiles')
          .select('nombre_completo')
          .eq('id', viajeroId)
          .single();

      // 3. Crear notificación para el anfitrión
      await NotificacionesHelper.crearNotificacionNuevaReserva(
        anfitrionId: propiedad['usuario_id'],
        viajeroNombre: viajero['nombre_completo'],
        propiedadNombre: propiedad['nombre'],
        reservaId: reserva['id'],
        context: context,
      );

      debugPrint('✅ Reserva creada y notificación enviada');
    } catch (e) {
      debugPrint('❌ Error al crear reserva: $e');
      rethrow;
    }
  }
}
```

#### Aceptar/Rechazar reserva
```dart
Future<void> actualizarEstadoReserva({
  required String reservaId,
  required String nuevoEstado, // 'aceptada' o 'rechazada'
  String? comentario,
  BuildContext? context,
}) async {
  try {
    // 1. Actualizar estado en la base de datos
    await supabase.from('reservas').update({
      'estado': nuevoEstado,
      'comentario_rechazo': comentario,
      'fecha_actualizacion': DateTime.now().toIso8601String(),
    }).eq('id', reservaId);

    // 2. Obtener datos de la reserva
    final reservaData = await supabase
        .from('reservas')
        .select('''
          viajero_id,
          propiedades!inner(nombre)
        ''')
        .eq('id', reservaId)
        .single();

    // 3. Crear notificación para el viajero
    await NotificacionesHelper.crearNotificacionDecisionReserva(
      viajeroId: reservaData['viajero_id'],
      aceptada: nuevoEstado == 'aceptada',
      propiedadNombre: reservaData['propiedades']['nombre'],
      reservaId: reservaId,
      comentario: comentario,
      context: context,
    );

    debugPrint('✅ Estado de reserva actualizado y notificación enviada');
  } catch (e) {
    debugPrint('❌ Error al actualizar estado de reserva: $e');
    rethrow;
  }
}
```

---

### 3. ⭐ INTEGRACIÓN EN RESEÑAS

#### Crear nueva reseña
```dart
class ResenasRepository {
  Future<void> crearResena({
    required String autorId,
    required String objetivoId, // ID del usuario o propiedad reseñada
    required int calificacion,
    required String comentario,
    required bool esResenaPropiedad,
    String? propiedadId,
    BuildContext? context,
  }) async {
    try {
      // 1. Crear reseña en la base de datos
      await supabase.from('resenas').insert({
        'autor_id': autorId,
        'objetivo_id': objetivoId,
        'calificacion': calificacion,
        'comentario': comentario,
        'es_resena_propiedad': esResenaPropiedad,
        'propiedad_id': propiedadId,
      });

      // 2. Obtener datos para la notificación
      final autor = await supabase
          .from('profiles')
          .select('nombre_completo')
          .eq('id', autorId)
          .single();

      String? propiedadNombre;
      if (esResenaPropiedad && propiedadId != null) {
        final propiedad = await supabase
            .from('propiedades')
            .select('nombre')
            .eq('id', propiedadId)
            .single();
        propiedadNombre = propiedad['nombre'];
      }

      // 3. Crear notificación
      await NotificacionesHelper.crearNotificacionNuevaResena(
        usuarioId: objetivoId,
        autorNombre: autor['nombre_completo'],
        calificacion: calificacion,
        esResenaPropiedad: esResenaPropiedad,
        propiedadNombre: propiedadNombre,
        context: context,
      );

      debugPrint('✅ Reseña creada y notificación enviada');
    } catch (e) {
      debugPrint('❌ Error al crear reseña: $e');
      rethrow;
    }
  }
}
```

---

### 4. 💬 INTEGRACIÓN EN CHAT

#### Enviar mensaje
```dart
class ChatRepository {
  Future<void> enviarMensaje({
    required String chatId,
    required String emisorId,
    required String receptorId,
    required String mensaje,
    BuildContext? context,
  }) async {
    try {
      // 1. Guardar mensaje en la base de datos
      await supabase.from('mensajes').insert({
        'chat_id': chatId,
        'emisor_id': emisorId,
        'receptor_id': receptorId,
        'mensaje': mensaje,
      });

      // 2. Obtener datos del emisor
      final emisor = await supabase
          .from('profiles')
          .select('nombre_completo, avatar_url')
          .eq('id', emisorId)
          .single();

      // 3. Crear notificación para el receptor
      await NotificacionesHelper.crearNotificacionNuevoMensaje(
        receptorId: receptorId,
        emisorNombre: emisor['nombre_completo'],
        chatId: chatId,
        mensajePreview: mensaje,
        avatarUrl: emisor['avatar_url'],
        context: context,
      );

      debugPrint('✅ Mensaje enviado y notificación creada');
    } catch (e) {
      debugPrint('❌ Error al enviar mensaje: $e');
      rethrow;
    }
  }
}
```

---

### 5. 👤 INTEGRACIÓN EN SISTEMA DE ANFITRIÓN

#### Procesar solicitud de anfitrión (Admin)
```dart
class AdminRepository {
  Future<void> procesarSolicitudAnfitrion({
    required String usuarioId,
    required bool aceptar,
    required String comentarioAdmin,
    BuildContext? context,
  }) async {
    try {
      // 1. Actualizar estado del usuario
      await supabase.from('profiles').update({
        'es_anfitrion': aceptar,
        'solicitud_anfitrion_estado': aceptar ? 'aprobada' : 'rechazada',
        'comentario_admin': comentarioAdmin,
      }).eq('id', usuarioId);

      // 2. Crear notificación
      await NotificacionesHelper.crearNotificacionDecisionAnfitrion(
        usuarioId: usuarioId,
        aceptado: aceptar,
        comentarioAdmin: comentarioAdmin,
        context: context,
      );

      debugPrint('✅ Solicitud de anfitrión procesada y notificación enviada');
    } catch (e) {
      debugPrint('❌ Error al procesar solicitud de anfitrión: $e');
      rethrow;
    }
  }
}
```

---

### 6. 🎨 INTEGRACIÓN EN UI

#### Agregar icono a cualquier AppBar
```dart
class MiPantallaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Pantalla'),
        actions: [
          // Icono de notificaciones con badge
          IconoNotificacionesCompacto(),
        ],
      ),
      body: MiContenido(),
    );
  }
}
```

#### Mostrar contador en navegación
```dart
class BottomNavigationBarCustom extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<NotificacionesProvider>(
      builder: (context, notificaciones, child) {
        return BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: notificaciones.hayNotificacionesNoLeidas,
                label: Text('${notificaciones.contadorNoLeidas}'),
                child: Icon(Icons.notifications),
              ),
              label: 'Notificaciones',
            ),
            // ... otros items
          ],
        );
      },
    );
  }
}
```

#### Usar extension para facilitar el uso
```dart
class ReservaScreen extends StatelessWidget {
  Future<void> _crearReserva() async {
    try {
      // Crear reserva...
      
      // Notificar usando la extension
      await context.notificarNuevaReserva(
        anfitrionId: anfitrionId,
        viajeroNombre: 'Juan Pérez',
        propiedadNombre: 'Casa en la playa',
        reservaId: reservaId,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reserva creada exitosamente')),
      );
    } catch (e) {
      // Manejar error...
    }
  }
}
```

---

### 7. 🔄 MANEJO DE ESTADOS

#### Escuchar cambios en tiempo real
```dart
class NotificacionesWidget extends StatefulWidget {
  @override
  _NotificacionesWidgetState createState() => _NotificacionesWidgetState();
}

class _NotificacionesWidgetState extends State<NotificacionesWidget> {
  @override
  void initState() {
    super.initState();
    
    // Inicializar notificaciones al cargar el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificacionesProvider>().inicializar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificacionesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return CircularProgressIndicator();
        }

        return Column(
          children: [
            // Mostrar contador
            if (provider.hayNotificacionesNoLeidas)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${provider.contadorNoLeidas} nuevas notificaciones',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            
            // Lista de notificaciones
            Expanded(
              child: ListView.builder(
                itemCount: provider.notificaciones.length,
                itemBuilder: (context, index) {
                  final notificacion = provider.notificaciones[index];
                  return NotificacionCard(notificacion: notificacion);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
```

---

### 8. 🧪 TESTING

#### Test de notificaciones
```dart
void main() {
  group('Notificaciones Tests', () {
    testWidgets('Debe mostrar badge cuando hay notificaciones no leídas', (tester) async {
      // Arrange
      final provider = NotificacionesProvider();
      provider.setContadorNoLeidas(5); // Mock

      // Act
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: [IconoNotificacionesCompacto()],
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('5'), findsOneWidget);
      expect(find.byType(Badge), findsOneWidget);
    });

    test('Debe crear notificación correctamente', () async {
      // Arrange
      final helper = NotificacionesHelper();

      // Act
      await helper.crearNotificacionNuevaReserva(
        anfitrionId: 'test-anfitrion-id',
        viajeroNombre: 'Test Viajero',
        propiedadNombre: 'Test Propiedad',
        reservaId: 'test-reserva-id',
      );

      // Assert
      // Verificar que la notificación se creó en la base de datos
    });
  });
}
```

---

### 9. 🚀 MEJORES PRÁCTICAS

#### ✅ DO (Hacer)
```dart
// Usar el helper para crear notificaciones
await NotificacionesHelper.crearNotificacionNuevaReserva(/* ... */);

// Pasar el context para actualizar el UI automáticamente
await helper.crearNotificacion(context: context);

// Manejar errores gracefully
try {
  await crearNotificacion();
} catch (e) {
  debugPrint('Error: $e');
  // No mostrar error al usuario, es background
}

// Usar extensions para código más limpio
await context.notificarNuevoMensaje(/* ... */);
```

#### ❌ DON'T (No hacer)
```dart
// No crear notificaciones directamente en el repository
await supabase.from('notificaciones').insert(/* ... */); // ❌

// No olvidar manejar errores
await crearNotificacion(); // ❌ Sin try-catch

// No bloquear el UI esperando notificaciones
await crearNotificacion(); // ❌ En el UI thread

// No crear notificaciones duplicadas
// Verificar antes de crear
```

---

### 10. 📊 MONITOREO Y DEBUG

#### Logs útiles
```dart
// Habilitar logs detallados
debugPrint('📱 Creando notificación: ${notificacion.tipo}');
debugPrint('👤 Para usuario: ${notificacion.usuarioId}');
debugPrint('📝 Mensaje: ${notificacion.mensaje}');

// Monitorear rendimiento
final stopwatch = Stopwatch()..start();
await crearNotificacion();
debugPrint('⏱️ Notificación creada en: ${stopwatch.elapsedMilliseconds}ms');
```

#### Métricas importantes
- Tiempo de creación de notificaciones
- Tasa de entrega de push notifications
- Tasa de apertura de notificaciones
- Errores en la creación

---

## 🎯 RESUMEN

Con esta integración tienes:

✅ **Sistema completo** de notificaciones en tiempo real  
✅ **Fácil de usar** con helpers y extensions  
✅ **Automático** - se integra con tus flujos existentes  
✅ **Escalable** - maneja miles de notificaciones  
✅ **Robusto** - manejo de errores y fallbacks  

**¡Tu app ahora mantiene a los usuarios siempre informados! 🔔✨**