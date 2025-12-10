# Requirements Document

## Introduction

Este documento especifica los requisitos para corregir el sistema de visualización de reservas en la aplicación "Donde Caiga". Actualmente, las reservas creadas no se visualizan correctamente debido a filtros incorrectos en las consultas de base de datos, y falta funcionalidad para que los viajeros vean sus propias reservas.

## Glossary

- **Sistema**: La aplicación móvil "Donde Caiga"
- **Viajero**: Usuario que busca y reserva alojamientos
- **Anfitrión**: Usuario que ofrece alojamientos
- **Reserva**: Solicitud de alojamiento para fechas específicas
- **Estado de Reserva**: Clasificación del estado actual de una reserva (pendiente, confirmada, rechazada, completada, cancelada)
- **Repository**: Capa de acceso a datos que maneja las consultas a Supabase

## Requirements

### Requirement 1

**User Story:** Como anfitrión, quiero ver todas mis reservas independientemente de su estado, para poder gestionar tanto las pendientes como las confirmadas.

#### Acceptance Criteria

1. WHEN un anfitrión accede a la pantalla de reservas THEN el sistema SHALL mostrar todas las reservas de sus propiedades sin filtrar por estado
2. WHEN el sistema consulta reservas de anfitrión THEN el sistema SHALL incluir reservas con estados: pendiente, confirmada, rechazada, completada y cancelada
3. WHEN un anfitrión selecciona un filtro de estado THEN el sistema SHALL aplicar el filtro solo en la interfaz de usuario, no en la consulta inicial
4. WHEN se crea una nueva reserva THEN el sistema SHALL mostrar inmediatamente la reserva en la lista del anfitrión

### Requirement 2

**User Story:** Como viajero, quiero ver todas mis reservas realizadas, para poder hacer seguimiento de mis solicitudes de alojamiento.

#### Acceptance Criteria

1. WHEN un viajero accede a su lista de reservas THEN el sistema SHALL mostrar todas sus reservas sin filtrar por estado
2. WHEN el sistema consulta reservas de viajero THEN el sistema SHALL incluir reservas con estados: pendiente, confirmada, rechazada, completada y cancelada
3. WHEN un viajero crea una nueva reserva THEN el sistema SHALL mostrar inmediatamente la reserva en su lista
4. WHEN un viajero visualiza una reserva THEN el sistema SHALL mostrar el título de la propiedad, fechas, estado y datos del anfitrión

### Requirement 3

**User Story:** Como usuario del sistema, quiero que las consultas de base de datos sean eficientes, para que la aplicación responda rápidamente.

#### Acceptance Criteria

1. WHEN el sistema consulta reservas THEN el sistema SHALL usar joins para obtener datos relacionados en una sola consulta
2. WHEN el sistema ordena reservas THEN el sistema SHALL ordenar por fecha de creación descendente
3. WHEN el sistema maneja errores de consulta THEN el sistema SHALL retornar listas vacías en lugar de fallar
4. WHEN el sistema realiza consultas THEN el sistema SHALL usar índices existentes en la base de datos

### Requirement 4

**User Story:** Como desarrollador, quiero que el código sea consistente y mantenible, para facilitar futuras modificaciones.

#### Acceptance Criteria

1. WHEN se implementan métodos de consulta THEN el sistema SHALL usar nombres descriptivos y consistentes
2. WHEN se manejan datos relacionados THEN el sistema SHALL mapear correctamente los datos anidados de Supabase
3. WHEN se crean pantallas de visualización THEN el sistema SHALL reutilizar componentes comunes
4. WHEN se filtran datos THEN el sistema SHALL aplicar filtros en la capa de presentación, no en la capa de datos
