import 'dart:async';

import 'package:cloudless/core/features/auth/domain/hooks/use_check_phone_numbers.dart';
import 'package:cloudless/core/features/auth/utilities/phone_number_normalizer.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_contact_with_permission.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_phone_contact.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/hooks/use_sms_launch.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/models/contact_model.dart';
import 'package:cloudless/presentation/pages/your_circle/components/invite_card_contacts.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Figma measurements (reference: 402x874 screen, card 371x600)
// ---------------------------------------------------------------------------

const _kCardRadius = 47.0;
const _kTitleGap = 13.0;
const _kSubtitleGap = 7.0;
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
// Main card
// ---------------------------------------------------------------------------

class _InviteCard extends HookConsumerWidget {
  const _InviteCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mq = MediaQuery.of(context);
    final cardWidth = mq.size.width - 24;
    final maxCardHeight = mq.size.height - 170;

    final controller = useTextEditingController();
    final input = useState('');
    final contactsData = useState<PhoneContactData?>(null);
    final getContacts = useContactWithPermission(ref);
    final inviteState = useSmsSender(ref);
    final debounce = useRef<Timer?>(null);
    final phoneToCheck = useState<String?>(null);

    final isPhone = useMemoized(() => looksLikePhone(input.value), [
      input.value,
    ]);

    // Load contacts once.
    useEffect(() {
      Future<void> load() async {
        final r = await getContacts();
        r.fold((d) {
          if (context.mounted) contactsData.value = d;
        }, (_) {});
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
        final digits = q.replaceAll(RegExp(r'[^\d]'), '');
        if (digits.isEmpty) return allContacts;
        return allContacts.where((c) {
          return c.phoneNumbers.any((p) {
            final normalized = p.replaceAll(RegExp(r'[^\d]'), '');
            return normalized.contains(digits);
          });
        }).toList();
      }
      final lower = q.toLowerCase();
      return allContacts.where((c) {
        return c.displayName.toLowerCase().contains(lower);
      }).toList();
    }, [allContacts, input.value, isPhone]);

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
      () => isPhone ? detectCountryFromPhone(input.value) : null,
      [input.value, isPhone],
    );

    // Dot colour: grey (search), accent (has goback), muted (phone).
    final colorScheme = Theme.of(context).colorScheme;
    final dotColor = useMemoized(() {
      if (!isPhone) return colorScheme.onSurface.withValues(alpha: 0.25);
      if (typedHasGoback) return MainColors.accent;
      return colorScheme.onSurface.withValues(alpha: 0.3);
    }, [isPhone, typedHasGoback, colorScheme]);

    // Handlers.
    void onContactTap(ContactModel c) {
      if (inviteState.isLoading) return;
      inviteState.sendInvite(c);
      Navigator.of(context).pop();
    }

    void onShare() {
      if (inviteState.isLoading) return;
      inviteState.shareInvite();
      Navigator.of(context).pop();
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: cardWidth,
            maxHeight: maxCardHeight,
          ),
          child: AppGlassContainer(
            config: const GlassConfig(
              tint: MainColors.accent,
              cornerRadius: _kCardRadius,
              opacity: 0.15,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            kInviteCardContactSidePad,
                            _kBottomPad,
                            kInviteCardContactSidePad,
                            0,
                          ),
                          child: InviteContactsList(
                            contacts: filteredContacts,
                            gobackPhones: gobackPhones,
                            showList: true,
                            onTap: onContactTap,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kInviteCardContactSidePad,
                          ),
                          child: InviteInputPill(
                            controller: controller,
                            onChanged: (t) => input.value = t,
                            dotColor: dotColor,
                            countryLabel: countryCode,
                            canSubmit: false,
                            onSend: () {},
                          ),
                        ),
                        const SizedBox(height: _kTitleGap),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kInviteCardContactSidePad,
                          ),
                          child: GestureDetector(
                            onTap: onShare,
                            child: SizedBox(
                              height: kInviteCardInputPillHeight,
                              child: AppGlassContainer(
                                config: const GlassConfig(
                                  tint: MainColors.accent,
                                  cornerRadius: kInviteCardInputPillRadius,
                                ),
                                child: const Center(
                                  child: Text(
                                    'Share invite link',
                                    style: TextStyle(
                                      fontFamily: MainFontFamilies.quicksand,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                      color: MainColors.dark,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: _kTitleGap),
                        const Text(
                          'Let them in',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: MainFontFamilies.quicksand,
                            fontWeight: FontWeight.w600,
                            fontSize: 27,
                            color: MainColors.dark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: _kSubtitleGap),
                        const Text(
                          'Invite a friend to your circle',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: MainFontFamilies.quicksand,
                            fontWeight: FontWeight.w400,
                            fontSize: 24,
                            color: MainColors.dark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: _kBottomPad),
                      ],
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
