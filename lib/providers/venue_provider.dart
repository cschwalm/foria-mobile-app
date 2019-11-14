import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';

///
/// Provides access to Venue related data from the Foria backend.
///
/// Utils packages abstracts away token retrieval and this provider uses generated
/// API clients and models to expose data from the underlying REST API.
///
class VenueProvider extends ChangeNotifier {

  AuthUtils _authUtils;
  VenueApi _venueApi;

  final MessageStream _errorStream = GetIt.instance<MessageStream>();

  VenueProvider() {
    _authUtils = GetIt.instance<AuthUtils>();
  }

  set venueApi(VenueApi value) {
    _venueApi = value;
  }

  ///
  /// Returns a list of events from the server.
  /// The first time this is run, the results are cached to prevent multiple network requests per app use.
  ///
  Future<List<Event>> getAllVenuesEvents() async {

    List<Event> venueEvents;
    List<Venue> venues;


    if (_venueApi == null) {
      ApiClient foriaApiClient = await _authUtils.obtainForiaApiClient();
      _venueApi = new VenueApi(foriaApiClient);
    }

    try {
      venues = await _venueApi.getAllVenues();
    } on ApiException catch (ex, stackTrace) {
      print("### FORIA SERVER ERROR: getAllVenues ###");
      print("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
      _errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, ex, stackTrace));
      rethrow;
    } catch (ex, stackTrace) {
      print("### UNKNOWN ERROR: getAllVenues Msg: ${ex.toString()} ###");
      _errorStream.announceError(ForiaNotification.error(MessageType.ERROR, netConnectionError, null, ex, stackTrace));
      rethrow;
    }

    for (Venue venue in venues) {

      for (Event event in venue.events) {
        venueEvents.add(event);
      }
    }

    debugPrint("${venueEvents.length} venueEvents loaded from network to display to user.");
    return venueEvents;
  }
}
