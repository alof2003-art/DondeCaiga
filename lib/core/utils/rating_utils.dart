class RatingUtils {
  /// Convierte una calificación de 0-5 a número de estrellas (1-5)
  static int getStarCount(double rating) {
    if (rating <= 1.0) return 1;
    if (rating <= 2.0) return 2;
    if (rating <= 3.0) return 3;
    if (rating <= 4.0) return 4;
    return 5;
  }

  /// Convierte una calificación de 0-5 a etiqueta de desempeño
  /// Retorna null para calificaciones muy bajas (0-20%)
  static String? getPerformanceLabel(double rating) {
    if (rating <= 1.0) return null; // 0-20%
    if (rating <= 2.0) return 'Básico'; // 21-40%
    if (rating <= 3.0) return 'Regular'; // 41-60%
    if (rating <= 4.0) return 'Bueno'; // 61-80%
    return 'Excelente'; // 81-100%
  }

  /// Convierte una calificación de 0-5 a porcentaje (0-100)
  static double ratingToPercentage(double rating) {
    return (rating / 5.0) * 100.0;
  }

  /// Genera el string de estrellas para mostrar
  static String getStarString(double rating) {
    final starCount = getStarCount(rating);
    return '⭐' * starCount;
  }
}
