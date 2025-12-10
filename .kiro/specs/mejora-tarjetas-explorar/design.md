# Design Document

## Overview

This design enhances the property cards in the explore screen by adding host information with performance indicators and property star ratings. The implementation focuses on providing users with quick visual cues about property quality and host reliability while maintaining good performance through efficient database queries.

## Architecture

The solution follows the existing repository pattern architecture:

```
Presentation Layer (UI)
    ↓
Repository Layer (Data Access)
    ↓
Supabase Database
```

**Key Components:**
- `ExplorarScreen`: Main screen displaying property cards
- `PropiedadCard`: Enhanced card widget with new visual elements
- `PropiedadRepository`: Extended to fetch rating data with properties
- `ResenaRepository`: Provides rating calculation utilities

## Components and Interfaces

### 1. Enhanced Propiedad Model

The `Propiedad` model already includes `nombreAnfitrion` and `fotoAnfitrion` fields. We'll add:

```dart
class Propiedad {
  // ... existing fields ...
  final double? calificacionPromedio;  // Average rating for this property (0-5)
  final int? numeroResenas;            // Number of reviews for this property
  final double? calificacionAnfitrion; // Average rating across all host properties (0-5)
}
```

### 2. Rating Utility Functions

Create utility functions to convert ratings to display formats:

```dart
class RatingUtils {
  // Convert 0-5 rating to star count (1-5)
  static int getStarCount(double rating);
  
  // Convert 0-5 rating to performance label
  static String? getPerformanceLabel(double rating);
  
  // Convert 0-5 rating to percentage (0-100)
  static double ratingToPercentage(double rating);
}
```

### 3. Enhanced PropiedadRepository

Modify the existing `obtenerPropiedadesActivas()` method to include rating data:

```dart
class PropiedadRepository {
  Future<List<Propiedad>> obtenerPropiedadesActivas() async {
    // Extend existing query to include:
    // - Property average rating (from resenas table)
    // - Property review count (from resenas table)
    // Uses existing LEFT JOIN pattern with users_profiles
  }
}
```

Note: We'll calculate host average rating on-demand in the UI using `ResenaRepository.obtenerPromedioCalificacion()` for each unique host, or we can add it to the query if needed.

### 4. Enhanced PropiedadCard Widget

The card widget will be restructured:

```dart
class _PropiedadCard extends StatelessWidget {
  Widget build(BuildContext context) {
    return Card(
      child: Stack(
        children: [
          Column(
            children: [
              _buildImage(),
              _buildInfo(),
            ],
          ),
          _buildStarRating(), // Positioned top-right
        ],
      ),
    );
  }
  
  Widget _buildStarRating() {
    // Display stars in top-right corner with semi-transparent background
  }
  
  Widget _buildInfo() {
    return Column(
      children: [
        _buildTitle(),
        _buildHostInfo(),  // NEW: Host name + performance label
        _buildLocation(),
        _buildCapacity(),
      ],
    );
  }
  
  Widget _buildHostInfo() {
    // Display: "Anfitrión: [Name] • [Performance Label]"
  }
}
```

## Data Models

### Rating Ranges and Labels

**Star Count Mapping (based on 0-5 scale):**
- 0.0 - 1.0 → 1 star ⭐ (0% - 20%)
- 1.01 - 2.0 → 2 stars ⭐⭐ (21% - 40%)
- 2.01 - 3.0 → 3 stars ⭐⭐⭐ (41% - 60%)
- 3.01 - 4.0 → 4 stars ⭐⭐⭐⭐ (61% - 80%)
- 4.01 - 5.0 → 5 stars ⭐⭐⭐⭐⭐ (81% - 100%)

**Performance Label Mapping (based on 0-5 scale):**
- 0.0 - 1.0 → No label (0% - 20%)
- 1.01 - 2.0 → "Básico" (21% - 40%)
- 2.01 - 3.0 → "Regular" (41% - 60%)
- 3.01 - 4.0 → "Bueno" (61% - 80%)
- 4.01 - 5.0 → "Excelente" (81% - 100%)

### Database Query Structure

We'll extend the existing query in `obtenerPropiedadesActivas()` to include rating aggregations. The current query already does:

```sql
SELECT 
  p.*,
  users_profiles.nombre,
  users_profiles.foto_perfil_url
FROM propiedades p
LEFT JOIN users_profiles ON p.anfitrion_id = users_profiles.user_id
WHERE p.estado = 'activo'
```

We'll enhance it to:

