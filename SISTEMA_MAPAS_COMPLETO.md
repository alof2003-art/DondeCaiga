# 🗺️ SISTEMA DE MAPAS - DOCUMENTACIÓN COMPLETA

**Fecha**: 2025-12-04  
**Estado**: ✅ COMPLETADO

---

## 🎯 DESCRIPCIÓN

Sistema completo de mapas interactivos usando `flutter_map` con OpenStreetMap (gratuito). Permite seleccionar ubicaciones en un mapa al crear propiedades y visualizar la ubicación en el detalle de la propiedad.

---

## 📋 FUNCIONALIDADES

### ✅ Funcionalidades Implementadas

1. **Selector de Ubicación Interactivo**
   - Mapa interactivo con OpenStreetMap
   - **🆕 Búsqueda de direcciones con Nominatim API**
   - **🆕 Autocompletado en tiempo real**
   - **🆕 Lista de resultados con sugerencias**
   - Toque en el mapa para seleccionar ubicación
   - Marcador visual en la ubicación seleccionada
   - Muestra coordenadas (latitud y longitud)
   - Botón para confirmar ubicación
   - Botón para centrar en ubicación seleccionada

2. **Integración en Crear Propiedad**
   - Botón "Seleccionar ubicación en el mapa" (opcional)
   - Muestra coordenadas seleccionadas
   - Guarda latitud y longitud en la base de datos

3. **Visualización en Detalle de Propiedad**
   - Mapa estático mostrando la ubicación
   - Marcador en la ubicación exacta
   - Solo se muestra si la propiedad tiene coordenadas

---

## 📦 DEPENDENCIAS

### Agregadas a `pubspec.yaml`

```yaml
dependencies:
  # Maps
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  
  # HTTP requests (para búsqueda de direcciones)
  http: ^1.2.0
```

**Instalación**:
```bash
flutter pub get
```

---

## 📁 ESTRUCTURA DE ARCHIVOS

```
lib/features/propiedades/
└── presentation/
    └── screens/
        ├── crear_propiedad_screen.dart      # Integración del selector
        ├── editar_propiedad_screen.dart     # (pendiente integración)
        └── location_picker_screen.dart      # ⭐ NUEVO: Selector de ubicación

lib/features/explorar/
└── presentation/
    └── screens/
        └── detalle_propiedad_screen.dart    # Visualización del mapa
```

---

## 🔧 ARCHIVOS IMPLEMENTADOS

### 1. Pantalla: `location_picker_screen.dart` ⭐

**Ubicación**: `lib/features/propiedades/presentation/screens/location_picker_screen.dart`

**Funcionalidades**:
- Mapa interactivo con OpenStreetMap
- Toque para seleccionar ubicación
- Marcador rojo en ubicación seleccionada
- Panel inferior con información:
  - Instrucciones
  - Coordenadas actuales
  - Botón "Confirmar Ubicación"
- Botón flotante para centrar mapa
- Ubicación inicial configurable

**Parámetros**:
- `initialLocation` (LatLng?): Ubicación inicial opcional

**Retorna**:
- `LatLng`: Coordenadas seleccionadas

**Ejemplo de uso**:
```dart
final result = await Navigator.of(context).push<LatLng>(
  MaterialPageRoute(
    builder: (context) => LocationPickerScreen(
      initialLocation: LatLng(-0.1807, -78.4678), // Quito, Ecuador
    ),
  ),
);

if (result != null) {
  print('Latitud: ${result.latitude}');
  print('Longitud: ${result.longitude}');
}
```

---

### 2. Integración: `crear_propiedad_screen.dart`

**Cambios realizados**:

1. **Imports agregados**:
```dart
import 'package:latlong2/latlong.dart';
import 'location_picker_screen.dart';
```

2. **Variables agregadas**:
```dart
double? _latitud;
double? _longitud;
```

3. **Función agregada**:
```dart
Future<void> _abrirMapa() async {
  final LatLng? ubicacionInicial = _latitud != null && _longitud != null
      ? LatLng(_latitud!, _longitud!)
      : null;

  final result = await Navigator.of(context).push<LatLng>(
    MaterialPageRoute(
      builder: (context) => LocationPickerScreen(
        initialLocation: ubicacionInicial,
      ),
    ),
  );

  if (result != null) {
    setState(() {
      _latitud = result.latitude;
      _longitud = result.longitude;
    });
  }
}
```

