import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/database_utils.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';

///
/// Provides access to Event related data from the Foria backend.
///
/// Utils packages abstracts away token retrieval and this provider uses generated
/// API clients and models to expose data from the underlying REST API.
///
class EventProvider extends ChangeNotifier {

  AuthUtils _authUtils;
  DatabaseUtils _databaseUtils;
  EventApi _eventApi;

  final Map<String, Event> _eventMap = new Map<String, Event>();
  final MessageStream _errorStream = GetIt.instance<MessageStream>();

  EventProvider() {

    _authUtils = GetIt.instance<AuthUtils>();
    _databaseUtils = GetIt.instance<DatabaseUtils>();
  }

  /// Returns an unmodifiable list that is safe to iterate over.
  List<Event> get events => List.unmodifiable(_eventMap.values);

  set eventApi(EventApi value) {
    _eventApi = value;
  }

  ///
  /// Returns a list of events from the server.
  /// The first time this is run, the results are cached to prevent multiple network requests per app use.
  ///
  Future<List<Event>> getAllEvents() async {

    if (_eventMap.isNotEmpty) {
      return _eventMap.values.toList();
    }

    if (_eventApi == null) {
      ApiClient foriaApiClient = await _authUtils.obtainForiaApiClient();
      _eventApi = new EventApi(foriaApiClient);
    }

    List<Event> events;
    try {
      events = await _eventApi.getAllEvents();
    } on ApiException catch (ex, stackTrace) {
      print("### FORIA SERVER ERROR: getAllEvents ###");
      print("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
      _errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, ex, stackTrace));
      rethrow;
    } catch (ex, stackTrace) {
      print("### UNKNOWN ERROR: getAllEvents Msg: ${ex.toString()} ###");
      _errorStream.announceError(ForiaNotification.error(MessageType.ERROR, netConnectionError, null, ex, stackTrace));
      rethrow;
    }

    //Cache results for future calls.
    for (Event event in events) {
      _eventMap[event.id] = event;
    }

    debugPrint("${_eventMap.length} loaded from network to display to user.");
    return events;
  }

  ///
  /// Loads event information specified by eventId via API.
  /// Stores in local db for offline use.
  ///
  /// Throws exception on network error.
  ///
  @visibleForTesting
  Future<Event> fetchEventByIdViaNetwork(String eventId) async {

    if (eventId == null || eventId.isEmpty) {
      return null;
    }

    if (_eventApi == null) {
      ApiClient foriaApiClient = await _authUtils.obtainForiaApiClient();
      _eventApi = new EventApi(foriaApiClient);
    }

    Event event;
    try {
      event = await _eventApi.getEvent(eventId);
    } on ApiException catch (ex, stackTrace) {
      print("### FORIA SERVER ERROR: getEventById ###");
      print("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
      _errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, ex, stackTrace));
      rethrow;
    }

    debugPrint("EventId: $eventId loaded from network.");
    _databaseUtils.storeEvent(event);

    return event;
  }

  ///
  /// Loads event information specified by eventId via the database.
  /// Throws an exception if not found.
  ///
  @visibleForTesting
  Future<Event> fetchEventByIdViaDatabase(String eventId) async {

    if (eventId == null || eventId.isEmpty) {
      return null;
    }

    Event event = await _databaseUtils.getEvent(eventId);
    if (event == null) {
      throw new Exception('Expected eventId: $eventId not in local database.');
    }
    debugPrint("EventId: $eventId loaded from offline database.");
    return event;
  }
}
