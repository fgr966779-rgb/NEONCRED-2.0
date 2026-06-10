import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// EnvConfig — centralized environment variable reader
// =============================================================================
//
// Usage:
//   final apiKey = ref.read(envProvider).openRouterApiKey;
//
// In production, replace _loadEnv() with flutter_dotenv or flutter_secure_storage.
// =============================================================================

class EnvConfig {
  // AI / LLM
  final String openRouterApiKey;

  // Banking — PrivatBank (Ukraine)
  final String privatbankMerchantId;
  final String privatbankPassword;
  final String privatbankCardNumber;

  // Banking — Plaid (International)
  final String plaidClientId;
  final String plaidSecret;
  final String plaidEnv;

  // Financial Data
  final String twelveDataApiKey;
  final String serpApiKey;

  // Events / Seasonal Calendar
  final String predicthqApiKey;

  // 3D / AR
  final String sketchfabApiKey;

  // Receipt Scanning
  final String mindeeApiKey;
  final String googleVisionApiKey;

  // Crypto
  final String okxApiKey;
  final String okxSecretKey;
  final String okxPassphrase;

  // Firebase
  final String firebaseApiKey;
  final String firebaseProjectId;
  final String firebaseMessagingSenderId;
  final String firebaseAppId;

  // Price API
  final String priceApiApiKey;

  // Coupon / Promo
  final String couponApiKey;

  // Email / Price Match
  final String sendgridApiKey;

  // Amazon Product API
  final String amazonAccessKey;
  final String amazonSecretKey;
  final String amazonPartnerTag;

  // Voice / Audio
  final String asrApiKey;
  final String ttsApiKey;

  // Second-Hand Market
  final String olxApiKey;

  // App Config
  final String dbName;
  final String appEnv;
  final bool debugLogging;

  const EnvConfig({
    this.openRouterApiKey = '',
    this.privatbankMerchantId = '',
    this.privatbankPassword = '',
    this.privatbankCardNumber = '',
    this.plaidClientId = '',
    this.plaidSecret = '',
    this.plaidEnv = 'sandbox',
    this.twelveDataApiKey = '',
    this.serpApiKey = '',
    this.predicthqApiKey = '',
    this.sketchfabApiKey = '',
    this.mindeeApiKey = '',
    this.googleVisionApiKey = '',
    this.okxApiKey = '',
    this.okxSecretKey = '',
    this.okxPassphrase = '',
    this.firebaseApiKey = '',
    this.firebaseProjectId = '',
    this.firebaseMessagingSenderId = '',
    this.firebaseAppId = '',
    this.priceApiApiKey = '',
    this.couponApiKey = '',
    this.sendgridApiKey = '',
    this.amazonAccessKey = '',
    this.amazonSecretKey = '',
    this.amazonPartnerTag = '',
    this.asrApiKey = '',
    this.ttsApiKey = '',
    this.olxApiKey = '',
    this.dbName = 'neoncred.db',
    this.appEnv = 'development',
    this.debugLogging = false,
  });

  /// Whether we're running in production.
  bool get isProduction => appEnv == 'production';

  /// Whether we're running in development.
  bool get isDevelopment => appEnv == 'development';

  /// Whether any banking API is configured.
  bool get hasBankConfig =>
      privatbankMerchantId.isNotEmpty || plaidClientId.isNotEmpty;

  /// Whether OpenRouter (AI) is configured.
  bool get hasAiConfig => openRouterApiKey.isNotEmpty;

  /// Whether Sketchfab (3D) is configured.
  bool get has3dConfig => sketchfabApiKey.isNotEmpty;

  /// Whether financial data APIs are configured.
  bool get hasFinancialConfig =>
      twelveDataApiKey.isNotEmpty || serpApiKey.isNotEmpty;

  /// Whether voice/audio APIs are configured.
  bool get hasVoiceConfig => asrApiKey.isNotEmpty && ttsApiKey.isNotEmpty;

