import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/database_utils.dart';
import 'package:foria_flutter_client/api.dart';

///
/// Provides access to Ticket related data from the Foria backend.
///
/// Utils packages abstracts away token retrieval and this provider uses generated
/// API clients and models to expose data from the underlying REST API.
///
class TicketProvider extends ChangeNotifier {

  EventApi _eventApi;
  UserApi _userApi;

  final Set<Event> _eventList = new HashSet();
  final Set<Ticket> _ticketList = new HashSet();

  final DatabaseUtils _databaseUtils = new DatabaseUtils();

  UnmodifiableListView<Event> get eventList => UnmodifiableListView(_eventList);
  UnmodifiableListView<Ticket> get userTicketList => UnmodifiableListView(_ticketList);

  set eventApi(EventApi value) {
    _eventApi = value;
  }


  set userApi(UserApi value) {
    _userApi = value;
  }

  ///
  /// Returns a subset of tickets from the specified ticket ID.
  ///
  Set<Ticket> getTicketsForEventId(String eventId) {

    assert (eventId != null);

    Set<Ticket> tickets = new Set<Ticket>();
    for (Ticket ticket in _ticketList) {
      if (ticket.eventId == eventId) {
        tickets.add(ticket);
      }
    }

    return tickets;
  }

  ///
  /// Obtains the latest set of Tickets for the authenticated user.
  ///
  Future<void> loadUserData([bool forceRefresh = false]) async {

    Set<Ticket> tickets;
    if (!forceRefresh) {

      tickets = await _databaseUtils.getAllTickets();
      if (tickets != null) {

        _ticketList.addAll(tickets);
        _eventList.addAll(await _buildEventSet(tickets));
        return;
      }
    }

    if (_userApi == null) {
      ApiClient foriaApiClient = await obtainForiaApiClient();
      _userApi = new UserApi(foriaApiClient);
    }

    try {
      tickets = (await _userApi.getTickets()).toSet();
    } on ApiException catch (ex) {
      print("### FORIA SERVER ERROR: getTickets ###");
      print("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
      rethrow;
    }

    debugPrint("Loaded ${tickets.length} tickets from Foria API.");
    await _databaseUtils.storeTicketSet(tickets.toSet());

    _ticketList.addAll(tickets);
    _eventList.addAll(await _buildEventSet(tickets));

    notifyListeners();
  }

  ///
  /// Create a list of unique events for the set of user tickets.
  ///
  Future<Set<Event>> _buildEventSet(Set<Ticket> tickets) async {

    Set<Event> events = Set<Event>();

    Set<String> processedEventIdSet = new HashSet();
    for (Ticket ticket in tickets) {
      if (!processedEventIdSet.contains(ticket.eventId)) {
        Event event = await fetchEventById(ticket.eventId);
        events.add(event);
        processedEventIdSet.add(ticket.eventId);
      }
    }

    return events;
  }

  ///
  /// Loads event information specified by eventId.
  /// Stores in local db for offline use.
  ///
  Future<Event> fetchEventById(String eventId, [forceRefresh = false]) async {

    if (eventId == null || eventId.isEmpty) {
      return null;
    }

    if (!forceRefresh) {

      Event event = await _databaseUtils.getEvent(eventId);
      if (event != null) {
        debugPrint("EventId: $eventId loaded from offline database");
        return event;
      }
    }

    if (_eventApi == null) {
      ApiClient foriaApiClient = await obtainForiaApiClient();
      _eventApi = new EventApi(foriaApiClient);
    }

    Event event;
    try {
      event = await _eventApi.getEvent(eventId);
    } on ApiException catch (ex) {
      print("### FORIA SERVER ERROR: getEventById ###");
      print("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
      rethrow;
    }

    await _databaseUtils.storeEvent(event);
    return event;
  }

  Future<Venue> fetchVenueById(String venueId) async {
    if (venueId.isEmpty) {
      return null;
    }

    ApiClient foriaApiClient = await obtainForiaApiClient();
    VenueApi venueApi = new VenueApi(foriaApiClient);
    Venue venue;
    try {
      venue = await venueApi.getVenue(venueId);
    } on ApiException catch (ex) {
      print("### FORIA SERVER ERROR: getVenueById ###");
      print("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
      rethrow;
    }

    return venue;
  }
}
