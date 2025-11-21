import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/constants.dart'; // Assuming you have your constants here
import 'package:sist_tickets/providers/adjunto_provider.dart';

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

  Future<void> _openCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      // Leer los bytes del archivo
      final bytes = await photo.readAsBytes();
      final fileName = photo.name;

      await Provider.of<AdjuntoProvider>(context, listen: false)
          .uploadAdjuntoFromBytes(widget.caseId, fileName, bytes);
    } else {
      print('User canceled the camera.');
    }
  }

  // Option 1: Pick files (documents, etc.) - Compatible con Web y Mobile
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      if (file.bytes != null) {
        // Web: usar bytes directamente
        await Provider.of<AdjuntoProvider>(context, listen: false)
            .uploadAdjuntoFromBytes(widget.caseId, file.name, file.bytes!);
      } else if (file.path != null) {
        // Mobile: leer archivo desde path
        await _uploadFromPath(file.path!, file.name);
      } else {
        print('Error: No se pudo obtener el archivo seleccionado.');
      }
    } else {
      print('User canceled the file picker.');
    }
  }

  // Option 2: Pick from gallery (photos and videos) - Compatible con Web y Mobile
  Future<void> _pickFromGallery() async {
    final XFile? media = await _picker.pickImage(source: ImageSource.gallery);

    if (media != null) {
      // Leer los bytes del archivo
      final bytes = await media.readAsBytes();
      final fileName = media.name;

      await Provider.of<AdjuntoProvider>(context, listen: false)
          .uploadAdjuntoFromBytes(widget.caseId, fileName, bytes);
    } else {
      print('User canceled the gallery picker.');
    }
  }

  // Método auxiliar para mobile - leer archivo desde path
  Future<void> _uploadFromPath(String path, String fileName) async {
    try {
      // En mobile, podemos leer el archivo desde el path
      final XFile file = XFile(path);
      final bytes = await file.readAsBytes();

      await Provider.of<AdjuntoProvider>(context, listen: false)
          .uploadAdjuntoFromBytes(widget.caseId, fileName, bytes);
    } catch (e) {
      print('Error al leer archivo desde path: $e');
      throw Exception('No se pudo leer el archivo seleccionado.');
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
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('Archivos del dispositivo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickFile();
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
              final downloadProgress =
                  provider.downloadProgress[documento.idCaso];
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
                  trailing: downloadProgress != null
                      ? CircularProgressIndicator(
                          value: downloadProgress,
                        )
                      : IconButton(
                          icon: const Icon(Icons.download_for_offline_outlined,
                              color: Colors.blueGrey),
                          onPressed: () async {
                            try {
                              final path =
                                  await provider.downloadAdjunto(documento);
                              if (path != null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Descargado en: $path'),
                                    backgroundColor: kSuccessColor,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al descargar: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_add_document',
        onPressed: () {
          _showAttachmentOptions();
        },
        backgroundColor: kPrimaryColor,
        shape: const CircleBorder(),
        tooltip: 'Adjuntar Documento',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
