import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/account_activity_model.dart';
import '../models/account_balance_model.dart';
import '../models/account_model.dart';
import '../models/credit_card_models.dart';
import '../models/transfer_model.dart';
import '../repositories/account_repository.dart';
import '../core/services/cache_service.dart';

enum AccountActionStatus { idle, loading, success, error }

/// Provider managing account list, detail, create, edit, default and archive
/// operations.  Follows the same session-generation + load-generation pattern
/// used by [TransactionProvider] to guard against stale async results after
/// logout.
class AccountProvider extends ChangeNotifier {
  final AccountRepository _repository;

  AccountProvider({AccountRepository? repository})
      : _repository = repository ?? AccountRepository();

  // ── Session isolation ─────────────────────────────────────────────────────
  int _sessionGeneration = 0;
  int _loadGeneration = 0;

  // ── List state ────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  List<AccountModel> _accounts = [];
  int _total = 0;
  int _currentPage = 1;
  static const int _limit = 20;

  // ── Action state ──────────────────────────────────────────────────────────
  AccountActionStatus _actionStatus = AccountActionStatus.idle;
  String? _actionError;

  // ── Active cancel token for list loads ────────────────────────────────────
  CancelToken? _activeCancelToken;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  List<AccountModel> get accounts => _accounts;
  int get total => _total;
  int get currentPage => _currentPage;
  bool get hasMore => _accounts.length < _total;
  AccountActionStatus get actionStatus => _actionStatus;
  String? get actionError => _actionError;

  // Convenience: default asset account (null if none set yet)
  AccountModel? get defaultAccount =>
      _accounts.where((a) => a.isDefault && a.isAsset).firstOrNull;

  // ── Session reset ─────────────────────────────────────────────────────────

  void clearSession() {
    _sessionGeneration++;
    _loadGeneration++;
    _activeCancelToken?.cancel('Session cleared');
    _activeCancelToken = null;
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    _accounts = [];
    _total = 0;
    _currentPage = 1;
    _actionStatus = AccountActionStatus.idle;
    _actionError = null;
    notifyListeners();
  }

  // ── Load accounts list ────────────────────────────────────────────────────

