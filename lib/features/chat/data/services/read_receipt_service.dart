import 'dart:async';
import '../models/read_receipt_settings.dart';

/// Service for managing read receipt settings and tracking.
class ReadReceiptService {
  ReadReceiptService._();
  static final ReadReceiptService instance = ReadReceiptService._();

  final _settingsController = StreamController<ReadReceiptSettings>.broadcast();
  final _receiptController = StreamController<MessageReceipt>.broadcast();

  Stream<ReadReceiptSettings> get settingsStream => _settingsController.stream;
  Stream<MessageReceipt> get receiptStream => _receiptController.stream;

  ReadReceiptSettings _currentSettings = const ReadReceiptSettings();
  final Map<String, MessageReceipt> _receipts = {};

  ReadReceiptSettings get currentSettings => _currentSettings;
  bool get isEnabled => _currentSettings.sendReadReceipts;

  /// Load settings.
  Future<ReadReceiptSettings> loadSettings({bool isPremium = false}) async {
    // In production, fetch from backend
    await Future.delayed(const Duration(milliseconds: 300));

    _currentSettings = ReadReceiptSettings(isPremium: isPremium);
    _settingsController.add(_currentSettings);
    return _currentSettings;
  }

  /// Toggle sending read receipts.
  Future<ReadReceiptSettings> toggleSendReadReceipts(bool enabled) async {
    if (!_currentSettings.canModify) {
      throw Exception('Premium required to modify read receipt settings');
    }

    _currentSettings = _currentSettings.copyWith(
      sendReadReceipts: enabled,
    );

    _settingsController.add(_currentSettings);
    await _saveSettings();
    return _currentSettings;
  }

  /// Toggle showing others' read receipts.
  Future<ReadReceiptSettings> toggleShowOthersReadReceipts(bool enabled) async {
    if (!_currentSettings.canModify) {
      throw Exception('Premium required to modify read receipt settings');
    }

    _currentSettings = _currentSettings.copyWith(
      showOthersReadReceipts: enabled,
    );

    _settingsController.add(_currentSettings);
    await _saveSettings();
    return _currentSettings;
  }

  /// Mark message as delivered.
  Future<MessageReceipt> markDelivered({
    required String messageId,
    required String recipientId,
  }) async {
    final receipt = MessageReceipt(
      messageId: messageId,
      recipientId: recipientId,
      status: ReadReceiptStatus.delivered,
      deliveredAt: DateTime.now(),
    );

    _receipts[messageId] = receipt;
    _receiptController.add(receipt);

    return receipt;
  }

  /// Mark message as read.
  Future<MessageReceipt> markRead({
    required String messageId,
    required String recipientId,
  }) async {
    final existing = _receipts[messageId];

    final receipt = MessageReceipt(
      messageId: messageId,
      recipientId: recipientId,
      status: ReadReceiptStatus.read,
      deliveredAt: existing?.deliveredAt ?? DateTime.now(),
      readAt: DateTime.now(),
    );

    _receipts[messageId] = receipt;

    // Only emit if sending read receipts is enabled
    if (_currentSettings.sendReadReceipts) {
      _receiptController.add(receipt);
    }

    return receipt;
  }

  /// Get receipt for a message.
  MessageReceipt? getReceipt(String messageId) => _receipts[messageId];

  /// Bulk mark messages as read.
  Future<void> markAllRead(List<String> messageIds, String recipientId) async {
    for (final messageId in messageIds) {
      await markRead(messageId: messageId, recipientId: recipientId);
    }
  }

  /// Check if should show read receipts.
  bool shouldShowReceipts() {
    return _currentSettings.showOthersReadReceipts;
  }

  Future<void> _saveSettings() async {
    // In production, save to backend
  }

  void dispose() {
    _settingsController.close();
    _receiptController.close();
  }
}

/// Individual message receipt.
class MessageReceipt {
  const MessageReceipt({
    required this.messageId,
    required this.recipientId,
    required this.status,
    this.deliveredAt,
    this.readAt,
  });

  final String messageId;
  final String recipientId;
  final ReadReceiptStatus status;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'recipientId': recipientId,
      'status': status.name,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }
}
