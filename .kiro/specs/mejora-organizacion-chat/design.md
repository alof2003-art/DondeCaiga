# Documento de Diseño - Mejora de Organización del Chat

## Overview

El sistema de mejora de organización del chat transforma la pantalla actual de chat de una lista simple a una interfaz organizada con dos apartados principales: "Mis Viajes" y "Mis Reservas". Cada apartado tiene colores distintivos, filtros específicos y funcionalidades adaptadas al rol del usuario (viajero vs anfitrión). El sistema integra la funcionalidad de reseñas existente y mejora la experiencia de usuario con navegación intuitiva y información contextual.

## Architecture

### Patrón Arquitectónico
El sistema extiende la funcionalidad del `ChatListaScreen` existente, manteniendo la arquitectura Clean Architecture:

```
lib/features/buzon/
├── data/
│   ├── models/
│   │   ├── chat_apartado.dart (nuevo)
│   │   ├── filtro_chat.dart (nuevo)
│   │   └── reserva_chat_info.dart (nuevo)
│   ├── repositories/
│   │   └── chat_repository.dart (extender existente)
│   └── services/
│       └── chat_filter_service.dart (nuevo)
└── presentation/
    ├── screens/
    │   └── chat_lista_screen.dart (refactorizar)
    └── widgets/
        ├── apartado_mis_viajes.dart (nuevo)
        ├── apartado_mis_reservas.dart (nuevo)
        ├── filtros_chat_dialog.dart (nuevo)
        ├── reserva_card_viajero.dart (nuevo)
        └── reserva_card_anfitrion.dart (nuevo)
```

### Integración con Sistema Existente
- **Pantalla Principal**: Refactoriza `ChatListaScreen` con arquitectura de pestañas/apartados
- **Modelos**: Extiende `Reserva` con información adicional para el contexto del chat
- **Repositorio**: Extiende funcionalidad para obtener reservas categorizadas
- **Reseñas**: Integra con el sistema de reseñas existente para mostrar estado y permitir creación

## Components and Interfaces

### Core Components

#### 1. ChatRepository (Extensión)
```dart
class ChatRepository {
  // Métodos existentes...
  
  // Nuevos métodos para apartados
  Future<List<Reserva>> obtenerReservasViajeroVigentes(String userId);
  Future<List<Reserva>> obtenerReservasViajeroPasadas(String userId);
  Future<List<Reserva>> obtenerReservasAnfitrionVigentes(String userId);
  Future<List<Reserva>> obtenerReservasAnfitrionPasadas(String userId);
  Future<bool> puedeResenar(String reservaId, String userId);
  Future<bool> yaReseno(String reservaId, String userId);
}
```

#### 2. ChatFilterService
```dart
class ChatFilterService {
  List<Reserva> aplicarFiltros(List<Reserva> reservas, FiltroChat filtro);
  List<Reserva> filtrarPorLugar(List<Reserva> reservas, String termino);
  List<Reserva> ordenarPorFecha(List<Reserva> reservas, OrdenFecha orden);
  List<Reserva> ordenarAlfabeticamente(List<Reserva> reservas, bool ascendente);
  List<Reserva> filtrarPorEstado(List<Reserva> reservas, EstadoReserva estado);
}
```

### UI Components

#### 1. ChatListaScreen (Refactorizada)
- Implementa `TabController` para manejar dos apartados
- Mantiene estado de filtros independiente por apartado
- Coordina la carga de datos y actualización de UI

#### 2. ApartadoMisViajes
- Muestra reserva vigente actual (si existe)
- Lista reservas pasadas con opción de reseñar
- Colores azules distintivos
- Mensaje de "Explora por más lugares" cuando no hay reservas

#### 3. ApartadoMisReservas
- Muestra reservas vigentes en propiedades del usuario
- Lista reservas pasadas en propiedades
- Colores verdes distintivos
- Mensaje para convertirse en anfitrión si no lo es

#### 4. FiltrosChatDialog
- Interfaz unificada de filtros para ambos apartados
- Filtros específicos según el contexto (viajero/anfitrión)
- Persistencia de filtros por apartado

## Data Models

### ChatApartado
```dart
enum TipoApartado { misViajes, misReservas }

class ChatApartado {
  final TipoApartado tipo;
  final String titulo;
  final Color colorPrimario;
  final Color colorSecundario;
  final IconData icono;
  final List<Reserva> reservasVigentes;
  final List<Reserva> reservasPasadas;
}
```

