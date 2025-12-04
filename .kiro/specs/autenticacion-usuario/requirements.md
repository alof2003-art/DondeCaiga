# Documento de Requisitos - Autenticación de Usuario

## Introducción

Este documento define los requisitos para el sistema de autenticación de usuarios de la aplicación "Donde Caiga", una plataforma de alojamiento gratuito estilo Airbnb. El sistema permitirá a los usuarios registrarse, iniciar sesión y verificar sus cuentas mediante correo electrónico utilizando Supabase como backend.

## Glosario

- **Sistema**: La aplicación móvil "Donde Caiga" desarrollada en Flutter
- **Usuario**: Persona que utiliza la aplicación para registrarse o iniciar sesión
- **Supabase**: Plataforma de backend que proporciona autenticación y base de datos
- **Pantalla de Splash**: Pantalla inicial que muestra el logo de la aplicación
- **Perfil de Usuario**: Información personal del usuario incluyendo nombre, apellido, email, teléfono y foto
- **Verificación de Email**: Proceso de confirmación de la dirección de correo electrónico del usuario
- **Sesión Activa**: Estado en el que un usuario ha iniciado sesión exitosamente

## Requisitos

### Requisito 1: Pantalla de Bienvenida

**User Story:** Como usuario nuevo, quiero ver el logo de la aplicación al iniciar, para identificar la aplicación y tener una experiencia de bienvenida profesional.

#### Criterios de Aceptación

1. WHEN el usuario abre la aplicación por primera vez, THEN el Sistema SHALL mostrar una pantalla de splash con el logo "Donde Caiga" y el tagline "Viaja. Conoce. Comparte."
2. WHEN la pantalla de splash se muestra, THEN el Sistema SHALL mantenerla visible durante 2-3 segundos antes de la transición
3. WHEN el tiempo de splash finaliza, THEN el Sistema SHALL navegar automáticamente a la pantalla de inicio de sesión

### Requisito 2: Inicio de Sesión

**User Story:** Como usuario registrado, quiero iniciar sesión con mi email y contraseña, para acceder a mi cuenta y utilizar las funcionalidades de la aplicación.

#### Criterios de Aceptación

1. WHEN el usuario accede a la pantalla de inicio de sesión, THEN el Sistema SHALL mostrar el logo en la parte superior, un campo de email, un campo de contraseña, un botón "ENTRAR" y un enlace "¿No tienes cuenta? Regístrate aquí"
2. WHEN el usuario ingresa credenciales válidas y presiona "ENTRAR", THEN el Sistema SHALL autenticar al usuario mediante Supabase y navegar a la pantalla principal
3. WHEN el usuario ingresa credenciales inválidas, THEN el Sistema SHALL mostrar un mensaje de error indicando que las credenciales son incorrectas
4. WHEN el usuario no ha verificado su email, THEN el Sistema SHALL mostrar un mensaje indicando que debe verificar su cuenta antes de iniciar sesión
5. WHEN el campo de email está vacío y el usuario presiona "ENTRAR", THEN el Sistema SHALL mostrar un mensaje de validación solicitando el email
6. WHEN el campo de contraseña está vacío y el usuario presiona "ENTRAR", THEN el Sistema SHALL mostrar un mensaje de validación solicitando la contraseña
7. WHEN el usuario presiona el enlace "¿No tienes cuenta? Regístrate aquí", THEN el Sistema SHALL navegar a la pantalla de registro

### Requisito 3: Registro de Usuario

**User Story:** Como usuario nuevo, quiero registrarme proporcionando mi información personal, para crear una cuenta y acceder a la plataforma.

#### Criterios de Aceptación

1. WHEN el usuario accede a la pantalla de registro, THEN el Sistema SHALL mostrar campos para foto de perfil (opcional), nombre, teléfono, email, contraseña, y un botón "Subir Cédula" y un botón "CREAR CUENTA"
2. WHEN el usuario completa todos los campos obligatorios y presiona "CREAR CUENTA", THEN el Sistema SHALL crear la cuenta en Supabase con los datos proporcionados
3. WHEN el usuario intenta registrarse con un email ya existente, THEN el Sistema SHALL mostrar un mensaje de error indicando que el email ya está registrado
4. WHEN el campo de nombre está vacío, THEN el Sistema SHALL mostrar un mensaje de validación solicitando el nombre
5. WHEN el campo de email está vacío o tiene formato inválido, THEN el Sistema SHALL mostrar un mensaje de validación solicitando un email válido
6. WHEN el campo de contraseña tiene menos de 6 caracteres, THEN el Sistema SHALL mostrar un mensaje indicando que la contraseña debe tener al menos 6 caracteres
7. WHEN el usuario selecciona una foto de perfil, THEN el Sistema SHALL permitir cargar la imagen desde la galería o cámara del dispositivo
8. WHEN el usuario presiona "Subir Cédula", THEN el Sistema SHALL permitir cargar una imagen de documento de identidad desde la galería o cámara
9. WHEN el registro es exitoso, THEN el Sistema SHALL navegar automáticamente a la pantalla de inicio de sesión

