# Documento de Diseño - Gestión de Usuarios por Administrador

## Overview

El sistema de gestión de usuarios por administrador es una funcionalidad crítica que permite a los administradores (rol_id = 3) gestionar las cuentas de viajeros y anfitriones en la plataforma "Donde Caiga". El sistema incluye capacidades para degradar anfitriones a viajeros (con reapertura de verificación), bloquear/desbloquear cuentas, y mantener un historial completo de auditoría. **IMPORTANTE**: Por seguridad, los administradores NO pueden promover viajeros a anfitriones directamente - deben usar el proceso de verificación existente. El sistema se integra con la interfaz de administración existente (`AdminDashboardScreen`).

## Architecture

### Patrón Arquitectónico
El sistema extiende la funcionalidad del `AdminDashboardScreen` existente, siguiendo la arquitectura Clean Architecture ya establecida:

```
lib/features/admin/
├── data/
│   ├── models/
│   │   ├── admin_stats.dart (existente)
│   │   ├── admin_action.dart (nuevo)
│   │   └── audit_log.dart (nuevo)
│   ├── repositories/
│   │   ├── admin_repository.dart (existente - extender)
│   │   └── audit_repository.dart (nuevo)
│   └── datasources/
│       └── audit_remote_datasource.dart (nuevo)
└── presentation/
    ├── screens/
    │   ├── admin_dashboard_screen.dart (existente - extender)
    │   └── audit_history_screen.dart (nuevo)
    └── widgets/
        ├── user_action_dialog.dart (nuevo)
        ├── confirmation_dialog.dart (nuevo)
        └── audit_log_item.dart (nuevo)
```

### Integración con Sistema Existente
- **Pantalla Principal**: Extiende `AdminDashboardScreen` existente agregando botones de acción en el diálogo de detalle de usuario
- **Repositorio**: Extiende `AdminRepository` existente con métodos de gestión de usuarios
- **Base de Datos**: Utiliza tablas existentes `users_profiles` y `solicitudes_anfitrion`, crea nueva tabla `admin_audit_log`
- **Autenticación**: Utiliza el sistema de autenticación existente para verificar permisos de administrador
- **Notificaciones**: Utiliza el sistema de email de Supabase para notificar cambios

## Components and Interfaces

### Core Components

#### 1. AdminRepository (Extensión)
```dart
// Extensión del AdminRepository existente
class AdminRepository {
  // ... métodos existentes ...
  
  // Nuevos métodos para gestión de usuarios
  Future<List<UserProfile>> obtenerUsuariosGestionables({
    String? searchQuery,
    int? roleFilter,
    String? statusFilter,
  });
  
  Future<AdminActionResult> degradarAnfitrionAViajero(String userId, String adminId, String reason);
  Future<AdminActionResult> bloquearCuentaUsuario(String userId, String reason, String adminId);
  Future<AdminActionResult> desbloquearCuentaUsuario(String userId, String adminId);
  Future<bool> validarPermisosAdmin(String adminId, String targetUserId);
}
```

#### 2. AuditRepository
```dart
abstract class AuditRepository {
  Future<void> registrarAccionAdmin(AdminAction action);
  Future<List<AuditLog>> obtenerHistorialAuditoria({
    String? actionTypeFilter,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  });
}
```

### UI Components

#### 1. AdminDashboardScreen (Extensión)
- Extiende el diálogo `_mostrarDetalleUsuario` existente
- Agrega botones de acción según el rol y estado del usuario
- Implementa búsqueda y filtros en la lista de usuarios
- Mantiene la funcionalidad existente intacta

#### 2. UserActionDialog
- Diálogos de confirmación para acciones críticas
- Campos para motivos de bloqueo
- Validación de entrada y permisos

#### 3. AuditHistoryScreen
- Lista completa del historial de auditoría
- Filtros por tipo de acción y fecha
- Paginación para grandes volúmenes de datos

## Data Models

### AdminAction
```dart
class AdminAction {
  final String adminId;
  final String targetUserId;
  final String actionType; // 'degrade_role', 'block_account', 'unblock_account'
  final Map<String, dynamic> actionData;
  final String? reason;
  final DateTime timestamp;
}
```

### AuditLog
```dart
class AuditLog {
  final String id;
  final String adminId;
  final String adminNombre;
  final String targetUserId;
  final String targetUserNombre;
  final String actionType;
  final Map<String, dynamic> actionData;
  final String? reason;
  final DateTime timestamp;
  final bool wasSuccessful;
}
```

