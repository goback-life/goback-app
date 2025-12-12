
# Dedecube Form

Dedecube Form is a Flutter package for advanced form management. It provides a type-safe, modular system for handling form controls, groups, and validations, built on top of reactive forms. With Dedecube Form you can easily build, customize, and manage forms in your app.

## Installation

Add `dedecube_form` to your dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  dedecube_form:
    git:
      url: git@github.com:dedecube/dedecube-form.git
      ref: v0.0.25
```

## Defining Form Controls

Dedecube Form uses the concept of `FormerControl` to manage individual form fields. You can create a control with default values or custom validators:

```dart
final nameControl = FormerControl<String>(
  value: 'example',
  validators: [FormerValidators.required()],
);
```

## Creating Form Groups

Group your controls using `FormerGroup` to easily manage multiple form elements:

```dart
final formGroup = FormerGroup({
  'name': FormerControl<String>(
    value: 'example',
    validators: [FormerValidators.required()],
  ),
  'email': FormerControl<String>(
    validators: [FormerValidators.email()],
  ),
});
```

This encapsulates a collection of controls and also supports both synchronous and asynchronous validation.

## Building and Rendering Forms

To build your UI, wrap your form widgets using the `FormerForm` widget. It takes a `FormerGroup` and a child widget tree:

```dart
FormerForm(
  form: formGroup,
  child: Column(
    children: [
      FormerFormConsumer(
        builder: (context, form, child) {
          return FormerFormTextfield<String>(
            control: formGroup.control('password'),
            validationMessages: {
              'required': (_) => 'obbligatorio',
              'pattern': (error) {
                final Map errorMap = error as Map;
                final String value = errorMap['actualValue'] as String? ?? '';

                if (value.length < 8) {
                  return 'min 8 caratteri';
                } 

                return 'invalida';
              },
              'invalid': (_) => '',
            },
          ),
        },
      ),
      FormerFormConsumer(
        builder: (context, formGroup, child) {
          final isFormValid = formGroup.valid;
          return ElevatedButton(
            title: 'Submit',
            onPressed: isFormValid ? _handleSubmit : null,
          );
        },
      );
      // ... Additional form fields
    ],
  ),
);
```

## Custom Validators

Leverage built-in validators from `FormerValidators` or create your own:

```dart
Map<String, String>? customValidator(FormerControl<String> control) {
  if ((control.value?.length ?? 0) < 3) {
    return {'minLength': 'Too short!'};
  }
  return null;
}
```

Then provide this validator to your control for tailored validation behavior.

## Form Hooks

For a more declarative approach, use the `useForm` hook to build your forms. The hook returns the current form state along with a submission callback:

```dart
final form = useForm(
  controls: {
    'username': FormerControl<String>(
      validators: [FormerValidators.required()],
    ),
  },
  onSubmit: (values) async {
    // Process submission logic here.
    return successResult;
  },
  onSuccess: (values) {
    // Handle successful form submission.
  },
  onFailure: (errors) {
    // Handle form submission errors.
  },
);
```

This hook simplifies form submission, state tracking, and integrates with your business logic effortlessly.

**Supported Fields:**

- **FormerFormTextfield** ✅ – Standard text input fields.
- **FormerFormCheckbox** ✅ – Standard checkbox input field.
- **FormerFormCheckboxTile** ✅ – A list tile with checkbox input field.
- **FormerFormRadio** ✅ – Standard radio button input field.
- **FormerFormRadioTile** ✅ – A list tile with radio button input field.
- **FormerFormDropdown** ✅ – Standard dropdown input field.
- **FormerFormDatePicker** ✅ – Standard date picker input field.
- **FormerFormPincodeTextfield** ✅ – Dedicated input for pin code entries.
- **FormerFormValueListenable** ✅ – A widget that rebuilds when its value changes.


## License

Dedecube Form is released under the [MIT License](LICENSE).