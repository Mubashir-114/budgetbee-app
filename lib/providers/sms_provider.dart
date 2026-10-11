import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/cache_service.dart';
import '../core/services/sms_service.dart';
import '../core/utils/sms_parser.dart';
import '../models/detected_transaction_model.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/smart_transaction_repository.dart';

class SmsProvider extends ChangeNotifier {
  SmsProvider({
    SmsService? smsService,
    TransactionRepository? repository,
    SmartTransactionRepository? smartRepo,
  })  : _smsService = smsService ?? SmsService(),
        _repository = repository ?? TransactionRepository(),
        _smartRepo = smartRepo ?? SmartTransactionRepository();

  final SmsService _smsService;
  final TransactionRepository _repository;
  final SmartTransactionRepository _smartRepo;

  bool _isScanning = false;
  bool _isImporting = false;
  bool _isLoadingDetected = false;
  bool _isOperating = false;
  String? _errorMessage;
  String? _detectedErrorMessage;

  List<ParsedSmsTransaction> _transactions = [];
  List<ParsedSmsTransaction> _archivedTransactions = [];
  final Set<String> _selectedHashes = {};

  // Phase 3B Smart Transactions state
  List<DetectedTransactionModel> _detectedTransactions = [];
  List<DetectedTransactionModel> _archivedDetectedTransactions = [];
  final Set<int> _selectedDetectedIds = {};

  PermissionStatus? _permissionStatus;
  SmsImportResponse? _importResponse;
  DateTime? _lastImportTime;
  int _sessionGeneration = 0;

  void clearSession() {
    _sessionGeneration++;
    _isScanning = false;
    _isImporting = false;
    _isLoadingDetected = false;
    _isOperating = false;
    _errorMessage = null;
    _detectedErrorMessage = null;
    _transactions = [];
    _archivedTransactions = [];
    _selectedHashes.clear();
    _detectedTransactions = [];
    _archivedDetectedTransactions = [];
    _selectedDetectedIds.clear();
    _permissionStatus = null;
    _importResponse = null;
    _lastImportTime = null;
    notifyListeners();
  }

