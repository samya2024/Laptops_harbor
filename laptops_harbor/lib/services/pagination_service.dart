import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PaginationService<T> {
  final Query query;
  final T Function(Map<dynamic, dynamic>) fromJson;
  final int pageSize;
  final String? orderBy;
  final bool descending;

  List<T> _items = [];
  bool _hasMore = true;
  bool _isLoading = false;
  String? _lastKey;
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);

  PaginationService({
    required this.query,
    required this.fromJson,
    this.pageSize = 10,
    this.orderBy,
    this.descending = false,
  });

  Future<List<T>> loadInitialData() async {
    if (_isLoading) return _items;
    _isLoading = true;
    isLoading.value = true;
    error.value = null;

    try {
      Query paginatedQuery = query;
      if (orderBy != null) {
        paginatedQuery = paginatedQuery.orderByChild(orderBy!);
        if (descending) {
          paginatedQuery = paginatedQuery.limitToLast(pageSize);
        } else {
          paginatedQuery = paginatedQuery.limitToFirst(pageSize);
        }
      } else {
        paginatedQuery = paginatedQuery.limitToFirst(pageSize);
      }

      final snapshot = await paginatedQuery.get();
      if (!snapshot.exists) {
        _hasMore = false;
        return _items;
      }

      _items = [];
      for (var child in snapshot.children) {
        final data = child.value as Map<dynamic, dynamic>;
        _items.add(fromJson(data));
      }

      if (snapshot.children.length < pageSize) {
        _hasMore = false;
      } else {
        _lastKey = snapshot.children.last.key;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      _isLoading = false;
      isLoading.value = false;
    }

    return _items;
  }

  Future<List<T>> loadMore() async {
    if (!_hasMore || _isLoading) return _items;
    _isLoading = true;
    isLoading.value = true;
    error.value = null;

    try {
      Query paginatedQuery = query;
      if (orderBy != null) {
        paginatedQuery = paginatedQuery.orderByChild(orderBy!);
        if (descending) {
          paginatedQuery = paginatedQuery
              .endBefore(_lastKey)
              .limitToLast(pageSize);
        } else {
          paginatedQuery = paginatedQuery
              .startAfter(_lastKey)
              .limitToFirst(pageSize);
        }
      } else {
        paginatedQuery = paginatedQuery
            .startAfter(_lastKey)
            .limitToFirst(pageSize);
      }

      final snapshot = await paginatedQuery.get();
      if (!snapshot.exists) {
        _hasMore = false;
        return _items;
      }

      for (var child in snapshot.children) {
        final data = child.value as Map<dynamic, dynamic>;
        _items.add(fromJson(data));
      }

      if (snapshot.children.length < pageSize) {
        _hasMore = false;
      } else {
        _lastKey = snapshot.children.last.key;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      _isLoading = false;
      isLoading.value = false;
    }

    return _items;
  }

  void reset() {
    _items = [];
    _hasMore = true;
    _lastKey = null;
    error.value = null;
  }

  bool get hasMore => _hasMore;
  List<T> get items => _items;
}
