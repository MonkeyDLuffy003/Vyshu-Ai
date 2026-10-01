import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../memory/vyshu_memory.dart';

/// VyshuBrain — Hybrid Brain Router
/// 
/// Inspects connectivity status:
/// - Online: Routes prompt to the local proxy / AI synthesis endpoint (`http://127.0.0.1:8080/generate`)
/// - Offline: Fallbacks and returns a JSON error formatted with "Offline Mode"
///   (ready for MediaPipe on-device integration in Phase 2).
/// Automatically persists both prompt and response into the 14-Day VyshuMemory.
class VyshuBrain {
  final String proxyUrl;

  VyshuBrain({this.proxyUrl = 'http://127.0.0.1:8080/generate'});

  /// Checks whether device currently has an active internet connection.
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[VyshuBrain] Connectivity check error: $e');
      return false;
    }
  }

  /// Process user prompt through the hybrid routing architecture.
  Future<String> processCommand(String prompt) async {
    final online = await isOnline();

    if (!online) {
      // Offline fallback: Format as JSON error indicating Offline Mode
      final offlineResponse = jsonEncode({
        'status': 'error',
        'error': 'Offline Mode',
        'message': 'No internet connection detected. MediaPipe on-device synthesis standing by.',
        'prompt': prompt,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Save turn to 14-day local memory
      await VyshuMemory.saveMemory(
        prompt: prompt,
        response: offlineResponse,
        metadata: {'mode': 'offline', 'source': 'hybrid_router'},
      );

      return offlineResponse;
    }

    // Online: Route HTTP POST to local proxy
    try {
      final url = Uri.parse(proxyUrl);
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'prompt': prompt,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseBody = response.body;

        // Save turn to 14-day local memory
        await VyshuMemory.saveMemory(
          prompt: prompt,
          response: responseBody,
          metadata: {'mode': 'online', 'proxy': proxyUrl, 'status': 200},
        );

        return responseBody;
      } else {
        final errorResponse = jsonEncode({
          'status': 'error',
          'code': response.statusCode,
          'message': 'Proxy returned HTTP error: ${response.statusCode}',
          'body': response.body,
        });

        await VyshuMemory.saveMemory(
          prompt: prompt,
          response: errorResponse,
          metadata: {'mode': 'online', 'error': true, 'status': response.statusCode},
        );

        return errorResponse;
      }
    } catch (e) {
      debugPrint('[VyshuBrain] Error communicating with proxy ($proxyUrl): $e');
      
      final connectionErrorResponse = jsonEncode({
        'status': 'error',
        'error': 'Proxy Connection Failure',
        'message': e.toString(),
        'fallback': 'Falling back to safe local handling',
      });

      await VyshuMemory.saveMemory(
        prompt: prompt,
        response: connectionErrorResponse,
        metadata: {'mode': 'online', 'error': true, 'exception': e.toString()},
      );

      return connectionErrorResponse;
    }
  }
}
