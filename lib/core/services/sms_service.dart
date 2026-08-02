import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/sms_parser.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();

  /// Checks the current SMS permission status.
  Future<PermissionStatus> getPermissionStatus() async {
    return await Permission.sms.status;
  }

  /// Requests runtime SMS permissions.
  Future<PermissionStatus> requestPermission() async {
    return await Permission.sms.request();
  }

  /// Queries the SMS inbox, filters bank transactions, and returns parsed transaction items.
  /// Throws an exception if permissions are denied.
  Future<List<ParsedSmsTransaction>> readAndParseSms() async {
    final status = await getPermissionStatus();
    if (!status.isGranted) {
      final requestStatus = await requestPermission();
      if (!requestStatus.isGranted) {
        throw Exception('SMS permission denied');
      }
    }

    // Query messages from the inbox
    final List<SmsMessage> messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
    );

    final List<ParsedSmsTransaction> transactions = [];
    for (final message in messages) {
      final String? sender = message.address;
      final String? body = message.body;
      final DateTime? date = message.date;

      if (sender == null || body == null) {
        continue;
      }

      // Parse individual message
      final parsed = SmsParser.parseSms(
        sender: sender,
        body: body,
        date: date ?? DateTime.now(),
      );

      if (parsed != null) {
        transactions.add(parsed);
      }
    }

    // Sort transactions by date descending (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }
}