  Future<void> loadAccounts({bool loadMore = false}) async {
    if (loadMore && (!hasMore || _isLoadingMore || _isLoading)) return;

    final sessionGeneration = _sessionGeneration;
    final loadGeneration = ++_loadGeneration;
    final page = loadMore ? _currentPage + 1 : 1;
    const cacheKey = 'accounts_active_page1';

    // Cancel any in-flight list request.
    _activeCancelToken?.cancel('New load requested');
    final cancelToken = CancelToken();
    _activeCancelToken = cancelToken;

    try {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _currentPage = 1;
        _isLoading = true;
        _isLoadingMore = false;

        // Serve cached data immediately while fetching
        final cached = await CacheService.get(cacheKey);
        if (sessionGeneration != _sessionGeneration ||
            loadGeneration != _loadGeneration) {
          return;
        }
        if (cached != null) {
          try {
            final list = cached['accounts'] as List<dynamic>;
            _accounts =
                list.map((e) => AccountModel.fromJson(e as Map<String, dynamic>)).toList();
            _total = cached['total'] as int? ?? _accounts.length;
            notifyListeners();
          } catch (_) {
            await CacheService.remove(cacheKey);
          }
        }
      }
      _errorMessage = null;
      notifyListeners();

      final response = await _repository.getAccounts(
        status: 'active',
        page: page,
        limit: _limit,
        cancelToken: cancelToken,
      );

      if (sessionGeneration != _sessionGeneration ||
          loadGeneration != _loadGeneration) {
        return;
      }

      if (loadMore) {
        _accounts.addAll(response.data.accounts);
      } else {
        _accounts = response.data.accounts;
        await CacheService.save(cacheKey, {
          'accounts': response.data.accounts.map((a) => a.toJson()).toList(),
          'total': response.data.total,
        });
      }
      _currentPage = page;
      _total = response.data.total;
      _errorMessage = null;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (sessionGeneration != _sessionGeneration ||
          loadGeneration != _loadGeneration) {
        return;
      }
      _errorMessage =
          (e.response?.data as Map?)?['message'] as String? ??
          e.message ??
          'Failed to load accounts';
    } catch (e) {
      if (sessionGeneration != _sessionGeneration ||
          loadGeneration != _loadGeneration) {
        return;
      }
      _errorMessage = e.toString();
    } finally {
      if (sessionGeneration == _sessionGeneration &&
          loadGeneration == _loadGeneration) {
        _isLoading = false;
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  // ── Invalidate cache and reload ───────────────────────────────────────────

  Future<void> refresh() async {
    await CacheService.remove('accounts_active_page1');
    await loadAccounts();
  }

  // ── Create account ────────────────────────────────────────────────────────

  Future<AccountModel?> createAccount({
    required String type,
    required String subtype,
    required String displayName,
    String? institutionName,
    String? maskedLast4,
    String openingAmount = '0.00',
    String? creditLimit,
    bool isDefault = false,
    required String clientCreationKey,
  }) async {
    final sessionGeneration = _sessionGeneration;
    try {
      _actionStatus = AccountActionStatus.loading;
      _actionError = null;
      notifyListeners();

      final response = await _repository.createAccount(
        type: type,
        subtype: subtype,
        displayName: displayName,
        institutionName: institutionName,
        maskedLast4: maskedLast4,
        openingAmount: openingAmount,
        creditLimit: creditLimit,
        isDefault: isDefault,
        clientCreationKey: clientCreationKey,
      );

      if (sessionGeneration != _sessionGeneration) return null;
      _actionStatus = AccountActionStatus.success;
      await refresh();
      return response.data;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return null;
      _actionStatus = AccountActionStatus.error;
      _actionError =
          (e.response?.data as Map?)?['message'] as String? ??
          e.message ??
          'Failed to create account';
      return null;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return null;
      _actionStatus = AccountActionStatus.error;
      _actionError = e.toString();
      return null;
    } finally {
      if (sessionGeneration == _sessionGeneration) notifyListeners();
    }
  }

  // ── Update account metadata ───────────────────────────────────────────────

  Future<AccountModel?> updateAccount(
    int id, {
    required String displayName,
    String? institutionName,
    String? maskedLast4,
  }) async {
    final sessionGeneration = _sessionGeneration;
    try {
      _actionStatus = AccountActionStatus.loading;
      _actionError = null;
      notifyListeners();

      final response = await _repository.updateAccount(
        id,
        displayName: displayName,
        institutionName: institutionName,
        maskedLast4: maskedLast4,
      );

      if (sessionGeneration != _sessionGeneration) return null;
      _actionStatus = AccountActionStatus.success;
      // Update local list entry in-place and refresh cache.
      _accounts = _accounts
          .map((a) => a.id == id ? response.data : a)
          .toList();
      await _persistListCache();
      notifyListeners();
      return response.data;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return null;
      _actionStatus = AccountActionStatus.error;
      _actionError =
          (e.response?.data as Map?)?['message'] as String? ??
          e.message ??
          'Failed to update account';
      notifyListeners();
      return null;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return null;
      _actionStatus = AccountActionStatus.error;
      _actionError = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ── Set default ───────────────────────────────────────────────────────────

  Future<bool> setDefault(int id) async {
    final sessionGeneration = _sessionGeneration;
    try {
      _actionStatus = AccountActionStatus.loading;
      _actionError = null;
      notifyListeners();

      await _repository.setDefault(id);

      if (sessionGeneration != _sessionGeneration) return false;
      _actionStatus = AccountActionStatus.success;
      await refresh();
      return true;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _actionStatus = AccountActionStatus.error;
      _actionError =
          (e.response?.data as Map?)?['message'] as String? ??
          e.message ??
          'Failed to set default account';
      notifyListeners();
      return false;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _actionStatus = AccountActionStatus.error;
      _actionError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Archive ───────────────────────────────────────────────────────────────

  Future<bool> archiveAccount(int id) async {
    final sessionGeneration = _sessionGeneration;
    try {
      _actionStatus = AccountActionStatus.loading;
      _actionError = null;
      notifyListeners();

      await _repository.archiveAccount(id);

      if (sessionGeneration != _sessionGeneration) return false;
      _actionStatus = AccountActionStatus.success;
      await refresh();
      return true;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _actionStatus = AccountActionStatus.error;
      _actionError =
          (e.response?.data as Map?)?['message'] as String? ??
          e.message ??
          'Failed to archive account';
      notifyListeners();
      return false;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _actionStatus = AccountActionStatus.error;
      _actionError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Reset action state (call from UI after reading error/success) ─────────

  void resetActionStatus() {
    _actionStatus = AccountActionStatus.idle;
    _actionError = null;
    notifyListeners();
  }

  // ── Exact Ledger Balance ──────────────────────────────────────────────────

  Future<AccountBalanceModel?> getAccountBalance(int id) async {
    try {
      final response = await _repository.getAccountBalance(id);
      return response.data;
    } catch (_) {
      return null;
    }
  }

  // ── Account Activity ──────────────────────────────────────────────────────

  Future<AccountActivityListResponse?> getAccountActivity(
    int id, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _repository.getAccountActivity(
        id,
        page: page,
        limit: limit,
      );
      return response.data;
    } catch (_) {
      return null;
    }
  }

  // ── Balance Adjustment ────────────────────────────────────────────────────

  Future<bool> createAdjustment(
    int id, {
    required String amount,
    required String reason,
    required String adjustmentDate,
    required String clientAdjustmentKey,
  }) async {
    final sessionGeneration = _sessionGeneration;
    try {
      _actionStatus = AccountActionStatus.loading;
      _actionError = null;
      notifyListeners();

      await _repository.createAdjustment(
        id,
        amount: amount,
        reason: reason,
        adjustmentDate: adjustmentDate,
        clientAdjustmentKey: clientAdjustmentKey,
      );

      if (sessionGeneration != _sessionGeneration) return false;
      _actionStatus = AccountActionStatus.success;
      await refresh();
      return true;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _actionStatus = AccountActionStatus.error;
      _actionError =
          (e.response?.data as Map?)?['message'] as String? ??
          e.message ??
          'Failed to record balance adjustment';
      notifyListeners();
      return false;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _actionStatus = AccountActionStatus.error;
      _actionError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Atomic Transfers ──────────────────────────────────────────────────────

  Future<bool> createTransfer({
    required int sourceAccountId,
    required int destinationAccountId,
    required String amount,
    required String transferDate,
    String? note,
    required String clientTransferKey,
  }) async {
    final sessionGeneration = _sessionGeneration;
    try {
      _actionStatus = AccountActionStatus.loading;
      _actionError = null;
      notifyListeners();

      await _repository.createTransfer(
        sourceAccountId: sourceAccountId,
        destinationAccountId: destinationAccountId,
        amount: amount,
        transferDate: transferDate,
        note: note,
        clientTransferKey: clientTransferKey,
      );

      if (sessionGeneration != _sessionGeneration) return false;
      _actionStatus = AccountActionStatus.success;
      await refresh();
      return true;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _actionStatus = AccountActionStatus.error;
      _actionError =
          (e.response?.data as Map?)?['message'] as String? ??
          e.message ??
          'Failed to complete transfer';
      notifyListeners();
      return false;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _actionStatus = AccountActionStatus.error;
      _actionError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<TransferListResponse?> getTransfers({
    int? accountId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _repository.getTransfers(
        accountId: accountId,
        page: page,
        limit: limit,
      );
      return response.data;
    } catch (_) {
      return null;
    }
  }

  // ── Credit Card Management ───────────────────────────────────────────────

  Future<CreditCardDetailsModel?> getCreditCardDetails(int cardId) async {
    try {
      final response = await _repository.getCreditCardDetails(cardId);
      return response.data;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateBillingSettings(
    int cardId, {
    int? statementClosingDay,
    int? paymentDueDay,
  }) async {
    final sessionGeneration = _sessionGeneration;
    try {
      _actionStatus = AccountActionStatus.loading;
      _actionError = null;
      notifyListeners();

      await _repository.updateBillingSettings(
        cardId,
        statementClosingDay: statementClosingDay,
        paymentDueDay: paymentDueDay,
      );

      if (sessionGeneration != _sessionGeneration) return false;
      _actionStatus = AccountActionStatus.success;
      await refresh();
      return true;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _actionStatus = AccountActionStatus.error;
      _actionError =
          (e.response?.data as Map?)?['message'] as String? ??
          e.message ??
          'Failed to update billing settings';
      notifyListeners();
      return false;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _actionStatus = AccountActionStatus.error;
      _actionError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<CreditCardRepaymentResult?> repayCreditCard({
    required int cardId,
    required int sourceAccountId,
    required String amount,
    required String paymentDate,
    String? note,
    required String clientPaymentKey,
  }) async {
    final sessionGeneration = _sessionGeneration;
    try {
      _actionStatus = AccountActionStatus.loading;
      _actionError = null;
      notifyListeners();

      final response = await _repository.repayCreditCard(
        cardId,
        sourceAccountId: sourceAccountId,
        amount: amount,
        paymentDate: paymentDate,
        note: note,
        clientPaymentKey: clientPaymentKey,
      );

      if (sessionGeneration != _sessionGeneration) return null;
      _actionStatus = AccountActionStatus.success;
      await refresh();
      return response.data;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return null;
      _actionStatus = AccountActionStatus.error;
      _actionError =
          (e.response?.data as Map?)?['message'] as String? ??
          e.message ??
          'Failed to complete credit card repayment';
      notifyListeners();
      return null;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return null;
      _actionStatus = AccountActionStatus.error;
      _actionError = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<CreditCardPaymentListResponse?> getCreditCardPayments(
    int cardId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _repository.getCreditCardPayments(
        cardId,
        page: page,
        limit: limit,
      );
      return response.data;
    } catch (_) {
      return null;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _persistListCache() async {
    await CacheService.save('accounts_active_page1', {
      'accounts': _accounts.map((a) => a.toJson()).toList(),
      'total': _total,
    });
  }
}