```sql
SELECT 
  p.*,
  users_profiles.nombre as nombre_anfitrion,
  users_profiles.foto_perfil_url as foto_anfitrion,
  AVG(resenas.calificacion) as calificacion_promedio,
  COUNT(resenas.id) as numero_resenas
FROM propiedades p
LEFT JOIN users_profiles ON p.anfitrion_id = users_profiles.user_id
LEFT JOIN resenas ON p.id = resenas.propiedad_id
WHERE p.estado = 'activo'
GROUP BY p.id, users_profiles.nombre, users_profiles.foto_perfil_url
ORDER BY p.created_at DESC
```

For host average rating, we have two options:
1. **Simple approach**: Calculate it in UI by calling existing `ResenaRepository.obtenerPromedioCalificacion()` for each unique host (lazy loading)
2. **Optimized approach**: Add a subquery to the main query (if performance becomes an issue)

We'll start with option 1 since it reuses existing code and is simpler.

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Host name display
*For any* property card with host data, the rendered widget should contain the host name text
**Validates: Requirements 1.1**

### Property 2: Host performance calculation
*For any* host with multiple properties and reviews, the calculated average rating should equal the sum of all review ratings across all host properties divided by the total number of reviews
**Validates: Requirements 2.1**

### Property 3: Star rating display
*For any* property card with rating data, the star rating widget should be present in the widget tree
**Validates: Requirements 3.1**

### Property 4: Graceful handling of missing ratings
*For any* property without reviews (null or zero ratings), the system should render the card without throwing exceptions and without displaying rating indicators
**Validates: Requirements 4.3**

### Property 5: Rating to star count conversion
*For any* rating value between 0 and 5, the star count function should return a value between 1 and 5, and the mapping should be monotonically increasing (higher ratings produce higher or equal star counts)
**Validates: Requirements 3.2, 3.3, 3.4, 3.5, 3.6**

### Property 6: Rating to performance label conversion
*For any* rating value between 0 and 5, the performance label function should return one of the valid labels (null, "Básico", "Regular", "Bueno", "Excelente"), and the mapping should be monotonically increasing (higher ratings produce better or equal labels)
**Validates: Requirements 2.2, 2.3, 2.4, 2.5, 2.6**

## Error Handling

### Missing Data Scenarios

1. **No reviews for property**: Display card without star rating
2. **No reviews for host**: Display host name without performance label
3. **Missing host data**: Display property without host information
4. **Database query failure**: Show error message with retry option (existing behavior)

### Null Safety

All new fields in the `Propiedad` model are nullable to handle missing data gracefully. The UI components check for null before rendering rating indicators.

## Testing Strategy

### Unit Tests

Unit tests will cover:
- `RatingUtils.getStarCount()` with boundary values (0, 1, 2, 3, 4, 5)
- `RatingUtils.getPerformanceLabel()` with boundary values
- `RatingUtils.ratingToPercentage()` conversion accuracy
- Widget rendering with null rating data
- Widget rendering with valid rating data

### Property-Based Tests

Property-based tests will use the `test` package with custom generators. We'll create generators for:
- Random ratings (0.0 - 5.0)
- Random property data with varying rating scenarios
- Random host data with multiple properties

**Testing Framework**: Dart's built-in `test` package with custom property-based test helpers

**Test Configuration**: Each property test should run a minimum of 100 iterations to ensure coverage across the input space.

### Widget Tests

Widget tests will verify:
- Star rating positioned correctly in card
- Host name and performance label displayed correctly
- Card renders without errors when rating data is missing
- Text truncation works for long host names

## Performance Considerations

### Database Optimization

- Single query with joins instead of multiple queries per property
- Aggregations performed at database level
- Indexed columns: `propiedades.estado`, `propiedades.anfitrion_id`, `resenas.propiedad_id`

### UI Performance

- Star rating uses simple Text widget (⭐) instead of complex graphics
- No additional network requests per card
- Efficient widget rebuilds using const constructors where possible

## Visual Design

### Star Rating Badge
- Position: Top-right corner of property image
- Background: Semi-transparent black (Color(0x88000000))
- Padding: 8px horizontal, 4px vertical
- Border radius: 8px
- Text: White color, size 14

### Host Information
- Position: Below property title, above location
- Format: "Anfitrión: [Name] • [Label]"
- Name color: Grey[800]
- Label color: Color(0xFF4DB6AC) (app primary color)
- Font size: 13
- Icon: Person icon before text

### Spacing
- 4px between host name and performance label
- 8px vertical spacing between sections
- Maintains existing card padding (16px)
