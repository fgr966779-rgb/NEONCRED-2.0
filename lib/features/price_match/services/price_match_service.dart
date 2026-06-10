import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// =============================================================================
// Price Match Ninja — AI-generated price-match requests to stores
// =============================================================================
//
// Helps users get the lowest price by finding cheaper offers and generating
// professional price-match emails in Ukrainian. Tracks store policies and
// awards XP for successful price matches.
//
// APIs:  SerpAPI Shopping (find cheaper prices)
//        + OpenRouter (AI email generation in Ukrainian)
//        + SendGrid (email delivery)
// =============================================================================

// -----------------------------------------------------------------------------
// Data models
// -----------------------------------------------------------------------------

/// Status of a price-match request.
enum PriceMatchStatus {
  pending('pending', 'Ochiuietsia'),
  sent('sent', 'Nadislano'),
  accepted('accepted', 'Pryiniato'),
  rejected('rejected', 'Vidkhylemo');

  final String id;
  final String labelUA;
  const PriceMatchStatus(this.id, this.labelUA);

  static PriceMatchStatus fromId(String id) {
    return PriceMatchStatus.values.firstWhere(
      (s) => s.id == id,
      orElse: () => PriceMatchStatus.pending,
    );
  }
}

/// A price-match request with all lifecycle data.
class PriceMatchRequest {
  final String id;
  final String productName;
  final double currentPrice;
  final String currentStore;
  final double cheaperPrice;
  final String cheaperStore;
  final String cheaperStoreUrl;
  final String matchLetterHtml;
  final String storePolicy;
  final PriceMatchStatus status;
  final String? responseDate;
  final int xpAwarded;
  final String createdAt;

  const PriceMatchRequest({
    required this.id,
    required this.productName,
    required this.currentPrice,
    required this.currentStore,
    this.cheaperPrice = 0.0,
    this.cheaperStore = '',
    this.cheaperStoreUrl = '',
    this.matchLetterHtml = '',
    this.storePolicy = '',
    this.status = PriceMatchStatus.pending,
    this.responseDate,
    this.xpAwarded = 0,
    this.createdAt = '',
  });

  double get savingsAmount => currentPrice - cheaperPrice;

  double get savingsPercent =>
      currentPrice > 0 ? (savingsAmount / currentPrice) * 100 : 0.0;

  bool get isSuccess => status == PriceMatchStatus.accepted;

  PriceMatchRequest copyWith({
    String? id,
    String? productName,
    double? currentPrice,
    String? currentStore,
    double? cheaperPrice,
    String? cheaperStore,
    String? cheaperStoreUrl,
    String? matchLetterHtml,
    String? storePolicy,
    PriceMatchStatus? status,
    String? responseDate,
    int? xpAwarded,
    String? createdAt,
  }) {
    return PriceMatchRequest(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      currentPrice: currentPrice ?? this.currentPrice,
      currentStore: currentStore ?? this.currentStore,
      cheaperPrice: cheaperPrice ?? this.cheaperPrice,
      cheaperStore: cheaperStore ?? this.cheaperStore,
      cheaperStoreUrl: cheaperStoreUrl ?? this.cheaperStoreUrl,
      matchLetterHtml: matchLetterHtml ?? this.matchLetterHtml,
      storePolicy: storePolicy ?? this.storePolicy,
      status: status ?? this.status,
      responseDate: responseDate ?? this.responseDate,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// State for the Price Match Ninja feature.
class PriceMatchState {
  final List<PriceMatchRequest> requests;
  final bool isLoading;
  final String? error;
  final int totalSaved;
  final int successfulMatches;

  const PriceMatchState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
    this.totalSaved = 0,
    this.successfulMatches = 0,
  });

  PriceMatchState copyWith({
    List<PriceMatchRequest>? requests,
    bool? isLoading,
    String? error,
    int? totalSaved,
    int? successfulMatches,
  }) {
    return PriceMatchState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalSaved: totalSaved ?? this.totalSaved,
      successfulMatches: successfulMatches ?? this.successfulMatches,
    );
  }
}

