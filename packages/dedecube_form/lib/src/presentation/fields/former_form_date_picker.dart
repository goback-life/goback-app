import 'package:dedecube_form/src/domain/former_control.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:reactive_date_time_picker/reactive_date_time_picker.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// A date/time picker field that binds to a [FormerControl] using [ReactiveDateTimePicker].
class FormerFormDatePicker extends StatelessWidget {
  const FormerFormDatePicker({
    required this.control,
    super.key,
    this.valueAccessor,
    this.validationMessages,
    this.showErrors,
    this.style,
    this.type = ReactiveDatePickerFieldType.date,
    this.decoration,
    this.showClearIcon = true,
    this.clearIcon = const Icon(Icons.clear),
    this.builder,
    this.useRootNavigator = true,
    this.cancelText,
    this.confirmText,
    this.helpText,
    this.getInitialDate,
    this.getInitialTime,
    this.dateFormat,
    this.firstDate,
    this.lastDate,
    this.datePickerEntryMode = DatePickerEntryMode.calendar,
    this.selectableDayPredicate,
    this.locale,
    this.textDirection,
    this.initialDatePickerMode = DatePickerMode.day,
    this.errorFormatText,
    this.errorInvalidText,
    this.fieldHintText,
    this.fieldLabelText,
    this.datePickerRouteSettings,
    this.keyboardType,
    this.anchorPoint,
    this.currentDate,
    this.barrierDismissible = true,
    this.barrierColor,
    this.barrierLabel,
    this.onDatePickerModeChange,
    this.timePickerEntryMode = TimePickerEntryMode.dial,
    this.timePickerRouteSettings,
    this.timePickerBarrierDismissible = true,
    this.timePickerBarrierColor,
    this.timePickerBarrierLabel,
    this.hourLabelText,
    this.minuteLabelText,
    this.timePickerErrorInvalidText,
    this.onEntryModeChanged,
    this.timePickerAnchorPoint,
    this.timePickerOrientation,
    this.onTap,
    this.errorBuilder,
    this.baseStyle,
    this.textAlign,
    this.textAlignVertical,
    this.expands = false,
    this.cursor = SystemMouseCursors.click,
    this.valueBuilder,
    this.switchToInputEntryModeIcon,
    this.switchToCalendarEntryModeIcon,
  });

  final FormerControl<DateTime> control;
  final reactive.ControlValueAccessor<DateTime, String>? valueAccessor;
  final Map<String, String Function(Object error)>? validationMessages;
  final reactive.ShowErrorsFunction<DateTime>? showErrors;
  final TextStyle? style;
  final ReactiveDatePickerFieldType type;
  final InputDecoration? decoration;
  final bool showClearIcon;
  final Widget clearIcon;
  final TransitionBuilder? builder;
  final bool useRootNavigator;
  final String? cancelText;
  final String? confirmText;
  final String? helpText;
  final GetInitialDate? getInitialDate;
  final GetInitialTime? getInitialTime;
  final intl.DateFormat? dateFormat;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DatePickerEntryMode datePickerEntryMode;
  final SelectableDayPredicate? selectableDayPredicate;
  final Locale? locale;
  final TextDirection? textDirection;
  final DatePickerMode initialDatePickerMode;
  final String? errorFormatText;
  final String? errorInvalidText;
  final String? fieldHintText;
  final String? fieldLabelText;
  final RouteSettings? datePickerRouteSettings;
  final TextInputType? keyboardType;
  final Offset? anchorPoint;
  final DateTime? currentDate;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;
  final ValueChanged<DatePickerEntryMode>? onDatePickerModeChange;
  final TimePickerEntryMode timePickerEntryMode;
  final RouteSettings? timePickerRouteSettings;
  final bool timePickerBarrierDismissible;
  final Color? timePickerBarrierColor;
  final String? timePickerBarrierLabel;
  final String? hourLabelText;
  final String? minuteLabelText;
  final String? timePickerErrorInvalidText;
  final EntryModeChangeCallback? onEntryModeChanged;
  final Offset? timePickerAnchorPoint;
  final Orientation? timePickerOrientation;
  final Future<DateTime?> Function(BuildContext context, DateTime? value)?
      onTap;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final TextStyle? baseStyle;
  final TextAlign? textAlign;
  final TextAlignVertical? textAlignVertical;
  final bool expands;
  final MouseCursor cursor;
  final Widget Function(BuildContext context, String? value)? valueBuilder;
  final Icon? switchToInputEntryModeIcon;
  final Icon? switchToCalendarEntryModeIcon;

  @override
  Widget build(BuildContext context) {
    return ReactiveDateTimePicker(
      formControl: control.internal,
      valueAccessor: valueAccessor,
      validationMessages: validationMessages,
      showErrors: showErrors,
      style: style,
      type: type,
      decoration: decoration,
      showClearIcon: showClearIcon,
      clearIcon: clearIcon,
      builder: builder,
      useRootNavigator: useRootNavigator,
      cancelText: cancelText,
      confirmText: confirmText,
      helpText: helpText,
      getInitialDate: getInitialDate,
      getInitialTime: getInitialTime,
      dateFormat: dateFormat,
      firstDate: firstDate,
      lastDate: lastDate,
      datePickerEntryMode: datePickerEntryMode,
      selectableDayPredicate: selectableDayPredicate,
      locale: locale,
      textDirection: textDirection,
      initialDatePickerMode: initialDatePickerMode,
      errorFormatText: errorFormatText,
      errorInvalidText: errorInvalidText,
      fieldHintText: fieldHintText,
      fieldLabelText: fieldLabelText,
      datePickerRouteSettings: datePickerRouteSettings,
      keyboardType: keyboardType,
      anchorPoint: anchorPoint,
      currentDate: currentDate,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      onDatePickerModeChange: onDatePickerModeChange,
      timePickerEntryMode: timePickerEntryMode,
      timePickerRouteSettings: timePickerRouteSettings,
      timePickerBarrierDismissible: timePickerBarrierDismissible,
      timePickerBarrierColor: timePickerBarrierColor,
      timePickerBarrierLabel: timePickerBarrierLabel,
      hourLabelText: hourLabelText,
      minuteLabelText: minuteLabelText,
      timePickerErrorInvalidText: timePickerErrorInvalidText,
      onEntryModeChanged: onEntryModeChanged,
      timePickerAnchorPoint: timePickerAnchorPoint,
      timePickerOrientation: timePickerOrientation,
      onTap: onTap,
      errorBuilder: errorBuilder,
      baseStyle: baseStyle,
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      expands: expands,
      cursor: cursor,
      valueBuilder: valueBuilder,
      switchToInputEntryModeIcon: switchToInputEntryModeIcon,
      switchToCalendarEntryModeIcon: switchToCalendarEntryModeIcon,
    );
  }
}
