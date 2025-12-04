# Documento de Diseño - Autenticación de Usuario

## Overview

Este documento describe el diseño técnico del sistema de autenticación para la aplicación "Donde Caiga". El sistema utilizará Supabase como backend para autenticación, almacenamiento de datos y storage de archivos. La aplicación Flutter implementará una arquitectura limpia con separación de responsabilidades entre UI, lógica de negocio y acceso a datos.

## Arquitectura

### Arquitectura General

La aplicación seguirá una arquitectura en capas:

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  (Screens, Widgets, State Mgmt)    │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│         Business Logic Layer        │
│     (Services, Use Cases)           │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│          Data Layer                 │
│  (Repositories, Data Sources)       │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│         External Services           │
│    (Supabase Auth, DB, Storage)     │
└─────────────────────────────────────┘
```

### Dependencias Principales

El proyecto utilizará los siguientes paquetes de Flutter:

- **supabase_flutter**: ^2.0.0 - Cliente oficial de Supabase para Flutter
- **image_picker**: ^1.0.0 - Para seleccionar imágenes de galería/cámara
- **shared_preferences**: ^2.2.0 - Para persistencia local de sesión
- **provider**: ^6.1.0 - Para gestión de estado
- **flutter_dotenv**: ^5.1.0 - Para manejo de variables de entorno

## Componentes y Interfaces

### 1. Capa de Presentación (UI)

#### SplashScreen
- **Responsabilidad**: Mostrar el logo de la aplicación durante 2-3 segundos
- **Widgets**: 
  - Logo image
  - Tagline text
- **Navegación**: Automática a LoginScreen después del delay

#### LoginScreen
- **Responsabilidad**: Permitir al usuario iniciar sesión
- **Widgets**:
  - Logo header
  - Email TextField con validación
  - Password TextField con obscureText
  - Login Button
  - Register link
- **Estado**: 
  - isLoading (bool)
  - errorMessage (String?)
- **Interacciones**:
  - onLoginPressed() → AuthService.signIn()
  - onRegisterLinkPressed() → Navigate to RegisterScreen

#### RegisterScreen
- **Responsabilidad**: Permitir al usuario crear una cuenta
- **Widgets**:
  - Profile photo picker (circular avatar)
  - Name TextField
  - Phone TextField
  - Email TextField con validación
  - Password TextField
  - ID document upload button
  - Register Button
- **Estado**:
  - profileImage (File?)
  - idDocumentImage (File?)
  - isLoading (bool)
  - errorMessage (String?)
- **Interacciones**:
  - onProfilePhotoTap() → ImagePicker
  - onIdDocumentTap() → ImagePicker
  - onRegisterPressed() → AuthService.signUp()

### 2. Capa de Lógica de Negocio

#### AuthService
```dart
class AuthService {
  final SupabaseClient _supabase;
  final StorageService _storage;
  
  // Autenticación
  Future<AuthResponse> signIn(String email, String password);
  Future<AuthResponse> signUp(UserRegistrationData data);
  Future<void> signOut();
  Future<User?> getCurrentUser();
  Future<bool> isEmailVerified();
  
  // Sesión
  Stream<AuthState> get authStateChanges;
  Future<bool> hasActiveSession();
}
```

#### StorageService
```dart
class StorageService {
  final SupabaseClient _supabase;
  
  Future<String> uploadProfilePhoto(File image, String userId);
  Future<String> uploadIdDocument(File image, String userId);
  Future<void> deleteFile(String path);
}
```

#### ValidationService
```dart
class ValidationService {
  static String? validateEmail(String? email);
  static String? validatePassword(String? password);
  static String? validateName(String? name);
  static String? validatePhone(String? phone);
}
```

### 3. Capa de Datos

#### UserRepository
```dart
class UserRepository {
  final SupabaseClient _supabase;
  
  Future<UserProfile> createUserProfile(UserProfileData data);
  Future<UserProfile?> getUserProfile(String userId);
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates);
  Future<void> markEmailAsVerified(String userId);
}
```

#### Models

**UserProfile**
```dart
class UserProfile {
  final String id;
  final String email;
  final String nombre;
  final String? telefono;
  final String? fotoPerfilUrl;
  final String? cedulaUrl;
  final DateTime createdAt;
  final bool emailVerified;
  
  UserProfile({...});
  
