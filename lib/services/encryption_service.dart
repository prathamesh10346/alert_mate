import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:image/image.dart' as img;

class EncryptionService {
  static final key = encrypt.Key.fromSecureRandom(32); // 32 bytes = 256 bits

  static final iv = encrypt.IV.fromLength(16);

  Future<String> get _localVaultPath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/secure_vault';
  }

  Future<void> deleteFile(File encryptedFile) async {
    // Check if the file exists before attempting to delete
    if (await encryptedFile.exists()) {
      await encryptedFile.delete();
    }
  }

  Future<void> initializeVault() async {
    final vaultPath = await _localVaultPath;
    await Directory(vaultPath).create(recursive: true);
  }

  Future<void> encryptFile(File sourceFile) async {
    final vaultPath = await _localVaultPath;
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final fileBytes = await sourceFile.readAsBytes();
    final encryptedBytes = encrypter.encryptBytes(fileBytes, iv: iv);

    final fileName = sourceFile.path.split('/').last;
    final encryptedFile = File('$vaultPath/${fileName}.encrypted');
    await encryptedFile.writeAsBytes(encryptedBytes.bytes);

    // Hide the original file from the gallery
    await File(sourceFile.path).delete();
  }

  Future<File> decryptFile(File encryptedFile) async {
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final fileBytes = await encryptedFile.readAsBytes();

    final decryptedBytes =
        encrypter.decryptBytes(encrypt.Encrypted(fileBytes), iv: iv);

    final fileName =
        encryptedFile.path.split('/').last.replaceAll('.encrypted', '');
    final decryptedFile = File(encryptedFile.path.replaceAll('.encrypted', ''));
    await decryptedFile.writeAsBytes(decryptedBytes);

    return decryptedFile;
  }

  Future<List<File>> listVaultFiles() async {
    final vaultPath = await _localVaultPath;
    return Directory(vaultPath)
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.encrypted'))
        .toList();
  }
}
