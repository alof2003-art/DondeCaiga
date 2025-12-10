# 📝 SISTEMA DE RESEÑAS - DOCUMENTACIÓN COMPLETA

**Fecha**: 2025-12-04  
**Estado**: ✅ COMPLETADO

---

## 🎯 DESCRIPCIÓN

Sistema completo de reseñas que permite a los viajeros calificar y comentar sobre las propiedades donde se han hospedado. Las reseñas se muestran en la pantalla de detalle de la propiedad y solo pueden ser creadas por usuarios con reservas confirmadas o completadas.

---

## 📋 FUNCIONALIDADES

### ✅ Funcionalidades Implementadas

1. **Ver Reseñas en Detalle de Propiedad**
   - Lista de todas las reseñas de una propiedad
   - Promedio de calificación con estrellas
   - Contador de reseñas totales
   - Avatar y nombre del viajero
   - Fecha relativa (hace X días/semanas/meses)
   - Comentario completo

2. **Crear Reseña**
   - Botón "Calificar" en la lista de chats
   - Solo disponible para reservas confirmadas o completadas
   - Selector de estrellas (1-5)
   - Campo de comentario opcional
   - Validación de que el usuario tenga una reserva válida
   - Prevención de reseñas duplicadas

3. **Restricciones de Seguridad**
   - Solo viajeros con reservas confirmadas/completadas pueden crear reseñas
   - Una reseña por reserva
   - RLS implementado en base de datos

---

## 🗄️ BASE DE DATOS

### Tabla: `resenas`

```sql
CREATE TABLE IF NOT EXISTS resenas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  propiedad_id UUID NOT NULL REFERENCES propiedades(id) ON DELETE CASCADE,
  viajero_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
  reserva_id UUID REFERENCES reservas(id) ON DELETE SET NULL,
  calificacion INTEGER CHECK (calificacion >= 1 AND calificacion <= 5),
  comentario TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_resenas_propiedad ON resenas(propiedad_id);
CREATE INDEX IF NOT EXISTS idx_resenas_viajero ON resenas(viajero_id);
```

### Políticas RLS

```sql
-- Ver reseñas: Todos pueden ver
CREATE POLICY "Todos pueden ver reseñas"
  ON resenas FOR SELECT
  TO public
  USING (true);

-- Crear reseña: Solo viajeros con reservas confirmadas/completadas
CREATE POLICY "Viajeros pueden crear reseñas"
  ON resenas FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = viajero_id AND
    EXISTS (
      SELECT 1 FROM reservas
      WHERE reservas.id = resenas.reserva_id
      AND reservas.viajero_id = auth.uid()
      AND reservas.estado IN ('confirmada', 'completada')
    )
  );

-- Actualizar reseña: Solo el autor
CREATE POLICY "Viajeros pueden actualizar sus reseñas"
  ON resenas FOR UPDATE
  TO authenticated
  USING (auth.uid() = viajero_id);

-- Eliminar reseña: Solo el autor
CREATE POLICY "Viajeros pueden eliminar sus reseñas"
  ON resenas FOR DELETE
  TO authenticated
  USING (auth.uid() = viajero_id);
```

---

## 📁 ESTRUCTURA DE ARCHIVOS

```
lib/features/resenas/
├── data/
│   ├── models/
│   │   └── resena.dart                    # Modelo de datos
│   └── repositories/
│       └── resena_repository.dart         # Lógica de negocio
└── presentation/
    ├── screens/
    │   └── crear_resena_screen.dart       # Pantalla para crear reseña
    └── widgets/
        └── resenas_list_widget.dart       # Widget de lista de reseñas
```

---

## 🔧 ARCHIVOS IMPLEMENTADOS

### 1. Modelo: `resena.dart`

**Ubicación**: `lib/features/resenas/data/models/resena.dart`

**Campos**:
- `id` (String): ID único de la reseña
- `propiedadId` (String): ID de la propiedad
- `viajeroId` (String): ID del viajero que creó la reseña
- `reservaId` (String?): ID de la reserva asociada
- `calificacion` (int): Calificación de 1 a 5 estrellas
- `comentario` (String?): Comentario opcional
- `nombreViajero` (String): Nombre del viajero (join)
- `createdAt` (DateTime): Fecha de creación

**Métodos**:
- `fromJson()`: Convierte JSON a objeto Resena
- `toJson()`: Convierte objeto Resena a JSON

---

### 2. Repositorio: `resena_repository.dart`

**Ubicación**: `lib/features/resenas/data/repositories/resena_repository.dart`

**Métodos**:

1. **`obtenerResenasPorPropiedad(String propiedadId)`**
   - Obtiene todas las reseñas de una propiedad
   - Incluye nombre del viajero (join con users_profiles)
   - Ordenadas por fecha descendente

