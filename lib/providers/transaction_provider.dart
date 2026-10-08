import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import '../core/services/cache_service.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();

  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;

  List<TransactionModel> _transactions = [];
  int _totalTransactions = 0;
  int _currentPage = 1;
  final int _limit = 10;
  bool _isLoadingMore = false;
  int _sessionGeneration = 0;
  int _loadGeneration = 0;

  // Filter States
  String? _selectedType; // null, "income", "expense"
  int? _selectedCategoryId;
  String? _searchQuery;
  DateTimeRange? _selectedDateRange;
  String _sortBy = "transaction_date"; // "transaction_date", "amount", "created_at"
  String _sortOrder = "desc"; // "asc", "desc"

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;

  List<TransactionModel> get transactions => _transactions;
  int get totalTransactions => _totalTransactions;
  int get currentPage => _currentPage;
  int get limit => _limit;
  bool get hasMore => _transactions.length < _totalTransactions;

  // Filter Getters
  String? get selectedType => _selectedType;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get searchQuery => _searchQuery;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;

  void clearSession() {
    _sessionGeneration++;
    _loadGeneration++;
    _isLoading = false;
    _isLoadingMore = false;
    _isActionLoading = false;
    _errorMessage = null;
    _transactions = [];
    _totalTransactions = 0;
    _currentPage = 1;
    _selectedType = null;
    _selectedCategoryId = null;
    _searchQuery = null;
    _selectedDateRange = null;
    _sortBy = 'transaction_date';
    _sortOrder = 'desc';
    notifyListeners();
  }

  // Setters for Filters (requires refresh)
  void setType(String? type) {
    _selectedType = type;
    _currentPage = 1;
    loadTransactions();
  }

  void setCategoryId(int? categoryId) {
    _selectedCategoryId = categoryId;
    _currentPage = 1;
    loadTransactions();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    _currentPage = 1;
    loadTransactions();
  }

  void setDateRange(DateTimeRange? range) {
    _selectedDateRange = range;
    _currentPage = 1;
    loadTransactions();
  }

  void setSort(String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    _currentPage = 1;
    loadTransactions();
  }

  void clearFilters() {
    _selectedType = null;
    _selectedCategoryId = null;
    _searchQuery = null;
    _selectedDateRange = null;
    _sortBy = "transaction_date";
    _sortOrder = "desc";
    _currentPage = 1;
    loadTransactions();
  }

  Future<void> loadTransactions({bool loadMore = false}) async {
    if (loadMore && (!hasMore || _isLoadingMore || _isLoading)) return;

    final sessionGeneration = _sessionGeneration;
    final loadGeneration = ++_loadGeneration;
    final page = loadMore ? _currentPage + 1 : 1;
    final type = _selectedType;
    final categoryId = _selectedCategoryId;
    final searchQuery = _searchQuery;
    final dateRange = _selectedDateRange;
    final sortBy = _sortBy;
    final sortOrder = _sortOrder;
    final fromDate = dateRange == null
        ? null
        : dateRange.start.toIso8601String().split('T')[0];
    final toDate = dateRange == null
        ? null
        : dateRange.end.toIso8601String().split('T')[0];
    final cacheKey = [
      'transactions',
      type ?? 'all',
      categoryId?.toString() ?? 'all',
      Uri.encodeComponent(searchQuery ?? ''),
      fromDate ?? 'none',
      toDate ?? 'none',
      sortBy,
      sortOrder,
      _limit,
    ].join('_');

    try {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _currentPage = 1;
        _isLoading = true;
        _isLoadingMore = false;

        // Try loading from local cache first
        final cachedData = await CacheService.get(cacheKey);
        if (sessionGeneration != _sessionGeneration ||
            loadGeneration != _loadGeneration) {
          return;
        }
        if (cachedData != null) {
          try {
            final List<dynamic> transactionsList = cachedData["transactions"];
            _transactions = transactionsList.map((item) => TransactionModel.fromJson(item)).toList();
            _totalTransactions = cachedData["total"] ?? _transactions.length;
            notifyListeners();
          } catch (_) {
            await CacheService.remove(cacheKey);
          }
        }
      }
      _errorMessage = null;
      notifyListeners();

      final response = await _repository.getTransactions(
        type: type,
        categoryId: categoryId,
        search: searchQuery,
        from: fromDate,
        to: toDate,
        sort: sortBy,
        order: sortOrder,
        page: page,
        limit: _limit,
      );
      if (sessionGeneration != _sessionGeneration ||
          loadGeneration != _loadGeneration) {
        return;
      }

      if (loadMore) {
        _transactions.addAll(response.data.transactions);
      } else {
        _transactions = response.data.transactions;
        
        // Save first page results to local cache
        await CacheService.save(cacheKey, {
          "transactions": response.data.transactions.map((t) => t.toJson()).toList(),
          "total": response.data.total,
        });
      }
      _currentPage = page;
      _totalTransactions = response.data.total;
      _errorMessage = null;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration ||
          loadGeneration != _loadGeneration) {
        return;
      }
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to load transactions";
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

  Future<bool> addTransaction({
    required int categoryId,
    required String type,
    required String title,
    required double amount,
    required String transactionDate,
    String? note,
  }) async {
    final sessionGeneration = _sessionGeneration;
    try {
      _isActionLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.addTransaction(
        categoryId: categoryId,
        type: type,
        title: title,
        amount: amount,
        transactionDate: transactionDate,
        note: note,
      );

      if (sessionGeneration != _sessionGeneration) return false;
      // Refresh list
      await loadTransactions();
      return true;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to add transaction";
      return false;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _errorMessage = e.toString();
      return false;
    } finally {
      if (sessionGeneration == _sessionGeneration) {
        _isActionLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> editTransaction({
    required int id,
    required int categoryId,
    required String type,
    required String title,
    required double amount,
    required String transactionDate,
    String? note,
  }) async {
    final sessionGeneration = _sessionGeneration;
    try {
      _isActionLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.editTransaction(
        id: id,
        categoryId: categoryId,
        type: type,
        title: title,
        amount: amount,
        transactionDate: transactionDate,
        note: note,
      );

      if (sessionGeneration != _sessionGeneration) return false;
      // Refresh list
      await loadTransactions();
      return true;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to update transaction";
      return false;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _errorMessage = e.toString();
      return false;
    } finally {
      if (sessionGeneration == _sessionGeneration) {
        _isActionLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> deleteTransaction(int id) async {
    final sessionGeneration = _sessionGeneration;
    try {
      _isActionLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.removeTransaction(id);

      if (sessionGeneration != _sessionGeneration) return false;
      // Refresh list
      await loadTransactions();
      return true;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to delete transaction";
      return false;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _errorMessage = e.toString();
      return false;
    } finally {
      if (sessionGeneration == _sessionGeneration) {
        _isActionLoading = false;
        notifyListeners();
      }
    }
  }
}
