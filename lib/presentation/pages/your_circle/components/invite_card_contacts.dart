import 'package:cloudless/core/features/auth/utilities/phone_number_normalizer.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/models/contact_model.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Shared constants (must match invite_card_popup.dart)
// ---------------------------------------------------------------------------

const kInviteCardInputPillHeight = 63.0;
const kInviteCardInputPillRadius = 47.0;
const kInviteCardContactRowHeight = 59.0;
const kInviteCardAvatarSize = 39.0;
const kInviteCardDotSize = 10.0;
const kInviteCardContactSidePad = 20.0;

// ---------------------------------------------------------------------------
// Country code detection
// ---------------------------------------------------------------------------

const kCountryCodes = <String, String>{
  '1': 'US',
  '7': 'RU',
  '20': 'EG',
  '27': 'ZA',
  '30': 'GR',
  '31': 'NL',
  '32': 'BE',
  '33': 'FR',
  '34': 'ES',
  '36': 'HU',
  '39': 'IT',
  '40': 'RO',
  '41': 'CH',
  '43': 'AT',
  '44': 'UK',
  '45': 'DK',
  '46': 'SE',
  '47': 'NO',
  '48': 'PL',
  '49': 'DE',
  '51': 'PE',
  '52': 'MX',
  '53': 'CU',
  '54': 'AR',
  '55': 'BR',
  '56': 'CL',
  '57': 'CO',
  '58': 'VE',
  '60': 'MY',
  '61': 'AU',
  '62': 'ID',
  '63': 'PH',
  '64': 'NZ',
  '65': 'SG',
  '66': 'TH',
  '81': 'JP',
  '82': 'KR',
  '84': 'VN',
  '86': 'CN',
  '90': 'TR',
  '91': 'IN',
  '92': 'PK',
  '93': 'AF',
  '94': 'LK',
  '95': 'MM',
  '98': 'IR',
  '212': 'MA',
  '213': 'DZ',
  '216': 'TN',
  '218': 'LY',
  '220': 'GM',
  '221': 'SN',
  '234': 'NG',
  '254': 'KE',
  '255': 'TZ',
  '256': 'UG',
  '260': 'ZM',
  '263': 'ZW',
  '351': 'PT',
  '352': 'LU',
  '353': 'IE',
  '354': 'IS',
  '358': 'FI',
  '370': 'LT',
  '371': 'LV',
  '372': 'EE',
  '380': 'UA',
  '381': 'RS',
  '385': 'HR',
  '386': 'SI',
  '420': 'CZ',
  '421': 'SK',
  '852': 'HK',
  '853': 'MO',
  '886': 'TW',
  '960': 'MV',
  '961': 'LB',
  '962': 'JO',
  '963': 'SY',
  '964': 'IQ',
  '965': 'KW',
  '966': 'SA',
  '967': 'YE',
  '968': 'OM',
  '970': 'PS',
  '971': 'AE',
  '972': 'IL',
  '973': 'BH',
  '974': 'QA',
};

/// Returns ISO code (e.g. "US") if a valid country code prefix is detected.
String? detectCountryFromPhone(String input) {
  final stripped = input.replaceAll(RegExp(r'[^\d+]'), '');
  if (!stripped.startsWith('+') || stripped.length < 2) return null;
  final digits = stripped.substring(1);
  for (final len in [3, 2, 1]) {
    if (digits.length >= len) {
      final code = kCountryCodes[digits.substring(0, len)];
      if (code != null) return code;
    }
  }
  return null;
}

/// Whether [text] looks like a phone number (starts with digit or +).
bool looksLikePhone(String text) {
  final t = text.trim();
  if (t.isEmpty) return false;
  return t.startsWith('+') || RegExp(r'^\d').hasMatch(t);
}

/// Whether [phone] is a submittable phone number (+CC followed by 7-14 digits).
bool isValidPhone(String phone) {
  final stripped = phone.replaceAll(RegExp(r'[^\d+]'), '');
  return RegExp(r'^\+\d{7,15}$').hasMatch(stripped);
}

// ---------------------------------------------------------------------------
// Contacts list
// ---------------------------------------------------------------------------

class InviteContactsList extends StatelessWidget {
  const InviteContactsList({
    super.key,
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
      padding: const EdgeInsets.only(bottom: kInviteCardInputPillHeight / 2),
      itemCount: contacts.length,
      itemBuilder: (context, i) {
        final c = contacts[i];
        final norm = c.primaryPhoneNumber != null
            ? PhoneNumberNormalizer.normalize(c.primaryPhoneNumber!)
            : '';
        final hasGoback = norm.isNotEmpty && gobackPhones.contains(norm);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InviteContactRow(
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
// Contact row
// ---------------------------------------------------------------------------

class InviteContactRow extends StatelessWidget {
  const InviteContactRow({
    super.key,
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
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: kInviteCardContactRowHeight,
        child: AppGlassContainer(
          config: const GlassConfig(tint: MainColors.accent, cornerRadius: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: kInviteCardAvatarSize,
                  height: kInviteCardAvatarSize,
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
                        fontSize: kInviteCardAvatarSize * 0.4,
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
                Container(
                  width: kInviteCardDotSize,
                  height: kInviteCardDotSize,
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
// Input pill
// ---------------------------------------------------------------------------

class InviteInputPill extends StatelessWidget {
  const InviteInputPill({
    super.key,
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
      height: kInviteCardInputPillHeight,
      child: AppGlassContainer(
        config: const GlassConfig(
          tint: MainColors.accent,
          cornerRadius: kInviteCardInputPillRadius,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                Container(
                  width: kInviteCardDotSize,
                  height: kInviteCardDotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
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
                          'Share',
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
