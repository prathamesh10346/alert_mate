import 'dart:io';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  final String _senderEmail;
  final String _password;

  EmailService(this._senderEmail, this._password);

  Future<bool> sendEmergencyEmail({
    required String recipientEmail,
    required String message,
    required List<String> attachmentPaths,
  }) async {
    try {
      final smtpServer = gmail(_senderEmail, _password);

      final emailMessage = Message()
        ..from = Address(_senderEmail)
        ..recipients.add(recipientEmail)
        ..subject = 'EMERGENCY: SOS Alert'
        ..text = message;

      // Add attachments
      for (final path in attachmentPaths) {
        final attachment = FileAttachment(File(path));
        emailMessage.attachments.add(attachment);
      }
      print("Sending emergency email");

      await send(emailMessage, smtpServer);
      print("Email sent successfully");
      return true;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }
}
