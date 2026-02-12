import 'dart:async';

import 'package:cloudless/core/features/auth/domain/hooks/use_check_phone_numbers.dart';
import 'package:cloudless/core/features/auth/utilities/phone_number_normalizer.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_contact_with_permission.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_phone_contact.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/hooks/use_sms_launch.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/models/contact_model.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Figma measurements (reference: 402x874 screen, card 371x600)
// ---------------------------------------------------------------------------

const _kCardRadius = 47.0;
const _kInputPillHeight = 63.0;
const _kInputPillRadius = 47.0;
const _kContactRowHeight = 59.0;
const _kAvatarSize = 39.0;
const _kDotSize = 10.0;
const _kContactSidePad = 20.0; // horizontal pad inside contacts area
const _kTitleGap = 13.0; // input bottom → title
const _kSubtitleGap = 7.0; // title bottom → subtitle
const _kBottomPad = 30.0;

/// Shows the invite card as a fade-in modal overlay (no screen darkening).
Future<void> showInviteCardPopup(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss invite card',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (context, anim, _, child) =>
        FadeTransition(opacity: anim, child: child),
    pageBuilder: (context, _, __) => const Center(child: _InviteCard()),
  );
}

// ---------------------------------------------------------------------------
// Country code detection
// ---------------------------------------------------------------------------

const _kCountryCodes = <String, String>{
  '1': 'US', '7': 'RU', '20': 'EG', '27': 'ZA', '30': 'GR', '31': 'NL',
  '32': 'BE', '33': 'FR', '34': 'ES', '36': 'HU', '39': 'IT', '40': 'RO',
  '41': 'CH', '43': 'AT', '44': 'UK', '45': 'DK', '46': 'SE', '47': 'NO',
  '48': 'PL', '49': 'DE', '51': 'PE', '52': 'MX', '53': 'CU', '54': 'AR',
  '55': 'BR', '56': 'CL', '57': 'CO', '58': 'VE', '60': 'MY', '61': 'AU',
  '62': 'ID', '63': 'PH', '64': 'NZ', '65': 'SG', '66': 'TH', '81': 'JP',
  '82': 'KR', '84': 'VN', '86': 'CN', '90': 'TR', '91': 'IN', '92': 'PK',
  '93': 'AF', '94': 'LK', '95': 'MM', '98': 'IR',
  '212': 'MA', '213': 'DZ', '216': 'TN', '218': 'LY', '220': 'GM',
  '221': 'SN', '234': 'NG', '254': 'KE', '255': 'TZ', '256': 'UG',
  '260': 'ZM', '263': 'ZW', '351': 'PT', '352': 'LU', '353': 'IE',
  '354': 'IS', '358': 'FI', '370': 'LT', '371': 'LV', '372': 'EE',
  '380': 'UA', '381': 'RS', '385': 'HR', '386': 'SI', '420': 'CZ',
  '421': 'SK', '852': 'HK', '853': 'MO', '886': 'TW',
  '960': 'MV', '961': 'LB', '962': 'JO', '963': 'SY', '964': 'IQ',
  '965': 'KW', '966': 'SA', '967': 'YE', '968': 'OM', '970': 'PS',
  '971': 'AE', '972': 'IL', '973': 'BH', '974': 'QA',
};

/// Returns ISO code (e.g. "US") if a valid country code prefix is detected.
String? _detectCountry(String input) {
  final stripped = input.replaceAll(RegExp(r'[^\d+]'), '');
  if (!stripped.startsWith('+') || stripped.length < 2) return null;
  final digits = stripped.substring(1);
  // Try longest prefix first (3 → 2 → 1).
  for (final len in [3, 2, 1]) {
    if (digits.length >= len) {
      final code = _kCountryCodes[digits.substring(0, len)];
      if (code != null) return code;
    }
  }
  return null;
}

/// Whether [text] looks like a phone number (starts with digit or +).
bool _looksLikePhone(String text) {
  final t = text.trim();
  if (t.isEmpty) return false;
  return t.startsWith('+') || RegExp(r'^\d').hasMatch(t);
}

/// Whether [phone] is a submittable phone number (+CC followed by 7-14 digits).
bool _isValidPhone(String phone) {
  final stripped = phone.replaceAll(RegExp(r'[^\d+]'), '');
  return RegExp(r'^\+\d{7,15}$').hasMatch(stripped);
}

// ---------------------------------------------------------------------------
// Main card
// ---------------------------------------------------------------------------

class _InviteCard extends HookConsumerWidget {
  const _InviteCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mq = MediaQuery.of(context);
    final cardWidth = mq.size.width - 24; // match post detail card
    final maxCardHeight = mq.size.height - 170; // match post detail card

