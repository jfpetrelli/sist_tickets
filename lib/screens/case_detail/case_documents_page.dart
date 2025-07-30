import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/constants.dart'; // Assuming you have your constants here
import 'package:sist_tickets/providers/adjunto_provider.dart';
import 'package:sist_tickets/models/adjunto.dart';

class CaseDocumentsPage extends StatefulWidget {
  final String caseId;

  const CaseDocumentsPage({
    super.key,
    required this.caseId,
  });

  @override
  State<CaseDocumentsPage> createState() => _CaseDocumentsPageState();
}

class _CaseDocumentsPageState extends State<CaseDocumentsPage> {
  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    // Fetch the documents when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // We use listen: false here because we are in initState.
      // The Consumer widget will handle UI updates.
      Provider.of<AdjuntoProvider>(context, listen: false)
          .fetchAdjuntos(widget.caseId);
    });
  }

  // Option 1: Pick from device files
  Future<void> _pickFromFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );

    if (result != null) {
      List<String> paths = result.paths.map((path) => path!).toList();

      await Provider.of<AdjuntoProvider>(context, listen: false)
          .uploadAdjunto(widget.caseId, paths[0]);
    } else {
      print('User canceled the file picker.');
    }
  }

  // Option 2: Pick from gallery (photos and videos)
  Future<void> _pickFromGallery() async {
    final XFile? media = await _picker.pickMedia();

    if (media != null) {
      await Provider.of<AdjuntoProvider>(context, listen: false)
          .uploadAdjunto(widget.caseId, media.path);
    } else {
      print('User canceled the gallery picker.');
    }
  }

  // Show a modal bottom sheet with options
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería (Fotos y Videos)'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('Archivos del dispositivo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickFromFiles();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper function to get an icon based on the filename
  IconData _getIconForFile(String filename) {
    if (filename.toLowerCase().endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (filename.toLowerCase().endsWith('.doc') ||
        filename.toLowerCase().endsWith('.docx')) {
      return Icons.description;
    } else if (filename.toLowerCase().endsWith('.jpg') ||
        filename.toLowerCase().endsWith('.jpeg') ||
        filename.toLowerCase().endsWith('.png')) {
      return Icons.image;
    } else {
      return Icons.insert_drive_file; // Default file icon
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjuntos'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AdjuntoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.adjuntos.isEmpty) {
            return const Center(
              child: Text(
                'No hay adjuntos para este caso.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // If we have documents, display them in a ListView
          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: provider.adjuntos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final documento = provider.adjuntos[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  leading: Icon(
                    _getIconForFile(documento.filename),
                    color: kPrimaryColor,
                    size: 40,
                  ),
                  title: Text(
                    documento.filename,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Subido el: ${DateFormat('dd/MM/yyyy HH:mm').format(documento.fecha.toLocal())}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.download_for_offline_outlined,
                        color: Colors.blueGrey),
                    onPressed: () {
                      // TODO: Implement file download/view logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Descargando ${documento.filename}...'),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAttachmentOptions();
        },
        backgroundColor: kPrimaryColor,
        tooltip: 'Adjuntar Documento',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