### AdminActionResult
```dart
class AdminActionResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final String? errorCode;
}
```

### Database Schema Extensions

#### Nueva tabla: admin_audit_log
```sql
CREATE TABLE admin_audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID NOT NULL REFERENCES users_profiles(id),
  target_user_id UUID NOT NULL REFERENCES users_profiles(id),
  action_type VARCHAR(50) NOT NULL,
  action_data JSONB,
  reason TEXT,
  was_successful BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_audit_log_admin ON admin_audit_log(admin_id);
CREATE INDEX idx_audit_log_target ON admin_audit_log(target_user_id);
CREATE INDEX idx_audit_log_action_type ON admin_audit_log(action_type);
CREATE INDEX idx_audit_log_created_at ON admin_audit_log(created_at);
```

#### Modificaciones a users_profiles
- El campo `estado_cuenta` ya existe con valores: 'activo', 'bloqueado'
- El campo `rol_id` ya existe con valores: 1 (viajero), 2 (anfitrión), 3 (admin)

#### Uso de solicitudes_anfitrion existente
- Cuando se degrada un anfitrión, se crea una nueva solicitud en estado 'pendiente'
- Esto permite que el usuario pueda solicitar ser anfitrión nuevamente

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property Reflection

Después de revisar todas las propiedades identificadas en el prework, he identificado las siguientes consolidaciones para eliminar redundancia:

- **Propiedades de degradación de rol** se consolidan en una sola propiedad que incluye la creación de solicitud de re-verificación
- **Propiedades de cambios de estado** se combinan en una propiedad general sobre cambios de estado
- **Propiedades de validaciones de administrador** se combinan en una propiedad general de validación
- **Propiedades de registro de auditoría** se combinan en una propiedad general de auditoría

### Propiedades de Correctness Consolidadas

**Property 1: Exclusión de administradores en lista**
*Para cualquier* conjunto de usuarios en la base de datos, la lista de usuarios gestionables debe excluir automáticamente todos los usuarios con rol_id = 3 (administradores)
**Validates: Requirements 1.3, 6.1**

**Property 2: Información completa de usuario**
*Para cualquier* usuario en la lista de gestión, la información mostrada debe incluir todos los campos requeridos: foto de perfil, nombre, email, rol actual, estado de cuenta y fecha de registro
**Validates: Requirements 1.4**

**Property 3: Ordenamiento por fecha**
*Para cualquier* lista de usuarios cargada, los usuarios deben estar ordenados por fecha de registro con los más recientes primero
**Validates: Requirements 1.5**

**Property 4: Filtrado de búsqueda**
*Para cualquier* término de búsqueda y conjunto de usuarios, el sistema debe filtrar usuarios que contengan el término en su nombre o email
**Validates: Requirements 2.2**

**Property 5: Filtrado por rol**
*Para cualquier* filtro de rol seleccionado y conjunto de usuarios, el sistema debe mostrar solo usuarios con ese rol específico
**Validates: Requirements 2.3**

**Property 6: Filtrado por estado**
*Para cualquier* filtro de estado seleccionado y conjunto de usuarios, el sistema debe mostrar solo usuarios con ese estado específico
**Validates: Requirements 2.4**

**Property 7: Degradación de anfitrión con re-verificación**
*Para cualquier* usuario con rol anfitrión, cuando se degrada a viajero, el sistema debe actualizar el rol_id de 2 a 1 y crear una nueva solicitud de anfitrión en estado 'pendiente'
**Validates: Requirements 3.3, 3.4, 3.5**

**Property 8: Cambio de estado de cuenta**
*Para cualquier* usuario con estado activo o bloqueado, cuando se cambia su estado, el sistema debe actualizar correctamente el estado_cuenta en la base de datos
**Validates: Requirements 4.3, 5.3**

**Property 9: Bloqueo impide acceso**
*Para cualquier* usuario con estado bloqueado, el sistema debe impedir el inicio de sesión y mostrar mensaje apropiado
**Validates: Requirements 4.4**

**Property 10: Cierre de sesiones al bloquear**
*Para cualquier* usuario que se bloquea, el sistema debe cerrar automáticamente todas sus sesiones activas
**Validates: Requirements 4.5**

**Property 11: Validación de permisos administrativos**
*Para cualquier* intento de gestión de usuario, el sistema debe validar que el usuario objetivo no sea administrador antes de proceder
**Validates: Requirements 6.2, 6.3, 6.4**

