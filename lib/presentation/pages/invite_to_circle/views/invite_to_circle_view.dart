import 'package:cloudless/core/features/connection/domain/hooks/use_contact_with_permission.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_phone_contact.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/components/form_field/custom_text_selection_controls.dart';
import 'package:cloudless/presentation/components/form_field/input_decoration.dart';
import 'package:cloudless/presentation/components/main_search_bar.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/components/invite_to_circle_contact_list.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/hooks/use_sms_launch.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/invite_to_circle_layout.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/models/contact_model.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/hooks/use_loading_overlay.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:phone_form_field/phone_form_field.dart';

class InviteToCircleView extends HookConsumerWidget
    with MainLayout, InviteToCircleLayout {
  const InviteToCircleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final getContactsWithPermission = useContactWithPermission(ref);
    final contactsData = useState<PhoneContactData?>(null);
    final searchQuery = useState<String>('');
    final inviteSendingState = useSmsSender(ref);

    final isLoading = useState(false);

    // Phone number input state
    final phoneFormKey = useMemoized(() => GlobalKey<FormState>());
    final phoneController = useMemoized(() => PhoneController());
    final phoneValidationError = useState<String?>(null);

    useEffect(() {
      Future<void> loadContacts() async {
        final result = await getContactsWithPermission();
        result.fold(
          (data) {
            if (context.mounted) {
              contactsData.value = data;
            }
          },
          (error) {
            if (context.mounted) {
              contactsData.value = PhoneContactData(
                groupedContacts: {},
                searchQuery: '',
                updateSearchQuery: (_) {},
                isLoading: false,
                hasPermission: false,
                isEmpty: true,
                error: error.toString(),
              );
            }
          },
        );
      }

      loadContacts();
      return null;
    }, []);

    // Create filtered contacts based on search query
    final filteredContactsData = useMemoized(() {
      final originalData = contactsData.value;
      if (originalData == null) {
        return null;
      }

      // If no search query, return original data but with working updateSearchQuery
      if (searchQuery.value.isEmpty) {
        return PhoneContactData(
          groupedContacts: originalData.groupedContacts,
          searchQuery: searchQuery.value,
          updateSearchQuery: (query) => searchQuery.value = query,
          isLoading: originalData.isLoading,
          hasPermission: originalData.hasPermission,
          isEmpty: originalData.isEmpty,
          error: originalData.error,
        );
      }

      // Filter contacts based on search query
      final filteredGroups = <String, List<ContactModel>>{};
      final query = searchQuery.value.toLowerCase();

      for (final entry in originalData.groupedContacts.entries) {
        final filteredContacts = entry.value.where((contact) {
          return contact.displayName.toLowerCase().contains(query) ||
              contact.phoneNumbers.any((phone) => phone.contains(query));
        }).toList();

        if (filteredContacts.isNotEmpty) {
          filteredGroups[entry.key] = filteredContacts;
        }
      }

      return PhoneContactData(
        groupedContacts: filteredGroups,
        searchQuery: searchQuery.value,
        updateSearchQuery: (query) => searchQuery.value = query,
        isLoading: originalData.isLoading,
        hasPermission: originalData.hasPermission,
        isEmpty: originalData.isEmpty,
        error: originalData.error,
      );
    }, [contactsData.value, searchQuery.value]);

    useEffect(() {
      if (isLoading.value != inviteSendingState.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            isLoading.value = inviteSendingState.isLoading;
          }
        });
      }
      return null;
    }, [inviteSendingState.isLoading]);

    useLoadingOverlay(isLoading);

    void handleContactTap(ContactModel contact) {
      if (!inviteSendingState.isLoading) {
        inviteSendingState.sendInvite(contact);
      }
    }

    Future<void> handleSendInviteToPhoneNumber() async {
      phoneValidationError.value = null;

      if (!phoneFormKey.currentState!.validate()) {
        return;
      }

      final phoneNumber = phoneController.value;

      // Validate phone number
      final validator = PhoneValidator.validMobile(
        context,
        errorText: translator.translate(
          'pages.invite_to_circle.error.phone_invalid',
        ),
      );
      final validationError = validator(phoneNumber);
      if (validationError != null) {
        phoneValidationError.value = validationError;
        return;
      }

      final phoneNumberString = phoneNumber.international;
      final contact = ContactModel.fromPhoneNumber(phoneNumberString);
      
      if (!inviteSendingState.isLoading) {
        await inviteSendingState.sendInvite(contact);
      }
    }

    if (filteredContactsData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredContactsData.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
          child: Text(
            translator.translate(
              'pages.invite_to_circle.no_contacts_available',
            ),
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          // Phone number input section
          Form(
            key: phoneFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translator.translate(
                    'pages.invite_to_circle.phone_number_label',
                  ),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                SizedBox(height: 4),
                Theme(
                  data: theme.copyWith(
                    textTheme: theme.textTheme,
                    appBarTheme: const AppBarTheme(
                      backgroundColor: MainColors.white,
                    ),
                  ),
                  child: PhoneFormField(
                    selectionControls: CustomTextSelectionControls(),
                    countrySelectorNavigator:
                        const CountrySelectorNavigator.dialog(),
                    onTapOutside: (event) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    controller: phoneController,
                    cursorColor: colorScheme.tertiary,
                    decoration: inputDecoration(context, ''),
                    validator: PhoneValidator.compose([
                      PhoneValidator.required(
                        context,
                        errorText: translator.translate(
                          'pages.invite_to_circle.error.phone_required',
                        ),
                      ),
                      PhoneValidator.validMobile(
                        context,
                        errorText: translator.translate(
                          'pages.invite_to_circle.error.phone_invalid',
                        ),
                      ),
                    ]),
                    isCountrySelectionEnabled: true,
                    isCountryButtonPersistent: true,
                    countryButtonStyle: CountryButtonStyle(
                      showDialCode: true,
                      showIsoCode: false,
                      showFlag: true,
                      textStyle: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    onChanged: (_) {
                      phoneValidationError.value = null;
                    },
                  ),
                ),
                if (phoneValidationError.value != null) ...[
                  SizedBox(height: 4),
                  Text(
                    phoneValidationError.value!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ],
                SizedBox(height: verticalSpacing / 2),
                CallToAction.primary.filled(
                  action: inviteSendingState.isLoading
                      ? null
                      : handleSendInviteToPhoneNumber,
                  label: Text(
                    translator.translate(
                      'pages.invite_to_circle.send_invite_button',
                    ),
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: verticalSpacing),
          MainSearchBar(
            searchQuery: searchQuery.value,
            onSearchChanged: (query) => searchQuery.value = query,
          ),
          SizedBox(height: verticalSpacing),
          InviteToCircleContactList(
            groupedContacts: filteredContactsData.groupedContacts,
            searchQuery: filteredContactsData.searchQuery,
            onSearchChanged: filteredContactsData.updateSearchQuery,
            onContactTap: handleContactTap,
          ),
        ],
      ),
    );
  }
}