    final controller = useTextEditingController();
    final input = useState('');
    final contactsData = useState<PhoneContactData?>(null);
    final getContacts = useContactWithPermission(ref);
    final inviteState = useSmsSender(ref);
    final debounce = useRef<Timer?>(null);
    final phoneToCheck = useState<String?>(null);

    final isPhone = useMemoized(
      () => _looksLikePhone(input.value),
      [input.value],
    );

    // Load contacts once.
    useEffect(() {
      Future<void> load() async {
        final r = await getContacts();
        r.fold(
          (d) {
            if (context.mounted) contactsData.value = d;
          },
          (_) {},
        );
      }

      load();
      return () => debounce.value?.cancel();
    }, []);

    // All contacts flat sorted.
    final allContacts = useMemoized(() {
      final data = contactsData.value;
      if (data == null) return <ContactModel>[];
      return data.groupedContacts.values.expand((l) => l).toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
    }, [contactsData.value]);

    // Filter contacts — works for both name and phone search.
    final filteredContacts = useMemoized(() {
      final q = input.value.trim();
      if (q.isEmpty) return allContacts;
      if (isPhone) {
        // Phone mode: search contacts by normalized number.
        final digits = q.replaceAll(RegExp(r'[^\d]'), '');
        if (digits.isEmpty) return allContacts;
        return allContacts.where((c) {
          return c.phoneNumbers.any((p) {
            final normalized = p.replaceAll(RegExp(r'[^\d]'), '');
            return normalized.contains(digits);
          });
        }).toList();
      }
      // Name search.
      final lower = q.toLowerCase();
      return allContacts.where((c) {
        return c.displayName.toLowerCase().contains(lower);
      }).toList();
    }, [allContacts, input.value, isPhone]);

    // In phone mode with no contact matches → "new number" entry mode.
    final isNewNumber = isPhone && filteredContacts.isEmpty;

    // Debounced phone number checking (whenever in phone mode).
    useEffect(() {
      if (!isPhone) {
        phoneToCheck.value = null;
        return null;
      }
      debounce.value?.cancel();
      debounce.value = Timer(const Duration(milliseconds: 500), () {
        final n = PhoneNumberNormalizer.normalize(input.value);
        if (n.isNotEmpty) {
          phoneToCheck.value = n;
        }
      });
      return null;
    }, [input.value, isPhone]);

    // Bulk goback check for contact dots.
    final allContactPhones = useMemoized(() {
      return allContacts
          .where((c) => c.primaryPhoneNumber != null)
          .map((c) => PhoneNumberNormalizer.normalize(c.primaryPhoneNumber!))
          .where((p) => p.isNotEmpty)
          .toList();
    }, [allContacts]);
    final gobackPhones = useCheckPhoneNumbers(ref, allContactPhones);

    // Typed phone goback check.
    final typedList = useMemoized(
      () => phoneToCheck.value != null ? [phoneToCheck.value!] : <String>[],
      [phoneToCheck.value],
    );
    final typedResult = useCheckPhoneNumbers(ref, typedList);
    final typedHasGoback =
        phoneToCheck.value != null && typedResult.contains(phoneToCheck.value!);

    // Country code detection.
    final countryCode = useMemoized(
      () => isPhone ? _detectCountry(input.value) : null,
      [input.value, isPhone],
    );

    // Dot colour: grey (search), accent (has goback), muted white (phone).
    final dotColor = useMemoized(() {
      if (!isPhone) return const Color(0x66FFFFFF); // grey
      if (typedHasGoback) return MainColors.accent;
      return MainColors.white.withValues(alpha: 0.5);
    }, [isPhone, typedHasGoback]);

    // Can submit?
    final canSubmit = isNewNumber && _isValidPhone(input.value);

    // Handlers.
    void onContactTap(ContactModel c) {
      if (inviteState.isLoading) return;
      inviteState.sendInvite(c);
      Navigator.of(context).pop();
    }

    void onSendPhone() {
      if (!canSubmit || inviteState.isLoading) return;
      final phone = input.value.trim().replaceAll(RegExp(r'[^\d+]'), '');
      inviteState.sendInvite(ContactModel.fromPhoneNumber(phone));
      Navigator.of(context).pop();
    }