// -----------------------------------------------------------------------------
// Predefined store policies
// -----------------------------------------------------------------------------

const _storePolicies = {
  'Rozetka': 'Prohrama "Naikrashcha tsina" — poveriaiut riznytsiu',
  'Comfy': 'Price match die na elektroniku ta pobutovu tekhniku',
  'Allo': 'Znyzhka do tsiny konkurenta pry nalaynosti pidtverdzhennia',
  'Citrus': 'Ofitsiinoi polityky nemaie, ale mozhna napsysty u pidtrymku',
  'MOYO': 'Nemaie ofitsiinoi polityky price match',
  'Fokstrot': 'Harantuiut naikrashchu tsinu na tekhniku',
  'Epicentr': 'Nemaie price match, ale ie aktsiini propozytsii',
};



// -----------------------------------------------------------------------------
// SendGrid — email delivery
// -----------------------------------------------------------------------------

Future<bool> _sendEmailViaSendGrid({
  required String sendgridKey,
  required String toEmail,
  required String fromEmail,
  required String subject,
  required String body,
}) async {
  if (sendgridKey.isEmpty) return false;

  final uri = Uri.https('api.sendgrid.com', '/v3/mail/send');
  final payload = jsonEncode({
    'personalizations': [
      {
        'to': [{'email': toEmail}],
        'subject': subject,
      }
    ],
    'from': {'email': fromEmail},
    'content': [
      {
        'type': 'text/plain',
        'value': body,
      }
    ],
  });

  try {
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $sendgridKey',
        'Content-Type': 'application/json',
      },
      body: payload,
    );
    return response.statusCode == 202;
  } catch (_) {
    return false;
  }
}

// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

class PriceMatchNotifier extends StateNotifier<PriceMatchState> {
  final Ref _ref;

  PriceMatchNotifier(this._ref) : super(const PriceMatchState());

  // ---------------------------------------------------------------------------
  // Find a cheaper price for a product via SerpAPI
  // ---------------------------------------------------------------------------