### FiltroChat
```dart
class FiltroChat {
  final String? terminoBusqueda;
  final OrdenFecha? ordenFecha;
  final bool ordenAlfabetico;
  final bool ascendente;
  final EstadoFiltro? estadoFiltro;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
}

enum OrdenFecha { masReciente, masAntigua, rango }
enum EstadoFiltro { vigentes, pasadas, conResenasPendientes }
```

### ReservaChatInfo
```dart
class ReservaChatInfo extends Reserva {
  final bool esVigente;
  final int? diasRestantes;
  final String? tiempoTranscurrido;
  final bool puedeResenar;
  final bool yaReseno;
  final double? calificacionOtroUsuario;
  final String? fotoPerfilOtroUsuario;
}
```

## UI Design Specifications

### Esquema de Colores

#### Apartado "Mis Viajes" (Azul)
- **Color Primario**: `#2196F3` (Blue)
- **Color Secundario**: `#E3F2FD` (Light Blue)
- **Color Acento**: `#1976D2` (Dark Blue)
- **Reservas Vigentes**: Borde azul intenso `#1976D2`
- **Reservas Pasadas**: Azul tenue `#90CAF9` con opacidad 0.7

#### Apartado "Mis Reservas" (Verde)
- **Color Primario**: `#4CAF50` (Green)
- **Color Secundario**: `#E8F5E8` (Light Green)
- **Color Acento**: `#388E3C` (Dark Green)
- **Reservas Vigentes**: Borde verde intenso `#388E3C`
- **Reservas Pasadas**: Verde tenue `#A5D6A7` con opacidad 0.7

#### Elementos Especiales
- **Reseña Pendiente**: `#FF9800` (Orange)
- **Estados de Carga**: `#9E9E9E` (Grey)
- **Mensajes de Estado**: `#607D8B` (Blue Grey)

### Layout Structure

