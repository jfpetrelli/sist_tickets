// lib/models/ticket_visita.dart

class TicketVisita {
  final int? idVisita;
  final int idCaso;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String? descripcion;
  final int idPersonalAsignado;
  final String estadoVisita;
  final DateTime? fechaCreacion;
  final String? tituloCaso;

  /// Optional: technician name, populated client-side from UserListProvider.
  final String? tecnicoNombre;

  TicketVisita({
    this.idVisita,
    required this.idCaso,
    required this.fechaInicio,
    required this.fechaFin,
    this.descripcion,
    required this.idPersonalAsignado,
    required this.estadoVisita,
    this.fechaCreacion,
    this.tituloCaso,
    this.tecnicoNombre,
  });

  factory TicketVisita.fromJson(Map<String, dynamic> json) {
    return TicketVisita(
      idVisita: json['id_visita'] as int?,
      idCaso: json['id_caso'] as int,
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
      fechaFin: DateTime.parse(json['fecha_fin'] as String),
      descripcion: json['descripcion'] as String?,
      idPersonalAsignado: json['id_personal_asignado'] as int,
      estadoVisita: json['estado_visita'] as String? ?? 'pendiente',
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'] as String)
          : null,
      tituloCaso: json['titulo_caso'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idVisita != null) 'id_visita': idVisita,
      'id_caso': idCaso,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin.toIso8601String(),
      if (descripcion != null) 'descripcion': descripcion,
      'id_personal_asignado': idPersonalAsignado,
      'estado_visita': estadoVisita,
      if (tituloCaso != null) 'titulo_caso': tituloCaso,
    };
  }

  TicketVisita copyWith({
    int? idVisita,
    int? idCaso,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? descripcion,
    int? idPersonalAsignado,
    String? estadoVisita,
    DateTime? fechaCreacion,
    String? tituloCaso,
    String? tecnicoNombre,
  }) {
    return TicketVisita(
      idVisita: idVisita ?? this.idVisita,
      idCaso: idCaso ?? this.idCaso,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      descripcion: descripcion ?? this.descripcion,
      idPersonalAsignado: idPersonalAsignado ?? this.idPersonalAsignado,
      estadoVisita: estadoVisita ?? this.estadoVisita,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      tituloCaso: tituloCaso ?? this.tituloCaso,
      tecnicoNombre: tecnicoNombre ?? this.tecnicoNombre,
    );
  }
}
