class TipoCaso {
  final int id;
  final String nombre;
  final int color;

  TipoCaso({
    required this.id,
    required this.nombre,
    required this.color, // Color azul por defecto
  });

  factory TipoCaso.fromJson(Map<String, dynamic> json) {
    return TipoCaso(
      id: json['ID_TipoCaso'],
      nombre: json['nombre'],
      color: json['color'],
    );
  }
}