```
ChatListaScreen
├── AppBar (con filtros)
├── TabBar
│   ├── Tab "Mis Viajes" (Azul)
│   └── Tab "Mis Reservas" (Verde)
└── TabBarView
    ├── ApartadoMisViajes
    │   ├── ReservaVigenteCard (si existe)
    │   ├── Divider "Lugares que ya visitaste"
    │   └── List<ReservaPasadaCard>
    └── ApartadoMisReservas
        ├── Divider "Reservas vigentes"
        ├── List<ReservaVigenteCard>
        ├── Divider "Reservas pasadas"
        └── List<ReservaPasadaCard>
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Propiedades de Correctness

**Property 1: Separación correcta de apartados**
*Para cualquier* usuario con reservas, el sistema debe mostrar las reservas como viajero en "Mis Viajes" y las reservas en sus propiedades en "Mis Reservas"
**Validates: Requirements 1.1, 2.1**

**Property 2: Colores distintivos por apartado**
*Para cualquier* apartado mostrado, el sistema debe usar consistentemente los colores azules para "Mis Viajes" y verdes para "Mis Reservas"
**Validates: Requirements 3.1, 3.2**

**Property 3: Ordenamiento temporal correcto**
*Para cualquier* lista de reservas, las reservas vigentes deben aparecer antes que las reservas pasadas
**Validates: Requirements 1.2, 2.2**

**Property 4: Control de reseñas único**
*Para cualquier* reserva pasada como viajero, el sistema debe permitir reseñar solo una vez y solo después de completar la estancia
**Validates: Requirements 1.5, 1.6, 5.1, 5.4**

**Property 5: Filtrado consistente**
*Para cualquier* filtro aplicado, el sistema debe mostrar solo las reservas que cumplan todos los criterios seleccionados
**Validates: Requirements 4.2, 4.3, 4.4, 4.5**

**Property 6: Persistencia de filtros por apartado**
*Para cualquier* cambio entre apartados, el sistema debe mantener los filtros específicos de cada apartado independientemente
**Validates: Requirements 6.2**

**Property 7: Mensajes de estado apropiados**
*Para cualquier* apartado sin contenido, el sistema debe mostrar mensajes específicos y acciones sugeridas apropiadas
**Validates: Requirements 1.3, 2.4, 2.5, 6.3**

**Property 8: Información temporal precisa**
*Para cualquier* reserva mostrada, el sistema debe calcular correctamente los días restantes para reservas vigentes o tiempo transcurrido para reservas pasadas
**Validates: Requirements 7.1, 7.2**

**Property 9: Integración correcta con reseñas**
*Para cualquier* reserva completada como viajero, el sistema debe verificar correctamente si puede reseñar y actualizar el estado después de reseñar
**Validates: Requirements 5.2, 5.3**

**Property 10: Rendimiento con paginación**
*Para cualquier* usuario con muchas reservas, el sistema debe cargar eficientemente usando paginación sin afectar la experiencia de usuario
**Validates: Requirements 8.1, 8.2**

## Error Handling

### Categorías de Errores

#### 1. Errores de Carga de Datos
- **NoReservasError**: Cuando no hay reservas para mostrar
- **ConnectionError**: Problemas de conectividad
- **DataSyncError**: Errores de sincronización de datos

#### 2. Errores de Filtros
- **InvalidFilterError**: Filtros con parámetros inválidos
- **FilterTimeoutError**: Filtros que toman demasiado tiempo

#### 3. Errores de Reseñas
- **AlreadyReviewedError**: Intento de reseñar por segunda vez
- **ReviewNotAllowedError**: Intento de reseñar sin haber completado la estancia
- **ReviewSubmissionError**: Errores al enviar reseña

### Estrategias de Manejo

```dart
class ChatErrorHandler {
  static Widget handleEmptyState(TipoApartado apartado, bool esAnfitrion) {
    switch (apartado) {
      case TipoApartado.misViajes:
        return EmptyStateWidget(
          icon: Icons.explore,
          title: "Explora por más lugares",
          subtitle: "Descubre alojamientos increíbles",
          actionText: "Explorar",
          onAction: () => Navigator.pushNamed(context, '/explorar'),
        );
      case TipoApartado.misReservas:
        return esAnfitrion 
          ? EmptyStateWidget(
              icon: Icons.home,
              title: "No tienes reservas",
              subtitle: "Las reservas en tus alojamientos aparecerán aquí",
            )
          : EmptyStateWidget(
              icon: Icons.add_business,
              title: "Conviértete en anfitrión",
              subtitle: "Comparte tu espacio y recibe huéspedes",
              actionText: "Ser Anfitrión",
              onAction: () => Navigator.pushNamed(context, '/solicitar-anfitrion'),
            );
    }
  }
}
```

## Testing Strategy

### Dual Testing Approach

#### Unit Testing
- **Filtros**: Pruebas para cada tipo de filtro y combinaciones
- **Categorización**: Verificar correcta separación de reservas por apartado
- **Estados**: Validar cálculos de tiempo y estados de reseñas
- **Integración**: Pruebas de integración con sistema de reseñas

#### Property-Based Testing
- **Biblioteca**: Se utilizará el paquete `faker` para generar datos de prueba aleatorios
- **Configuración**: Cada prueba de propiedad ejecutará un mínimo de 100 iteraciones
- **Etiquetado**: Cada prueba incluirá el formato: `**Feature: mejora-organizacion-chat, Property {number}: {property_text}**`

#### Ejemplos de Pruebas de Propiedad

```dart
// **Feature: mejora-organizacion-chat, Property 1: Separación correcta de apartados**
test('should correctly separate reservations by user role', () {
  final faker = Faker();
  
  // Generate random reservations with different user roles
  final reservations = List.generate(100, (index) => Reserva(
    viajeroId: faker.randomGenerator.boolean() ? 'user-123' : faker.guid.guid(),
    anfitrionId: faker.randomGenerator.boolean() ? 'user-123' : faker.guid.guid(),
    // ... other random fields
  ));
  
  final apartados = ChatService.categorizarReservas(reservations, 'user-123');
  
  // Property: All reservations in "Mis Viajes" should have user as viajero
  expect(apartados.misViajes.every((r) => r.viajeroId == 'user-123'), isTrue);
  // Property: All reservations in "Mis Reservas" should have user as anfitrion
  expect(apartados.misReservas.every((r) => r.anfitrionId == 'user-123'), isTrue);
});

// **Feature: mejora-organizacion-chat, Property 4: Control de reseñas único**
test('should allow review only once per completed reservation', () {
  final faker = Faker();
  
  // Generate random completed reservations
  final reservations = List.generate(50, (index) => Reserva(
    fechaFin: faker.date.dateTime(minYear: 2020, maxYear: 2023),
    estado: 'completada',
    // ... other random fields
  ));
  
  for (final reserva in reservations) {
    final canReview = ChatService.puedeResenar(reserva, 'user-123');
    
    // Property: Should be able to review completed reservations
    expect(canReview, isTrue);
    
    // Simulate review submission
    ChatService.marcarComoResenado(reserva.id, 'user-123');
    
    // Property: Should not be able to review again
    expect(ChatService.puedeResenar(reserva, 'user-123'), isFalse);
  }
});
```

### Testing Requirements
- Cada propiedad de correctness debe ser implementada por UNA SOLA prueba basada en propiedades
- Las pruebas unitarias y de propiedades son complementarias
- Se debe verificar la correcta integración con el sistema de reseñas existente
- Las pruebas deben cubrir todos los escenarios de filtrado y categorización