4. **Botón agregado en el formulario** (después del campo de dirección):
```dart
OutlinedButton.icon(
  onPressed: _abrirMapa,
  icon: const Icon(Icons.map),
  label: Text(
    _latitud != null && _longitud != null
        ? 'Ubicación seleccionada en el mapa'
        : 'Seleccionar ubicación en el mapa (opcional)',
  ),
  style: OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF4DB6AC),
    side: const BorderSide(color: Color(0xFF4DB6AC)),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
),
```

5. **Indicador de coordenadas** (se muestra cuando hay ubicación seleccionada):
```dart
if (_latitud != null && _longitud != null) ...[
  const SizedBox(height: 8),
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.teal.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.location_on, color: Color(0xFF4DB6AC), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Lat: ${_latitud!.toStringAsFixed(6)}, Lng: ${_longitud!.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    ),
  ),
],
```

6. **Actualización en `_crearPropiedad()`**:
```dart
final propiedadId = await _propiedadRepository.crearPropiedad(
  // ... otros parámetros
  latitud: _latitud,
  longitud: _longitud,
);
```

---

### 3. Visualización: `detalle_propiedad_screen.dart`

**Cambios realizados**:

1. **Imports agregados**:
```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
```

2. **Mapa agregado** (después de la sección de ubicación):
```dart
// Mapa (si tiene coordenadas)
if (_propiedad!.latitud != null && _propiedad!.longitud != null) ...[
  const SizedBox(height: 16),
  Container(
    height: 250,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    clipBehavior: Clip.antiAlias,
    child: FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(
          _propiedad!.latitud!,
          _propiedad!.longitud!,
        ),
        initialZoom: 15.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.donde_caigav2',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(
                _propiedad!.latitud!,
                _propiedad!.longitud!,
              ),
              width: 50,
              height: 50,
              child: const Icon(
                Icons.location_on,
                size: 50,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
],
```

---

## 🗄️ BASE DE DATOS

La tabla `propiedades` ya tiene los campos necesarios:

```sql
CREATE TABLE propiedades (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- ... otros campos
  latitud DECIMAL(10, 8),
  longitud DECIMAL(11, 8),
  -- ... otros campos
);
```

**No se requieren cambios en la base de datos** ✅

---

## 🎨 DISEÑO Y UX

### Colores

- **Botón selector**: `Color(0xFF4DB6AC)` (Teal)
- **Marcador**: `Colors.red`
- **Fondo info**: `Colors.teal.withValues(alpha: 0.1)`

### Dimensiones

- **Altura del mapa en detalle**: 250px
- **Tamaño del marcador**: 50x50px
- **Zoom inicial**: 15.0
- **Border radius**: 12px

### Interacciones

- **Toque en el mapa**: Selecciona nueva ubicación
- **Botón flotante**: Centra el mapa en la ubicación seleccionada
- **Botón confirmar**: Guarda y cierra la pantalla

---

## 📊 FLUJO DE USUARIO

### Flujo: Crear Propiedad con Ubicación

```
1. Usuario crea nueva propiedad
   ↓
2. Llena formulario (título, dirección, etc.)
   ↓
3. Presiona "Seleccionar ubicación en el mapa"
   ↓
4. Se abre pantalla de mapa
   ↓
5. Toca en el mapa para seleccionar ubicación
   ↓
6. Ve coordenadas actualizarse
   ↓
7. Presiona "Confirmar Ubicación"
   ↓
8. Regresa al formulario
   ↓
9. Ve indicador con coordenadas seleccionadas
   ↓
10. Completa formulario y crea propiedad
    ↓
11. Ubicación se guarda en BD
```

### Flujo: Ver Ubicación en Detalle

```
1. Usuario ve detalle de propiedad
   ↓
2. Scroll hacia abajo después de ubicación
   ↓
3. Si la propiedad tiene coordenadas:
   - Ve mapa con marcador
   - Puede hacer zoom/pan
   - Ve ubicación exacta
   ↓
4. Si no tiene coordenadas:
   - No se muestra el mapa
   - Solo ve dirección de texto
```

