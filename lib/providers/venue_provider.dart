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

  final Map<String, Event> _venueEventMap = new Map<String, Event>();
  final MessageStream _errorStream = GetIt.instance<MessageStream>();

  VenueProvider() {
    _authUtils = GetIt.instance<AuthUtils>();
  }

  /// Returns an unmodifiable list that is safe to iterate over.
  List<Event> get venueEvents => List.unmodifiable(_venueEventMap.values);

  set venueApi(VenueApi value) {
    _venueApi = value;
  }

  ///
  /// Returns a list of events from the server.
  /// The first time this is run, the results are cached to prevent multiple network requests per app use.
  ///
  Future<List<Event>> getAllVenuesEvents() async {

    if (_venueApi == null) {
      ApiClient foriaApiClient = await _authUtils.obtainForiaApiClient();
      _venueApi = new VenueApi(foriaApiClient);
    }

    List<Venue> venues;
    try {
      venues = await _venueApi.getAllVenues();
    } on ApiException catch (ex, stackTrace) {

      if (ex.code == 403) {
        debugPrint("### NO PERMISSION: venue:read scope MISSING ###");
        await _authUtils.logout();
        return null;
      }

      debugPrint("### FORIA SERVER ERROR: getAllVenues ###");
      debugPrint("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
      _errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, ex, stackTrace));
      rethrow;
    } catch (ex, stackTrace) {
      debugPrint("### NETWORK ERROR: getAllVenues Msg: ${ex.toString()} ###");
      _errorStream.announceError(ForiaNotification.error(MessageType.ERROR, netConnectionError, null, ex, stackTrace));
    }

    //Cache results for future calls.
    for (Venue venue in venues) {

      for (Event event in venue.events) {
        _venueEventMap[event.id] = event;
      }
    }

    notifyListeners();

    debugPrint("${_venueEventMap.length} venueEvents loaded from network to display to user.");
    return _venueEventMap.values.toList();
  }
}