  factory UserProfile.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

**UserRegistrationData**
```dart
class UserRegistrationData {
  final String email;
  final String password;
  final String nombre;
  final String? telefono;
  final File? profilePhoto;
  final File? idDocument;
  
  UserRegistrationData({...});
}
```

## Data Models

### Esquema de Base de Datos Supabase

#### Tabla: users_profiles

```sql
CREATE TABLE users_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  nombre TEXT NOT NULL,
  telefono TEXT,
  foto_perfil_url TEXT,
  cedula_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  email_verified BOOLEAN DEFAULT FALSE
);

-- Índices
CREATE INDEX idx_users_profiles_email ON users_profiles(email);

-- RLS (Row Level Security)
ALTER TABLE users_profiles ENABLE ROW LEVEL SECURITY;

-- Política: Los usuarios solo pueden leer su propio perfil
CREATE POLICY "Users can read own profile"
  ON users_profiles FOR SELECT
  USING (auth.uid() = id);

-- Política: Los usuarios solo pueden actualizar su propio perfil
CREATE POLICY "Users can update own profile"
  ON users_profiles FOR UPDATE
  USING (auth.uid() = id);

-- Política: Permitir inserción durante registro
CREATE POLICY "Users can insert own profile"
  ON users_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);
```

#### Storage Buckets

**Bucket: profile-photos**
- Público: No
- Tamaño máximo: 5MB
- Tipos permitidos: image/jpeg, image/png, image/webp

**Bucket: id-documents**
- Público: No
- Tamaño máximo: 10MB
- Tipos permitidos: image/jpeg, image/png, image/pdf

```sql
-- Políticas de Storage para profile-photos
CREATE POLICY "Users can upload own profile photo"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'profile-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can read own profile photo"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'profile-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Políticas similares para id-documents
CREATE POLICY "Users can upload own id document"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'id-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can read own id document"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'id-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );
```

### Configuración de Supabase Auth

- **Email confirmation**: Habilitado
- **Email templates**: Personalizar con branding de "Donde Caiga"
- **Redirect URLs**: Configurar deep links para la app móvil
- **Session duration**: 7 días por defecto

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: Splash screen timing consistency
*For any* app launch, the splash screen should remain visible for a duration between 2 and 3 seconds before navigation occurs
**Validates: Requirements 1.2**

### Property 2: Valid credentials authenticate successfully
*For any* valid email and password combination that exists in the system, attempting to sign in should result in successful authentication and navigation to the main screen
**Validates: Requirements 2.2**

### Property 3: Invalid credentials show error
*For any* invalid email or password combination, attempting to sign in should result in an error message being displayed
**Validates: Requirements 2.3**

### Property 4: Valid registration creates account
*For any* valid registration data (valid email format, password ≥6 chars, non-empty name), creating an account should successfully store the user in Supabase
**Validates: Requirements 3.2**

### Property 5: Invalid email format fails validation
*For any* string that doesn't contain "@" or doesn't have a valid domain format, email validation should return an error
**Validates: Requirements 3.5, 7.1, 7.2**

### Property 6: Email verification is triggered on registration
*For any* successful user registration, the system should automatically trigger Supabase's email verification flow
**Validates: Requirements 4.1**

### Property 7: User profile data persistence
*For any* user registration with complete data (name, phone, email), all provided fields should be correctly stored in the users_profiles table with matching values
**Validates: Requirements 5.1**

### Property 8: Profile photo upload and URL storage
*For any* valid image file uploaded as a profile photo, the system should upload it to Supabase storage and store the resulting URL in the foto_perfil_url field
**Validates: Requirements 5.2**

### Property 9: ID document upload and URL storage
*For any* valid image file uploaded as an ID document, the system should upload it to Supabase storage and store the resulting URL in the cedula_url field
**Validates: Requirements 5.3**

### Property 10: New users have unverified email by default
*For any* newly created user account, the email_verified field should be set to false
**Validates: Requirements 5.4**

### Property 11: Session token persistence
*For any* successful login, the system should store the Supabase session token in local storage
**Validates: Requirements 6.1**

### Property 12: Logout clears session
*For any* logged-in user, calling logout should remove the session token from local storage and navigate to the login screen
**Validates: Requirements 6.4**

### Property 13: Form submission prevention with invalid email
*For any* registration or login attempt with an invalid email format, the form submission should be prevented
**Validates: Requirements 7.3**

## Error Handling

### Error Categories

1. **Validation Errors**
   - Empty required fields
   - Invalid email format
   - Password too short (< 6 characters)
   - Display inline error messages below respective fields

2. **Authentication Errors**
   - Invalid credentials → "Email o contraseña incorrectos"
   - Email not verified → "Por favor verifica tu email antes de iniciar sesión"
   - Email already exists → "Este email ya está registrado"
   - Display as snackbar or alert dialog

3. **Network Errors**
   - No internet connection → "Sin conexión a internet"
   - Supabase connection failed → "Error de conexión. Verifica tu internet e intenta nuevamente"
   - Display as snackbar with retry option

4. **File Upload Errors**
   - File too large → "La imagen es demasiado grande (máx 5MB para fotos, 10MB para documentos)"
   - Invalid file type → "Formato de archivo no válido"
   - Upload failed → "Error al subir la imagen. Intenta nuevamente"
   - Display as snackbar

### Error Handling Strategy

```dart
class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is AuthException) {
      return _handleAuthError(error);
    } else if (error is StorageException) {
      return _handleStorageError(error);
    } else if (error is SocketException) {
      return "Sin conexión a internet";
    } else {
      return "Ocurrió un error inesperado. Intenta nuevamente";
    }
  }
  
  static String _handleAuthError(AuthException error) {
    switch (error.statusCode) {
      case '400':
        return "Email o contraseña incorrectos";
      case '422':
        return "Este email ya está registrado";
      default:
        return "Error de autenticación";
    }
  }
  
  static String _handleStorageError(StorageException error) {
    if (error.message.contains('size')) {
      return "La imagen es demasiado grande";
    }
    return "Error al subir la imagen";
  }
}
```

### Logging Strategy

- Log all authentication attempts (success/failure) with timestamps
- Log file upload attempts and results
- Log navigation events for debugging user flows
- Use Flutter's `debugPrint` for development
- Consider integrating Sentry or Firebase Crashlytics for production error tracking

## Testing Strategy

### Unit Testing

La estrategia de testing incluirá pruebas unitarias y pruebas basadas en propiedades (property-based testing) para asegurar la corrección del sistema.

**Unit Tests** cubrirán:
- Validación de formularios (email, password, name formats)
- Transformación de datos (JSON serialization/deserialization)
- Manejo de errores específicos
- Navegación entre pantallas

**Ejemplos de unit tests**:
```dart
test('validateEmail returns error for empty string', () {
  expect(ValidationService.validateEmail(''), isNotNull);
});

test('validateEmail returns null for valid email', () {
  expect(ValidationService.validateEmail('test@example.com'), isNull);
});

test('UserProfile.fromJson creates correct object', () {
  final json = {'id': '123', 'email': 'test@test.com', ...};
  final profile = UserProfile.fromJson(json);
  expect(profile.id, '123');
  expect(profile.email, 'test@test.com');
});
```

### Property-Based Testing

Utilizaremos el paquete **faker** para generar datos aleatorios y **test** (el framework de testing estándar de Dart) para implementar property-based tests.

**Property-Based Tests** verificarán:
- Propiedades universales que deben cumplirse para cualquier entrada válida
- Comportamiento consistente a través de múltiples ejecuciones con datos aleatorios
- Invariantes del sistema que deben mantenerse

**Configuración**:
- Cada property test ejecutará un mínimo de 100 iteraciones
- Cada test estará etiquetado con el formato: `**Feature: autenticacion-usuario, Property {number}: {property_text}**`
- Los tests usarán el paquete `faker` para generar datos aleatorios realistas

**Ejemplos de property-based tests**:
```dart
// **Feature: autenticacion-usuario, Property 5: Invalid email format fails validation**
test('Property: any string without @ fails email validation', () {
  final faker = Faker();
  for (int i = 0; i < 100; i++) {
    final invalidEmail = faker.lorem.word(); // No contiene @
    final result = ValidationService.validateEmail(invalidEmail);
    expect(result, isNotNull, reason: 'Email without @ should fail validation');
  }
});

// **Feature: autenticacion-usuario, Property 7: User profile data persistence**
test('Property: all registration data is correctly stored', () async {
  final faker = Faker();
  for (int i = 0; i < 100; i++) {
    final testData = UserRegistrationData(
      email: faker.internet.email(),
      password: faker.internet.password(length: 8),
      nombre: faker.person.name(),
      telefono: faker.phoneNumber.us(),
    );
    
    final profile = await userRepository.createUserProfile(testData);
    
    expect(profile.email, testData.email);
    expect(profile.nombre, testData.nombre);
    expect(profile.telefono, testData.telefono);
  }
});
```

### Integration Testing

- Flujo completo de registro: desde la pantalla de registro hasta la creación en Supabase
- Flujo completo de login: desde la pantalla de login hasta la navegación a home
- Persistencia de sesión: cerrar y reabrir la app con sesión activa

### Widget Testing

- Verificar que todos los elementos UI estén presentes en cada pantalla
- Verificar que los botones respondan a taps
- Verificar que los mensajes de error se muestren correctamente
- Verificar navegación entre pantallas

## Flujo de Navegación

```mermaid
graph TD
    A[App Start] --> B[Splash Screen]
    B --> C{Has Active Session?}
    C -->|Yes| D[Home Screen]
    C -->|No| E[Login Screen]
    E --> F{Login Action}
    F -->|Success| D
    F -->|Error| E
    E --> G[Register Screen]
    G --> H{Register Action}
    H -->|Success| I[Show Verification Message]
    I --> E
    H -->|Error| G
    D --> J{Logout}
    J --> E
```

## Configuración del Proyecto

### Variables de Entorno

Crear archivo `.env` en la raíz del proyecto:

```env
SUPABASE_URL=https://louehuwimvwsoqesjjau.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvdWVodXdpbXZ3c29xZXNqamF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3OTQ4MTYsImV4cCI6MjA4MDM3MDgxNn0.vhqclBtgt-o_GTNFGsU-pKYK68coeemIjl_CTQl8Rz8
```

### Inicialización de Supabase

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  runApp(MyApp());
}
```

## Estructura de Directorios

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── utils/
│   │   ├── error_handler.dart
│   │   └── validators.dart
│   └── config/
│       └── supabase_config.dart
├── features/
│   └── auth/
│       ├── data/
│       │   ├── models/
│       │   │   ├── user_profile.dart
│       │   │   └── user_registration_data.dart
│       │   ├── repositories/
│       │   │   └── user_repository.dart
│       │   └── datasources/
│       │       └── supabase_auth_datasource.dart
│       ├── domain/
│       │   ├── entities/
│       │   └── repositories/
│       └── presentation/
│           ├── screens/
│           │   ├── splash_screen.dart
│           │   ├── login_screen.dart
│           │   └── register_screen.dart
│           ├── widgets/
│           │   ├── custom_text_field.dart
│           │   ├── custom_button.dart
│           │   └── profile_photo_picker.dart
│           └── providers/
│               └── auth_provider.dart
└── services/
    ├── auth_service.dart
    ├── storage_service.dart
    └── validation_service.dart
```

