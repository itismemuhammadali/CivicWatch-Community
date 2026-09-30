import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cctv_app/core/services/remote_config_service.dart';

class TelnyxSmsService {
  TelnyxSmsService._();
  static final TelnyxSmsService instance = TelnyxSmsService._();

  static const String _telnyxApiEndpoint = 'https://api.telnyx.com/v2/messages';

  /// Sends an invitation SMS to a defendant who is not registered on the app
  Future<bool> sendCollaborationInvite({
    required String toNumber,
    required String creatorName,
    required String caseTitle,
    String? customDownloadUrl,
  }) async {
    try {
      final remoteConfig = RemoteConfigService.instance;
      final apiKey = remoteConfig.telnyxApiKey;
      final fromNumber = remoteConfig.telnyxFromNumber;
      final downloadUrl = customDownloadUrl ?? remoteConfig.appDownloadUrl;

      if (apiKey.isEmpty) {
        debugPrint('TelnyxSmsService: API key is empty.');
        return false;
      }

      final formattedTo = _formatPhoneNumber(toNumber);
      if (formattedTo.isEmpty) {
        debugPrint('TelnyxSmsService: Invalid phone number: $toNumber');
        return false;
      }

      final sender = creatorName.trim().isNotEmpty ? creatorName.trim() : 'Someone';
      final title = caseTitle.trim().isNotEmpty ? '"${caseTitle.trim()}"' : 'a post';
      final messageText =
          '$sender tagged you in $title on CommCTV! Click the link to download the app and join the verdict: $downloadUrl';

      final requestBody = {
        'from': fromNumber,
        'to': formattedTo,
        'text': messageText,
      };

      final response = await http.post(
        Uri.parse(_telnyxApiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        debugPrint('Telnyx SMS Response [${response.statusCode}]: ${response.body}');
      }

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('TelnyxSmsService exception: $e');
      return false;
    }
  }

  String _formatPhoneNumber(String phone) {
    var cleaned = phone.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (!cleaned.startsWith('+')) {
      // Default to adding + if missing
      cleaned = '+$cleaned';
    }
    return cleaned;
  }
}
