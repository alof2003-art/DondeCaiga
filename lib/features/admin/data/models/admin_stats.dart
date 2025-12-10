class AdminStats {
  final int totalUsuarios;
  final int totalViajeros;
  final int totalAnfitriones;
  final int totalAdministradores;
  final int totalAlojamientos;

  AdminStats({
    required this.totalUsuarios,
    required this.totalViajeros,
    required this.totalAnfitriones,
    required this.totalAdministradores,
    required this.totalAlojamientos,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsuarios: json['total_usuarios'] as int? ?? 0,
      totalViajeros: json['total_viajeros'] as int? ?? 0,
      totalAnfitriones: json['total_anfitriones'] as int? ?? 0,
      totalAdministradores: json['total_administradores'] as int? ?? 0,
      totalAlojamientos: json['total_alojamientos'] as int? ?? 0,
    );
  }
}
