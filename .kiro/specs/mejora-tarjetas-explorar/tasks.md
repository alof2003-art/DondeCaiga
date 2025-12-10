# Implementation Plan

- [ ] 1. Create rating utility functions
  - Create `lib/core/utils/rating_utils.dart` with conversion functions
  - Implement `getStarCount()` to convert 0-5 rating to 1-5 stars
  - Implement `getPerformanceLabel()` to convert rating to performance text
  - Implement `ratingToPercentage()` helper function
  - _Requirements: 2.2, 2.3, 2.4, 2.5, 2.6, 3.2, 3.3, 3.4, 3.5, 3.6_

- [ ]* 1.1 Write property test for rating conversions
  - **Property 5: Rating to star count conversion**
  - **Validates: Requirements 3.2, 3.3, 3.4, 3.5, 3.6**

- [ ]* 1.2 Write property test for performance label conversion
  - **Property 6: Rating to performance label conversion**
  - **Validates: Requirements 2.2, 2.3, 2.4, 2.5, 2.6**

- [ ]* 1.3 Write unit tests for rating utilities
  - Test boundary values for star count (0, 1, 2, 3, 4, 5)
  - Test boundary values for performance labels
  - Test percentage conversion accuracy
  - _Requirements: 2.2, 2.3, 2.4, 2.5, 2.6, 3.2, 3.3, 3.4, 3.5, 3.6_

- [ ] 2. Extend Propiedad model with rating fields
  - Add `calificacionPromedio`, `numeroResenas`, and `calificacionAnfitrion` fields to model
  - Update `fromJson()` to parse new fields
  - Handle null values for properties without reviews
  - _Requirements: 2.1, 3.1, 4.3_

- [ ] 3. Enhance PropiedadRepository with rating queries
  - Modify existing `obtenerPropiedadesActivas()` to add LEFT JOIN with `resenas` table
  - Add AVG(resenas.calificacion) as calificacion_promedio
  - Add COUNT(resenas.id) as numero_resenas
  - Add GROUP BY clause to support aggregations
  - Parse new fields in the response mapping
  - _Requirements: 2.1, 4.1, 4.2_

- [ ]* 3.1 Write property test for host performance calculation
  - **Property 2: Host performance calculation**
  - **Validates: Requirements 2.1**

- [ ] 4. Create star rating widget component
  - Create `_StarRatingBadge` widget in explorar_screen.dart
  - Position badge in top-right corner using Stack and Positioned
  - Add semi-transparent background for readability
  - Display appropriate number of star emojis based on rating
  - Handle null ratings (don't display badge)
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8_

- [ ]* 4.1 Write property test for star rating display
  - **Property 3: Star rating display**
  - **Validates: Requirements 3.1**

- [ ]* 4.2 Write widget tests for star rating badge
  - Test badge renders with valid rating
  - Test badge doesn't render with null rating
  - Test correct star count for different ratings
  - _Requirements: 3.1, 3.7_

- [ ] 5. Create host info widget component
  - Create `_HostInfoRow` widget in explorar_screen.dart
  - Display host name with person icon
  - Calculate host average using existing ResenaRepository methods (or pass it from parent)
  - Display performance label next to host name using RatingUtils
  - Apply appropriate styling and colors
  - Handle text truncation for long names
  - Handle null host data gracefully
  - _Requirements: 1.1, 1.2, 1.3, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

- [ ]* 5.1 Write property test for host name display
  - **Property 1: Host name display**
  - **Validates: Requirements 1.1**

- [ ]* 5.2 Write widget tests for host info row
  - Test host name renders correctly
  - Test performance label displays for different ratings
  - Test no label displays for low ratings or no reviews
  - Test text truncation for long names
  - _Requirements: 1.1, 1.3, 2.7_

- [ ] 6. Integrate new components into PropiedadCard
  - Wrap card content in Stack to allow star rating overlay
  - Add star rating badge positioned over image
  - Add host info row below property title
  - Adjust spacing to accommodate new elements
  - Ensure responsive layout on different screen sizes
  - _Requirements: 1.1, 3.1, 3.8_

- [ ]* 6.1 Write property test for graceful error handling
  - **Property 4: Graceful handling of missing ratings**
  - **Validates: Requirements 4.3**

- [ ]* 6.2 Write widget tests for complete card
  - Test card renders with all rating data
  - Test card renders without rating data
  - Test card renders with partial data (property rating but no host rating)
  - _Requirements: 4.3_

- [ ] 7. Update ExplorarScreen to use enhanced repository method
  - Call `obtenerPropiedadesActivas()` which now includes rating data
  - Pass rating data to PropiedadCard widgets
  - Ensure error handling still works correctly
  - _Requirements: 4.1, 4.3_

- [ ] 8. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Manual testing and visual verification
  - Test with properties that have reviews
  - Test with properties without reviews
  - Test with hosts that have multiple properties
  - Test with hosts that have no reviews
  - Verify star rating positioning on different screen sizes
  - Verify text truncation works correctly
  - Verify performance labels display correctly
  - _Requirements: All_
