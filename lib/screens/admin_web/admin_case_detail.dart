import 'package:flutter/material.dart';
import 'package:sist_tickets/screens/case_detail/case_detail_content.dart';

class AdminCaseDetail extends StatelessWidget {
  final int? caseId;

  const AdminCaseDetail({
    super.key,
    this.caseId,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay caso seleccionado, mostrar placeholder
    if (caseId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Selecciona un caso para ver los detalles',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Si hay caso seleccionado, mostrar el detalle
    // Usar Key para forzar la reconstrucción cuando cambia el caso
    return CaseDetailContent(
      key: Key(caseId.toString()),
      caseId: caseId.toString(),
      // Callbacks vacíos ya que no navegamos en la versión web
      onBack: () {},
      onShowConfirmationSignature: () {},
    );
  }
}
