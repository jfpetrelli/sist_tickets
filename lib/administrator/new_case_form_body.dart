// lib/administrator/new_case_form_body.dart
import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFFE74C3C); // E74C3C

class NewCaseFormBody extends StatefulWidget {
  final VoidCallback onAddDocuments;
  final VoidCallback onCompleteCase;

  const NewCaseFormBody({
    super.key,
    required this.onAddDocuments,
    required this.onCompleteCase,
  });

  @override
  State<NewCaseFormBody> createState() => _NewCaseFormBodyState();
}

class _NewCaseFormBodyState extends State<NewCaseFormBody> {
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedType;
  String? _selectedPriority;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<String> _types = ['Instalación', 'Reparación', 'Mantenimiento', 'Soporte'];
  final List<String> _priorities = ['Baja', 'Media', 'Alta', 'Urgente'];

  // Modificado: Ahora el método _selectDate devuelve DateTime?
  Future<DateTime?> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kPrimaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
    return picked; // Retornamos la fecha seleccionada (o null si se canceló)
  }

  // Modificado: Ahora el método _selectTime devuelve TimeOfDay?
  Future<TimeOfDay?> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kPrimaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
    return picked; // Retornamos la hora seleccionada (o null si se canceló)
  }

  String get _formattedDateTime {
    final String month = _selectedDate.month.toString().padLeft(2, '0');
    final String day = _selectedDate.day.toString().padLeft(2, '0');
    final String year = _selectedDate.year.toString();
    final String hour = _selectedTime.hour.toString().padLeft(2, '0');
    final String minute = _selectedTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute hs';
  }

  @override
  void dispose() {
    _clientController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nuevo Caso',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('Cliente'),
          _buildTextField(_clientController, 'Input', Icons.person_outline),
          const SizedBox(height: 16),

          _buildSectionHeader('Título'),
          _buildTextField(_titleController, 'Input', Icons.title),
          const SizedBox(height: 16),

          _buildSectionHeader('Fecha y Hora'),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    // CAMBIO CLAVE AQUÍ: Lógica para manejar la cancelación del DatePicker
                    onTap: () async {
                      final DateTime? pickedDate = await _selectDate(context);
                      // Solo si se seleccionó una fecha, entonces se procede a la hora
                      if (pickedDate != null) {
                        await _selectTime(context);
                      }
                    },
                    child: Text(
                      _formattedDateTime,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.person_pin, color: Colors.white, size: 24),
                    Text('Tecnico', style: TextStyle(color: Colors.white, fontSize: 10)),
                    Text('Juan Ortega', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('Tipo'),
          _buildDropdownField(_types, 'Seleccione el tipo', (String? newValue) {
            setState(() {
              _selectedType = newValue;
            });
          }, _selectedType),
          const SizedBox(height: 16),

          _buildSectionHeader('Prioridad'),
          _buildDropdownField(_priorities, 'Seleccione la prioridad', (String? newValue) {
            setState(() {
              _selectedPriority = newValue;
            });
          }, _selectedPriority),
          const SizedBox(height: 16),

          _buildSectionHeader('Descripción'),
          _buildTextField(_descriptionController, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque ut ultrices metus.', Icons.description, maxLines: 5),
          const SizedBox(height: 16),

          // Sección de Documentos
          const Text(
            'Ningún documento agregado',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                widget.onAddDocuments();
              },
              icon: const Icon(Icons.add, color: kPrimaryColor),
              label: const Text(
                'Documento',
                style: TextStyle(color: kPrimaryColor),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kPrimaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Botón Completar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onCompleteCase();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
              child: const Text(
                'Completar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- Widgets Auxiliares ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
      ),
    );
  }

  Widget _buildDropdownField(List<String> items, String hint, Function(String?) onChanged, String? value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint, style: TextStyle(color: Colors.grey[400])),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
        items: items.map<DropdownMenuItem<String>>((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}