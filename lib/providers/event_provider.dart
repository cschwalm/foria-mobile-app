import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:foria/utils/auth_utils.dart';
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
  EventApi _eventApi;

  final Map<String, Event> _eventMap = new Map<String, Event>();
  final MessageStream _errorStream = GetIt.instance<MessageStream>();

  EventProvider() {
    _authUtils = GetIt.instance<AuthUtils>();
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
    }

    //Cache results for future calls.
    for (Event event in events) {

      if (!isValidEvent(event)) {
        continue;
      }
      _eventMap[event.id] = event;
    }

    notifyListeners();

    debugPrint("${_eventMap.length} loaded from network to display to user.");
    return _eventMap.values.toList();
  }

  ///
  /// Returns a list of Attendees for a specific eventId from the server.
  /// Results are not cached
  ///
  Future<List<Attendee>> getAttendeesForEvent(final String eventId) async {

    if (_eventApi == null) {
      ApiClient foriaApiClient = await _authUtils.obtainForiaApiClient();
      _eventApi = new EventApi(foriaApiClient);
    }

    List<Attendee> attendees;
    try {
      attendees = await _eventApi.getAttendeesForEvent(eventId);
    } on ApiException catch (ex, stackTrace) {
      debugPrint("### FORIA SERVER ERROR: getAttendeesForEvent ###");
      debugPrint("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
      _errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, ex, stackTrace));
      rethrow;
    } catch (ex, stackTrace) {
      debugPrint("### UNKNOWN ERROR: getAttendeesForEvent Msg: ${ex.toString()} ###");
      debugPrint(stackTrace.toString());
      _errorStream.announceError(ForiaNotification.error(MessageType.ERROR, netConnectionError, null, ex, stackTrace));
    }

    for (int i = 0; i < attendees.length; i++) {
      if (!isValidAttendee(attendees[i])) {
        attendees.removeAt(i);
      }
    }

    debugPrint("${attendees.length} attendees loaded from network to display to user.");
    return attendees;
  }

  ///
  /// If any fields related to an event are null, method returns false
  ///
  bool isValidAttendee(Attendee attendee) {
    if (attendee == null) {
      _errorStream.reportError('Error in event_provider: An Attendee is null',null);
      return false;
    }
    if (attendee.ticketId == null) {
      _errorStream.reportError('Error in event_provider: An Attendee ticket ID is null',null);
      return false;
    }
    if (attendee.ticket == null) {
      _errorStream.reportError('Error in event_provider: An Attendee ticket is null',null);
      return false;
    }
    if (attendee.firstName == null) {
      _errorStream.reportError('Error in event_provider: An Attendee fistName for ticketId ${attendee.ticketId} null',null);
      return false;
    }
    if (attendee.lastName == null) {
      _errorStream.reportError('Error in event_provider: An Attendee lastName for ticketId ${attendee.ticketId} null',null);
      return false;
    }
    if (attendee.userId == null) {
      _errorStream.reportError('Error in event_provider: An Attendee userName for ticketId ${attendee.ticketId} null',null);
      return false;
    }
    return true;
  }

  ///
  /// If any fields related to an event are null, method returns false
  ///
  bool isValidEvent(Event event) {
    if (event == null) {
      _errorStream.reportError('Error in event_provider: An Event is null',null);
      return false;
    }
    if (event.id == null) {
      _errorStream.reportError('Error in event_provider: An Event ID is null',null);
      return false;
    }
    if (event.startTime == null) {
      _errorStream.reportError('Error in event_provider: Event ID ${event.id} has startTime null',null);
      return false;
    }
    if (event.endTime == null) {
      _errorStream.reportError('Error in event_provider: Event ID ${event.id} has endTime null',null);
      return false;
    }
    if (DateTime.now().isAfter(event.endTime)) {
      _errorStream.reportError('Error in event_provider: Event ID ${event.id} has startTime null',null);
      return false;
    }
    if (event.address == null) {
      _errorStream.reportError('Error in event_provider: Event ID ${event.id} has address null',null);
      return false;
    }
    if (event.imageUrl == null) {
      _errorStream.reportError('Error in event_provider: Event ID ${event.id} has imageUrl null',null);
      return false;
    }
    if (event.ticketTypeConfig == null) {
      _errorStream.reportError('Error in event_provider: Event ID ${event.id} has ticketTypeConfig null',null);
      return false;
    }
    if (event.ticketTypeConfig.isEmpty) {
      _errorStream.reportError('Error in event_provider: Event ID ${event.id} has ticketTypeConfig list empty',null);
      return false;
    }
    for (TicketTypeConfig tier in event.ticketTypeConfig) {

      if (tier.amountRemaining == null) {
        _errorStream.reportError('Error in event_provider: tier ID ${tier.id} has amount remaining null',null);
        return false;
      }
      if (tier.price == null) {
        _errorStream.reportError('Error in event_provider: tier ID ${tier.id} has price null',null);
        return false;
      }
      if (tier.calculatedFee == null) {
        _errorStream.reportError('Error on ExploreEventsTab: tier ID ${tier.id} has calculatedFee null',null);
        return false;
      }
      if (tier.currency == null) {
        _errorStream.reportError('Error in event_provider: tier ID ${tier.id} has currency null',null);
        return false;
      }
    }
    return true;
  }
}
