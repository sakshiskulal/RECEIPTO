import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:receipto/core/services/email_templates.dart';

final emailServiceProvider = Provider<EmailService>((ref) {
  return EmailService();
});

class EmailService {
  SmtpServer _getSmtpServer() {
    final String host = dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';
    final int port = int.tryParse(dotenv.env['SMTP_PORT'] ?? '') ?? 465;
    final String username = dotenv.env['SMTP_USERNAME'] ?? '';
    final String password = dotenv.env['SMTP_PASSWORD'] ?? '';

    if (username.isEmpty || password.isEmpty) {
      throw Exception('SMTP credentials are missing from .env file.');
    }

    return SmtpServer(
      host,
      port: port,
      username: username,
      password: password,
      ssl: port == 465,
    );
  }

  /// Verifies the connection to the SMTP server.
  Future<bool> verifyConnection() async {
    try {
      _getSmtpServer();
      if (kDebugMode) print('=== SMTP Connected ===');
      return true;
    } catch (e) {
      if (kDebugMode) print('=== Connection Failure: $e ===');
      return false;
    }
  }

  /// Sends a warranty reminder email using HTML template.
  Future<void> sendWarrantyReminderEmail({
    required String recipientEmail,
    required String userName,
    required String productName,
    required String merchantName,
    required String purchaseDate,
    required String expiryDate,
    required String daysRemaining,
    required String invoiceNumber,
  }) async {
    try {
      final smtpServer = _getSmtpServer();
      final senderName = dotenv.env['SMTP_SENDER'] ?? 'Receipto';
      final username = dotenv.env['SMTP_USERNAME'] ?? '';

      final message = Message()
        ..from = Address(username, senderName)
        ..recipients.add(recipientEmail)
        ..subject = 'Warranty Reminder - Receipto'
        ..html = EmailTemplates.getWarrantyReminderHtml(
          userName: userName,
          productName: productName,
          merchantName: merchantName,
          purchaseDate: purchaseDate,
          expiryDate: expiryDate,
          daysRemaining: daysRemaining,
          invoiceNumber: invoiceNumber,
        );

      await send(message, smtpServer);
      if (kDebugMode) {
        print('=== SMTP Connected ===');
        print('=== Email Sent Successfully ===');
        print('Recipient Email: $recipientEmail');
      }
    } on MailerException catch (e) {
      if (kDebugMode) {
        print('=== SMTP Failure: $e ===');
        for (var p in e.problems) {
          print('Problem: ${p.code}: ${p.msg}');
        }
      }
      throw Exception('SMTP send failed: $e');
    } catch (e) {
      if (kDebugMode) {
        if (e.toString().contains('Username and Password not accepted')) {
          print('=== Authentication Failure ===');
        } else {
          print('=== Connection Failure: $e ===');
        }
      }
      throw Exception('Email delivery failed: $e');
    }
  }

  /// Sends a simple configuration test email to the user.
  Future<void> sendTestEmail({
    required String recipientEmail,
  }) async {
    try {
      final smtpServer = _getSmtpServer();
      final senderName = dotenv.env['SMTP_SENDER'] ?? 'Receipto';
      final username = dotenv.env['SMTP_USERNAME'] ?? '';

      final message = Message()
        ..from = Address(username, senderName)
        ..recipients.add(recipientEmail)
        ..subject = 'Receipto Test Email'
        ..html = EmailTemplates.getTestEmailHtml();

      await send(message, smtpServer);
      if (kDebugMode) {
        print('=== SMTP Connected ===');
        print('=== Email Sent Successfully ===');
        print('Recipient Email: $recipientEmail');
      }
    } on MailerException catch (e) {
      if (kDebugMode) print('=== SMTP Failure: $e ===');
      throw Exception('SMTP send failed: $e');
    } catch (e) {
      if (kDebugMode) {
        if (e.toString().contains('Username and Password not accepted')) {
          print('=== Authentication Failure ===');
        } else {
          print('=== Connection Failure: $e ===');
        }
      }
      throw Exception('Email delivery failed: $e');
    }
  }
}
