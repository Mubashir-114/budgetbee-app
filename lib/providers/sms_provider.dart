import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

import '../core/services/sms_service.dart';
import '../core/utils/sms_parser.dart';
import '../repositories/transaction_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmsProvider extends ChangeNotifier {
  final SmsService _smsService = SmsService();
  final TransactionRepository _repository = TransactionRepository();

  bool _isScanning = false;
  bool _isImporting = false;
  String? _errorMessage;
  
  List<ParsedSmsTransaction> _transactions = [];
  List<ParsedSmsTransaction> _archivedTransactions = [];
  final Set<String> _selectedHashes = {};
  PermissionStatus? _permissionStatus;
  SmsImportResponse? _importResponse;
  DateTime? _lastImportTime;

  SmsProvider() {
    loadLastImportTime();
  }

  Future<void> loadLastImportTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString('last_sms_import_time');
      if (timeStr != null) {
        _lastImportTime = DateTime.parse(timeStr);
        notifyListeners();
      }
    } catch (_) {}
  }

  // Getters
  bool get isScanning => _isScanning;
  bool get isImporting => _isImporting;
  String? get errorMessage => _errorMessage;
  List<ParsedSmsTransaction> get transactions => _transactions;
  List<ParsedSmsTransaction> get archivedTransactions => _archivedTransactions;
  Set<String> get selectedHashes => _selectedHashes;
  PermissionStatus? get permissionStatus => _permissionStatus;
  SmsImportResponse? get importResponse => _importResponse;
  DateTime? get lastImportTime => _lastImportTime;

  int get foundCount => _transactions.length;
  int get selectedCount => _selectedHashes.length;
  bool get isAllSelected => _transactions.isNotEmpty && _selectedHashes.length == _transactions.length;

  /// Check permissions and scan for financial transactions in the device SMS inbox.
  Future<void> scanSms() async {
    _isScanning = true;
    _errorMessage = null;
    _importResponse = null;
    notifyListeners();

    try {
      // 1. Check and request SMS permission
      final status = await _smsService.getPermissionStatus();
      _permissionStatus = status;

      if (!status.isGranted) {
        final requestStatus = await _smsService.requestPermission();
        _permissionStatus = requestStatus;
        
        if (!requestStatus.isGranted) {
          _isScanning = false;
          if (requestStatus.isPermanentlyDenied) {
            _errorMessage = 'SMS permission permanently denied. Please enable it in system settings.';
          } else {
            _errorMessage = 'SMS permission denied.';
          }
          notifyListeners();
          return;
        }
      }

      // 2. Fetch already imported SMS hashes from the backend
      final hashResponse = await _repository.getImportedSmsHashes();
      final importedSet = Set<String>.from(hashResponse.success ? hashResponse.data : []);

      // 3. Query and parse SMS inbox
      final parsedList = await _smsService.readAndParseSms();

      // 4. Split into new and archived transactions
      _transactions = [];
      _archivedTransactions = [];
      for (final tx in parsedList) {
        if (importedSet.contains(tx.smsHash)) {
          _archivedTransactions.add(tx);
        } else {
          _transactions.add(tx);
        }
      }

      // 5. Select all discovered new transactions by default
      _selectedHashes.clear();
      for (final tx in _transactions) {
        _selectedHashes.add(tx.smsHash);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _transactions = [];
      _archivedTransactions = [];
      _selectedHashes.clear();
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Toggle selection checkbox for a specific transaction
  void toggleSelection(String hash) {
    if (_selectedHashes.contains(hash)) {
      _selectedHashes.remove(hash);
    } else {
      _selectedHashes.add(hash);
    }
    notifyListeners();
  }

  /// Select or deselect all transactions in the checklist
  void toggleSelectAll(bool select) {
    _selectedHashes.clear();
    if (select) {
      for (final tx in _transactions) {
        _selectedHashes.add(tx.smsHash);
      }
    }
    notifyListeners();
  }

  /// Clear any active error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Upload the selected transactions to the backend
  Future<bool> importSelectedTransactions() async {
    if (_selectedHashes.isEmpty) {
      _errorMessage = 'No transactions selected for import.';
      notifyListeners();
      return false;
    }

    _isImporting = true;
    _errorMessage = null;
    notifyListeners();

    // Filter selected transactions
    final selectedTxs = _transactions
        .where((tx) => _selectedHashes.contains(tx.smsHash))
        .toList();

    try {
      final response = await _repository.importSmsTransactions(selectedTxs);

      if (response.success) {
        _importResponse = response.data;
        
        // Save last import time
        _lastImportTime = DateTime.now();
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_sms_import_time', _lastImportTime!.toIso8601String());
        } catch (_) {}

        // Add successfully imported transactions to the archived list
        final importedTxs = _transactions
            .where((tx) => _selectedHashes.contains(tx.smsHash))
            .toList();
        _archivedTransactions.addAll(importedTxs);

        // Remove successfully processed/skipped transactions from the list
        _transactions.removeWhere((tx) => _selectedHashes.contains(tx.smsHash));
        _selectedHashes.clear();
        
        _isImporting = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isImporting = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        _errorMessage = e.response?.data["message"] ?? e.message ?? 'Failed to connect to the server.';
      } else {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      _isImporting = false;
      notifyListeners();
      return false;
    }
  }
}