---

## 🔍 BÚSQUEDA DE DIRECCIONES (NOMINATIM)

### Descripción

Sistema de búsqueda de direcciones integrado usando **Nominatim**, el servicio de geocodificación gratuito de OpenStreetMap.

### Características

- ✅ **Búsqueda en tiempo real**: Resultados mientras escribes
- ✅ **Autocompletado**: Sugerencias automáticas
- ✅ **Sin API Key**: Servicio gratuito
- ✅ **Global**: Búsqueda en todo el mundo
- ✅ **Detalles completos**: Dirección completa con ciudad, país, etc.

### Funcionamiento

1. Usuario escribe en el campo de búsqueda
2. Después de 500ms, se hace petición a Nominatim
3. Se muestran hasta 5 resultados
4. Usuario selecciona un resultado
5. Mapa se centra en la ubicación seleccionada
6. Marcador se actualiza automáticamente

### API Endpoint

```
https://nominatim.openstreetmap.org/search
```

**Parámetros**:
- `q`: Query de búsqueda
- `format`: json
- `limit`: 5 (máximo de resultados)
- `addressdetails`: 1 (incluir detalles)

### Ejemplo de Petición

```dart
final url = Uri.parse(
  'https://nominatim.openstreetmap.org/search?'
  'q=${Uri.encodeComponent(query)}&'
  'format=json&'
  'limit=5&'
  'addressdetails=1',
);

final response = await http.get(
  url,
  headers: {
    'User-Agent': 'DondeCaigaApp/1.0',
  },
);
```

### Ejemplo de Respuesta

```json
[
  {
    "display_name": "Quito, Pichincha, Ecuador",
    "lat": "-0.1807",
    "lon": "-78.4678",
    "address": {
      "city": "Quito",
      "state": "Pichincha",
      "country": "Ecuador"
    }
  }
]
```

### Términos de Uso

- ✅ Incluir User-Agent apropiado
- ✅ Máximo 1 request por segundo
- ✅ No hacer búsquedas automáticas sin interacción del usuario
- ✅ Cachear resultados cuando sea posible

### UI/UX

**Campo de búsqueda**:
- Placeholder: "Buscar dirección o lugar..."
- Icono de búsqueda (lupa)
- Icono de carga mientras busca
- Botón para limpiar búsqueda

**Lista de resultados**:
- Máximo 5 resultados
- Icono de ubicación en cada resultado
- Dirección completa visible
- Scroll si hay muchos resultados
- Desaparece al seleccionar

**Interacción**:
- Búsqueda con delay de 500ms
- Búsqueda al presionar Enter
- Selección con tap
- Limpieza con botón X

---

## 🌍 OPENSTREETMAP

### ¿Por qué OpenStreetMap?

- ✅ **Gratuito**: Sin costos ni límites de uso
- ✅ **Sin API Key**: No requiere configuración adicional
- ✅ **Open Source**: Datos abiertos y colaborativos
- ✅ **Global**: Cobertura mundial
- ✅ **Actualizado**: Comunidad activa

### Tiles URL

```
https://tile.openstreetmap.org/{z}/{x}/{y}.png
```

### Términos de Uso

- Incluir atribución a OpenStreetMap
- No hacer más de 2 requests por segundo
- Usar `userAgentPackageName` apropiado

**Atribución automática**: `flutter_map` incluye atribución por defecto

---

## 🔒 PRIVACIDAD Y SEGURIDAD

### Datos Almacenados

- **Latitud**: Coordenada geográfica (decimal)
- **Longitud**: Coordenada geográfica (decimal)
- **Precisión**: 6 decimales (~11cm de precisión)

### Consideraciones

- ✅ Las coordenadas son **opcionales**
- ✅ No se accede a ubicación del dispositivo
- ✅ Usuario selecciona manualmente la ubicación
- ✅ No se rastrea ubicación en tiempo real
- ✅ Datos públicos (visibles en detalle de propiedad)

---

## 🧪 PRUEBAS

