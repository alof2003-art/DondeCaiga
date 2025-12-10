# Design Document

## Overview

Este documento describe el diseño técnico para corregir dos problemas críticos en el sistema de reservas:
1. Prevenir múltiples reservas simultáneas por usuario
2. Corregir la validación de disponibilidad de fechas

## Architecture

### Componentes Afectados:

```
┌─────────────────────────────────────┐
│  ReservaCalendarioScreen            │
│  - Validación de reservas activas   │
│  - Validación de disponibilidad     │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  ReservaRepository                  │
│  + verificarReservasActivas()       │ ← NUEVO
│  + verificarDisponibilidad()        │ ← MEJORADO
│  + obtenerFechasOcupadas()          │ ← MEJORADO
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Supabase Database                  │
│  - Tabla: reservas                  │
└─────────────────────────────────────┘
```

## Components and Interfaces

### 1. ReservaRepository

#### Nuevo Método: `verificarReservasActivas()`

```dart
/// Verificar si un viajero tiene reservas activas futuras
/// Retorna true si tiene reservas activas, false si no
Future<bool> verificarReservasActivas(String viajeroId) async
```

**Lógica**:
- Consultar reservas del viajero
- Filtrar por estado: 'pendiente' o 'confirmada'
- Filtrar por fecha_inicio >= hoy
- Retornar true si existe al menos una

#### Método Mejorado: `verificarDisponibilidad()`

**Problema Actual**:
```dart
.or('fecha_inicio.lte.${fechaFin},fecha_fin.gte.${fechaInicio}')
```

Esta consulta está mal formada y puede causar falsos positivos.

**Solución**:
```dart
// Buscar reservas que se solapen con el rango solicitado
// Hay solapamiento si:
// - La reserva existente empieza antes o durante nuestro rango Y termina después o durante nuestro inicio
```

**Nueva Lógica**:
- Usar filtros separados más claros
- Verificar solapamiento correcto de rangos
- Considerar solo estados 'pendiente' y 'confirmada'

#### Método Mejorado: `obtenerFechasOcupadas()`

**Mejora**: Asegurar que solo se marquen fechas de reservas activas

### 2. ReservaCalendarioScreen

#### Flujo de Validación Actualizado:

```
Usuario presiona "Confirmar Reserva"
         │
         ▼
┌─────────────────────────────────────┐
│ 1. Verificar reservas activas       │
│    del usuario                      │
└──────────────┬──────────────────────┘
               │
               ├─── SI tiene ───> Mostrar mensaje
               │                  "Ya tienes una reserva activa"
               │                  DETENER
               │
               ▼ NO tiene
┌─────────────────────────────────────┐
│ 2. Verificar disponibilidad         │
│    de fechas                        │
└──────────────┬──────────────────────┘
               │
               ├─── NO disponible ───> Mostrar mensaje
               │                       "Fechas no disponibles"
               │                       DETENER
               │
               ▼ Disponible
┌─────────────────────────────────────┐
│ 3. Crear reserva                    │
└─────────────────────────────────────┘
```

## Data Models

### Reserva (sin cambios)

El modelo existente es suficiente. Solo se mejora la lógica de consultas.

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Unicidad de reserva activa por viajero

*For any* viajero, en cualquier momento, el viajero debe tener como máximo una reserva activa futura (pendiente o confirmada)

**Validates: Requirements 1.1, 1.2**

### Property 2: No solapamiento de fechas

*For any* propiedad y dos reservas activas diferentes, los rangos de fechas no deben solaparse

**Validates: Requirements 2.1, 2.2, 2.3**

### Property 3: Validación de estado

*For any* validación de disponibilidad, solo se deben considerar reservas con estado 'pendiente' o 'confirmada'

**Validates: Requirements 1.4, 2.4, 3.3**

### Property 4: Precisión de fechas ocupadas

*For any* propiedad, las fechas marcadas como ocupadas deben corresponder exactamente a los días de reservas activas

**Validates: Requirements 3.4**

## Error Handling

### Errores a Manejar:

1. **Usuario con reserva activa**:
   - Tipo: Validación de negocio
   - Mensaje: "Ya tienes una reserva activa. Completa tu reserva actual antes de crear una nueva."
   - Color: Naranja (advertencia)
   - Acción: Detener creación

2. **Fechas no disponibles**:
   - Tipo: Conflicto de disponibilidad
   - Mensaje: "Las fechas seleccionadas no están disponibles. Por favor selecciona otras fechas."
   - Color: Naranja (advertencia)
   - Acción: Permitir seleccionar otras fechas

3. **Error de red/base de datos**:
   - Tipo: Error técnico
   - Mensaje: "Error al verificar disponibilidad: [detalle]"
   - Color: Rojo (error)
   - Acción: Reintentar

## Testing Strategy

### Unit Tests

1. **Test: Usuario sin reservas activas puede crear reserva**
   - Setup: Usuario sin reservas
   - Acción: Intentar crear reserva
   - Esperado: Permitir creación

2. **Test: Usuario con reserva activa no puede crear otra**
   - Setup: Usuario con reserva pendiente futura
   - Acción: Intentar crear reserva
   - Esperado: Rechazar con mensaje apropiado

3. **Test: Fechas sin solapamiento están disponibles**
   - Setup: Reserva del 1-5 de enero
   - Acción: Intentar reservar del 10-15 de enero
   - Esperado: Permitir reserva

4. **Test: Fechas con solapamiento no están disponibles**
   - Setup: Reserva del 1-10 de enero
   - Acción: Intentar reservar del 5-15 de enero
   - Esperado: Rechazar reserva

