/// Data read from a GoBack NFC venue tag.
///
/// Tag format (NDEF Text record): GOBACK|{venue_id}|{venue_name}
/// Example: GOBACK|a1b2c3d4|The Dunvegan
class VenueTagModel {
  const VenueTagModel({required this.venueId, required this.venueName});

  final String venueId;
  final String venueName;
}
