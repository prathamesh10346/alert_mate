import 'dart:io';

import 'package:alert_mate/services/encryption_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';

class VaultScreen extends StatefulWidget {
  @override
  _VaultScreenState createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final EncryptionService _encryptionService = EncryptionService();
  List<File> _encryptedFiles = [];
  void _deleteFile(File encryptedFile) async {
    await _encryptionService.deleteFile(encryptedFile);
    _refreshFileList();
  }

  @override
  void initState() {
    super.initState();
    _initializeVault();
  }

  void _initializeVault() async {
    await _encryptionService.initializeVault();
    _refreshFileList();
  }

  void _refreshFileList() async {
    final files = await _encryptionService.listVaultFiles();
    setState(() {
      _encryptedFiles = files;
    });
  }

  void _pickAndEncryptFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File sourceFile = File(result.files.single.path!);
      await _encryptionService.encryptFile(sourceFile);
      _refreshFileList();
    }
  }

  void _decryptFile(File encryptedFile) async {
    final decryptedFile = await _encryptionService.decryptFile(encryptedFile);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilePreviewScreen(file: decryptedFile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Secure File Vault'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _pickAndEncryptFile,
          ),
        ],
      ),
      body: _encryptedFiles.isEmpty
          ? Center(child: Text('No encrypted files'))
          : ListView.builder(
              itemCount: _encryptedFiles.length,
              itemBuilder: (context, index) {
                final file = _encryptedFiles[index];
                return ListTile(
                  title: Text(file.path.split('/').last),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.lock_open),
                        onPressed: () => _decryptFile(file),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteFile(file),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class FilePreviewScreen extends StatelessWidget {
  final File file;

  FilePreviewScreen({required this.file});

  @override
  Widget build(BuildContext context) {
    final fileType = file.path.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png'].contains(fileType)) {
      return Scaffold(
        appBar: AppBar(title: Text('Image Preview')),
        body: Center(
          child: Image.file(file),
        ),
      );
    } else if (['mp4', 'mov'].contains(fileType)) {
      return VideoPlayerScreen(file: file);
    } else if (fileType == 'pdf') {
      return Scaffold(
        appBar: AppBar(title: Text('PDF Preview')),
        body: PDFView(
          filePath: file.path,
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: Text('File Preview')),
        body: Center(child: Text('Cannot preview this file type')),
      );
    }
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final File file;

  VideoPlayerScreen({required this.file});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Preview')),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : CircularProgressIndicator(),
      ),
    );
  }
}
