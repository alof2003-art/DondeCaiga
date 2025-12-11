# Servicios del Sistema de Chat/Buzón

Esta carpeta contiene los servicios específicos para el manejo de filtros y persistencia del sistema de chat.

## Estructura de Servicios

### `chat_filter_service.dart`
- **Propósito**: Aplicar filtros avanzados a las reservas del chat
- **Funcionalidades**:
  - Filtrado por término de búsqueda
  - Filtrado por estado (vigentes, pasadas, con reseñas pendientes)
  - Ordenamiento por fecha y alfabético
  - Filtrado por rango de fechas
  - Cache para mejorar rendimiento
  - Filtros inteligentes y sugerencias

### `filter_storage.dart`
- **Propósito**: Persistir filtros del chat en almacenamiento local
- **Funcionalidades**:
  - Guardar filtros por apartado (Mis Viajes / Mis Reservas)
  - Cargar filtros guardados
  - Limpiar filtros específicos
  - Manejo de errores silencioso



### `services.dart`
- **Propósito**: Barrel file para exportar todos los servicios
- **Uso**: Permite importar todos los servicios con una sola línea

## Uso Recomendado

```dart
import '../../data/services/services.dart';

// En tu widget o clase
final filterService = ChatFilterService();
final storageService = FilterStorage();
```

## Dependencias

- `shared_preferences`: Para persistencia local
- `../models/filtro_chat.dart`: Modelo de filtros
- `../models/reserva_chat_info.dart`: Modelo extendido de reservas
- `../models/chat_apartado.dart`: Modelo de apartados

## Notas Importantes

- Los servicios están optimizados para rendimiento con cache
- El manejo de errores es silencioso para no interrumpir la UX
- Los filtros se persisten automáticamente por apartado
- Compatible con el sistema de reservas existente