  Future<void> loadLastImportTime() async {
    final sessionGeneration = _sessionGeneration;
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString(
        CacheService.userScopedKey('last_sms_import_time'),
      );
      if (timeStr != null) {
        final lastImportTime = DateTime.parse(timeStr);
        if (sessionGeneration == _sessionGeneration) {
          _lastImportTime = lastImportTime;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  // Getters - Legacy & Generic
  bool get isScanning => _isScanning;
  bool get isImporting => _isImporting;
  bool get isLoadingDetected => _isLoadingDetected;
  bool get isOperating => _isOperating;
  String? get errorMessage => _errorMessage;
  String? get detectedErrorMessage => _detectedErrorMessage;
  List<ParsedSmsTransaction> get transactions => _transactions;
  List<ParsedSmsTransaction> get archivedTransactions => _archivedTransactions;
  Set<String> get selectedHashes => _selectedHashes;
  PermissionStatus? get permissionStatus => _permissionStatus;
  SmsImportResponse? get importResponse => _importResponse;
  DateTime? get lastImportTime => _lastImportTime;

  int get foundCount => _transactions.length;
  int get selectedCount => _selectedHashes.length;
  bool get isAllSelected => _transactions.isNotEmpty && _selectedHashes.length == _transactions.length;

  // Getters - Phase 3B Smart Transactions
  List<DetectedTransactionModel> get detectedTransactions => _detectedTransactions;
  List<DetectedTransactionModel> get archivedDetectedTransactions => _archivedDetectedTransactions;
  Set<int> get selectedDetectedIds => _selectedDetectedIds;
  int get detectedCount => _detectedTransactions.length;
  int get selectedDetectedCount => _selectedDetectedIds.length;
  bool get isAllDetectedSelected =>
      _detectedTransactions.isNotEmpty && _selectedDetectedIds.length == _detectedTransactions.length;

  // ── Phase 3B Smart Transactions Methods ─────────────────────────────────────

  void toggleDetectedSelection(int id) {
    if (_selectedDetectedIds.contains(id)) {
      _selectedDetectedIds.remove(id);
    } else {
      _selectedDetectedIds.add(id);
    }
    notifyListeners();
  }

  void toggleSelectAllDetected(bool select) {
    _selectedDetectedIds.clear();
    if (select) {
      for (final tx in _detectedTransactions) {
        _selectedDetectedIds.add(tx.id);
      }
    }
    notifyListeners();
  }

  /// Loads detected transactions from backend for review.
  Future<void> loadDetectedTransactions({String status = "suggested"}) async {
    final sessionGeneration = _sessionGeneration;
    _isLoadingDetected = true;
    _detectedErrorMessage = null;
    notifyListeners();

    try {
      final res = await _smartRepo.getDetectedTransactions(status: status);
      if (sessionGeneration != _sessionGeneration) return;

      if (res.success) {
        if (status == "suggested" || status == "detected") {
          _detectedTransactions = res.data;
          _selectedDetectedIds.clear();
          for (final item in _detectedTransactions) {
            _selectedDetectedIds.add(item.id);
          }
        } else {
          _archivedDetectedTransactions = res.data;
        }
      } else {
        _detectedErrorMessage = res.message;
      }
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return;
      _detectedErrorMessage = e is DioException
          ? (e.response?.data["message"] ?? e.message ?? "Failed to load detected transactions")
          : e.toString().replaceAll("Exception: ", "");
    } finally {
      if (sessionGeneration == _sessionGeneration) {
        _isLoadingDetected = false;
        notifyListeners();
      }
    }
  }

  /// Scans device SMS inbox, transmits financial SMS to backend for smart parsing,
  /// and updates both smart transactions and legacy transactions.
  Future<void> scanAndDetectSmartTransactions() async {
    if (_isScanning || _isImporting) return;
    final sessionGeneration = _sessionGeneration;
    _isScanning = true;
    _errorMessage = null;
    _detectedErrorMessage = null;
    notifyListeners();

    try {
      await loadLastImportTime();
      if (sessionGeneration != _sessionGeneration) return;

      // 1. Check and request SMS permission
      final status = await _smsService.getPermissionStatus();
      if (sessionGeneration != _sessionGeneration) return;
      _permissionStatus = status;

      if (!status.isGranted) {
        final requestStatus = await _smsService.requestPermission();
        if (sessionGeneration != _sessionGeneration) return;
        _permissionStatus = requestStatus;

        if (!requestStatus.isGranted) {
          if (requestStatus.isPermanentlyDenied) {
            _errorMessage = 'SMS permission permanently denied. Please enable it in system settings.';
          } else {
            _errorMessage = 'SMS permission denied.';
          }
          notifyListeners();
          return;
        }
      }

      // 2. Read messages from inbox
      final parsedList = await _smsService.readAndParseSms();
      if (sessionGeneration != _sessionGeneration) return;

      if (parsedList.isNotEmpty) {
        final messagesPayload = parsedList.map((p) => p.toJson()).toList();
        await _smartRepo.detectTransactions(messagesPayload);
      }

      // 3. Load detected transactions from backend
      await loadDetectedTransactions(status: "suggested");
      await loadDetectedTransactions(status: "confirmed");

      // 4. Also maintain legacy transactions list for backwards compatibility
      final hashResponse = await _repository.getImportedSmsHashes();
      if (sessionGeneration != _sessionGeneration) return;
      final importedSet = Set<String>.from(hashResponse.data);

      _transactions = [];
      _archivedTransactions = [];
      for (final tx in parsedList) {
        if (importedSet.contains(tx.smsHash)) {
          _archivedTransactions.add(tx);
        } else {
          _transactions.add(tx);
        }
      }
      _selectedHashes.clear();
      for (final tx in _transactions) {
        _selectedHashes.add(tx.smsHash);
      }
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return;
      _errorMessage = e is DioException
          ? (e.response?.data["message"] ?? e.message ?? "Failed to scan SMS")
          : e.toString().replaceAll("Exception: ", "");
    } finally {
      if (sessionGeneration == _sessionGeneration) {
        _isScanning = false;
        notifyListeners();
      }
    }
  }

  /// Confirms a single detected transaction into the ledger.
  Future<bool> confirmDetected(int id, {Map<String, dynamic>? overrides}) async {
    _isOperating = true;
    _detectedErrorMessage = null;
    notifyListeners();

    try {
      final res = await _smartRepo.confirmTransaction(id, overrides: overrides);
      if (res.success) {
        _detectedTransactions.removeWhere((t) => t.id == id);
        _selectedDetectedIds.remove(id);
        await CacheService.remove('dashboard_cache');
        await CacheService.clearBudgetCaches();
        notifyListeners();
        return true;
      } else {
        _detectedErrorMessage = res.message;
        return false;
      }
    } catch (e) {
      _detectedErrorMessage = e is DioException
          ? (e.response?.data["message"] ?? e.message ?? "Failed to confirm transaction")
          : e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Rejects a detected transaction so it never enters the ledger.
  Future<bool> rejectDetected(int id, {String? reason}) async {
    _isOperating = true;
    _detectedErrorMessage = null;
    notifyListeners();

    try {
      final res = await _smartRepo.rejectTransaction(id, reason: reason);
      if (res.success) {
        _detectedTransactions.removeWhere((t) => t.id == id);
        _selectedDetectedIds.remove(id);
        notifyListeners();
        return true;
      } else {
        _detectedErrorMessage = res.message;
        return false;
      }
    } catch (e) {
      _detectedErrorMessage = e is DioException
          ? (e.response?.data["message"] ?? e.message ?? "Failed to reject transaction")
          : e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Updates a detected transaction with manual user corrections.
  Future<bool> updateDetected(int id, Map<String, dynamic> changes) async {
    _isOperating = true;
    _detectedErrorMessage = null;
    notifyListeners();

    try {
      final res = await _smartRepo.updateDetectedTransaction(id, changes);
      if (res.success) {
        final index = _detectedTransactions.indexWhere((t) => t.id == id);
        if (index != -1) {
          _detectedTransactions[index] = res.data;
        }
        notifyListeners();
        return true;
      } else {
        _detectedErrorMessage = res.message;
        return false;
      }
    } catch (e) {
      _detectedErrorMessage = e is DioException
          ? (e.response?.data["message"] ?? e.message ?? "Failed to update transaction")
          : e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Batch confirms all selected detected transactions.
  Future<bool> batchConfirmSelected() async {
    if (_selectedDetectedIds.isEmpty) return false;
    _isOperating = true;
    _detectedErrorMessage = null;
    notifyListeners();

    try {
      final items = _selectedDetectedIds.map((id) => {"id": id}).toList();
      final res = await _smartRepo.batchConfirm(items);
      if (res.success) {
        _detectedTransactions.removeWhere((t) => _selectedDetectedIds.contains(t.id));
        _selectedDetectedIds.clear();
        await CacheService.remove('dashboard_cache');
        await CacheService.clearBudgetCaches();
        notifyListeners();
        return true;
      } else {
        _detectedErrorMessage = res.message;
        return false;
      }
    } catch (e) {
      _detectedErrorMessage = e is DioException
          ? (e.response?.data["message"] ?? e.message ?? "Failed to batch confirm transactions")
          : e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Batch rejects all selected detected transactions.
  Future<bool> batchRejectSelected({String? reason}) async {
    if (_selectedDetectedIds.isEmpty) return false;
    _isOperating = true;
    _detectedErrorMessage = null;
    notifyListeners();

    try {
      final ids = _selectedDetectedIds.toList();
      final res = await _smartRepo.batchReject(ids, reason: reason);
      if (res.success) {
        _detectedTransactions.removeWhere((t) => _selectedDetectedIds.contains(t.id));
        _selectedDetectedIds.clear();
        notifyListeners();
        return true;
      } else {
        _detectedErrorMessage = res.message;
        return false;
      }
    } catch (e) {
      _detectedErrorMessage = e is DioException
          ? (e.response?.data["message"] ?? e.message ?? "Failed to batch reject transactions")
          : e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  // ── Existing SMS Scanning and Import Methods (Preserved) ────────────────────

  /// Check permissions and scan for financial transactions in the device SMS inbox.
  Future<void> scanSms() async {
    if (_isScanning || _isImporting) return;
    final sessionGeneration = _sessionGeneration;
    _isScanning = true;
    _errorMessage = null;
    _importResponse = null;
    notifyListeners();

    try {
      await loadLastImportTime();
      if (sessionGeneration != _sessionGeneration) return;

      // 1. Check and request SMS permission
      final status = await _smsService.getPermissionStatus();
      if (sessionGeneration != _sessionGeneration) return;
      _permissionStatus = status;

      if (!status.isGranted) {
        final requestStatus = await _smsService.requestPermission();
        if (sessionGeneration != _sessionGeneration) return;
        _permissionStatus = requestStatus;

        if (!requestStatus.isGranted) {
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
      if (sessionGeneration != _sessionGeneration) return;
      if (!hashResponse.success) {
        throw Exception(
          hashResponse.message.isEmpty
              ? 'Could not check previously imported SMS transactions.'
              : hashResponse.message,
        );
      }
      final importedSet = Set<String>.from(hashResponse.data);

      // 3. Query and parse SMS inbox
      final parsedList = await _smsService.readAndParseSms();
      if (sessionGeneration != _sessionGeneration) return;

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

      // 6. Also load server-side detected transactions
      try {
        await loadDetectedTransactions(status: "suggested");
      } catch (_) {}
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _transactions = [];
      _archivedTransactions = [];
      _selectedHashes.clear();
    } finally {
      if (sessionGeneration == _sessionGeneration) {
        _isScanning = false;
        notifyListeners();
      }
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
    _detectedErrorMessage = null;
    notifyListeners();
  }

  /// Upload the selected transactions to the backend
  Future<bool> importSelectedTransactions() async {
    if (_isScanning || _isImporting) return false;
    if (_selectedHashes.isEmpty) {
      _errorMessage = 'No transactions selected for import.';
      notifyListeners();
      return false;
    }

    _isImporting = true;
    final sessionGeneration = _sessionGeneration;
    _errorMessage = null;
    notifyListeners();

    // Filter selected transactions
    final selectedTxs = _transactions
        .where((tx) => _selectedHashes.contains(tx.smsHash))
        .toList();

    try {
      final response = await _repository.importSmsTransactions(selectedTxs);
      if (sessionGeneration != _sessionGeneration) return false;

      if (response.success) {
        _importResponse = response.data;
        await CacheService.remove('dashboard_cache');
        await CacheService.clearBudgetCaches();

        // Save last import time
        _lastImportTime = DateTime.now();
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            CacheService.userScopedKey('last_sms_import_time'),
            _lastImportTime!.toIso8601String(),
          );
        } catch (_) {}

        if (response.data.failed == 0) {
          final importedTxs = _transactions
              .where((tx) => _selectedHashes.contains(tx.smsHash))
              .toList();
          _archivedTransactions.addAll(importedTxs);
          _transactions.removeWhere(
            (tx) => _selectedHashes.contains(tx.smsHash),
          );
          _selectedHashes.clear();
        }
        return true;
      } else {
        _errorMessage = response.message;
        return false;
      }
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      if (e is DioException) {
        _errorMessage = e.response?.data["message"] ?? e.message ?? 'Failed to connect to the server.';
      } else {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      return false;
    } finally {
      if (sessionGeneration == _sessionGeneration) {
        _isImporting = false;
        notifyListeners();
      }
    }
  }
}