**Property 12: Prevención de auto-gestión**
*Para cualquier* administrador, el sistema debe impedir que gestione su propia cuenta (degradación de rol o bloqueo)
**Validates: Requirements 6.6**

**Property 13: Registro de auditoría completo**
*Para cualquier* acción administrativa realizada, el sistema debe registrar en la tabla de auditoría: fecha, administrador, usuario objetivo, acción realizada y motivo
**Validates: Requirements 4.6, 5.5, 6.5, 7.1**

**Property 14: Ordenamiento de historial**
*Para cualquier* conjunto de acciones en el historial de auditoría, las acciones deben estar ordenadas por fecha con las más recientes primero
**Validates: Requirements 7.2**

**Property 15: Información completa de auditoría**
*Para cualquier* entrada en el historial de auditoría, debe incluir: fecha/hora, nombre del administrador, usuario afectado, tipo de acción y motivo (si aplica)
**Validates: Requirements 7.3**

**Property 16: Filtrado de historial por tipo**
*Para cualquier* filtro de tipo de acción y conjunto de entradas de auditoría, el sistema debe mostrar solo las acciones del tipo especificado
**Validates: Requirements 7.5**

**Property 17: Filtrado de historial por fecha**
*Para cualquier* rango de fechas y conjunto de entradas de auditoría, el sistema debe mostrar solo las acciones dentro del rango especificado
**Validates: Requirements 7.6**

**Property 18: Botones de confirmación estándar**
*Para cualquier* diálogo de confirmación mostrado, debe incluir botones claramente etiquetados "Confirmar" y "Cancelar"
**Validates: Requirements 8.4**

**Property 19: Cancelación sin cambios**
*Para cualquier* acción cancelada por el administrador, el sistema debe cerrar el diálogo sin realizar cambios en la base de datos
**Validates: Requirements 8.5**

**Property 20: Mensajes de éxito consistentes**
*Para cualquier* acción administrativa exitosa, el sistema debe mostrar un mensaje de confirmación verde con detalles específicos
**Validates: Requirements 9.1**

**Property 21: Mensajes de error consistentes**
*Para cualquier* acción administrativa fallida, el sistema debe mostrar un mensaje de error rojo con información específica del problema
**Validates: Requirements 9.2**

**Property 22: Preservación de reservas en degradación**
*Para cualquier* usuario que se degrada de anfitrión a viajero, el sistema debe mantener todas sus reservas existentes como viajero
**Validates: Requirements 10.1**

**Property 23: Desactivación de propiedades en degradación**
*Para cualquier* usuario que se degrada de anfitrión a viajero, el sistema debe mantener sus propiedades pero cambiar su estado a "inactivo"
**Validates: Requirements 10.2**

**Property 24: Creación de solicitud de re-verificación**
*Para cualquier* anfitrión que se degrada a viajero, el sistema debe crear automáticamente una nueva solicitud de anfitrión en estado "pendiente"
**Validates: Requirements 10.3**

**Property 25: Desactivación de propiedades al bloquear anfitrión**
*Para cualquier* anfitrión que se bloquea, el sistema debe cambiar automáticamente todas sus propiedades activas a estado "inactivo"
**Validates: Requirements 10.4**

**Property 26: Cancelación de reservas al bloquear usuario**
*Para cualquier* usuario que se bloquea, el sistema debe cancelar automáticamente todas sus reservas pendientes
**Validates: Requirements 10.5**

**Property 27: Notificación de cambios administrativos**
*Para cualquier* cambio administrativo realizado, el sistema debe notificar al usuario afectado por email sobre los cambios en su cuenta
**Validates: Requirements 10.7**

## Error Handling

### Categorías de Errores

#### 1. Errores de Permisos
- **AdminPermissionError**: Cuando un no-administrador intenta acceder
- **SelfManagementError**: Cuando un admin intenta gestionarse a sí mismo
- **AdminTargetError**: Cuando se intenta gestionar otro administrador

#### 2. Errores de Validación
- **UserNotFoundError**: Usuario objetivo no existe
- **InvalidRoleError**: Rol especificado no válido
- **InvalidStatusError**: Estado especificado no válido
- **MissingReasonError**: Motivo requerido para bloqueo no proporcionado
- **ViajeroPromotionError**: Intento de promover viajero a anfitrión directamente

#### 3. Errores de Conectividad
- **NetworkError**: Problemas de conexión a Supabase
- **DatabaseError**: Errores en operaciones de base de datos
- **TimeoutError**: Operaciones que exceden tiempo límite

