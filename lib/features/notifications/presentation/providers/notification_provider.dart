import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/services/notification_database_service.dart';
import 'package:receipto/features/notifications/domain/models/notification_model.dart';

final notificationNotifierProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  final dbService = ref.watch(notificationDatabaseServiceProvider);
  final authService = ref.watch(firebaseAuthServiceProvider);
  return NotificationNotifier(dbService, authService);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationNotifierProvider);
  return state.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationDatabaseService _dbService;
  final FirebaseAuthService _authService;

  NotificationNotifier(this._dbService, this._authService) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  String get _userId => _authService.currentUser?.uid ?? '';

  /// Fetches user notification records.
  Future<void> loadNotifications() async {
    if (_userId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final notifications = await _dbService.fetchNotifications(_userId);
      state = AsyncValue.data(notifications);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Triggers full state reload.
  Future<void> refresh() async {
    await loadNotifications();
  }

  /// Marks a specific notification log as read.
  Future<void> markRead(String id) async {
    try {
      await _dbService.markAsRead(id);
      
      state.whenData((list) {
        state = AsyncValue.data(
          list.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
        );
      });
    } catch (e) {
      if (kDebugMode) print('Error marking notification as read: $e');
    }
  }

  /// Marks all current user notifications as read in database.
  Future<void> markAllAsRead() async {
    if (_userId.isEmpty) return;
    try {
      state.whenData((list) async {
        for (final n in list) {
          if (!n.isRead && n.id != null) {
            await _dbService.markAsRead(n.id!);
          }
        }
        state = AsyncValue.data(
          list.map((n) => n.copyWith(isRead: true)).toList(),
        );
      });
    } catch (e) {
      if (kDebugMode) print('Error marking all notifications as read: $e');
    }
  }

  /// Deletes a specific notification log.
  Future<void> delete(String id) async {
    try {
      await _dbService.deleteNotification(id);
      
      state.whenData((list) {
        state = AsyncValue.data(
          list.where((n) => n.id != id).toList(),
        );
      });
    } catch (e) {
      if (kDebugMode) print('Error deleting notification: $e');
    }
  }

  /// Deletes all notifications for current user.
  Future<void> deleteAll() async {
    if (_userId.isEmpty) return;
    try {
      await _dbService.deleteAllNotifications(_userId);
      state = const AsyncValue.data([]);
    } catch (e) {
      if (kDebugMode) print('Error deleting all notifications: $e');
    }
  }
}
