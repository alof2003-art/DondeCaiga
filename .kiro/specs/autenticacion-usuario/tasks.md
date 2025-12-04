# Plan de Implementación - Autenticación de Usuario

## Tareas de Implementación

- [x] 1. Configurar proyecto Flutter con dependencias y Supabase



  - Agregar dependencias necesarias al pubspec.yaml (supabase_flutter, image_picker, shared_preferences, provider, flutter_dotenv)
  - Crear archivo .env con las credenciales de Supabase
  - Configurar inicialización de Supabase en main.dart
  - Crear estructura de directorios según el diseño
  - _Requirements: Todos_

- [x] 2. Crear esquema de base de datos en Supabase

  - Ejecutar script SQL para crear tabla users_profiles
  - Crear índices necesarios
  - Configurar Row Level Security (RLS) policies
  - Crear buckets de storage (profile-photos, id-documents)
  - Configurar políticas de storage
  - Habilitar email confirmation en Supabase Auth
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 4.1_

- [-] 3. Implementar modelos de datos y utilidades core

  - [x] 3.1 Crear modelo UserProfile con serialización JSON

    - Implementar clase UserProfile con todos los campos
    - Agregar métodos fromJson y toJson
    - _Requirements: 5.1_
  


  - [ ] 3.2 Crear modelo UserRegistrationData
    - Implementar clase para datos de registro
    - _Requirements: 3.1, 3.2_
  
  - [x] 3.3 Implementar ValidationService


    - Crear método validateEmail con regex
    - Crear método validatePassword (mínimo 6 caracteres)
    - Crear método validateName (no vacío)
    - Crear método validatePhone
    - _Requirements: 7.1, 7.2, 3.5, 3.6_
  
  - [ ]* 3.4 Escribir property test para validación de email
    - **Property 5: Invalid email format fails validation**
    - **Validates: Requirements 3.5, 7.1, 7.2**
  
  - [ ]* 3.5 Escribir property test para prevención de envío de formulario
    - **Property 13: Form submission prevention with invalid email**
    - **Validates: Requirements 7.3**
  

  - [x] 3.6 Implementar ErrorHandler

    - Crear método getErrorMessage para manejar diferentes tipos de errores
    - Implementar manejo específico para AuthException, StorageException, SocketException
    - _Requirements: 8.1, 8.2, 8.3_

- [ ] 4. Implementar capa de datos (repositories y datasources)
  - [x] 4.1 Crear UserRepository


    - Implementar createUserProfile
    - Implementar getUserProfile
    - Implementar updateUserProfile
    - Implementar markEmailAsVerified
    - _Requirements: 5.1, 5.4, 5.5_
  
  - [ ]* 4.2 Escribir property test para persistencia de datos de usuario
    - **Property 7: User profile data persistence**
    - **Validates: Requirements 5.1**
  
  - [ ]* 4.3 Escribir property test para email no verificado por defecto
    - **Property 10: New users have unverified email by default**
    - **Validates: Requirements 5.4**

- [ ] 5. Implementar servicios de negocio
  - [x] 5.1 Crear StorageService


    - Implementar uploadProfilePhoto
    - Implementar uploadIdDocument
    - Implementar deleteFile
    - _Requirements: 5.2, 5.3_
  
  - [ ]* 5.2 Escribir property test para subida de foto de perfil
    - **Property 8: Profile photo upload and URL storage**
    - **Validates: Requirements 5.2**
  
  - [ ]* 5.3 Escribir property test para subida de documento de identidad
    - **Property 9: ID document upload and URL storage**
    - **Validates: Requirements 5.3**
  
  - [x] 5.4 Crear AuthService


    - Implementar signIn con manejo de errores
    - Implementar signUp con creación de perfil
    - Implementar signOut
    - Implementar getCurrentUser
    - Implementar isEmailVerified
    - Implementar hasActiveSession
    - Agregar stream authStateChanges
    - _Requirements: 2.2, 2.3, 2.4, 3.2, 3.3, 4.1, 4.4, 6.1, 6.2, 6.3, 6.4_
  
  - [ ]* 5.5 Escribir property test para registro válido
    - **Property 4: Valid registration creates account**
    - **Validates: Requirements 3.2**
  
  - [ ]* 5.6 Escribir property test para credenciales válidas
    - **Property 2: Valid credentials authenticate successfully**
    - **Validates: Requirements 2.2**
  
  - [ ]* 5.7 Escribir property test para credenciales inválidas
    - **Property 3: Invalid credentials show error**
    - **Validates: Requirements 2.3**
  
  - [ ]* 5.8 Escribir property test para verificación de email
    - **Property 6: Email verification is triggered on registration**
    - **Validates: Requirements 4.1**
  
  - [ ]* 5.9 Escribir property test para persistencia de sesión
    - **Property 11: Session token persistence**
    - **Validates: Requirements 6.1**
  
  - [ ]* 5.10 Escribir property test para logout
    - **Property 12: Logout clears session**
    - **Validates: Requirements 6.4**

