import 'package:cloudless/core/features/permission/domain/enums/permission_status.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_type.dart';
import 'package:dedecube_core/dedecube_core.dart';

abstract interface class PermissionServiceContract {
  /// Checks the current status of the given permission type.
  /// Returns a [PermissionStatus] wrapped in a [FutureResult].
  FutureResult<PermissionStatus> checkPermissionStatus(PermissionType type);

  /// Requests the specified permission from the user.
  /// Returns the resulting [PermissionStatus] wrapped in a [FutureResult].
  FutureResult<PermissionStatus> requestPermission(PermissionType type);

  /// Opens the app settings page where the user can manually change permissions.
  /// Returns a [FutureResult] that completes when the settings page is opened.
  FutureResult<void> openAppSettings();

  /// Determines whether the app should show a rationale (an explanatory message) to the user
  /// before requesting the given permission. This is typically true if the user has previously
  /// denied the permission, and the platform recommends explaining why the permission is needed
  /// before prompting again. Returns a [bool] wrapped in a [FutureResult].
  FutureResult<bool> shouldShowRationale(PermissionType type);
}
