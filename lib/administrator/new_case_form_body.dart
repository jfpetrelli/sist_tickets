
import 'package:flutter/material.dart';
import 'package:sist_tickets/constants.dart';


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
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _clientController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedType;
  String? _selectedPriority;
  final _descriptionController = TextEditingController();

  final List<String> _types = ['Instalación', 'Reparación', 'Mantenimiento'];
  final List<String> _priorities = ['Alta', 'Media', 'Baja'];
  
  

  @override
  void initState() {
    super.initState();
    
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
  }

  Widget _buildInputWithLabel(String label, Widget child) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: child,
        ),
        Positioned(
          left: 12,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            color: Colors.white,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(Icons.search, size: 20, color: Colors.grey[600]),
          ),
          Expanded(
            child: TextFormField(
              controller: _clientController,
              decoration: const InputDecoration(
                hintText: 'Input',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextFormField(
        controller: _titleController,
        decoration: const InputDecoration(
          hintText: 'Input',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildDateTimeField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final DateTime? date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: kPrimaryColor,
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
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
                  if (date != null) {
                    final TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: kPrimaryColor,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
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
                    if (time != null) {
                      setState(() {
                        _selectedDate = date;
                        _selectedTime = time;
                      });
                    }
                  }
                },
                child: const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianField() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Icon(
        Icons.person_outline,
        size: 20,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTypeField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            value: _selectedType,
            hint: const Text(
              'Instalación',
              style: TextStyle(fontSize: 14),
            ),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            items: _types.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedType = newValue;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            value: _selectedPriority,
            hint: const Text(
              'Baja',
              style: TextStyle(fontSize: 14),
            ),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            items: _priorities.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedPriority = newValue;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque ut ultrices metus.',
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputWithLabel('Cliente', _buildSearchField()),
          const SizedBox(height: 16),
          
          _buildInputWithLabel('Título', _buildTitleField()),
          const SizedBox(height: 16),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInputWithLabel('Fecha y Hora', _buildDateTimeField()),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      'Técnico',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTechnicianField(),
                      const SizedBox(width: 8),
                      Text(
                        'Juan Ortega',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildInputWithLabel('Tipo', _buildTypeField()),
          const SizedBox(height: 16),

          _buildInputWithLabel('Prioridad', _buildPriorityField()),
          const SizedBox(height: 16),

          _buildInputWithLabel('Descripción', _buildDescriptionField()),
          const SizedBox(height: 16),

          const Text(
            'Ningún documento agregado',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onAddDocuments,
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

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onCompleteCase();
                }
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

  @override
  void dispose() {
    _titleController.dispose();
    _clientController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}