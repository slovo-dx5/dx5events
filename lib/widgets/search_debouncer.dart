// This file contains utility functions to support search and pagination

import 'dart:async';

class SearchDebouncer {
  final Duration delay;
  Timer? _timer;

  SearchDebouncer({this.delay = const Duration(milliseconds: 500)});

  void run(Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

class PaginationHelper {
  // Helper function to build filter parameters for Directus API
  static String buildFilterParams({
    required String idField,
    required String idValue,
    String statusField = 'status',
    String statusValue = 'approved',
    Map<String, String>? additionalFilters,
    String? searchQuery,
    List<String>? searchFields,
  }) {
    // Start with base filters
    String filterParams = "&filter[$idField][_eq]=$idValue&filter[$statusField][_eq]=$statusValue";

    // Add additional filters if provided
    if (additionalFilters != null && additionalFilters.isNotEmpty) {
      additionalFilters.forEach((field, value) {
        filterParams += "&filter[$field][_eq]=$value";
      });
    }

    // Add search query across multiple fields if provided
    if (searchQuery != null && searchQuery.isNotEmpty &&
        searchFields != null && searchFields.isNotEmpty) {
      for (int i = 0; i < searchFields.length; i++) {
        filterParams += "&filter[_or][$i][${searchFields[i]}][_contains]=$searchQuery";
      }
    }

    return filterParams;
  }

  // Helper function to manage cache keys
  static String generateCacheKey({
    required String prefix,
    required String id,
    required int page,
    required int pageSize,
    String? searchQuery,
    List<String>? additionalParams,
  }) {
    String key = '${prefix}_${id}_${page}_${pageSize}';

    if (searchQuery != null && searchQuery.isNotEmpty) {
      key += '_$searchQuery';
    } else {
      key += '_no_search';
    }

    if (additionalParams != null && additionalParams.isNotEmpty) {
      for (final param in additionalParams) {
        key += '_$param';
      }
    }

    return key;
  }
}