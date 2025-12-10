# 📚 DOCUMENTACIÓN COMPLETA DEL PROYECTO
## Donde Caiga - Aplicación de Alojamiento

**Fecha de Creación**: 2025-12-04  
**Versión**: 1.0.0  
**Estado**: ✅ Producción

---

## 📋 ÍNDICE

1. [Descripción General](#descripción-general)
2. [Arquitectura del Sistema](#arquitectura-del-sistema)
3. [Base de Datos](#base-de-datos)
4. [Funcionalidades Principales](#funcionalidades-principales)
5. [Archivos Importantes](#archivos-importantes)
6. [Historial de Cambios](#historial-de-cambios)
7. [Errores Comunes y Soluciones](#errores-comunes-y-soluciones)
8. [Guía de Mantenimiento](#guía-de-mantenimiento)

---

## 🎯 DESCRIPCIÓN GENERAL

**Donde Caiga** es una aplicación móvil desarrollada en Flutter que conecta viajeros con anfitriones que ofrecen alojamiento. Similar a Airbnb, permite:

- Registro de usuarios (viajeros y anfitriones)
- Publicación de propiedades
- Sistema de reservas
- Chat en tiempo real entre viajeros y anfitriones
- Códigos de verificación para check-in
- Panel de administración

### Tecnologías Utilizadas

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase
- **Base de Datos**: PostgreSQL
- **Autenticación**: Supabase Auth
- **Storage**: Supabase Storage
- **Realtime**: Supabase Realtime

---

## 🏗️ ARQUITECTURA DEL SISTEMA

### Estructura de Carpetas Flutter

```
lib/
├── core/
│   └── utils/
│       └── error_handler.dart
├── services/
│   ├── auth_service.dart
│   ├── storage_service.dart
│   └── validation_service.dart
└── features/
    ├── auth/                    # Autenticación y registro
    ├── home/                    # Pantalla principal
    ├── explorar/                # Búsqueda de propiedades
    ├── propiedades/             # Gestión de propiedades
    ├── reservas/                # Sistema de reservas
    ├── chat/                    # Sistema de mensajería
    ├── buzon/                   # Lista de chats
    ├── perfil/                  # Perfil de usuario
    ├── anfitrion/               # Solicitudes de anfitrión
    └── main/                    # Navegación principal
```

### Arquitectura por Capas

Cada feature sigue la arquitectura limpia:

```
feature/
├── data/
│   ├── models/              # Modelos de datos
│   └── repositories/        # Lógica de negocio
└── presentation/
    ├── screens/             # Pantallas
    └── widgets/             # Componentes reutilizables
```

---

## 🗄️ BASE DE DATOS

### Tablas Principales

#### 1. **roles**
```sql
- id (SERIAL PRIMARY KEY)
- nombre (VARCHAR) - 'viajero', 'anfitrion', 'admin'
- descripcion (TEXT)
- created_at (TIMESTAMP)
```

#### 2. **users_profiles**
```sql
- id (UUID PRIMARY KEY) → auth.users(id)
- email (TEXT UNIQUE)
- nombre (TEXT)
- telefono (TEXT)
- foto_perfil_url (TEXT)
- cedula_url (TEXT)
- rol_id (INTEGER) → roles(id)
- estado_cuenta (VARCHAR) - 'activo', 'suspendido'
- email_verified (BOOLEAN)
- created_at, updated_at (TIMESTAMP)
```

#### 3. **propiedades**
```sql
- id (UUID PRIMARY KEY)
- anfitrion_id (UUID) → users_profiles(id)
- titulo (VARCHAR)
- descripcion (TEXT)
- direccion (TEXT)
- ciudad, pais (VARCHAR)
- latitud, longitud (DECIMAL)
- capacidad_personas (INTEGER)
- numero_habitaciones, numero_banos (INTEGER)
- tiene_garaje (BOOLEAN)
- foto_principal_url (TEXT)
- estado (VARCHAR) - 'activo', 'inactivo'
- created_at, updated_at (TIMESTAMP)
```

#### 4. **reservas**
```sql
- id (UUID PRIMARY KEY)
- propiedad_id (UUID) → propiedades(id)
- viajero_id (UUID) → users_profiles(id)
- fecha_inicio, fecha_fin (DATE)
- estado (TEXT) - 'pendiente', 'confirmada', 'rechazada', 'completada', 'cancelada'
- codigo_verificacion (TEXT) - Generado automáticamente al confirmar
- created_at, updated_at (TIMESTAMP)
```

#### 5. **mensajes**
```sql
- id (UUID PRIMARY KEY)
- reserva_id (UUID) → reservas(id)
- remitente_id (UUID) → users_profiles(id)
- mensaje (TEXT)
- leido (BOOLEAN)
- created_at (TIMESTAMP)
```

#### 6. **solicitudes_anfitrion**
```sql
- id (UUID PRIMARY KEY)
- usuario_id (UUID) → users_profiles(id)
- foto_selfie_url (TEXT)
- foto_propiedad_url (TEXT)
- mensaje (TEXT)
- estado (VARCHAR) - 'pendiente', 'aprobada', 'rechazada'
- fecha_solicitud, fecha_respuesta (TIMESTAMP)
- admin_revisor_id (UUID) → users_profiles(id)
- comentario_admin (TEXT)
```

#### 7. **fotos_propiedades**
```sql
- id (UUID PRIMARY KEY)
- propiedad_id (UUID) → propiedades(id)
- url_foto (TEXT)
- es_principal (BOOLEAN)
- orden (INTEGER)
- created_at (TIMESTAMP)
```

#### 8. **resenas**
```sql
- id (UUID PRIMARY KEY)
- propiedad_id (UUID) → propiedades(id)
- viajero_id (UUID) → users_profiles(id)
- reserva_id (UUID) → reservas(id)
- calificacion (INTEGER) - 1 a 5
- comentario (TEXT)
- created_at (TIMESTAMP)
```

### Funciones Importantes

#### 1. **generar_codigo_verificacion()**
Genera un código aleatorio de 6 dígitos para verificación de reservas.

```sql
CREATE OR REPLACE FUNCTION generar_codigo_verificacion()
RETURNS TEXT AS $$
BEGIN
    RETURN LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;
```

#### 2. **asignar_codigo_verificacion()**
Trigger que asigna automáticamente un código cuando una reserva se confirma.

#### 3. **crear_perfil_usuario_automatico()**
Trigger que crea automáticamente un perfil en `users_profiles` cuando se registra un usuario en `auth.users`.

#### 4. **update_updated_at_column()**
Función genérica para actualizar el campo `updated_at` automáticamente.

### Buckets de Storage

1. **profile-photos** - Fotos de perfil de usuarios
2. **id-documents** - Documentos de identidad (cédulas)
3. **solicitudes-anfitrion** - Fotos de solicitudes de anfitrión
4. **propiedades-fotos** - Fotos de propiedades

### Seguridad (RLS)

Todas las tablas tienen Row Level Security (RLS) habilitado con políticas específicas:

- **Usuarios**: Solo pueden ver/editar su propio perfil
- **Propiedades**: Todos ven activas, solo anfitriones editan las suyas
- **Reservas**: Viajeros ven las suyas, anfitriones ven las de sus propiedades
- **Mensajes**: Solo participantes de la reserva pueden ver/enviar
- **Admins**: Acceso completo a todas las tablas

---

## ⚙️ FUNCIONALIDADES PRINCIPALES

### 1. Autenticación y Registro

**Archivos**:
- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/auth/presentation/screens/register_screen.dart`
- `lib/services/auth_service.dart`

**Flujo**:
1. Usuario se registra con email, contraseña, nombre, teléfono
2. Puede subir foto de perfil y cédula
3. Trigger crea automáticamente perfil en `users_profiles`
4. Usuario inicia sesión
5. Splash screen verifica sesión existente

### 2. Exploración de Propiedades

**Archivos**:
- `lib/features/explorar/presentation/screens/explorar_screen.dart`
- `lib/features/explorar/presentation/screens/detalle_propiedad_screen.dart`

**Funcionalidades**:
- Lista de propiedades activas
- Búsqueda por ciudad
- Filtros por capacidad, habitaciones
- Vista detallada con fotos
- Botón para reservar

### 3. Gestión de Propiedades (Anfitriones)

**Archivos**:
- `lib/features/propiedades/presentation/screens/crear_propiedad_screen.dart`
- `lib/features/propiedades/presentation/screens/editar_propiedad_screen.dart`
- `lib/features/propiedades/data/repositories/propiedad_repository.dart`

**Funcionalidades**:
- Crear nueva propiedad
- Subir múltiples fotos
- Editar información
- Activar/desactivar propiedad

### 4. Sistema de Reservas

**Archivos**:
- `lib/features/reservas/presentation/screens/reserva_calendario_screen.dart`
- `lib/features/reservas/presentation/screens/mis_reservas_anfitrion_screen.dart`
- `lib/features/reservas/data/repositories/reserva_repository.dart`

**Flujo Viajero**:
1. Selecciona propiedad
2. Elige fechas en calendario
3. Crea reserva (estado: pendiente)
4. Espera confirmación del anfitrión

**Flujo Anfitrión**:
1. Ve solicitudes de reserva
2. Confirma o rechaza
3. Al confirmar, se genera código de verificación automáticamente
4. Código visible en el chat

### 5. Sistema de Chat

**Archivos**:
- `lib/features/buzon/presentation/screens/chat_lista_screen.dart`
- `lib/features/chat/presentation/screens/chat_conversacion_screen.dart`
- `lib/features/chat/data/repositories/mensaje_repository.dart`

**Funcionalidades**:
- Lista de chats (solo reservas confirmadas)
- Mensajes en tiempo real (Supabase Realtime)
- Código de verificación visible/oculto
- Burbujas diferenciadas para remitente/destinatario
- Marca mensajes como leídos
- Scroll automático a nuevos mensajes

**Características Técnicas**:
- Suscripción Realtime a tabla `mensajes`
- Filtrado por `reserva_id`
- Políticas RLS aseguran que solo participantes vean mensajes

### 6. Solicitudes de Anfitrión

**Archivos**:
- `lib/features/anfitrion/presentation/screens/solicitud_anfitrion_screen.dart`
- `lib/features/anfitrion/presentation/screens/admin_solicitudes_screen.dart`

**Flujo**:
1. Usuario viajero solicita ser anfitrión
2. Sube selfie y foto de propiedad
3. Admin revisa solicitud
4. Aprueba o rechaza
5. Si aprueba, `rol_id` cambia a 2 (anfitrión)

### 7. Panel de Administración

**Funcionalidades**:
- Ver todas las solicitudes de anfitrión
- Aprobar/rechazar solicitudes
- Acceso completo a todas las tablas (RLS)
- Gestión de usuarios

---

## 📁 ARCHIVOS IMPORTANTES

### Archivos SQL Principales

#### Archivos Activos (Usar estos):

1. **`BASE_DATOS_COMPLETA_FINAL.sql`** ⭐
   - Esquema completo de la base de datos
   - Todas las tablas, funciones, triggers, políticas RLS
   - Configuración de Storage
   - **Usar este para setup inicial**

2. **`SISTEMA_CHAT_FINAL.sql`** ⭐
   - Sistema completo de chat y mensajería
   - Códigos de verificación
   - Políticas RLS para mensajes
   - Configuración Realtime
   - **Usar este para actualizar chat**

3. **`HISTORIAL_CAMBIOS_COMPLETO_SQL.sql`** 📖
   - Documentación de TODOS los cambios SQL
   - Historial cronológico
   - Referencias a archivos originales

4. **`ERRORES_Y_SOLUCIONES_SQL.sql`** 🐛
   - 14 errores documentados con soluciones
   - Problemas comunes y cómo resolverlos

#### Archivos de Utilidad:

5. **`crear_cuenta_admin.sql`**
   - Convierte un usuario en administrador
   - Cambiar email antes de ejecutar

6. **`borrar_todos_usuarios.sql`** ⚠️
   - Elimina todos los usuarios (solo desarrollo)
   - **PELIGROSO - No usar en producción**

7. **`storage_policies_final.sql`**
   - Políticas permisivas para Storage
   - Solo para desarrollo

8. **`crear_tabla_reservas.sql`**
   - Creación de tabla de reservas
   - Ya incluido en BASE_DATOS_COMPLETA_FINAL.sql

### Archivos Markdown de Documentación

#### Documentación Principal:

1. **`DOCUMENTACION_COMPLETA_PROYECTO.md`** ⭐ (Este archivo)
   - Documentación completa del proyecto
   - Arquitectura, base de datos, funcionalidades

2. **`SISTEMA_CHAT_DOCUMENTACION_FINAL.md`** 📱
   - Documentación técnica del sistema de chat
   - Guía de uso y pruebas

3. **`HISTORIAL_CAMBIOS_CHAT.md`** 📝
   - Historial detallado de cambios del chat
   - Problemas encontrados y soluciones

#### Documentación de Funcionalidades:

4. **`SISTEMA_RESERVAS_COMPLETO.md`**
   - Sistema de reservas completo
   - Flujos de viajero y anfitrión

5. **`COMO_PROBAR_RESERVAS.md`**
   - Guía paso a paso para probar reservas

6. **`ESPECIFICACIONES_COMPLETAS.md`**
   - Especificaciones técnicas del proyecto

#### Documentación de Desarrollo:

7. **`CAMBIOS_HOY.md`**
   - Cambios del día actual

8. **`CONTINUAR_MAÑANA.md`**
   - Tareas pendientes

9. **`RESUMEN_IMPLEMENTACION.md`**
   - Resumen de implementación general

### Archivos SQL Eliminados (Consolidados)

Los siguientes archivos fueron eliminados el 2025-12-04 porque su contenido fue consolidado:

1. ~~`agregar_codigo_verificacion_reservas.sql`~~ → Consolidado en `SISTEMA_CHAT_FINAL.sql`
2. ~~`crear_tabla_mensajes.sql`~~ → Estructura incorrecta, reemplazado
3. ~~`arreglar_tabla_mensajes.sql`~~ → Consolidado en `SISTEMA_CHAT_FINAL.sql`
4. ~~`actualizar_chat_completo.sql`~~ → Versión intermedia, reemplazado

---

## 📜 HISTORIAL DE CAMBIOS

### Fase 1: Configuración Inicial (Inicio del proyecto)
- Creación de tabla `users_profiles`
- Sistema de roles (viajero, anfitrión, admin)
- Autenticación con Supabase
- Políticas RLS básicas

### Fase 2: Propiedades y Alojamientos
- Tabla `propiedades`
- Tabla `fotos_propiedades`
- CRUD de propiedades
- Storage para fotos

### Fase 3: Sistema de Reservas
- Tabla `reservas`
- Calendario de disponibilidad
- Estados de reserva
- Políticas RLS para reservas

### Fase 4: Solicitudes de Anfitrión
- Tabla `solicitudes_anfitrion`
- Flujo de aprobación
- Panel de administración

### Fase 5: Sistema de Chat (2025-12-04)
- Tabla `mensajes`
- Códigos de verificación automáticos
- Realtime para mensajes
- Lista de chats para viajeros y anfitriones
- Conversación con burbujas
- Políticas RLS para mensajes

### Fase 6: Optimizaciones y Correcciones (2025-12-04)
- Corrección de estructura de tabla mensajes
- Filtro de reservas confirmadas para chat
- Actualización de API deprecated (withOpacity)
- Consolidación de documentación

---

## 🐛 ERRORES COMUNES Y SOLUCIONES

### Error 1: Políticas Duplicadas

**Error**: `policy "..." already exists`

**Solución**:
```sql
DROP POLICY IF EXISTS "nombre_politica" ON tabla;
CREATE POLICY "nombre_politica" ...
```

### Error 2: Usuario No Puede Registrarse

**Error**: RLS bloquea inserción en `users_profiles`

**Solución**: Usar trigger `crear_perfil_usuario_automatico()` que ya está implementado

### Error 3: Storage No Permite Subir Archivos

**Error**: Políticas de storage muy restrictivas

**Solución**: Ejecutar `storage_policies_final.sql` (solo desarrollo)

### Error 4: Realtime No Funciona

**Error**: Mensajes no se actualizan en tiempo real

**Solución**:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE mensajes;
```

### Error 5: Anfitriones No Ven Chats

**Error**: Lista de chats vacía para anfitriones

**Solución**: Ya corregido en `chat_lista_screen.dart` - obtiene reservas de viajero Y anfitrión

### Error 6: Código de Verificación No Se Genera

**Error**: Campo `codigo_verificacion` queda NULL

**Solución**: Trigger `asignar_codigo_verificacion()` ya implementado - se genera al confirmar reserva

### Error 7: withOpacity Deprecated

**Error**: Warning en Flutter

**Solución**:
```dart
// Antes
Colors.blue.withOpacity(0.05)

// Después
Colors.blue.withValues(alpha: 0.05)
```

---

## 🔧 GUÍA DE MANTENIMIENTO

### Setup Inicial de Base de Datos

1. Crear proyecto en Supabase
2. Ejecutar `BASE_DATOS_COMPLETA_FINAL.sql`
3. Verificar que todos los buckets de Storage existen
4. Crear primer usuario admin:
   - Registrarse en la app
   - Ejecutar `crear_cuenta_admin.sql` (cambiar email)

### Actualizar Sistema de Chat

1. Ejecutar `SISTEMA_CHAT_FINAL.sql`
2. Verificar que Realtime está habilitado en tabla `mensajes`
3. Probar envío de mensajes

### Agregar Nuevo Administrador

```sql
UPDATE users_profiles
SET rol_id = 3
WHERE email = 'nuevo_admin@example.com';
```

### Limpiar Base de Datos (Solo Desarrollo)

```sql
-- Ejecutar borrar_todos_usuarios.sql
-- ⚠️ PELIGROSO - Elimina todos los usuarios
```

### Deshabilitar RLS (Solo Desarrollo)

```sql
-- Ejecutar deshabilitar_rls_todas_tablas.sql
-- ⚠️ Solo para debugging, NO usar en producción
```

### Verificar Estado de la Base de Datos

```sql
-- Ver todas las tablas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Ver políticas RLS
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';

-- Ver triggers
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public';

-- Ver funciones
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public';
```

### Backup de Base de Datos

1. En Supabase Dashboard → Database → Backups
2. O usar pg_dump:
```bash
pg_dump -h db.xxx.supabase.co -U postgres -d postgres > backup.sql
```

### Monitoreo de Realtime

1. Supabase Dashboard → Database → Replication
2. Verificar que tabla `mensajes` está en la publicación
3. Monitorear conexiones activas

### Optimización de Performance

1. **Índices**: Ya creados en todas las tablas principales
2. **Consultas lentas**: Revisar en Supabase Dashboard → Database → Query Performance
3. **Storage**: Limpiar archivos huérfanos periódicamente

### Actualizar Flutter Dependencies

```bash
flutter pub upgrade
flutter pub outdated
```

### Solución de Problemas Comunes

1. **App no conecta a Supabase**:
   - Verificar `.env` tiene las credenciales correctas
   - Verificar que Supabase project está activo

2. **Imágenes no cargan**:
   - Verificar políticas de Storage
   - Verificar que buckets existen
   - Verificar URLs en base de datos

3. **Mensajes no llegan en tiempo real**:
   - Verificar Realtime está habilitado
   - Verificar suscripción en código Flutter
   - Revisar políticas RLS de mensajes

---

## 📊 ESTADÍSTICAS DEL PROYECTO

### Base de Datos
- **Tablas**: 8 principales
- **Funciones**: 5
- **Triggers**: 6
- **Políticas RLS**: ~25
- **Buckets Storage**: 4

### Código Flutter
- **Features**: 9
- **Screens**: ~20
- **Repositories**: 7
- **Models**: 8
- **Services**: 3

### Documentación
- **Archivos SQL activos**: 8
- **Archivos MD**: 15+
- **Errores documentados**: 14
- **Cambios SQL documentados**: 50+

---

## 🚀 PRÓXIMOS PASOS SUGERIDOS

### Funcionalidades Pendientes

1. **Sistema de Reseñas**
   - Tabla `resenas` ya existe
   - Implementar UI en Flutter
   - Mostrar calificaciones en propiedades

2. **Notificaciones Push**
   - Integrar Firebase Cloud Messaging
   - Notificar nuevas reservas
   - Notificar nuevos mensajes

3. **Pagos**
   - Integrar Stripe o similar
   - Gestión de pagos de reservas
   - Comisiones para la plataforma

4. **Búsqueda Avanzada**
   - Filtros por precio
   - Búsqueda por ubicación (mapa)
   - Filtros por amenidades

5. **Calendario de Disponibilidad**
   - Anfitriones bloquean fechas
   - Vista de calendario mensual
   - Sincronización con reservas

### Mejoras de Seguridad

1. **Políticas RLS más estrictas en Storage**
   - Actualmente muy permisivas (desarrollo)
   - Implementar políticas por usuario

2. **Validación de Datos**
   - Validación más estricta en backend
   - Constraints adicionales en BD

3. **Rate Limiting**
   - Limitar requests por usuario
   - Prevenir spam en mensajes

### Optimizaciones

1. **Caché de Imágenes**
   - Implementar caché local
   - Reducir llamadas a Storage

2. **Paginación**
   - Implementar en lista de propiedades
   - Implementar en lista de mensajes

3. **Índices Adicionales**
   - Analizar queries lentas
   - Agregar índices según necesidad

---

## 📞 CONTACTO Y SOPORTE

### Desarrollador Principal
- Email: alof2003@gmail.com

### Recursos Útiles
- [Documentación Supabase](https://supabase.com/docs)
- [Documentación Flutter](https://flutter.dev/docs)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)

---

## 📝 NOTAS FINALES

### Archivos Clave para Nuevos Desarrolladores

Si eres nuevo en el proyecto, lee estos archivos en orden:

1. **`DOCUMENTACION_COMPLETA_PROYECTO.md`** (este archivo) - Visión general
2. **`BASE_DATOS_COMPLETA_FINAL.sql`** - Estructura de BD
3. **`SISTEMA_CHAT_DOCUMENTACION_FINAL.md`** - Sistema de chat
4. **`ERRORES_Y_SOLUCIONES_SQL.sql`** - Problemas comunes
5. **`ESPECIFICACIONES_COMPLETAS.md`** - Especificaciones técnicas

### Convenciones de Código

- **Dart**: Seguir [Effective Dart](https://dart.dev/guides/language/effective-dart)
- **SQL**: Nombres en snake_case, políticas en español
- **Commits**: Mensajes descriptivos en español

### Testing

Actualmente no hay tests automatizados. Se recomienda:
- Implementar tests unitarios para repositories
- Implementar tests de integración para flujos principales
- Implementar tests de UI con Flutter Driver

---

**Última Actualización**: 2025-12-04  
**Versión del Documento**: 1.0.0  
**Estado del Proyecto**: ✅ Funcional y en Producción

---

## ✅ CHECKLIST DE VERIFICACIÓN

Usa este checklist para verificar que todo está funcionando:

### Base de Datos
- [ ] Todas las tablas existen
- [ ] Todas las funciones existen
- [ ] Todos los triggers están activos
- [ ] RLS está habilitado en todas las tablas
- [ ] Políticas RLS están creadas
- [ ] Buckets de Storage existen
- [ ] Realtime está habilitado en `mensajes`

### Funcionalidades
- [ ] Registro de usuarios funciona
- [ ] Login funciona
- [ ] Subida de fotos funciona
- [ ] Crear propiedad funciona
- [ ] Crear reserva funciona
- [ ] Confirmar reserva genera código
- [ ] Chat muestra mensajes en tiempo real
- [ ] Solicitud de anfitrión funciona
- [ ] Panel admin funciona

### Seguridad
- [ ] Usuarios solo ven sus propios datos
- [ ] Anfitriones solo editan sus propiedades
- [ ] Mensajes solo visibles para participantes
- [ ] Storage tiene políticas configuradas

---

**FIN DE LA DOCUMENTACIÓN COMPLETA**