    return Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: cardWidth,
          maxHeight: maxCardHeight,
        ),
        child: AppGlassContainer(
          config: const GlassConfig(cornerRadius: _kCardRadius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Contacts area — shrinks to content, scrolls at max.
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _kContactSidePad, _kBottomPad, _kContactSidePad, 0,
                  ),
                  child: _ContactsList(
                    contacts: filteredContacts,
                    gobackPhones: gobackPhones,
                    showList: !isNewNumber,
                    onTap: onContactTap,
                  ),
                ),
              ),
              // Input pill.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _kContactSidePad),
                child: _InputPill(
                  controller: controller,
                  onChanged: (t) => input.value = t,
                  dotColor: dotColor,
                  countryLabel: countryCode,
                  canSubmit: canSubmit,
                  onSend: onSendPhone,
                ),
              ),
              const SizedBox(height: _kTitleGap),
              // Title.
              const Text(
                'Let them in',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: MainFontFamilies.quicksand,
                  fontWeight: FontWeight.w600,
                  fontSize: 27,
                  color: MainColors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: _kSubtitleGap),
              // Subtitle.
              const Text(
                'Invite a friend to your circle',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: MainFontFamilies.quicksand,
                  fontWeight: FontWeight.w400,
                  fontSize: 24,
                  color: MainColors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: _kBottomPad),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Contacts list
// ---------------------------------------------------------------------------

class _ContactsList extends StatelessWidget {
  const _ContactsList({
    required this.contacts,
    required this.gobackPhones,
    required this.showList,
    required this.onTap,
  });

  final List<ContactModel> contacts;
  final Set<String> gobackPhones;
  final bool showList;
  final ValueChanged<ContactModel> onTap;

  @override
  Widget build(BuildContext context) {
    if (!showList || contacts.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      reverse: true,
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: _kInputPillHeight / 2),
      itemCount: contacts.length,
      itemBuilder: (context, i) {
        final c = contacts[i];
        final norm = c.primaryPhoneNumber != null
            ? PhoneNumberNormalizer.normalize(c.primaryPhoneNumber!)
            : '';
        final hasGoback = norm.isNotEmpty && gobackPhones.contains(norm);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ContactRow(
            contact: c,
            hasGoback: hasGoback,
            onTap: () => onTap(c),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Contact row — glass with accent tint, matching Figma row layout
// ---------------------------------------------------------------------------

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.contact,
    required this.hasGoback,
    required this.onTap,
  });

  final ContactModel contact;
  final bool hasGoback;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: _kContactRowHeight,
        child: AppGlassContainer(
          config: const GlassConfig(
            tint: MainColors.accent,
            cornerRadius: 16,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Avatar placeholder.
                Container(
                  width: _kAvatarSize,
                  height: _kAvatarSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: MainColors.accent,
                  ),
                  child: Center(
                    child: Text(
                      contact.displayName.isNotEmpty
                          ? contact.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontFamily: MainFontFamilies.quicksand,
                        fontWeight: FontWeight.w500,
                        fontSize: _kAvatarSize * 0.4,
                        color: MainColors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.displayName,
                        style: const TextStyle(
                          fontFamily: MainFontFamilies.quicksand,
                          fontWeight: FontWeight.w500,
                          fontSize: 20,
                          color: MainColors.white,
                          letterSpacing: -1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (contact.primaryPhoneNumber != null)
                        Text(
                          contact.primaryPhoneNumber!,
                          style: const TextStyle(
                            fontFamily: MainFontFamilies.quicksand,
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: Color(0x99FFFFFF),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Goback indicator dot.
                Container(
                  width: _kDotSize,
                  height: _kDotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasGoback
                        ? MainColors.accent
                        : MainColors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input pill — accent 20% tint, status dot always inside on the right
// ---------------------------------------------------------------------------

class _InputPill extends StatelessWidget {
  const _InputPill({
    required this.controller,
    required this.onChanged,
    required this.dotColor,
    required this.countryLabel,
    required this.canSubmit,
    required this.onSend,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Color dotColor;
  final String? countryLabel;
  final bool canSubmit;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kInputPillHeight,
      child: AppGlassContainer(
        config: const GlassConfig(
          tint: MainColors.accent,
          cornerRadius: _kInputPillRadius,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Text input.
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    onSubmitted: canSubmit ? (_) => onSend() : null,
                    maxLength: 30,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      fontFamily: MainFontFamilies.quicksand,
                      fontWeight: FontWeight.w500,
                      fontSize: 20,
                      color: MainColors.white,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Phone or name...',
                      hintStyle: TextStyle(
                        fontFamily: MainFontFamilies.quicksand,
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                        color: Color(0x66FFFFFF),
                      ),
                    ),
                  ),
                ),
              // Country code label (fades in when detected).
              if (countryLabel != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    countryLabel!,
                    style: const TextStyle(
                      fontFamily: MainFontFamilies.quicksand,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: Color(0x99FFFFFF),
                    ),
                  ),
                ),
              // Status dot — always visible.
              Container(
                width: _kDotSize,
                height: _kDotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              // Send button — appears only with valid phone number.
              if (canSubmit)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: onSend,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: MainColors.accent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Send',
                        style: TextStyle(
                          fontFamily: MainFontFamilies.quicksand,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: MainColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
