class TicketIntervencion {
  final int? idCaso;
  final int? idIntervencion;
  final DateTime fechaVencimiento;
  final DateTime fecha;
  final int idTipoIntervencion;
  final String detalle;
  final int tiempoUtilizado;
  final int idContacto;

  TicketIntervencion({
    this.idCaso,
    this.idIntervencion,
    required this.fechaVencimiento,
    required this.fecha,
    required this.idTipoIntervencion,
    required this.detalle,
    required this.tiempoUtilizado,
    required this.idContacto,
  });

  // Método para crear un objeto TicketIntervencion a partir de un Map
  factory TicketIntervencion.fromJson(Map<String, dynamic> json) {
    return TicketIntervencion(
      idCaso: json['id_caso'] as int?,
      idIntervencion: json['id_intervencion'] as int?,
      fechaVencimiento: DateTime.parse(json['fecha_vencimiento']),
      fecha: DateTime.parse(json['fecha']),
      idTipoIntervencion: json['id_tipo_intervencion'] as int,
      detalle: json['detalle'] as String,
      tiempoUtilizado: json['tiempo_utilizado'] as int,
      idContacto: json['id_contacto'] as int,
    );
  }

  // Método para convertir un objeto TicketIntervencion a un Map
  Map<String, dynamic> toJson() {
    return {
      'id_caso': idCaso,
      'id_intervencion': idIntervencion,
      'fecha_vencimiento': fechaVencimiento.toIso8601String(),
      'fecha': fecha.toIso8601String(),
      'id_tipo_intervencion': idTipoIntervencion,
      'detalle': detalle,
      'tiempo_utilizado': tiempoUtilizado,
      'id_contacto': idContacto,
    };
  }
}