  /// Whether Firebase is configured.
  bool get hasFirebaseConfig => firebaseApiKey.isNotEmpty;
}

// =============================================================================
// .env file parser — reads KEY=VALUE pairs from .env file
// =============================================================================

Map<String, String> _parseEnvFile(String content) {
  final result = <String, String>{};

  for (final line in content.split('\n')) {
    final trimmed = line.trim();

    // Skip empty lines and comments
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

    final eqIndex = trimmed.indexOf('=');
    if (eqIndex == -1) continue;

    final key = trimmed.substring(0, eqIndex).trim();
    var value = trimmed.substring(eqIndex + 1).trim();

    // Remove surrounding quotes if present
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }

    result[key] = value;
  }

  return result;
}

/// Load environment variables from the .env file.
///
/// In a real Flutter app, use `flutter_dotenv` package instead:
///   await dotenv.load(fileName: ".env");
///   final key = dotenv.env['OPENROUTER_API_KEY'];
///
/// This implementation reads .env from the project root for development.
EnvConfig _loadEnv() {
  // Try to read from .env file
  Map<String, String> envVars = {};

  try {
    // In production, use flutter_dotenv or platform-specific secure storage.
    // For development, we read from the project root .env file.
    // Note: This path works in development mode only.
    const envPath = '.env';
    final file = File(envPath);
    if (file.existsSync()) {
      final content = file.readAsStringSync();
      envVars = _parseEnvFile(content);
    }
  } catch (_) {
    // If .env file can't be read, fall back to empty config.
    // All features have graceful fallbacks when keys are empty.
  }

  return EnvConfig(
    // AI / LLM
    openRouterApiKey: envVars['OPENROUTER_API_KEY'] ?? '',

    // Banking — PrivatBank
    privatbankMerchantId: envVars['PRIVATBANK_MERCHANT_ID'] ?? '',
    privatbankPassword: envVars['PRIVATBANK_PASSWORD'] ?? '',
    privatbankCardNumber: envVars['PRIVATBANK_CARD_NUMBER'] ?? '',

    // Banking — Plaid
    plaidClientId: envVars['PLAID_CLIENT_ID'] ?? '',
    plaidSecret: envVars['PLAID_SECRET'] ?? '',
    plaidEnv: envVars['PLAID_ENV'] ?? 'sandbox',

    // Financial Data
    twelveDataApiKey: envVars['TWELVE_DATA_API_KEY'] ?? '',
    serpApiKey: envVars['SERPAPI_KEY'] ?? '',

    // Events / Seasonal Calendar
    predicthqApiKey: envVars['PREDICTHQ_API_KEY'] ?? '',

    // 3D / AR
    sketchfabApiKey: envVars['SKETCHFAB_API_KEY'] ?? '',

    // Receipt Scanning
    mindeeApiKey: envVars['MINDEE_API_KEY'] ?? '',
    googleVisionApiKey: envVars['GOOGLE_VISION_API_KEY'] ?? '',

    // Crypto
    okxApiKey: envVars['OKX_API_KEY'] ?? '',
    okxSecretKey: envVars['OKX_SECRET_KEY'] ?? '',
    okxPassphrase: envVars['OKX_PASSPHRASE'] ?? '',

    // Firebase
    firebaseApiKey: envVars['FIREBASE_API_KEY'] ?? '',
    firebaseProjectId: envVars['FIREBASE_PROJECT_ID'] ?? '',
    firebaseMessagingSenderId: envVars['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
    firebaseAppId: envVars['FIREBASE_APP_ID'] ?? '',

    // Price API
    priceApiApiKey: envVars['PRICEAPI_KEY'] ?? '',

    // Coupon / Promo
    couponApiKey: envVars['COUPON_API_KEY'] ?? '',

    // Email / Price Match
    sendgridApiKey: envVars['SENDGRID_API_KEY'] ?? '',

    // Amazon Product API
    amazonAccessKey: envVars['AMAZON_ACCESS_KEY'] ?? '',
    amazonSecretKey: envVars['AMAZON_SECRET_KEY'] ?? '',
    amazonPartnerTag: envVars['AMAZON_PARTNER_TAG'] ?? '',

    // Voice / Audio
    asrApiKey: envVars['ASR_API_KEY'] ?? '',
    ttsApiKey: envVars['TTS_API_KEY'] ?? '',

    // Second-Hand Market
    olxApiKey: envVars['OLX_API_KEY'] ?? '',

    // App Config
    dbName: envVars['DB_NAME'] ?? 'neoncred.db',
    appEnv: envVars['APP_ENV'] ?? 'development',
    debugLogging: (envVars['DEBUG_LOGGING'] ?? 'false').toLowerCase() == 'true',
  );
}

// =============================================================================
// Riverpod provider — single source of truth for all env vars
// =============================================================================

/// Centralized environment config provider.
///
/// All API key providers should read from this:
///   final openRouterKey = ref.watch(envProvider).openRouterApiKey;
final envProvider = Provider<EnvConfig>((ref) {
  return _loadEnv();
});

// =============================================================================
// Convenience providers — one per API key
// =============================================================================

/// OpenRouter API key (AI features).
final openRouterApiKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).openRouterApiKey;
});

