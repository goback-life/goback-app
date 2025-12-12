import 'package:cloudless/core/features/connection/domain/contracts/connection_repository_contract.dart';
import 'package:cloudless/core/features/permission/data/exceptions/contact_permission_denied_exception.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_status.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_type.dart';
import 'package:cloudless/core/features/permission/domain/providers/check_permission_status_provider.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/models/contact_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class GetContactWithPermissionUseCase
    implements UseCaseContract<FutureResult<List<ContactModel>>> {
  const GetContactWithPermissionUseCase({required this.repository});

  final ConnectionRepositoryContract repository;

  @override
  FutureResult<List<ContactModel>> execute() async {
    final permissionResult = await riverpodContainer().read(
      checkPermissionStatusProvider(type: PermissionType.contact).future,
    );

    return permissionResult.asyncFold(
      (permissionStatus) async {
        if (permissionStatus.status != PermissionStatus.granted) {
          if (permissionStatus.status == PermissionStatus.permanentlyDenied) {
            return Failure(
              ContactPermissionDeniedException(isPermanentlyDenied: true),
            );
          }
          return Failure(ContactPermissionDeniedException());
        }

        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: true,
        );

        final contactModels = contacts
            .where(
              (contact) =>
                  contact.phones.isNotEmpty && contact.displayName.isNotEmpty,
            )
            .map((contact) => _convertToContactModel(contact))
            .toList();

        return Success(contactModels);
      },
      (error) async {
        return Failure(ContactPermissionDeniedException());
      },
    );
  }

  ContactModel _convertToContactModel(Contact flutterContact) {
    return ContactModel(
      id: flutterContact.id,
      displayName: flutterContact.displayName,
      phoneNumbers: flutterContact.phones.map((phone) => phone.number).toList(),
      photo: flutterContact.photoOrThumbnail,
    );
  }
}
