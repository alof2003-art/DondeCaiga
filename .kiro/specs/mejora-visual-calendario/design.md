# Design Document

## Overview

Este documento describe el diseño técnico para mejorar la visualización del calendario de reservas, haciendo más evidente qué fechas están ocupadas mediante indicadores visuales en rojo y mensajes informativos.

## Architecture

### Componente Afectado:

```
┌─────────────────────────────────────┐
│  ReservaCalendarioScreen            │
│  - calendarBuilders (NUEVO)         │
│  - _onDaySelected (MEJORADO)        │
│  - calendarStyle (MEJORADO)         │
└─────────────────────────────────────┘
```

## Components and Interfaces

### ReservaCalendarioScreen

#### Cambios Necesarios:

1. **Agregar `calendarBuilders`** para personalizar la apariencia de fechas ocupadas
2. **Mejorar `_onDaySelected`** para mostrar mensaje cuando se toca fecha ocupada
3. **Actualizar `calendarStyle`** para mejorar contraste y legibilidad

## Data Models

No se requieren cambios en los modelos de datos. Se utilizan las estructuras existentes.

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Consistencia visual de fechas ocupadas

*For any* fecha ocupada en el calendario, el sistema debe mostrarla con fondo rojo y texto blanco

**Validates: Requirements 1.1, 1.2**

### Property 2: Retroalimentación al usuario

*For any* intento de seleccionar una fecha ocupada, el sistema debe mostrar un mensaje informativo

**Validates: Requirements 2.1, 2.2, 2.3**

### Property 3: No selección de fechas ocupadas

*For any* fecha ocupada, el sistema no debe permitir que sea seleccionada como parte de una reserva

**Validates: Requirements 2.4**

## Error Handling

### Mensajes al Usuario:

1. **Fecha ocupada seleccionada**:
   - Mensaje: "Esta fecha ya está reservada. Por favor selecciona otra fecha."
   - Color: Naranja (advertencia)
   - Duración: 2 segundos

## Testing Strategy

### Manual Testing

1. **Test: Fechas ocupadas se muestran en rojo**
   - Crear reserva en fechas específicas
   - Abrir calendario
   - Verificar que fechas ocupadas aparecen en rojo

2. **Test: Mensaje al tocar fecha ocupada**
   - Tocar una fecha ocupada
   - Verificar que aparece mensaje
   - Verificar que fecha no se selecciona

3. **Test: Fechas disponibles funcionan normal**
   - Tocar fecha disponible
   - Verificar que se selecciona normalmente

## Implementation Details

### Cambios en ReservaCalendarioScreen

#### 1. Agregar `calendarBuilders` al TableCalendar

```dart
TableCalendar(
  // ... configuración existente ...
  calendarBuilders: CalendarBuilders(
    // Personalizar días ocupados
    defaultBuilder: (context, day, focusedDay) {
      if (_esFechaOcupada(day)) {
        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${day.day}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
      return null; // Usar estilo por defecto
    },
  ),
  // ... resto de configuración ...
)
```

#### 2. Mejorar método `_onDaySelected`

```dart
void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
  // Verificar si la fecha está ocupada
  if (_esFechaOcupada(selectedDay)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Esta fecha ya está reservada. Por favor selecciona otra fecha.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
    return; // No permitir selección
  }

  // Verificar si es seleccionable (fecha pasada)
  if (!_esFechaSeleccionable(selectedDay)) {
    return;
  }

  // Lógica existente de selección...
  setState(() {
    _focusedDay = focusedDay;

    if (_fechaInicio == null || (_fechaInicio != null && _fechaFin != null)) {
      _fechaInicio = selectedDay;
      _fechaFin = null;
    } else if (selectedDay.isBefore(_fechaInicio!)) {
      _fechaInicio = selectedDay;
      _fechaFin = null;
    } else {
      // Verificar que no haya fechas ocupadas en el rango
      bool hayFechasOcupadas = false;
      for (
        var fecha = _fechaInicio!;
        fecha.isBefore(selectedDay) || fecha.isAtSameMomentAs(selectedDay);
        fecha = fecha.add(const Duration(days: 1))
      ) {
        if (_esFechaOcupada(fecha)) {
          hayFechasOcupadas = true;
          break;
        }
      }

      if (hayFechasOcupadas) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hay fechas ocupadas en el rango seleccionado'),
            backgroundColor: Colors.orange,
          ),
        );
        _fechaInicio = selectedDay;
        _fechaFin = null;
      } else {
        _fechaFin = selectedDay;
      }
    }
  });
}
```