5. **Test: Reservas completadas no bloquean disponibilidad**
   - Setup: Reserva completada del 1-5 de enero
   - Acción: Intentar reservar del 1-5 de enero
   - Esperado: Permitir reserva

### Property-Based Tests

Se utilizará el framework de testing de Dart/Flutter para implementar tests basados en propiedades.

**Configuración**: Mínimo 100 iteraciones por test

### Integration Tests

1. **Test: Flujo completo de creación de reserva**
   - Verificar validaciones en orden
   - Verificar mensajes de error
   - Verificar creación exitosa

## Implementation Details

### Cambios en ReservaRepository

#### 1. Nuevo método `verificarReservasActivas()`

```dart
/// Verificar si un viajero tiene reservas activas futuras
Future<bool> verificarReservasActivas(String viajeroId) async {
  final hoy = DateTime.now();
  final hoyStr = DateTime(hoy.year, hoy.month, hoy.day).toIso8601String();
  
  final response = await _supabase
      .from('reservas')
      .select('id')
      .eq('viajero_id', viajeroId)
      .inFilter('estado', ['pendiente', 'confirmada'])
      .gte('fecha_inicio', hoyStr);
  
  return (response as List).isNotEmpty;
}
```

#### 2. Método mejorado `verificarDisponibilidad()`

```dart
/// Verificar si hay conflicto de fechas
Future<bool> verificarDisponibilidad({
  required String propiedadId,
  required DateTime fechaInicio,
  required DateTime fechaFin,
}) async {
  // Normalizar fechas (sin hora)
  final inicio = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
  final fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
  
  final response = await _supabase
      .from('reservas')
      .select('id, fecha_inicio, fecha_fin')
      .eq('propiedad_id', propiedadId)
      .inFilter('estado', ['pendiente', 'confirmada']);
  
  // Verificar solapamiento manualmente para mayor precisión
  for (final reserva in response as List) {
    final reservaInicio = DateTime.parse(reserva['fecha_inicio'] as String);
    final reservaFin = DateTime.parse(reserva['fecha_fin'] as String);
    
    // Hay solapamiento si:
    // - La nueva reserva empieza antes de que termine la existente Y
    // - La nueva reserva termina después de que empiece la existente
    if (inicio.isBefore(reservaFin.add(Duration(days: 1))) &&
        fin.isAfter(reservaInicio.subtract(Duration(days: 1)))) {
      return false; // No disponible
    }
  }
  
  return true; // Disponible
}
```

### Cambios en ReservaCalendarioScreen

#### Método `_crearReserva()` actualizado:

```dart
Future<void> _crearReserva() async {
  if (_fechaInicio == null || _fechaFin == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selecciona las fechas de inicio y fin'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  setState(() => _isCreating = true);

  try {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // PASO 1: Verificar si el usuario tiene reservas activas
    final tieneReservasActivas = await _reservaRepository.verificarReservasActivas(user.id);
    
    if (tieneReservasActivas) {
      throw Exception(
        'Ya tienes una reserva activa. Completa tu reserva actual antes de crear una nueva.'
      );
    }

    // PASO 2: Verificar disponibilidad de fechas
    final disponible = await _reservaRepository.verificarDisponibilidad(
      propiedadId: widget.propiedad.id,
      fechaInicio: _fechaInicio!,
      fechaFin: _fechaFin!,
    );

    if (!disponible) {
      throw Exception(
        'Las fechas seleccionadas no están disponibles. Por favor selecciona otras fechas.'
      );
    }

    // PASO 3: Crear reserva
    await _reservaRepository.crearReserva(
      propiedadId: widget.propiedad.id,
      viajeroId: user.id,
      fechaInicio: _fechaInicio!,
      fechaFin: _fechaFin!,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Reserva creada! Espera la confirmación del anfitrión'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop(true);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.orange,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isCreating = false);
    }
  }
}
```

## Performance Considerations

### Optimizaciones:

1. **Índices de Base de Datos**:
   - Ya existen índices en `viajero_id`, `propiedad_id`, `estado`, `fecha_inicio`, `fecha_fin`
   - No se requieren cambios

2. **Consultas**:
   - `verificarReservasActivas()`: Consulta simple con índices
   - `verificarDisponibilidad()`: Trae todas las reservas activas de la propiedad (normalmente pocas)

3. **Caché**:
   - No necesario por ahora
   - Considerar si hay problemas de rendimiento

## Security Considerations

### RLS (Row Level Security):

Las políticas existentes son suficientes:
- Viajeros pueden crear sus propias reservas
- Viajeros pueden ver sus propias reservas
- Anfitriones pueden ver reservas de sus propiedades

No se requieren cambios de seguridad.

## Migration Plan

### Pasos:

1. ✅ Actualizar `ReservaRepository`:
   - Agregar `verificarReservasActivas()`
   - Mejorar `verificarDisponibilidad()`

2. ✅ Actualizar `ReservaCalendarioScreen`:
   - Modificar `_crearReserva()`
   - Agregar validación de reservas activas

3. ✅ Probar manualmente:
   - Caso 1: Usuario sin reservas
   - Caso 2: Usuario con reserva activa
   - Caso 3: Fechas disponibles
   - Caso 4: Fechas ocupadas

4. ✅ Desplegar

### Rollback:

Si hay problemas, revertir cambios en `ReservaRepository` y `ReservaCalendarioScreen`.

## Conclusion

Este diseño soluciona ambos problemas:
1. Previene múltiples reservas simultáneas
2. Corrige la validación de disponibilidad

La implementación es simple, eficiente y no requiere cambios en la base de datos.