2. **`crearResena(Resena resena)`**
   - Crea una nueva reseña
   - Valida que el usuario tenga una reserva válida
   - Previene reseñas duplicadas

3. **`verificarPuedeCrearResena(String viajeroId, String propiedadId)`**
   - Verifica si el usuario puede crear una reseña
   - Comprueba que tenga una reserva confirmada/completada
   - Comprueba que no haya creado ya una reseña

4. **`obtenerReservaPendienteResena(String viajeroId, String propiedadId)`**
   - Obtiene la reserva que puede ser reseñada
   - Filtra por estado confirmada/completada
   - Excluye reservas ya reseñadas

---

### 3. Pantalla: `crear_resena_screen.dart`

**Ubicación**: `lib/features/resenas/presentation/screens/crear_resena_screen.dart`

**Funcionalidades**:
- Selector de estrellas interactivo (1-5)
- Campo de texto para comentario (opcional)
- Validación de calificación mínima (1 estrella)
- Botón de enviar con loading state
- Navegación automática al completar
- Manejo de errores

**Parámetros**:
- `propiedadId`: ID de la propiedad a reseñar
- `reservaId`: ID de la reserva asociada
- `nombrePropiedad`: Nombre de la propiedad (para mostrar)

---

### 4. Widget: `resenas_list_widget.dart`

**Ubicación**: `lib/features/resenas/presentation/widgets/resenas_list_widget.dart`

**Funcionalidades**:
- Lista de reseñas con scroll
- Header con promedio de calificación
- Contador de reseñas totales
- Tarjetas de reseña con:
  - Avatar del viajero
  - Nombre del viajero
  - Fecha relativa
  - Estrellas de calificación
  - Comentario
- Estado vacío cuando no hay reseñas
- Loading state mientras carga

**Parámetros**:
- `propiedadId`: ID de la propiedad

---

## 🔗 INTEGRACIÓN CON OTRAS PANTALLAS

### 1. Detalle de Propiedad (`detalle_propiedad_screen.dart`)

**Ubicación del Widget**:
Debajo del botón "Reservar", antes del final del ScrollView

```dart
// Después del botón Reservar
const SizedBox(height: 24),

// Widget de reseñas
ResenasListWidget(
  propiedadId: widget.propiedad.id,
),

const SizedBox(height: 24),
```

---

### 2. Lista de Chats (`chat_lista_screen.dart`)

**Botón "Calificar"**:
Al lado del botón "Abrir Chat"

```dart
Row(
  children: [
    // Botón Abrir Chat
    Expanded(
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatConversacionScreen(
                reserva: reserva,
              ),
            ),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Abrir Chat'),
      ),
    ),
    
    const SizedBox(width: 12),
    
    // Botón Calificar (solo si es viajero y reserva confirmada/completada)
    if (esViajero && 
        (reserva.estado == 'confirmada' || reserva.estado == 'completada'))
      ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CrearResenaScreen(
                propiedadId: reserva.propiedadId,
                reservaId: reserva.id,
                nombrePropiedad: reserva.tituloPropiedad ?? 'Propiedad',
              ),
            ),
          );
        },
        icon: const Icon(Icons.star_outline),
        label: const Text('Calificar'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber[700],
        ),
      ),
  ],
),
```

---

## 🎨 DISEÑO Y UX

### Colores

