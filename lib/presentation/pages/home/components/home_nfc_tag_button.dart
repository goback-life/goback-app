import 'package:cloudless/core/features/nfc/data/services/nfc_service.dart';
import 'package:cloudless/core/features/nfc/domain/models/venue_tag_model.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// A circular button that starts an NFC scan session.
///
/// When a valid GoBack venue tag is scanned, [onTagDetected] is called with
/// the parsed [VenueTagModel].
class HomeNfcTagButton extends StatefulWidget with MainLayout, HomeLayout {
  const HomeNfcTagButton({
    super.key,
    required this.onTagDetected,
    required this.nfcService,
  });

  final void Function(VenueTagModel venue) onTagDetected;
  final NfcService nfcService;

  @override
  State<HomeNfcTagButton> createState() => _HomeNfcTagButtonState();
}

class _HomeNfcTagButtonState extends State<HomeNfcTagButton>
    with MainLayout, HomeLayout {
  bool _isScanning = false;

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    await widget.nfcService.startReadSession(
      onTagRead: (venue) {
        if (mounted) {
          setState(() => _isScanning = false);
          widget.onTagDetected(venue);
        }
      },
      onInvalidTag: () {
        if (mounted) setState(() => _isScanning = false);
      },
      onError: () {
        if (mounted) setState(() => _isScanning = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _startScan,
      child: Container(
        padding: EdgeInsets.all(feedPostImageBorderRadius),
        width: createContentButtonSize,
        height: createContentButtonSize,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
        ),
        child: _isScanning
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primaryContainer,
                ),
              )
            : Icon(
                Icons.nfc_rounded,
                color: colorScheme.primaryContainer,
                size: 28,
              ),
      ),
    );
  }
}
