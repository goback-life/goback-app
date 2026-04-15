import 'package:cloudless/core/features/nfc/data/services/nfc_service.dart';
import 'package:cloudless/core/features/nfc/domain/models/venue_tag_model.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// NFC scan button styled for the V1 feed (dark background, glass accent).
///
/// Shows a spinner while scanning and the NFC icon otherwise.
/// Calls [onTagDetected] when a valid GoBack venue tag is read.
class FeedNfcTagButton extends StatefulWidget {
  const FeedNfcTagButton({
    super.key,
    required this.onTagDetected,
    required this.nfcService,
    required this.scale,
  });

  final void Function(VenueTagModel venue) onTagDetected;
  final NfcService nfcService;

  /// The screen-width scale factor (`screenWidth / 402`).
  final double scale;

  @override
  State<FeedNfcTagButton> createState() => _FeedNfcTagButtonState();
}

class _FeedNfcTagButtonState extends State<FeedNfcTagButton> {
  bool _isScanning = false;

  Future<void> _startScan() async {
    logger.info(
      '[FeedNfcTagButton] _startScan called, isScanning=$_isScanning',
    );
    if (_isScanning) return;

    // Show spinner immediately so tap feedback is always visible.
    setState(() => _isScanning = true);
    logger.info('[FeedNfcTagButton] spinner shown, starting NFC read session');

    try {
      await widget.nfcService.startReadSession(
        onTagRead: (venue) {
          logger.info('[FeedNfcTagButton] tag read: ${venue.venueName}');
          if (mounted) {
            setState(() => _isScanning = false);
            widget.onTagDetected(venue);
          }
        },
        onInvalidTag: () {
          logger.warning('[FeedNfcTagButton] invalid tag scanned');
          if (mounted) setState(() => _isScanning = false);
        },
        onError: () {
          logger.warning('[FeedNfcTagButton] NFC session error');
          if (mounted) setState(() => _isScanning = false);
        },
      );
    } catch (e) {
      logger.error('[FeedNfcTagButton] Unexpected error', exception: e);
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = 54.0 * widget.scale;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _startScan,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: MainColors.white.withValues(alpha: 0.12),
          border: Border.all(
            color: MainColors.white.withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
        child: Center(
          child: _isScanning
              ? SizedBox(
                  width: 22 * widget.scale,
                  height: 22 * widget.scale,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: MainColors.white.withValues(alpha: 0.80),
                  ),
                )
              : Icon(
                  Icons.nfc_rounded,
                  color: MainColors.white.withValues(alpha: 0.80),
                  size: 26 * widget.scale,
                ),
        ),
      ),
    );
  }
}
