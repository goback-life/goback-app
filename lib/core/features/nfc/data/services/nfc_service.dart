import 'package:cloudless/core/features/nfc/domain/models/venue_tag_model.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/services.dart';

/// Reads GoBack venue NFC tags via a custom NFCNDEFReaderSession channel.
///
/// Uses NFCNDEFReaderSession (not NFCTagReaderSession) so only the NDEF
/// entitlement is required — no TAG entitlement needed.
///
/// Tag payload format (NDEF Text record, UTF-8):
///   GOBACK|{venue_id}|{venue_name}
class NfcService {
  static const _channel = MethodChannel('goback/nfc');
  static const _prefix = 'GOBACK|';

  /// Starts an NFC scanning session and shows the iOS native NFC sheet.
  Future<void> startReadSession({
    required void Function(VenueTagModel venue) onTagRead,
    void Function()? onInvalidTag,
    void Function()? onError,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'startNdefRead',
        'Hold your iPhone near a GoBack tag',
      );

      final type = result?['type'] as String?;
      if (type == 'success') {
        final text = result?['text'] as String?;
        final venue = text != null ? _parseVenueText(text) : null;
        if (venue != null) {
          onTagRead(venue);
        } else {
          onInvalidTag?.call();
        }
      } else if (type == 'invalid') {
        onInvalidTag?.call();
      } else if (type == 'error') {
        logger.error('[NfcService] NFC error: ${result?['message']}');
        onError?.call();
      }
      // 'cancelled' → user dismissed, no callback needed
    } on PlatformException catch (e, st) {
      logger.error(
        '[NfcService] Platform exception',
        exception: e,
        stackTrace: st,
      );
      onError?.call();
    } catch (e, st) {
      logger.error(
        '[NfcService] Unexpected error',
        exception: e,
        stackTrace: st,
      );
      onError?.call();
    }
  }

  Future<void> stopSession() async {
    // NFCNDEFReaderSession auto-stops after first read or user dismissal.
  }

  VenueTagModel? _parseVenueText(String text) {
    if (!text.startsWith(_prefix)) return null;
    final parts = text.split('|');
    // parts[0]='GOBACK', parts[1]=venue_id, parts[2..]=venue_name
    if (parts.length < 3) return null;
    final venueId = parts[1];
    final venueName = parts.sublist(2).join('|');
    if (venueId.isEmpty || venueName.isEmpty) return null;
    return VenueTagModel(venueId: venueId, venueName: venueName);
  }
}
