// lib/administrator/new_case_content.dart
import 'package:flutter/material.dart';
import 'package:sist_tickets/administrator/new_case_form_body.dart';
import 'package:sist_tickets/administrator/add_documents_content.dart';
import 'package:sist_tickets/administrator/case_registered_content.dart';

const Color kPrimaryColor = Color(0xFFE74C3C);

enum NewCaseFlowStep {
  form,
  addDocuments,
  registered,
}

class NewCaseContent extends StatefulWidget {
  final ValueChanged<int> onTabSelected;

  const NewCaseContent({super.key, required this.onTabSelected});

  @override
  State<NewCaseContent> createState() => _NewCaseContentState();
}

class _NewCaseContentState extends State<NewCaseContent> {
  NewCaseFlowStep _currentStep = NewCaseFlowStep.form;

  void _goToAddDocuments() {
    setState(() {
      _currentStep = NewCaseFlowStep.addDocuments;
    });
  }

  void _goToCaseRegistered() {
    setState(() {
      _currentStep = NewCaseFlowStep.registered;
    });
  }

  void _goToForm() {
    setState(() {
      _currentStep = NewCaseFlowStep.form;
    });
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case NewCaseFlowStep.form:
        return NewCaseFormBody(
          onAddDocuments: _goToAddDocuments,
          // Cuando se completa el formulario principal, va a "registered"
          onCompleteCase: _goToCaseRegistered,
        );
      case NewCaseFlowStep.addDocuments:
        return AddDocumentsContent(
          onBack: _goToForm,
          // <--- ¡CAMBIO CLAVE AQUÍ!
          // Cuando se confirma en añadir documentos, vuelve al formulario principal.
          onConfirm: _goToForm,
        );
      case NewCaseFlowStep.registered:
        return CaseRegisteredContent(
          onGoBackToForm: _goToForm,
          onGoToCasesTab: () => widget.onTabSelected(1), // Cambia a la pestaña de "Casos" (índice 1)
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildCurrentStepContent();
  }
}