#### 3. Actualizar `calendarStyle` (opcional, para mejorar contraste)

```dart
calendarStyle: CalendarStyle(
  // Fechas seleccionadas (verde/turquesa)
  selectedDecoration: BoxDecoration(
    color: const Color(0xFF4DB6AC),
    shape: BoxShape.circle,
  ),
  // Día de hoy
  todayDecoration: BoxDecoration(
    color: const Color(0xFF80CBC4),
    shape: BoxShape.circle,
  ),
  // Fechas deshabilitadas (pasadas)
  disabledDecoration: BoxDecoration(
    color: Colors.grey.shade300,
    shape: BoxShape.circle,
  ),
  disabledTextStyle: TextStyle(
    color: Colors.grey.shade500,
  ),
),
```

### Esquema de Colores

| Estado | Color | Uso |
|--------|-------|-----|
| Ocupado | Rojo (`Colors.red.shade400`) | Fechas con reservas activas |
| Seleccionado | Verde/Turquesa (`0xFF4DB6AC`) | Fechas seleccionadas por el usuario |
| Hoy | Turquesa claro (`0xFF80CBC4`) | Día actual |
| Pasado | Gris (`Colors.grey.shade300`) | Fechas pasadas (no seleccionables) |
| Disponible | Blanco/Default | Fechas disponibles para reservar |

## Performance Considerations

### Optimizaciones:

1. **CalendarBuilders**: Se ejecuta solo para días visibles en el calendario
2. **Caché de fechas ocupadas**: Ya se carga una vez al inicio
3. **No hay consultas adicionales**: Usa datos ya cargados

## Security Considerations

No hay cambios de seguridad. Solo mejoras visuales en la UI.

## Migration Plan

### Pasos:

1. ✅ Actualizar `ReservaCalendarioScreen`:
   - Agregar `calendarBuilders`
   - Mejorar `_onDaySelected`
   - Actualizar `calendarStyle` (opcional)

2. ✅ Probar manualmente:
   - Verificar fechas ocupadas en rojo
   - Verificar mensaje al tocar fecha ocupada
   - Verificar selección normal de fechas disponibles

3. ✅ Desplegar

### Rollback:

Si hay problemas, revertir cambios en `ReservaCalendarioScreen`.

## Visual Design

### Antes:
- Fechas ocupadas: Deshabilitadas (gris claro, poco visible)
- Sin retroalimentación al tocar

### Después:
- Fechas ocupadas: Rojo brillante con texto blanco (muy visible)
- Mensaje claro al tocar fecha ocupada

### Mockup de Colores:

```
┌─────────────────────────────────┐
│  Calendario                     │
├─────────────────────────────────┤
│  L  M  M  J  V  S  D           │
│                                 │
│  1  2  [3] 4  5  6  7          │
│     ⚪  🟢  ⚪                   │
│                                 │
│  8  9  [10][11]12 13 14        │
│     ⚪  🔴  🔴  ⚪              │
│                                 │
│ 15 16  17  18 19 20 21         │
│     ⚪  ⚪  ⚪                   │
└─────────────────────────────────┘

Leyenda:
🟢 = Seleccionado (verde/turquesa)
🔴 = Ocupado (rojo)
⚪ = Disponible (blanco)
```

## Conclusion

Este diseño mejora significativamente la experiencia del usuario al hacer reservas, proporcionando indicadores visuales claros y retroalimentación inmediata.
