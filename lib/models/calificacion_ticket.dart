class CalificacionTicket {
  final int idCalificacion;
  final int idCaso;
  final int? puntuacion;
  final String? comentarioCliente;
  final DateTime? fechaCalificacion;

  CalificacionTicket({
    required this.idCalificacion,
    required this.idCaso,
    this.puntuacion,
    this.comentarioCliente,
    this.fechaCalificacion,
  });

  // Método para crear un objeto CalificacionTicket a partir de un Map
  factory CalificacionTicket.fromJson(Map<String, dynamic> json) {
    return CalificacionTicket(
      idCalificacion: json['id_calificacion'] as int,
      idCaso: json['id_caso'] as int,
      puntuacion: json['puntuacion'] as int?,
      comentarioCliente: json['comentario_cliente'] as String?,
      fechaCalificacion: json['fecha_calificacion'] != null
          ? DateTime.parse(json['fecha_calificacion'])
          : null,
    );
  }

  // Método para convertir un objetoCalificacionTicket a un Map
  Map<String, dynamic> toJson() {
    return {
      'id_calificacion': idCalificacion,
      'id_caso': idCaso,  
      'puntuacion': puntuacion,
      'comentario_cliente': comentarioCliente,
      'fecha_calificacion':
          fechaCalificacion?.toIso8601String(),
    };
  }
} 