- [ ] 6. Crear widgets reutilizables
  - [x] 6.1 Crear CustomTextField widget


    - Implementar widget con validación
    - Agregar soporte para obscureText (contraseñas)
    - Agregar iconos y estilos personalizados
    - _Requirements: 2.1, 3.1_
  
  - [x] 6.2 Crear CustomButton widget


    - Implementar botón con loading state
    - Agregar estilos consistentes
    - _Requirements: 2.1, 3.1_
  
  - [x] 6.3 Crear ProfilePhotoPicker widget


    - Implementar selector de imagen circular
    - Integrar con image_picker
    - Permitir selección desde galería o cámara
    - _Requirements: 3.7, 3.8_

- [ ] 7. Implementar SplashScreen
  - [x] 7.1 Crear pantalla splash con logo y tagline


    - Mostrar logo "Donde Caiga"
    - Mostrar tagline "Viaja. Conoce. Comparte."
    - Implementar delay de 2-3 segundos
    - Verificar sesión activa y navegar apropiadamente
    - _Requirements: 1.1, 1.2, 1.3, 6.2_
  
  - [ ]* 7.2 Escribir property test para timing del splash
    - **Property 1: Splash screen timing consistency**
    - **Validates: Requirements 1.2**

- [x] 8. Implementar LoginScreen

  - [ ] 8.1 Crear UI de login
    - Agregar logo en la parte superior
    - Crear campo de email con validación
    - Crear campo de contraseña
    - Agregar botón "ENTRAR"
    - Agregar enlace "¿No tienes cuenta? Regístrate aquí"
    - _Requirements: 2.1_

  
  - [ ] 8.2 Implementar lógica de login
    - Conectar con AuthService.signIn
    - Implementar validación de campos vacíos
    - Mostrar mensajes de error apropiados
    - Implementar loading state
    - Navegar a home en login exitoso
    - Navegar a registro al presionar enlace
    - _Requirements: 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_


- [ ] 9. Implementar RegisterScreen
  - [ ] 9.1 Crear UI de registro
    - Agregar selector de foto de perfil (opcional)
    - Crear campo de nombre
    - Crear campo de teléfono
    - Crear campo de email con validación
    - Crear campo de contraseña
    - Agregar botón "Subir Cédula"

    - Agregar botón "CREAR CUENTA"
    - _Requirements: 3.1_
  
  - [ ] 9.2 Implementar lógica de registro
    - Conectar con AuthService.signUp
    - Implementar validación de campos
    - Implementar selección de imágenes (perfil y cédula)
    - Mostrar mensajes de error apropiados
    - Implementar loading state
    - Mostrar mensaje de verificación de email
    - Navegar a login después de registro exitoso
    - _Requirements: 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 4.2_

- [ ] 10. Implementar navegación y gestión de estado
  - [ ] 10.1 Configurar Provider para AuthService
    - Crear AuthProvider
    - Configurar en main.dart
    - _Requirements: Todos_
  
  - [ ] 10.2 Configurar rutas de navegación
    - Definir rutas nombradas
    - Implementar navegación entre splash, login, register y home
    - _Requirements: 1.3, 2.7, 3.9_
  
  - [x] 10.3 Crear pantalla Home placeholder



    - Crear pantalla simple con mensaje de bienvenida
    - Agregar botón de logout
    - _Requirements: 2.2, 6.4_

- [ ] 11. Checkpoint final - Verificar que todo funciona
  - Asegurar que todos los tests pasen
  - Verificar flujo completo: splash → login → registro → verificación email → login → home
  - Verificar persistencia de sesión
  - Verificar subida de imágenes
  - Preguntar al usuario si hay dudas o problemas