## Consideraciones de Seguridad

1. **Nunca almacenar contraseñas en texto plano** - Supabase maneja el hashing automáticamente
2. **Validar datos en cliente y servidor** - Implementar validación en Flutter y usar RLS en Supabase
3. **Usar HTTPS** - Supabase proporciona esto por defecto
4. **Implementar rate limiting** - Configurar en Supabase para prevenir ataques de fuerza bruta
5. **Sanitizar inputs** - Prevenir inyección SQL (Supabase usa prepared statements)
6. **Proteger archivos sensibles** - Los documentos de identidad solo deben ser accesibles por el usuario propietario

## Consideraciones de UX

1. **Loading states** - Mostrar indicadores de carga durante operaciones asíncronas
2. **Feedback inmediato** - Validación en tiempo real de formularios
3. **Mensajes claros** - Errores descriptivos en español
4. **Accesibilidad** - Tamaños de fuente legibles, contraste adecuado
5. **Responsive design** - Adaptar a diferentes tamaños de pantalla
6. **Offline handling** - Detectar y comunicar problemas de conectividad

## Performance

1. **Lazy loading** - Cargar imágenes solo cuando sea necesario
2. **Image optimization** - Comprimir imágenes antes de subir (max 5MB para fotos, 10MB para documentos)
3. **Caching** - Cachear datos de perfil localmente
4. **Debouncing** - En validación de formularios para reducir llamadas