/// Sketchfab API key (3D trophy gallery).
final sketchfabApiKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).sketchfabApiKey;
});

/// SerpAPI key (financial news radar).
final serpApiKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).serpApiKey;
});

/// Twelve Data API key (financial quotes).
final twelveDataApiKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).twelveDataApiKey;
});

/// PrivatBank merchant ID.
final privatbankMerchantIdProvider = Provider<String>((ref) {
  return ref.watch(envProvider).privatbankMerchantId;
});

/// PrivatBank password.
final privatbankPasswordProvider = Provider<String>((ref) {
  return ref.watch(envProvider).privatbankPassword;
});

/// Plaid client ID.
final plaidClientIdProvider = Provider<String>((ref) {
  return ref.watch(envProvider).plaidClientId;
});

/// Plaid secret.
final plaidSecretProvider = Provider<String>((ref) {
  return ref.watch(envProvider).plaidSecret;
});

/// Mindee API key (receipt scanning).
final mindeeApiKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).mindeeApiKey;
});

/// Google Vision API key (OCR fallback).
final googleVisionApiKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).googleVisionApiKey;
});

/// OKX API key (crypto).
final okxApiKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).okxApiKey;
});

/// OKX secret key (crypto).
final okxSecretKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).okxSecretKey;
});

/// Coupon API key (promo code lookup).
final couponApiKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).couponApiKey;
});

/// ASR API key (speech-to-text).
final asrApiKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).asrApiKey;
});

/// TTS API key (text-to-speech).
final ttsApiKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).ttsApiKey;
});

/// Firebase API key.
final firebaseApiKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).firebaseApiKey;
});

/// Firebase project ID.
final firebaseProjectIdProvider = Provider<String>((ref) {
  return ref.watch(envProvider).firebaseProjectId;
});

/// PriceAPI.com API key (price comparison).
final priceApiApiKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).priceApiApiKey;
});

/// SendGrid API key (email delivery for price match).
final sendgridApiKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).sendgridApiKey;
});

/// Amazon Product Advertising API access key.
final amazonAccessKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).amazonAccessKey;
});

/// Amazon Product Advertising API secret key.
final amazonSecretKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).amazonSecretKey;
});

/// Amazon Partner Tag (associate ID).
final amazonPartnerTagProvider = Provider<String>((ref) {
  return ref.watch(envProvider).amazonPartnerTag;
});

/// OLX API key (second-hand market).
final olxApiKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).olxApiKey;
});

/// PredictHQ API key (seasonal calendar events).
final predicthqApiKeyProvider = Provider<String>((ref) {
  return ref.watch(envProvider).predicthqApiKey;
});
