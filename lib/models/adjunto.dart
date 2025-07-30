class Adjunto {
  final int idCaso;
  final int? idIntervencion;
  final int idUsuarioAutor;
  final String filename;
  final String filepath;
  final DateTime fecha;

  Adjunto({
    required this.idCaso,
    this.idIntervencion,
    required this.idUsuarioAutor,
    required this.filename,
    required this.filepath,
    DateTime? fecha,
  }) : fecha = fecha ?? DateTime.now();

  factory Adjunto.fromJson(Map<String, dynamic> json) {
    return Adjunto(
      idCaso: json['id_caso'],
      idIntervencion: json['id_intervencion'],
      idUsuarioAutor: json['id_usuario_autor'],
      filename: json['filename'],
      filepath: json['filepath'],
      fecha: DateTime.parse(json['fecha']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_caso': idCaso,
      'id_intervencion': idIntervencion,
      'id_usuario_autor': idUsuarioAutor,
      'filename': filename,
      'filepath': filepath,
      'fecha': fecha.toIso8601String(),
    };
  }
}