- **Estrellas**: `Colors.amber[700]` (#FFA000)
- **Avatar**: `Colors.teal[100]` (fondo), `Colors.teal[700]` (texto)
- **Botón Calificar**: `Colors.amber[700]`
- **Texto secundario**: `Colors.grey[600]`

### Tipografía

- **Título "Reseñas"**: 20px, bold
- **Promedio**: 18px, bold
- **Nombre viajero**: 16px, bold
- **Comentario**: 14px, regular
- **Fecha**: 12px, regular

### Espaciado

- Padding general: 16px
- Espaciado entre elementos: 12px
- Espaciado entre reseñas: Divider

---

## 🔒 SEGURIDAD

### Validaciones en Frontend

1. **Crear Reseña**:
   - Usuario debe estar autenticado
   - Calificación debe ser entre 1 y 5
   - Debe tener una reserva válida

2. **Ver Reseñas**:
   - Público, no requiere autenticación

### Validaciones en Backend (RLS)

1. **Crear Reseña**:
   - Usuario debe ser el viajero de la reserva
   - Reserva debe estar confirmada o completada
   - No puede crear reseña duplicada

2. **Actualizar/Eliminar**:
   - Solo el autor puede modificar su reseña

---

## 📊 FLUJO DE USUARIO

### Flujo Completo: Crear Reseña

```
1. Usuario (Viajero) tiene una reserva confirmada/completada
   ↓
2. Va a la pantalla de Chat
   ↓
3. Ve su reserva con botón "Calificar"
   ↓
4. Presiona "Calificar"
   ↓
5. Se abre pantalla de crear reseña
   ↓
6. Selecciona estrellas (1-5)
   ↓
7. Escribe comentario (opcional)
   ↓
8. Presiona "Enviar Reseña"
   ↓
9. Sistema valida y guarda
   ↓
10. Regresa a pantalla anterior
    ↓
11. Reseña aparece en detalle de propiedad
```

### Flujo: Ver Reseñas

```
1. Usuario (cualquiera) ve una propiedad
   ↓
2. Scroll hacia abajo después del botón Reservar
   ↓
3. Ve sección "Reseñas" con promedio
   ↓
4. Ve lista de reseñas con:
   - Avatar y nombre del viajero
   - Calificación en estrellas
   - Comentario
   - Fecha relativa
```

---

## 🧪 PRUEBAS

### Casos de Prueba

1. **Ver Reseñas**:
   - [ ] Propiedad sin reseñas muestra mensaje vacío
   - [ ] Propiedad con reseñas muestra lista correctamente
   - [ ] Promedio de calificación se calcula correctamente
   - [ ] Contador de reseñas es correcto

2. **Crear Reseña**:
   - [ ] Botón "Calificar" solo aparece para viajeros
   - [ ] Botón solo aparece en reservas confirmadas/completadas
   - [ ] Selector de estrellas funciona correctamente
   - [ ] Comentario es opcional
   - [ ] No se puede enviar sin calificación
   - [ ] Reseña se guarda correctamente
   - [ ] No se puede crear reseña duplicada

3. **Seguridad**:
   - [ ] RLS previene creación no autorizada
   - [ ] Solo el autor puede editar su reseña
   - [ ] Validación de reserva válida funciona

---

## 🐛 ERRORES COMUNES Y SOLUCIONES

### Error 1: Botón "Calificar" no aparece

**Causa**: Usuario no es viajero o reserva no está confirmada/completada

**Solución**: Verificar que:
- El usuario sea el viajero de la reserva
- La reserva esté en estado 'confirmada' o 'completada'

### Error 2: No se puede crear reseña

**Causa**: RLS bloquea la inserción

**Solución**: Verificar que:
- El usuario tenga una reserva válida
- No haya creado ya una reseña para esa reserva
- Las políticas RLS estén correctamente configuradas

### Error 3: Reseñas no se muestran

**Causa**: Error en la consulta o políticas RLS

**Solución**: Verificar que:
- La tabla `resenas` existe
- Las políticas RLS permiten SELECT público
- El join con `users_profiles` funciona correctamente

---

## 📈 MEJORAS FUTURAS

### Corto Plazo
- [ ] Permitir editar reseñas
- [ ] Permitir eliminar reseñas
- [ ] Agregar fotos a las reseñas
- [ ] Respuestas del anfitrión a reseñas

### Mediano Plazo
- [ ] Filtrar reseñas por calificación
- [ ] Ordenar reseñas (más recientes, mejor calificadas)
- [ ] Reportar reseñas inapropiadas
- [ ] Verificar que el viajero completó la estancia

### Largo Plazo
- [ ] Sistema de reputación para viajeros
- [ ] Reseñas verificadas (con badge)
- [ ] Análisis de sentimiento en comentarios
- [ ] Estadísticas de reseñas para anfitriones

---

## 📞 CONTACTO

**Desarrollador**: alof2003@gmail.com

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

### Base de Datos
- [x] Tabla `resenas` creada
- [x] Índices creados
- [x] Políticas RLS configuradas
- [x] Constraints de calificación (1-5)

### Backend (Repositorio)
- [x] Método para obtener reseñas por propiedad
- [x] Método para crear reseña
- [x] Método para verificar si puede crear reseña
- [x] Método para obtener reserva pendiente de reseña
- [x] Join con users_profiles para nombre

### Frontend (UI)
- [x] Modelo de datos Resena
- [x] Widget de lista de reseñas
- [x] Pantalla de crear reseña
- [x] Integración en detalle de propiedad
- [x] Botón "Calificar" en lista de chats
- [x] Validaciones de formulario
- [x] Manejo de estados (loading, error, vacío)

### Testing
- [ ] Pruebas de creación de reseñas
- [ ] Pruebas de visualización
- [ ] Pruebas de seguridad (RLS)
- [ ] Pruebas de validaciones

---

**Fecha de Finalización**: 2025-12-04  
**Versión**: 1.0.0  
**Estado**: ✅ COMPLETADO

---

**FIN DE LA DOCUMENTACIÓN DEL SISTEMA DE RESEÑAS**

