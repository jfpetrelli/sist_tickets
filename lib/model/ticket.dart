// model for ticket
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Ticket {
  final int? idCaso;
  final DateTime? fecha;
  final String titulo;
  final int idCliente;
  final int idPersonalCreador;
  final int idPersonalAsignado;
  final int idTipocaso;
  final int idEstado;
  final int idPrioridad;
  final DateTime? ultimaModificacion;
  final DateTime? fechaTentativaInicio;
  final DateTime? fechaTentativaFinalizacion;
  final VoidCallback onTap;

  Ticket(
      {this.idCaso,
      this.fecha,
      required this.titulo,
      required this.idCliente,
      required this.idPersonalCreador,
      required this.idPersonalAsignado,
      required this.idTipocaso,
      required this.idEstado,
      required this.idPrioridad,
      this.ultimaModificacion,
      this.fechaTentativaInicio,
      this.fechaTentativaFinalizacion,
      required this.onTap});

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      idCaso: json['id_caso'] as int?,
      fecha: json['fecha'] == null
          ? null
          : DateTime.parse(json['fecha'] as String),
      titulo: json['titulo'] as String,
      idCliente: json['id_cliente'] as int,
      idPersonalCreador: json['id_personal_creador'] as int,
      idPersonalAsignado: json['id_personal_asignado'] as int,
      idTipocaso: json['id_tipocaso'] as int,
      idEstado: json['id_estado'] as int,
      idPrioridad: json['id_prioridad'] as int,
      ultimaModificacion: json['ultima_modificacion'] == null
          ? null
          : DateTime.parse(json['ultima_modificacion'] as String),
      fechaTentativaInicio: json['fecha_tentativa_inicio'] == null
          ? null
          : DateTime.parse(json['fecha_tentativa_inicio'] as String),
      fechaTentativaFinalizacion: json['fecha_tentativa_finalizacion'] == null
          ? null
          : DateTime.parse(json['fecha_tentativa_finalizacion'] as String),
      onTap: () {
        // Define the action to be performed when the ticket is tapped
        print('');
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_caso': idCaso,
      'fecha': fecha?.toIso8601String(),
      'titulo': titulo,
      'id_cliente': idCliente,
      'id_personal_creador': idPersonalCreador,
      'id_personal_asignado': idPersonalAsignado,
      'id_tipocaso': idTipocaso,
      'id_estado': idEstado,
      'id_prioridad': idPrioridad,
      'ultima_modificacion': ultimaModificacion?.toIso8601String(),
      'fecha_tentativa_inicio': fechaTentativaInicio?.toIso8601String(),
      'fecha_tentativa_finalizacion':
          fechaTentativaFinalizacion?.toIso8601String(),
    };
  }

  static Future<List<Ticket>> getTickets() async {
    try {
      final response = await ApiService.getTickets();
      return response.map((ticket) => Ticket.fromJson(ticket)).toList();
    } catch (e) {
      print('$e');
      return [];
    }
  }

  static Future<Ticket?> getTicketById(String id) async {
    try {
      final response = await ApiService.getTicketById(id);
      return Ticket.fromJson(response);
    } catch (e) {
      print('$e');
      return null;
    }
  }
}