  Future<PriceMatchRequest?> findCheaperPrice(
    String productName,
    double currentPrice,
    String currentStore,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final env = _ref.read(envProvider);
      final usdUahRate = 41.5;

      final result = await _ref.read(serpApiServiceProvider).searchShoppingRaw(
        '$productName ціна Україна',
      );

      final shoppingResults =
          result['shopping_results'] as List? ?? [];

      String cheaperStore = '';
      double cheaperPrice = 0.0;
      String cheaperUrl = '';

      for (final r in shoppingResults) {
        final store = (r['store'] ?? r['source'] ?? '').toString();
        final priceStr =
            (r['extracted_price'] ?? r['price'] ?? '0').toString();
        double price = double.tryParse(
          priceStr.replaceAll(RegExp(r'[^\d.]'), ''),
        ) ?? 0.0;
        final link = (r['link'] ?? r['product_link'] ?? '').toString();

        if (price > 0 && price < 1000) {
          price = price * usdUahRate;
        }

        if (price > 0 &&
            price < currentPrice &&
            !store.toLowerCase().contains(currentStore.toLowerCase())) {
          if (cheaperPrice == 0.0 || price < cheaperPrice) {
            cheaperPrice = price;
            cheaperStore = store;
            cheaperUrl = link;
          }
        }
      }

      if (cheaperPrice > 0.0) {
        // Find store policy
        String policy = '';
        for (final entry in _storePolicies.entries) {
          if (currentStore.toLowerCase().contains(entry.key.toLowerCase())) {
            policy = entry.value;
            break;
          }
        }

        final request = PriceMatchRequest(
          id: 'pm_${DateTime.now().millisecondsSinceEpoch}',
          productName: productName,
          currentPrice: currentPrice,
          currentStore: currentStore,
          cheaperPrice: cheaperPrice,
          cheaperStore: cheaperStore,
          cheaperStoreUrl: cheaperUrl,
          storePolicy: policy,
          createdAt: DateTime.now().toIso8601String(),
          xpAwarded: 15,
        );

        final updatedRequests = [request, ...state.requests];
        state = state.copyWith(
          requests: updatedRequests,
          isLoading: false,
        );

        return request;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Deshevshu tsinu ne znaideno dlia "$productName" '
              'v inshykh mahazynakh. Vy vzhe maete naikrashchu tsinu!',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Pomylka poshuku tsin: $e',
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Generate a price-match email using AI
  // ---------------------------------------------------------------------------

  Future<String> generateMatchLetter(PriceMatchRequest request) async {
    final openRouter = _ref.read(openRouterServiceProvider);
    final apiKey = _ref.read(openRouterApiKeyProvider);

    if (apiKey.isEmpty) {
      return 'Pomylka: API kliuch OpenRouter ne nalashtovanyi. '
          'Zvernitisia do pidtrymky mahazynu samostiino.';
    }

    final policyNote = request.storePolicy.isNotEmpty
        ? 'Polityka mahazynu: ${request.storePolicy}. Zhadai tse u listi.'
        : 'Neviedomo, chy ie price match — sprobuvi perekonaty pidtrymku.';

    final systemPrompt =
        'Ty VAULT-17 — kyberpunk AI-asystent dodatku NEONCRED. '
        'Ty heneruiesh profesioni listy dlia price match zapytiv do mahazyniv v Ukraini. '
        'Styl: vvichlyvyi, profesioni, ale z kyberpunk-dukhom. '
        'Pyshy ukrainskoiu movoiu. Lyst maie buty hotovyi do vidpravky. '
        'Ne dodavai subject riadok — lyshe tilo lista.';

    final userPrompt =
        'Zenerui price match list dlia mahazynu ${request.currentStore}.\n\n'
        'Tovar: ${request.productName}\n'
        'Tsina v ${request.currentStore}: ${request.currentPrice.toStringAsFixed(0)} hrn\n'
        'Deshevshe v ${request.cheaperStore}: ${request.cheaperPrice.toStringAsFixed(0)} hrn\n'
        'Riznytsia: ${request.savingsAmount.toStringAsFixed(0)} hrn\n\n'
        'Polityka mahazynu: $policyNote\n\n'
        'Lyst maie:\n'
        '1. Vvichlyvo vkazaty na nyzhchu tsinu v inshomu mahazyni\n'
        '2. Nadaty konkretni tsyfry\n'
        '3. Poprosyty znyzyty tsinu do rivnia konkurenta\n'
        '4. Zhadaty, shcho ia postiinyi kliient\n'
        '5. Diakuvaty za rozhliad zapytu';

    try {
      final result = await openRouter.chat(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        temperature: 0.8,
        maxTokens: 600,
      );

      final letter = result ?? 'Ne vdalosia zeneruvaty list. Sprobuvi shche raz.';

      // Update the request with generated letter
      final updatedRequests = state.requests.map((r) {
        if (r.id == request.id) {
          return r.copyWith(matchLetterHtml: letter);
        }
        return r;
      }).toList();

      state = state.copyWith(requests: updatedRequests);

      return letter;
    } catch (e) {
      return 'Pomylka heneratsii lista: $e';
    }
  }

  // ---------------------------------------------------------------------------
  // Find store's price match policy using AI
  // ---------------------------------------------------------------------------

  Future<String> findStorePolicy(String storeName) async {
    // Check predefined policies first
    for (final entry in _storePolicies.entries) {
      if (storeName.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Use AI to search for policy
    final openRouter = _ref.read(openRouterServiceProvider);
    final apiKey = _ref.read(openRouterApiKeyProvider);

    if (apiKey.isEmpty) {
      return 'Polityka nevidoma — API kliuch ne nalashtovanyi';
    }

    final systemPrompt =
        'Ty VAULT-17 — kyberpunk AI-asystent dodatku NEONCRED. '
        'Ty shukaiesh informatsiiu pro polityku price match mahazyniv. '
        'Pyshy ukrainskoiu. Korotka vidpovid (1-2 rechennia).';

    final userPrompt =
        'Yaka polityka price match v mahazyni $storeName v Ukraini? '
        'Chy ye u nykh ofitsiina prohrama porivniannia tsin? '
        'Yakshcho nevidomo, skazhy tse.';

    try {
      final result = await openRouter.chat(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        temperature: 0.5,
        maxTokens: 200,
      );
      return result ?? 'Polityka nevidoma dlia $storeName';
    } catch (_) {
      return 'Ne vdalosia znalyty polityku dlia $storeName';
    }
  }

  // ---------------------------------------------------------------------------
  // Send a price-match email via SendGrid
  // ---------------------------------------------------------------------------

  Future<bool> sendMatchRequest(PriceMatchRequest request) async {
    if (request.matchLetterHtml.isEmpty) {
      state = state.copyWith(
        error: 'Lyst ne zenerovanyi. Spersh zeneruite list.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final env = _ref.read(envProvider);
      final sendgridKey =
          (env as dynamic).sendgridApiKey as String? ?? '';

      // Determine the store support email
      final storeEmail = _getStoreSupportEmail(request.currentStore);

      final success = await _sendEmailViaSendGrid(
        sendgridKey: sendgridKey,
        toEmail: storeEmail,
        fromEmail: 'ninja@neoncred.app',
        subject:
            'Zapyt na price match: ${request.productName} — '
            '${request.cheaperPrice.toStringAsFixed(0)} hrn v ${request.cheaperStore}',
        body: request.matchLetterHtml,
      );

      final updatedRequests = state.requests.map((r) {
        if (r.id == request.id) {
          return r.copyWith(
            status: success
                ? PriceMatchStatus.sent
                : r.status,
            xpAwarded: r.xpAwarded + (success ? 25 : 0),
          );
        }
        return r;
      }).toList();

      state = state.copyWith(
        requests: updatedRequests,
        isLoading: false,
      );

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Pomylka vidpravky lista: $e',
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Update the status of a request
  // ---------------------------------------------------------------------------

  void updateStatus(String requestId, PriceMatchStatus status) {
    final updatedRequests = state.requests.map((r) {
      if (r.id == requestId) {
        int newXp = r.xpAwarded;
        if (status == PriceMatchStatus.accepted) {
          newXp += 100; // Success bonus
        }
        return r.copyWith(
          status: status,
          responseDate: DateTime.now().toIso8601String(),
          xpAwarded: newXp,
        );
      }
      return r;
    }).toList();

    // Recalculate stats
    int totalSaved = 0;
    int successful = 0;
    for (final r in updatedRequests) {
      if (r.status == PriceMatchStatus.accepted) {
        totalSaved += r.savingsAmount.round();
        successful++;
      }
    }

    state = state.copyWith(
      requests: updatedRequests,
      totalSaved: totalSaved,
      successfulMatches: successful,
    );
  }

  // ---------------------------------------------------------------------------
  // Get stats
  // ---------------------------------------------------------------------------

  (int totalSaved, int successfulMatches, double successRate) getStats() {
    final total = state.requests.length;
    final successful = state.successfulMatches;
    final rate = total > 0 ? (successful / total) * 100 : 0.0;
    return (state.totalSaved, successful, rate);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _getStoreSupportEmail(String storeName) {
    final lowerName = storeName.toLowerCase();
    if (lowerName.contains('rozetka')) return 'support@rozetka.com.ua';
    if (lowerName.contains('comfy')) return 'support@comfy.ua';
    if (lowerName.contains('citrus')) return 'support@citrus.ua';
    if (lowerName.contains('allo')) return 'support@allo.ua';
    if (lowerName.contains('moyo')) return 'support@moyo.ua';
    if (lowerName.contains('fokstrot') || lowerName.contains('fox')) {
      return 'support@fox.ua';
    }
    if (lowerName.contains('epicentr')) {
      return 'support@epicentrk.com';
    }
    return 'support@${lowerName.replaceAll(' ', '')}.com';
  }
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

final priceMatchProvider =
    StateNotifierProvider<PriceMatchNotifier, PriceMatchState>((ref) {
  return PriceMatchNotifier(ref);
});
