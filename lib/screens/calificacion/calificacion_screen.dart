import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/api/api_service.dart';
import 'package:sist_tickets/constants.dart';

class CalificacionScreen extends StatefulWidget {
  final String token;

  const CalificacionScreen({
    super.key,
    required this.token,
  });

  @override
  State<CalificacionScreen> createState() => _CalificacionScreenState();
}

class _CalificacionScreenState extends State<CalificacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _comentarioController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  bool _hasError = false;
  String? _errorMessage;

  Map<String, dynamic>? _ticketData;
  int _selectedStars = 0;

  @override
  void initState() {
    super.initState();
    _loadCalificacion();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _loadCalificacion() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final data = await apiService.getCalificacion(widget.token);

      setState(() {
        _ticketData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        if (e.toString().contains('invalid_or_used')) {
          _errorMessage =
              'Este enlace de calificación es inválido o ya fue utilizado.';
        } else {
          _errorMessage =
              'Error al cargar la calificación. Por favor, intente nuevamente.';
        }
      });
    }
  }

  Future<void> _submitCalificacion() async {
    if (_selectedStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, seleccione una calificación'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiService = context.read<ApiService>();
      await apiService.submitCalificacion(
        widget.token,
        _selectedStars,
        _comentarioController.text.isEmpty ? null : _comentarioController.text,
      );

      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar la calificación: ${e.toString()}'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        return IconButton(
          iconSize: 48,
          icon: Icon(
            starNumber <= _selectedStars ? Icons.star : Icons.star_border,
            color: starNumber <= _selectedStars ? Colors.amber : Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _selectedStars = starNumber;
            });
          },
        );
      }),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.rate_review,
              size: 80,
              color: kPrimaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Califica nuestro servicio',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_ticketData != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ticket #${_ticketData!['id_caso'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _ticketData!['titulo'] ?? 'Sin título',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (_ticketData!['descripcion'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _ticketData!['descripcion'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
            const Text(
              '¿Cómo calificarías nuestro servicio?',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildStarRating(),
            if (_selectedStars > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _getStarLabel(_selectedStars),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _comentarioController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Comentarios (opcional)',
                hintText: 'Cuéntanos más sobre tu experiencia...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLength: 500,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCalificacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Enviar Calificación',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 100,
              color: kSuccessColor,
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Muchas gracias por su calificación!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Su opinión nos ayuda a mejorar nuestro servicio.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 100,
              color: kErrorColor,
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage ?? 'Ha ocurrido un error',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_errorMessage?.contains('inválido') == false)
              ElevatedButton(
                onPressed: _loadCalificacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
          ],
        ),
      ),
    );
  }

  String _getStarLabel(int stars) {
    switch (stars) {
      case 1:
        return 'Muy insatisfecho';
      case 2:
        return 'Insatisfecho';
      case 3:
        return 'Neutral';
      case 4:
        return 'Satisfecho';
      case 5:
        return 'Muy satisfecho';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificación de Servicio'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorMessage()
              : _isSubmitted
                  ? _buildSuccessMessage()
                  : _buildForm(),
    );
  }
}