#### 4. Errores de Estado
- **UserAlreadyBlockedError**: Intento de bloquear usuario ya bloqueado
- **UserAlreadyActiveError**: Intento de desbloquear usuario ya activo
- **UserAlreadyViajeroError**: Intento de degradar usuario que ya es viajero

### Estrategias de Manejo

```dart
class UserManagementErrorHandler {
  static AdminActionResult handleError(Exception error) {
    switch (error.runtimeType) {
      case AdminPermissionError:
        return AdminActionResult(
          success: false,
          message: "No tienes permisos para realizar esta acción",
          errorCode: "PERMISSION_DENIED"
        );
      case ViajeroPromotionError:
        return AdminActionResult(
          success: false,
          message: "Los viajeros deben usar el proceso de verificación normal para ser anfitriones",
          errorCode: "VIAJERO_PROMOTION_DENIED"
        );
      case UserNotFoundError:
        return AdminActionResult(
          success: false,
          message: "El usuario seleccionado no existe o fue eliminado",
          errorCode: "USER_NOT_FOUND"
        );
      case NetworkError:
        return AdminActionResult(
          success: false,
          message: "Error de conexión. Verifica tu internet e intenta nuevamente",
          errorCode: "NETWORK_ERROR"
        );
      default:
        return AdminActionResult(
          success: false,
          message: "Ocurrió un error inesperado. Intenta nuevamente",
          errorCode: "UNKNOWN_ERROR"
        );
    }
  }
}
```

## Testing Strategy

### Dual Testing Approach

El sistema implementará tanto pruebas unitarias como pruebas basadas en propiedades para garantizar cobertura completa:

#### Unit Testing
- **Casos específicos**: Pruebas para escenarios concretos y casos edge
- **Integración**: Verificación de puntos de integración entre componentes
- **UI**: Validación de elementos de interfaz específicos
- **Manejo de errores**: Pruebas para condiciones de error específicas

#### Property-Based Testing
- **Biblioteca**: Se utilizará el paquete `faker` ya incluido en el proyecto para generar datos de prueba aleatorios
- **Configuración**: Cada prueba de propiedad ejecutará un mínimo de 100 iteraciones
- **Etiquetado**: Cada prueba de propiedad incluirá un comentario con el formato: `**Feature: gestion-usuarios-admin, Property {number}: {property_text}**`
- **Cobertura**: Las propiedades verificarán comportamientos universales que deben mantenerse para cualquier entrada válida

#### Ejemplos de Pruebas de Propiedad

```dart
// **Feature: gestion-usuarios-admin, Property 1: Exclusión de administradores en lista**
test('should exclude all administrators from manageable users list', () {
  final faker = Faker();
  
  // Generate random users with different roles including admins
  final users = List.generate(100, (index) => UserProfile(
    id: faker.guid.guid(),
    rolId: faker.randomGenerator.integer(3, min: 1), // 1, 2, or 3
    // ... other random fields
  ));
  
  final manageableUsers = UserManagementService.filterManageableUsers(users);
  
  // Property: No user in the result should have rol_id = 3
  expect(manageableUsers.every((user) => user.rolId != 3), isTrue);
});

// **Feature: gestion-usuarios-admin, Property 7: Degradación de anfitrión con re-verificación**
test('should create new host application when degrading host to traveler', () {
  final faker = Faker();
  
  // Generate random host users
  final hostUsers = List.generate(50, (index) => UserProfile(
    id: faker.guid.guid(),
    rolId: 2, // Host
    estadoCuenta: 'activo',
    // ... other random fields
  ));
  
  for (final user in hostUsers) {
    final result = UserManagementService.degradeHostToTraveler(user.id, 'admin-id', 'test reason');
    
    // Property: User should become traveler and have new pending application
    expect(result.success, isTrue);
    expect(getUserById(user.id).rolId, equals(1)); // Now traveler
    expect(hasPendingHostApplication(user.id), isTrue); // Has new application
  }
});
```

### Testing Requirements
- Cada propiedad de correctness debe ser implementada por UNA SOLA prueba basada en propiedades
- Las pruebas unitarias y de propiedades son complementarias y ambas deben incluirse
- Las pruebas de propiedades manejan la cobertura de muchas entradas, las unitarias capturan bugs concretos
- Se debe verificar que todas las propiedades de correctness estén cubiertas por pruebas