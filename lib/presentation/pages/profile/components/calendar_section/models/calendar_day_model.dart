class CalendarDayModel {
  const CalendarDayModel({
    required this.date,
    required this.isCurrentMonth,
    required this.isFuture,
    this.hasContent = false,
    this.thumbnailUrl,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isFuture;
  final bool hasContent;
  final String? thumbnailUrl;

  int get day => date.day;
}
