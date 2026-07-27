import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipto/features/notifications/data/services/notification_settings_service.dart';
import 'package:receipto/features/notifications/data/services/notification_scheduler.dart';
import 'package:receipto/features/notifications/domain/models/notification_settings_state.dart';
import 'package:receipto/features/warranty/presentation/providers/warranty_provider.dart';

final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>((ref) {
  final service = ref.watch(notificationSettingsServiceProvider);
  return NotificationSettingsNotifier(service, ref);
});

class NotificationSettingsNotifier extends StateNotifier<NotificationSettingsState> {
  final NotificationSettingsService _service;
  final Ref _ref;

  NotificationSettingsNotifier(this._service, this._ref)
      : super(NotificationSettingsState(
          notificationsEnabled: true,
          reminderHour: 9,
          reminderMinute: 0,
          emailNotificationsEnabled: false,
          reminderTypes: {30: true, 15: true, 7: true, 1: true, 0: true},
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _service.getSettings();
    state = settings;
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _service.setNotificationsEnabled(enabled);
    await _rescheduleAll();
  }

  Future<void> updateReminderTime(int hour, int minute) async {
    state = state.copyWith(reminderHour: hour, reminderMinute: minute);
    await _service.setReminderTime(hour, minute);
    await _rescheduleAll();
  }

  Future<void> updateEmailNotificationsEnabled(bool enabled) async {
    state = state.copyWith(emailNotificationsEnabled: enabled);
    await _service.setEmailNotificationsEnabled(enabled);
    await _rescheduleAll();
  }

  Future<void> updateSetting(int days, bool enabled) async {
    final updatedReminderTypes = Map<int, bool>.from(state.reminderTypes)..[days] = enabled;
    state = state.copyWith(reminderTypes: updatedReminderTypes);
    await _service.updateSingleSetting(days, enabled);
    await _rescheduleAll();
  }

  Future<void> enableAll() async {
    final updatedReminderTypes = {30: true, 15: true, 7: true, 1: true, 0: true};
    state = state.copyWith(reminderTypes: updatedReminderTypes);
    await _service.setRemindersEnabled(
      remind30Days: true,
      remind15Days: true,
      remind7Days: true,
      remind1Day: true,
      remindOnExpiry: true,
    );
    await _rescheduleAll();
  }

  Future<void> disableAll() async {
    final updatedReminderTypes = {30: false, 15: false, 7: false, 1: false, 0: false};
    state = state.copyWith(reminderTypes: updatedReminderTypes);
    await _service.setRemindersEnabled(
      remind30Days: false,
      remind15Days: false,
      remind7Days: false,
      remind1Day: false,
      remindOnExpiry: false,
    );
    await _rescheduleAll();
  }

  Future<void> _rescheduleAll() async {
    try {
      final warranties = await _ref.read(dbWarrantiesProvider.future);
      await _ref.read(notificationSchedulerProvider).syncWarranties(warranties);
    } catch (e) {
      // Handle error gracefully
    }
  }
}

final nextScheduledReminderProvider = FutureProvider<DateTime?>((ref) async {
  // Watch settings to recalculate automatically on toggles or time modifications
  ref.watch(notificationSettingsProvider);
  
  final warranties = await ref.watch(dbWarrantiesProvider.future);
  final scheduler = ref.read(notificationSchedulerProvider);
  return scheduler.getNextReminderDate(warranties);
});
