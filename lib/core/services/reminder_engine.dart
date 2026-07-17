import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:receipto/core/services/notification_service.dart';
import 'package:receipto/core/services/email_service.dart';
import 'package:receipto/core/services/warranty_database_service.dart';
import 'package:receipto/core/services/notification_database_service.dart';
import 'package:receipto/features/notifications/domain/models/notification_model.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:receipto/core/utils/warranty_utils.dart';

final reminderEngineProvider = Provider<ReminderEngine>((ref) {
  final dbService = ref.watch(warrantyDatabaseServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final emailService = ref.watch(emailServiceProvider);
  final notiDbService = ref.watch(notificationDatabaseServiceProvider);
  return ReminderEngine(dbService, notificationService, emailService, notiDbService);
});

class ReminderEngine {
  final WarrantyDatabaseService _dbService;
  final NotificationService _notificationService;
  final EmailService _emailService;
  final NotificationDatabaseService _notiDbService;

  ReminderEngine(this._dbService, this._notificationService, this._emailService, this._notiDbService);

  /// Performs warranty alerts scanning for a user.
  Future<void> checkWarrantyReminders(String userId, String? email, String? displayName) async {
    if (kDebugMode) print('=== Checking warranties... ===');
    try {
      final client = Supabase.instance.client;
      // Fetch active receipts
      final activeResponse = await client
          .from('receipts')
          .select('id')
          .eq('user_id', userId)
          .or('is_deleted.is.null,is_deleted.eq.false');
      final activeReceiptIds = (activeResponse as List).map((r) => r['id'].toString()).toSet();

      final allWarranties = await _dbService.fetchAllWarranties(userId);
      final warranties = allWarranties.where((w) => activeReceiptIds.contains(w.receiptId)).toList();

      if (kDebugMode) print('=== Found ${warranties.length} active warranties ===');

      final recipientEmail = email ?? '';
      final userName = displayName ?? 'User';

      for (final w in warranties) {
        await processWarranty(w, recipientEmail, userName);
      }
    } catch (e) {
      if (kDebugMode) print('Error checking warranty reminders: $e');
    }
  }

  /// Evaluates dates, updates flags, and triggers reminders for a single warranty entry.
  Future<void> processWarranty(WarrantyModel w, String recipientEmail, String userName) async {
    // Ignore warranties whose status is EXPIRED unless the expired reminder has not yet been sent.
    final isExpired = w.status == 'EXPIRED';
    if (isExpired && w.notificationExpiredSent && w.emailExpiredSent) {
      return;
    }

    final daysRemaining = WarrantyUtils.calculateDaysRemaining(w.expiryDate);
    if (kDebugMode) {
      print('=== Warranty: ${w.productName} ===');
      print('=== Days Remaining: $daysRemaining ===');
    }

    bool sendNotificationFlag = false;
    bool sendEmailFlag = false;

    // Check local notification triggers
    if (daysRemaining == 30 && !w.notification30Sent) {
      sendNotificationFlag = true;
    } else if (daysRemaining == 15 && !w.notification15Sent) {
      sendNotificationFlag = true;
    } else if (daysRemaining == 7 && !w.notification7Sent) {
      sendNotificationFlag = true;
    } else if (daysRemaining == 3 && !w.notification3Sent) {
      sendNotificationFlag = true;
    } else if (daysRemaining == 1 && !w.notification1Sent) {
      sendNotificationFlag = true;
    } else if (daysRemaining == 0 && !w.notificationTodaySent) {
      sendNotificationFlag = true;
    } else if (daysRemaining < 0 && !w.notificationExpiredSent) {
      sendNotificationFlag = true;
    }

    // Check email triggers
    if (recipientEmail.isNotEmpty) {
      if (daysRemaining == 30 && !w.email30Sent) {
        sendEmailFlag = true;
      } else if (daysRemaining == 15 && !w.email15Sent) {
        sendEmailFlag = true;
      } else if (daysRemaining == 7 && !w.email7Sent) {
        sendEmailFlag = true;
      } else if (daysRemaining == 3 && !w.email3Sent) {
        sendEmailFlag = true;
      } else if (daysRemaining == 1 && !w.email1Sent) {
        sendEmailFlag = true;
      } else if (daysRemaining == 0 && !w.emailTodaySent) {
        sendEmailFlag = true;
      } else if (daysRemaining < 0 && !w.emailExpiredSent) {
        sendEmailFlag = true;
      }
    }

    if (sendNotificationFlag) {
      await sendReminder(w, recipientEmail, userName, daysRemaining, 'notification');
    }

    if (sendEmailFlag) {
      await sendReminder(w, recipientEmail, userName, daysRemaining, 'email');
    }

    if (sendNotificationFlag || sendEmailFlag) {
      await updateReminderFlags(w,
          updateNotification: sendNotificationFlag,
          updateEmail: sendEmailFlag,
          daysRemaining: daysRemaining);
      if (kDebugMode) print('=== Reminder Completed ===');
    }
  }

  /// Sends reminder using the requested platform transport.
  Future<void> sendReminder(WarrantyModel w, String recipientEmail, String userName,
      int daysRemaining, String type) async {
    final isExpired = daysRemaining < 0;

    String subjectText = 'Warranty Reminder';
    String bodyText = '';

    if (daysRemaining == 30) {
      bodyText = 'Your ${w.productName} warranty expires in 30 days.';
    } else if (daysRemaining == 15) {
      bodyText = 'Only 15 days remaining for your ${w.productName} warranty.';
    } else if (daysRemaining == 7) {
      bodyText = 'Only one week remaining for your ${w.productName} warranty.';
    } else if (daysRemaining == 3) {
      bodyText = 'Your warranty expires in 3 days.';
    } else if (daysRemaining == 1) {
      bodyText = 'Your warranty expires tomorrow.';
    } else if (daysRemaining == 0) {
      subjectText = 'Warranty Expired Today';
      bodyText = 'Your warranty expires today.';
    } else if (isExpired) {
      subjectText = 'Warranty Expired';
      bodyText = 'Your warranty has expired.';
    }

    if (type == 'notification') {
      if (kDebugMode) print('=== Sending Notification... ===');
      final id = w.id.hashCode;
      final payload = jsonEncode({
        'warrantyId': w.id,
        'receiptId': w.receiptId,
        'productName': w.productName,
      });

      await _notificationService.showNotification(
        id: id,
        title: subjectText,
        body: bodyText,
        payload: payload,
      );

      try {
        await _notiDbService.saveNotification(
          NotificationModel(
            userId: w.userId,
            warrantyId: w.id,
            receiptId: w.receiptId,
            title: subjectText,
            message: bodyText,
            type: 'WARRANTY',
            createdAt: DateTime.now(),
          ),
        );
      } catch (e) {
        if (kDebugMode) print('Error storing warranty notification in DB: $e');
      }
    } else if (type == 'email') {
      if (kDebugMode) print('=== Sending Email... ===');
      await _emailService.sendWarrantyReminderEmail(
        recipientEmail: recipientEmail,
        userName: userName,
        productName: w.productName,
        merchantName: w.merchantName,
        purchaseDate: w.purchaseDate,
        expiryDate: w.expiryDate,
        daysRemaining: daysRemaining.toString(),
        invoiceNumber: w.invoiceNumber ?? '',
      );

      try {
        await _notiDbService.saveNotification(
          NotificationModel(
            userId: w.userId,
            warrantyId: w.id,
            receiptId: w.receiptId,
            title: 'Email Reminder Sent',
            message: 'Email reminder sent: $bodyText',
            type: 'EMAIL',
            createdAt: DateTime.now(),
          ),
        );
      } catch (e) {
        if (kDebugMode) print('Error storing email notification in DB: $e');
      }
    }
  }

  /// Saves updated sent flags back to Supabase database.
  Future<void> updateReminderFlags(WarrantyModel w,
      {required bool updateNotification,
      required bool updateEmail,
      required int daysRemaining}) async {
    WarrantyModel updated = w;

    if (updateNotification) {
      if (daysRemaining == 30) {
        updated = updated.copyWith(notification30Sent: true);
      } else if (daysRemaining == 15) {
        updated = updated.copyWith(notification15Sent: true);
      } else if (daysRemaining == 7) {
        updated = updated.copyWith(notification7Sent: true);
      } else if (daysRemaining == 3) {
        updated = updated.copyWith(notification3Sent: true);
      } else if (daysRemaining == 1) {
        updated = updated.copyWith(notification1Sent: true);
      } else if (daysRemaining == 0) {
        updated = updated.copyWith(notificationTodaySent: true);
      } else if (daysRemaining < 0) {
        updated = updated.copyWith(notificationExpiredSent: true);
      }
    }

    if (updateEmail) {
      if (daysRemaining == 30) {
        updated = updated.copyWith(email30Sent: true);
      } else if (daysRemaining == 15) {
        updated = updated.copyWith(email15Sent: true);
      } else if (daysRemaining == 7) {
        updated = updated.copyWith(email7Sent: true);
      } else if (daysRemaining == 3) {
        updated = updated.copyWith(email3Sent: true);
      } else if (daysRemaining == 1) {
        updated = updated.copyWith(email1Sent: true);
      } else if (daysRemaining == 0) {
        updated = updated.copyWith(emailTodaySent: true);
      } else if (daysRemaining < 0) {
        updated = updated.copyWith(emailExpiredSent: true);
      }
    }

    await _dbService.updateWarranty(updated);
    if (kDebugMode) print('=== Flags Updated ===');
  }
}
