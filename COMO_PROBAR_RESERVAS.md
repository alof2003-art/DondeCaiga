# 🧪 CÓMO PROBAR EL SISTEMA DE RESERVAS

## 📋 Requisitos Previos

1. ✅ Tener al menos 2 usuarios registrados:
   - **Usuario 1**: Viajero (para hacer reservas)
   - **Usuario 2**: Anfitrión (para aprobar/rechazar)

2. ✅ El Usuario 2 debe tener al menos 1 alojamiento publicado

---

## 🎯 PRUEBA 1: Crear Reserva como Viajero

### Pasos:

1. **Iniciar sesión como Usuario 1 (Viajero)**
   - Email: [tu email de viajero]
   - Password: [tu password]

2. **Ir a "Explorar"**
   - Ver lista de alojamientos disponibles
   - Seleccionar un alojamiento que NO sea tuyo

3. **Ver Detalle del Alojamiento**
   - Click en cualquier alojamiento
   - Revisar información completa

4. **Click en "Reservar"**
   - Debe abrir el calendario

5. **Seleccionar Fechas**
   - Click en fecha de inicio (ej: 15/12/2024)
   - Click en fecha de fin (ej: 18/12/2024)
   - Debe mostrar duración: "4 días"

6. **Confirmar Reserva**
   - Click en "Confirmar Reserva (4 días)"
   - Debe mostrar: "¡Reserva creada! Espera la confirmación del anfitrión"
   - Debe volver a la pantalla anterior

### ✅ Resultado Esperado:
- Reserva creada en estado "pendiente"
- NO aparece en el buzón todavía
- Guardada en la base de datos

---

## 🎯 PRUEBA 2: Ver y Aprobar Reserva como Anfitrión

### Pasos:

1. **Cerrar sesión del Usuario 1**
   - Ir a "Perfil"
   - Click en "Cerrar Sesión"

2. **Iniciar sesión como Usuario 2 (Anfitrión)**
   - Email: [tu email de anfitrión]
   - Password: [tu password]

3. **Ir a "Anfitrión"**
   - Debe ver botón "Ver Mis Reservas"

4. **Click en "Ver Mis Reservas"**
   - Debe ver la reserva pendiente
   - Filtro "Pendientes" debe mostrar contador (1)

5. **Ver Detalles de la Reserva**
   - Nombre del viajero
   - Propiedad reservada
   - Fechas: 15/12/2024 → 18/12/2024
   - Duración: 4 días
   - Estado: Pendiente (naranja)

6. **Aprobar la Reserva**
   - Click en botón verde "Aprobar"
   - Debe mostrar: "¡Reserva aprobada!"
   - Estado cambia a "Confirmada" (verde)

### ✅ Resultado Esperado:
- Reserva cambia a estado "confirmada"
- Ahora SÍ aparece en el buzón
- Viajero puede ver la confirmación

---

## 🎯 PRUEBA 3: Validaciones

### A. Anfitrión NO puede reservar su propio alojamiento

**Pasos:**
1. Iniciar sesión como anfitrión
2. Ir a "Explorar"
3. Click en TU PROPIO alojamiento
4. Click en "Reservar"

**✅ Resultado Esperado:**
- Mensaje: "No puedes reservar tu propio alojamiento"
- NO abre el calendario

---

### B. Fechas ocupadas NO disponibles

**Pasos:**
1. Crear una reserva del 15/12 al 18/12
2. Intentar crear otra reserva del 16/12 al 20/12

**✅ Resultado Esperado:**
- Fechas 15, 16, 17, 18 marcadas en rojo
- NO se pueden seleccionar
- Mensaje: "Hay fechas ocupadas en el rango seleccionado"

---

### C. Fechas pasadas NO seleccionables

**Pasos:**
1. Abrir calendario de reservas
2. Intentar seleccionar una fecha pasada

**✅ Resultado Esperado:**
- Fechas pasadas en gris
- NO se pueden seleccionar

---

## 🎯 PRUEBA 4: Rechazar Reserva

### Pasos:

1. **Crear una reserva como viajero**
   - Seguir pasos de PRUEBA 1

2. **Iniciar sesión como anfitrión**
   - Ir a "Anfitrión" → "Ver Mis Reservas"

3. **Rechazar la Reserva**
   - Click en botón rojo "Rechazar"
   - Confirmar en el diálogo
   - Debe mostrar: "Reserva rechazada"

### ✅ Resultado Esperado:
- Reserva cambia a estado "rechazada" (rojo)
- NO aparece en el buzón
- Viajero puede ver el rechazo

---

## 🎯 PRUEBA 5: Filtros de Reservas

### Pasos:

1. **Crear varias reservas:**
   - 2 pendientes
   - 1 confirmada
   - 1 rechazada

2. **Probar Filtros:**
   - Click en "Todas" → Debe mostrar 4 reservas
   - Click en "Pendientes" → Debe mostrar 2 reservas
   - Click en "Confirmadas" → Debe mostrar 1 reserva

### ✅ Resultado Esperado:
- Filtros funcionan correctamente
- Contador de pendientes muestra número correcto
- Colores de estado correctos

---

## 📊 Estados de Reserva

| Estado | Color | Descripción | Aparece en Buzón |
|--------|-------|-------------|------------------|
| **Pendiente** | 🟠 Naranja | Esperando aprobación | ❌ NO |
| **Confirmada** | 🟢 Verde | Aprobada por anfitrión | ✅ SÍ |
| **Rechazada** | 🔴 Rojo | Rechazada por anfitrión | ❌ NO |
| **Completada** | 🔵 Azul | Reserva finalizada | ✅ SÍ |
| **Cancelada** | ⚫ Gris | Cancelada por usuario | ❌ NO |

---

## 🐛 Problemas Comunes

### 1. "No se pueden cargar las reservas"
**Solución:** Verificar que el usuario tenga propiedades creadas

### 2. "Fechas no disponibles"
**Solución:** Verificar que no haya reservas existentes en esas fechas

### 3. "Error al crear reserva"
**Solución:** 
- Verificar conexión a Supabase
- Verificar que la tabla `reservas` exista
- Verificar permisos RLS

---

## ✅ Checklist de Pruebas

- [ ] Crear reserva como viajero
- [ ] Ver reserva como anfitrión
- [ ] Aprobar reserva
- [ ] Rechazar reserva
- [ ] Validar: anfitrión NO puede reservar su propio alojamiento
- [ ] Validar: fechas ocupadas NO disponibles
- [ ] Validar: fechas pasadas NO seleccionables
- [ ] Probar filtros (Todas, Pendientes, Confirmadas)
- [ ] Verificar contador de pendientes
- [ ] Verificar colores de estados
- [ ] Verificar que reserva pendiente NO aparece en buzón
- [ ] Verificar que reserva confirmada SÍ aparece en buzón

---

## 🎉 ¡Sistema Funcionando!

Si todas las pruebas pasan, el sistema de reservas está funcionando correctamente.

**Próximos pasos:**
- Implementar chat/mensajería
- Agregar notificaciones
- Agregar historial de reservas
