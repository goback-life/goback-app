// Copyright 2020 Joan Pablo Jimenez Milian. All rights reserved.
// Use of this source code is governed by the MIT license that can be
// found in the LICENSE file.

import 'package:dedecube_form/src/domain/former_abstract_control.dart';
import 'package:dedecube_form/src/domain/typedefs/former_validator_typedef.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// A wrapper for [Validator] that allows it to be used with [FormerAbstractControl].
abstract class FormerValidator<T> extends Validator<T> {
  const FormerValidator();

  /// Validates the [FormerAbstractControl] by delegating to [validateFormer].
  Map<String, dynamic>? validateFormer(FormerAbstractControl<T> control);

  @override
  Map<String, dynamic>? validate(AbstractControl<T> control) {
    return validateFormer(FormerAbstractControl<T>(control));
  }

  /// Converts this [FormerValidator] to a [FormerControlValidator] function.
  FormerControlValidator<T> asFormerControlValidator() =>
      (control) => validateFormer(control.toAbstract());
}
