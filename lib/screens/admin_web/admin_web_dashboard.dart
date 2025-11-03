import 'package:flutter/material.dart';
import 'package:sist_tickets/screens/admin_web/admin_case_list.dart';
import 'package:sist_tickets/screens/admin_web/admin_case_detail.dart';

class AdminWebDashboard extends StatefulWidget {
  const AdminWebDashboard({super.key});

  @override
  State<AdminWebDashboard> createState() => _AdminWebDashboardState();
}

class _AdminWebDashboardState extends State<AdminWebDashboard> {
  int? _selectedCaseId;

  void _onCaseSelected(int caseId) {
    setState(() {
      _selectedCaseId = caseId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        centerTitle: true,
      ),
      body: Row(
        children: [
          // Master panel (lista de casos)
          Expanded(
            flex: 1,
            child: AdminCaseList(
              onCaseSelected: _onCaseSelected,
              selectedCaseId: _selectedCaseId,
            ),
          ),
          // Divider vertical
          const VerticalDivider(width: 1, thickness: 1),
          // Detail panel (detalle del caso seleccionado)
          Expanded(
            flex: 2,
            child: AdminCaseDetail(
              caseId: _selectedCaseId,
            ),
          ),
        ],
      ),
    );
  }
}
