import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/env_provider.dart';

/// Shared utility for OpenRouter API calls across all NEONCRED features.
///
/// Eliminates the duplicated API call pattern, _stripCodeFences, and
/// constant definitions that were copy-pasted across 6+ service files.

class OpenRouterService {
  static const String baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String defaultModel = 'deepseek/deepseek-chat-v3-5:free';

  final Ref _ref;

  OpenRouterService(this._ref);

  /// Send a chat completion request to OpenRouter.
  ///
  /// [systemPrompt] — the system message for the AI.
  /// [userPrompt] — the user's message.
  /// [temperature] — creativity level (0.0–1.0), default 0.85.
  /// [maxTokens] — max response tokens, default 512.
  ///
  /// Returns the AI response text, or null on failure.
  Future<String?> chat({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.85,
    int maxTokens = 512,
  }) async {
    final apiKey = _ref.read(openRouterApiKeyProvider);
    if (apiKey.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://neoncred.app',
          'X-Title': 'NEONCRED',
        },
        body: jsonEncode({
          'model': defaultModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = body['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return stripCodeFences(content);
          }
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Send a chat request and parse the response as JSON.
  ///
  /// Returns the parsed Map, or null on failure.
  Future<Map<String, dynamic>?> chatJson({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.85,
    int maxTokens = 512,
  }) async {
    final text = await chat(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    if (text == null) return null;

    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Strip markdown code fences (```json ... ```) from AI responses.
  static String stripCodeFences(String content) {
    var cleaned = content.trim();
    if (cleaned.startsWith('```')) {
      final firstNewline = cleaned.indexOf('\n');
      if (firstNewline != -1) {
        cleaned = cleaned.substring(firstNewline + 1);
      }
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }
}

/// Provider for the shared OpenRouter service.
final openRouterServiceProvider = Provider<OpenRouterService>((ref) {
  return OpenRouterService(ref);
});
