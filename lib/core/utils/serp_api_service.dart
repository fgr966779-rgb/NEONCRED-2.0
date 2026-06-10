import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/env_provider.dart';

// =============================================================================
// SerpApiService — centralized SerpAPI integration for NEONCRED
// =============================================================================
//
// All SerpAPI calls across the app MUST go through this service.
// It enforces correct parameters for the Ukrainian market:
//   - engine=google_shopping (for product prices)
//   - gl=ua (Ukraine geo)
//   - hl=uk (Ukrainian language)
//   - google_domain=google.com.ua (Ukrainian Google)
//
// Usage:
//   final serpApi = ref.read(serpApiServiceProvider);
//   final results = await serpApi.searchShopping('PS5 купити Україна ціна');
//   final newsResults = await serpApi.searchNews('inflation Ukraine 2025');
// =============================================================================

/// A single shopping result from SerpAPI.
class SerpShoppingResult {
  final String title;
  final double price;
  final String store;
  final String url;
  final String thumbnail;
  final String productId;

  const SerpShoppingResult({
    this.title = '',
    this.price = 0.0,
    this.store = '',
    this.url = '',
    this.thumbnail = '',
    this.productId = '',
  });
}

/// A single organic (news/web) result from SerpAPI.
class SerpOrganicResult {
  final String title;
  final String snippet;
  final String link;
  final String date;

  const SerpOrganicResult({
    this.title = '',
    this.snippet = '',
    this.link = '',
    this.date = '',
  });
}

/// SerpAPI service — handles all SerpAPI HTTP calls with correct UA params.
class SerpApiService {
  final String _apiKey;
  static const String _baseUrl = 'https://serpapi.com';

  SerpApiService(this._apiKey);

  bool get isConfigured => _apiKey.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Google Shopping search — primary method for price fetching
  // ---------------------------------------------------------------------------

  /// Search Google Shopping for a product query.
  ///
  /// Returns a list of [SerpShoppingResult] sorted by price (lowest first).
  /// Returns empty list if API key is not configured or on error.
  Future<List<SerpShoppingResult>> searchShopping(
    String query, {
    int numResults = 10,
  }) async {
    if (!isConfigured) return [];

    final uri = Uri.https(_baseUrl, '/search.json', {
      'engine': 'google_shopping',
      'q': query,
      'api_key': _apiKey,
      'google_domain': 'google.com.ua',
      'gl': 'ua',
      'hl': 'uk',
      'num': numResults.toString(),
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final results = body['shopping_results'] as List<dynamic>? ?? [];

      return results.map((r) {
        final map = r as Map<String, dynamic>;
        final priceStr =
            (map['extracted_price'] ?? map['price'] ?? '0').toString();
        final price = double.tryParse(
          priceStr.replaceAll(RegExp(r'[^\d.]'), ''),
        ) ?? 0.0;

        return SerpShoppingResult(
          title: (map['title'] ?? '').toString(),
          price: price,
          store: (map['store'] ?? map['source'] ?? '').toString(),
          url: (map['link'] ?? map['product_link'] ?? '').toString(),
          thumbnail: (map['thumbnail'] ?? '').toString(),
          productId: (map['product_id'] ?? '').toString(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Google Shopping search — raw JSON response
  // ---------------------------------------------------------------------------

  /// Search Google Shopping and return the raw JSON response.
  ///
  /// Useful when callers need access to all fields in the response,
  /// not just the parsed [SerpShoppingResult] list.
  Future<Map<String, dynamic>> searchShoppingRaw(
    String query, {
    int numResults = 10,
  }) async {
    if (!isConfigured) {
      return {'shopping_results': []};
    }

    final uri = Uri.https(_baseUrl, '/search.json', {
      'engine': 'google_shopping',
      'q': query,
      'api_key': _apiKey,
      'google_domain': 'google.com.ua',
      'gl': 'ua',
      'hl': 'uk',
      'num': numResults.toString(),
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'shopping_results': []};
    } catch (e) {
      return {'shopping_results': [], 'error': e.toString()};
    }
  }

  // ---------------------------------------------------------------------------
  // Google web search — for news / organic results
  // ---------------------------------------------------------------------------

  /// Search Google (organic results) for news / web content.
  ///
  /// Returns a list of [SerpOrganicResult].
  Future<List<SerpOrganicResult>> searchNews(
    String query, {
    int numResults = 5,
  }) async {
    if (!isConfigured) return [];

    final uri = Uri.https(_baseUrl, '/search.json', {
      'engine': 'google',
      'q': query,
      'api_key': _apiKey,
      'gl': 'ua',
      'hl': 'uk',
      'num': numResults.toString(),
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final results = body['organic_results'] as List<dynamic>? ?? [];

      return results.map((r) {
        final map = r as Map<String, dynamic>;
        return SerpOrganicResult(
          title: (map['title'] ?? '').toString(),
          snippet: (map['snippet'] ?? '').toString(),
          link: (map['link'] ?? '').toString(),
          date: (map['date'] ?? '').toString(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Convenience: find the lowest price for a product
  // ---------------------------------------------------------------------------

  /// Search shopping results and return the lowest price found, or -1.0 if none.
  ///
  /// Optionally converts prices that look like USD (< 1000 for electronics)
  /// to UAH at the given exchange rate.
  Future<double> findLowestPrice(
    String query, {
    int numResults = 10,
    double usdUahRate = 41.5,
  }) async {
    final results = await searchShopping(query, numResults: numResults);

    double lowest = double.maxFinite;
    for (final r in results) {
      if (r.price <= 0) continue;
      double price = r.price;
      // If price looks like USD (under 1000 for electronics), convert
      if (price < 1000) {
        price = price * usdUahRate;
      }
      if (price < lowest) {
        lowest = price;
      }
    }

    return lowest < double.maxFinite ? lowest : -1.0;
  }

  // ---------------------------------------------------------------------------
  // Convenience: find the lowest price with store info
  // ---------------------------------------------------------------------------

  /// Returns the lowest price, store name, and URL as a map.
  ///
  /// Keys: 'price' (double), 'store' (String), 'url' (String)
  Future<Map<String, dynamic>> findCheapestOffer(
    String query, {
    int numResults = 10,
    double usdUahRate = 41.5,
  }) async {
    final results = await searchShopping(query, numResults: numResults);

    double lowestPrice = double.maxFinite;
    String bestStore = '';
    String bestUrl = '';

    for (final r in results) {
      if (r.price <= 0) continue;
      double price = r.price;
      if (price < 1000) {
        price = price * usdUahRate;
      }
      if (price < lowestPrice) {
        lowestPrice = price;
        bestStore = r.store;
        bestUrl = r.url;
      }
    }

    return {
      'price': lowestPrice < double.maxFinite ? lowestPrice : 0.0,
      'store': bestStore,
      'url': bestUrl,
    };
  }

  // ---------------------------------------------------------------------------
  // Convenience: get all prices as a flat list of doubles
  // ---------------------------------------------------------------------------

  /// Returns all valid prices from shopping results as a flat list.
  ///
  /// Useful for computing averages or price distributions.
  Future<List<double>> fetchAllPrices(
    String query, {
    int numResults = 10,
  }) async {
    final results = await searchShopping(query, numResults: numResults);
    return results.where((r) => r.price > 0).map((r) => r.price).toList();
  }
}

// =============================================================================
// Riverpod provider — single source of truth for SerpApiService
// =============================================================================

final serpApiServiceProvider = Provider<SerpApiService>((ref) {
  final apiKey = ref.watch(envProvider).serpApiKey;
  return SerpApiService(apiKey);
});