### Casos de Prueba

1. **Selector de Ubicación**:
   - [ ] Mapa se carga correctamente
   - [ ] Toque en el mapa actualiza marcador
   - [ ] Coordenadas se muestran correctamente
   - [ ] Botón confirmar retorna coordenadas
   - [ ] Botón centrar funciona
   - [ ] Ubicación inicial se respeta

2. **Crear Propiedad**:
   - [ ] Botón selector aparece en formulario
   - [ ] Abrir selector funciona
   - [ ] Coordenadas se guardan al confirmar
   - [ ] Indicador muestra coordenadas
   - [ ] Propiedad se crea con coordenadas
   - [ ] Propiedad se crea sin coordenadas (opcional)

3. **Detalle de Propiedad**:
   - [ ] Mapa se muestra si hay coordenadas
   - [ ] Mapa NO se muestra si no hay coordenadas
   - [ ] Marcador está en posición correcta
   - [ ] Zoom/pan funcionan
   - [ ] Tiles se cargan correctamente

---

## 🐛 ERRORES COMUNES Y SOLUCIONES

### Error 1: Tiles no cargan

**Causa**: Problema de conexión a internet o URL incorrecta

**Solución**: Verificar conexión y URL de tiles:
```dart
urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
```

### Error 2: Mapa no se muestra

**Causa**: Dependencias no instaladas

**Solución**:
```bash
flutter pub get
flutter clean
flutter run
```

### Error 3: Coordenadas no se guardan

**Causa**: Variables null no se pasan al repositorio

**Solución**: Verificar que se pasan `latitud` y `longitud` en `crearPropiedad()`

### Error 4: Marcador no aparece

**Causa**: Coordenadas inválidas o fuera de rango

**Solución**: Verificar que latitud está entre -90 y 90, longitud entre -180 y 180

---

## 📈 MEJORAS FUTURAS

### Corto Plazo
- [ ] Agregar selector de ubicación en editar propiedad
- [x] Búsqueda de direcciones (geocoding) ✅
- [x] Autocompletar dirección con Nominatim ✅
- [ ] Botón para obtener ubicación actual del dispositivo

### Mediano Plazo
- [ ] Mapa en pantalla de explorar (ver todas las propiedades)
- [ ] Filtrar propiedades por distancia
- [ ] Calcular distancia entre ubicaciones
- [ ] Rutas y direcciones

### Largo Plazo
- [ ] Mapa de calor de propiedades
- [ ] Áreas de cobertura
- [ ] Integración con servicios de transporte
- [ ] Puntos de interés cercanos

---

## 🔗 RECURSOS

### Documentación

- [flutter_map](https://docs.fleaflet.dev/)
- [OpenStreetMap](https://www.openstreetmap.org/)
- [latlong2](https://pub.dev/packages/latlong2)

### Ejemplos

- [flutter_map Examples](https://github.com/fleaflet/flutter_map/tree/master/example)
- [OpenStreetMap Tiles](https://wiki.openstreetmap.org/wiki/Tiles)

---

## 📞 CONTACTO

**Desarrollador**: alof2003@gmail.com

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

### Dependencias
- [x] flutter_map agregado a pubspec.yaml
- [x] latlong2 agregado a pubspec.yaml
- [x] Dependencias instaladas

### Pantallas
- [x] LocationPickerScreen creada
- [x] Integración en crear_propiedad_screen
- [x] Visualización en detalle_propiedad_screen
- [ ] Integración en editar_propiedad_screen (pendiente)

### Funcionalidades
- [x] Selector de ubicación interactivo
- [x] Guardar coordenadas en BD
- [x] Mostrar mapa en detalle
- [x] Marcador en ubicación
- [x] Zoom y pan en mapa

### Testing
- [ ] Pruebas de selector de ubicación
- [ ] Pruebas de creación con coordenadas
- [ ] Pruebas de visualización
- [ ] Pruebas sin coordenadas

---

**Fecha de Finalización**: 2025-12-04  
**Versión**: 1.0.0  
**Estado**: ✅ COMPLETADO

---

**FIN DE LA DOCUMENTACIÓN DEL SISTEMA DE MAPAS**