### Requisito 4: Verificación de Email

**User Story:** Como usuario registrado, quiero recibir un email de verificación, para confirmar mi dirección de correo electrónico y activar mi cuenta.

#### Criterios de Aceptación

1. WHEN el usuario completa el registro exitosamente, THEN el Sistema SHALL enviar automáticamente un email de verificación a la dirección proporcionada mediante Supabase Auth
2. WHEN el email de verificación es enviado, THEN el Sistema SHALL mostrar un mensaje informando al usuario que revise su correo para verificar la cuenta
3. WHEN el usuario hace clic en el enlace de verificación del email, THEN Supabase SHALL marcar la cuenta como verificada
4. WHEN el usuario intenta iniciar sesión sin verificar el email, THEN el Sistema SHALL mostrar un mensaje solicitando la verificación de la cuenta

### Requisito 5: Almacenamiento de Datos de Usuario

**User Story:** Como sistema, necesito almacenar la información del usuario en la base de datos, para mantener los perfiles de usuario y permitir la autenticación.

#### Criterios de Aceptación

1. WHEN un usuario se registra, THEN el Sistema SHALL crear un registro en la tabla de usuarios de Supabase con los campos: id, email, nombre, apellido, teléfono, foto_perfil_url, cedula_url, created_at, email_verified
2. WHEN se almacena una foto de perfil, THEN el Sistema SHALL subir la imagen al storage de Supabase y guardar la URL en el campo foto_perfil_url
3. WHEN se almacena una cédula, THEN el Sistema SHALL subir la imagen al storage de Supabase y guardar la URL en el campo cedula_url
4. WHEN se crea un usuario, THEN el Sistema SHALL establecer email_verified como false por defecto
5. WHEN el usuario verifica su email, THEN Supabase SHALL actualizar el campo email_verified a true

### Requisito 6: Persistencia de Sesión

**User Story:** Como usuario, quiero que mi sesión se mantenga activa después de iniciar sesión, para no tener que autenticarme cada vez que abro la aplicación.

#### Criterios de Aceptación

1. WHEN el usuario inicia sesión exitosamente, THEN el Sistema SHALL almacenar el token de sesión de Supabase localmente
2. WHEN el usuario abre la aplicación con una sesión activa válida, THEN el Sistema SHALL navegar directamente a la pantalla principal sin mostrar el login
3. WHEN el token de sesión expira, THEN el Sistema SHALL redirigir al usuario a la pantalla de inicio de sesión
4. WHEN el usuario cierra sesión, THEN el Sistema SHALL eliminar el token de sesión local y navegar a la pantalla de inicio de sesión

### Requisito 7: Validación de Formato de Email

**User Story:** Como sistema, necesito validar que el email ingresado tenga un formato correcto, para asegurar la calidad de los datos y la capacidad de enviar emails de verificación.

#### Criterios de Aceptación

1. WHEN el usuario ingresa un email, THEN el Sistema SHALL validar que contenga el símbolo "@" y un dominio válido
2. WHEN el formato del email es inválido, THEN el Sistema SHALL mostrar un mensaje de error indicando "Ingrese un email válido"
3. WHEN el usuario intenta registrarse o iniciar sesión con un email de formato inválido, THEN el Sistema SHALL prevenir el envío del formulario

### Requisito 8: Manejo de Errores de Conexión

**User Story:** Como usuario, quiero recibir mensajes claros cuando hay problemas de conexión, para entender qué está sucediendo y poder tomar acción.

#### Criterios de Aceptación

1. WHEN el Sistema no puede conectarse a Supabase durante el registro o login, THEN el Sistema SHALL mostrar un mensaje de error indicando "Error de conexión. Verifica tu internet e intenta nuevamente"
2. WHEN ocurre un error inesperado durante la autenticación, THEN el Sistema SHALL mostrar un mensaje genérico de error y registrar el error en logs para debugging
3. WHEN el Sistema detecta que no hay conexión a internet, THEN el Sistema SHALL mostrar un mensaje indicando "Sin conexión a internet"
