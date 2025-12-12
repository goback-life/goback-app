import 'package:dedecube_form/src/domain/former_control.dart';
import 'package:dedecube_form/src/domain/former_group.dart';
import 'package:dedecube_form/src/domain/typedefs/former_validator_typedef.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// A collection of helper methods to convert reactive validators
/// into validators that work with [FormerControl] and [FormerGroup].
class FormerValidators {
  /// Converts a [reactive.Validator] into a [FormerControlValidator] for the control.
  ///
  /// The provided [validator] is applied to the internal control state.
  static FormerControlValidator<T> from<T>(
    reactive.Validator<dynamic> validator,
  ) {
    return (FormerControl<T> control) => validator.validate(control.internal);
  }

  /// Converts a [reactive.AsyncValidator] into a [FormerControlAsyncValidator] for the control.
  ///
  /// The provided asynchronous [validator] is applied to the control's internal state.
  static FormerControlAsyncValidator<T> asyncFrom<T>(
    reactive.AsyncValidator<dynamic> validator,
  ) {
    return (FormerControl<T> control) => validator.validate(control.internal);
  }

  /// Returns a validator that checks if the control's value is not null or empty.
  static FormerControlValidator<T> required<T>() =>
      from<T>(reactive.Validators.required);

  /// Returns a validator that checks if a boolean control's value is true.
  static FormerControlValidator<bool> requiredTrue() =>
      from<bool>(reactive.Validators.requiredTrue);

  /// Returns a validator that checks if the control's value is a valid email address.
  static FormerControlValidator<String> email() =>
      from<String>(reactive.Validators.email);

  /// Returns a validator that ensures the control's value has a minimum length of [min].
  static FormerControlValidator<String> minLength(int min) =>
      from<String>(reactive.Validators.minLength(min));

  /// Returns a validator that ensures the control's value does not exceed [max] length.
  static FormerControlValidator<String> maxLength(int max) =>
      from<String>(reactive.Validators.maxLength(max));

  /// Returns a validator that checks if the control's value matches a [pattern].
  ///
  /// An optional [validationMessage] can be provided to customize the error message.
  static FormerControlValidator<String> pattern(
    Pattern pattern, {
    String validationMessage = reactive.ValidationMessage.pattern,
  }) =>
      from<String>(
        reactive.Validators.pattern(
          pattern,
          validationMessage: validationMessage,
        ),
      );

  /// Returns a validator that checks if the control's value equals the specified [value].
  static FormerControlValidator<T> equals<T>(T value) =>
      from<T>(reactive.Validators.equals(value));

  /// Returns a validator that checks if the control's numerical value is not less than [min].
  static FormerControlValidator<num> min(num min) =>
      from<num>(reactive.Validators.min(min));

  /// Returns a validator that checks if the control's numerical value does not exceed [max].
  static FormerControlValidator<num> max(num max) =>
      from<num>(reactive.Validators.max(max));

  /// Returns a validator that checks if the control's value is a valid credit card number.
  static FormerControlValidator<String> creditCard() =>
      from<String>(reactive.Validators.creditCard);

  /// Returns a validator that checks if the control's value is a valid number.
  ///
  /// Parameters:
  /// - [allowNull]: Whether null values are permitted.
  /// - [allowedDecimals]: The maximum number of allowed decimal places.
  /// - [allowNegatives]: Whether negative numbers are allowed.
  static FormerControlValidator<String> number({
    bool allowNull = false,
    int allowedDecimals = 0,
    bool allowNegatives = true,
  }) =>
      from<String>(
        reactive.Validators.number(
          allowNull: allowNull,
          allowedDecimals: allowedDecimals,
          allowNegatives: allowNegatives,
        ),
      );

  /// Converts a [reactive.Validator] into a [FormerGroupValidator] for a group.
  ///
  /// The provided [validator] is applied to the group's internal state.
  static FormerGroupValidator fromGroup(
    reactive.Validator<dynamic> validator,
  ) {
    return (FormerGroup group) => validator.validate(group.internal);
  }

  /// Returns a group validator that ensures two controls have matching values.
  ///
  /// [controlName] is the name of the first control and [matchingControlName] is the name of the control
  /// to compare against. The [markAsDirty] parameter indicates whether to mark the control as dirty when
  /// the validation fails.
  static FormerGroupValidator mustMatch(
    String controlName,
    String matchingControlName, {
    bool markAsDirty = true,
  }) =>
      fromGroup(
        reactive.Validators.mustMatch(
          controlName,
          matchingControlName,
          markAsDirty: markAsDirty,
        ),
      );
}
