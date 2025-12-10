# Requirements Document

## Introduction

Esta especificación define las mejoras visuales para las tarjetas de propiedades en la pantalla de explorar. El objetivo es proporcionar más información relevante al usuario mostrando el nombre del anfitrión con un indicador de desempeño basado en las calificaciones promedio de sus propiedades, y mostrar la calificación en estrellas de cada propiedad en la esquina superior derecha de la tarjeta.

## Glossary

- **Sistema**: La aplicación móvil "Donde Caiga v2"
- **Tarjeta de Propiedad**: Componente visual que muestra información resumida de un alojamiento en la pantalla de explorar
- **Anfitrión**: Usuario que publica propiedades en la plataforma
- **Indicador de Desempeño**: Etiqueta textual que describe la calidad del servicio del anfitrión basada en el promedio de calificaciones
- **Calificación en Estrellas**: Representación visual del promedio de reseñas de una propiedad usando el símbolo ⭐
- **Promedio de Calificación**: Valor numérico calculado a partir de todas las reseñas de una propiedad o anfitrión

## Requirements

### Requirement 1

**User Story:** Como usuario explorando alojamientos, quiero ver el nombre del anfitrión debajo del título de la propiedad, para saber quién ofrece el alojamiento.

#### Acceptance Criteria

1. WHEN the Sistema displays a property card THEN the Sistema SHALL show the host name below the property title
2. WHEN the host name is displayed THEN the Sistema SHALL use a distinct visual style to differentiate it from the property title
3. WHEN the host name exceeds the available space THEN the Sistema SHALL truncate the text with ellipsis

### Requirement 2

**User Story:** Como usuario explorando alojamientos, quiero ver un indicador de desempeño junto al nombre del anfitrión, para evaluar rápidamente la calidad del servicio que ofrece.

#### Acceptance Criteria

1. WHEN the Sistema calculates the host performance indicator THEN the Sistema SHALL compute the average rating across all properties owned by that host
2. WHEN the average rating is between 0% and 20% THEN the Sistema SHALL display no performance label
3. WHEN the average rating is between 21% and 40% THEN the Sistema SHALL display the label "Básico"
4. WHEN the average rating is between 41% and 60% THEN the Sistema SHALL display the label "Regular"
5. WHEN the average rating is between 61% and 80% THEN the Sistema SHALL display the label "Bueno"
6. WHEN the average rating is between 81% and 100% THEN the Sistema SHALL display the label "Excelente"
7. WHEN the host has no reviews THEN the Sistema SHALL display no performance label

### Requirement 3

**User Story:** Como usuario explorando alojamientos, quiero ver la calificación en estrellas de cada propiedad en la esquina superior derecha de la tarjeta, para identificar rápidamente las propiedades mejor valoradas.

#### Acceptance Criteria

1. WHEN the Sistema displays a property card THEN the Sistema SHALL show the star rating in the top-right corner of the card
2. WHEN the property has an average rating between 0% and 20% THEN the Sistema SHALL display one star (⭐)
3. WHEN the property has an average rating between 21% and 40% THEN the Sistema SHALL display two stars (⭐⭐)
4. WHEN the property has an average rating between 41% and 60% THEN the Sistema SHALL display three stars (⭐⭐⭐)
5. WHEN the property has an average rating between 61% and 80% THEN the Sistema SHALL display four stars (⭐⭐⭐⭐)
6. WHEN the property has an average rating between 81% and 100% THEN the Sistema SHALL display five stars (⭐⭐⭐⭐⭐)
7. WHEN the property has no reviews THEN the Sistema SHALL display no star rating
8. WHEN the star rating is displayed THEN the Sistema SHALL position it over the property image with a semi-transparent background for readability

### Requirement 4

**User Story:** Como desarrollador, quiero que el sistema calcule eficientemente los promedios de calificación, para mantener un buen rendimiento en la aplicación.

#### Acceptance Criteria

1. WHEN the Sistema loads properties for the explore screen THEN the Sistema SHALL fetch rating averages in a single database query using joins
2. WHEN the Sistema calculates host performance THEN the Sistema SHALL aggregate ratings from all host properties efficiently
3. WHEN rating data is unavailable THEN the Sistema SHALL handle the absence gracefully without errors
