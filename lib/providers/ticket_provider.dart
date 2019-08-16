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

  DatabaseUtils _databaseUtils = new DatabaseUtils();
  EventApi _eventApi;
  UserApi _userApi;

  final Set<Event> _eventList = new HashSet();
  final Set<Ticket> _ticketList = new HashSet();

  UnmodifiableListView<Event> get eventList => UnmodifiableListView(_eventList);
  UnmodifiableListView<Ticket> get userTicketList => UnmodifiableListView(_ticketList);

  set databaseUtils(DatabaseUtils value) {
    _databaseUtils = value;
  }

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
  /// Obtains the latest set of Tickets for the authenticated user via network.
  ///
  /// Throws exception on network error.
  ///
  Future<void> loadUserDataFromNetwork() async {

    if (_userApi == null) {
      ApiClient foriaApiClient = await obtainForiaApiClient();
      _userApi = new UserApi(foriaApiClient);
    }

    Set<Ticket> tickets;
    try {
      tickets = (await _userApi.getTickets()).toSet();
    } on ApiException catch (ex) {
      print("### FORIA SERVER ERROR: getTickets ###");
      print("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
      throw new Exception(ex.message);
    } catch (e) {
      print("### UNKNOWN ERROR: getTickets Msg: ${e.toString()} ###");
      rethrow;
    }

    debugPrint("Loaded ${tickets.length} tickets from Foria API.");
    _databaseUtils.storeTicketSet(tickets.toSet());

    _ticketList.addAll(tickets);
    _eventList.addAll(await _buildEventSet(tickets, true));

    notifyListeners();
  }

  ///
  /// Obtains the latest set of Tickets for the authenticated user via database.
  ///
  Future<void> loadUserDataFromLocalDatabase() async {

    Set<Ticket> tickets = await _databaseUtils.getAllTickets();
    if (tickets == null) {
      debugPrint('No tickets stored in offline storage.');
      return;
    }

    debugPrint("Loaded ${tickets.length} tickets from offline database.");
    _ticketList.addAll(tickets);
    _eventList.addAll(await _buildEventSet(tickets, false));
    notifyListeners();
  }

  ///
  /// Create a list of unique events for the set of user tickets.
  ///
  Future<Set<Event>> _buildEventSet(Set<Ticket> tickets, bool forceRefresh) async {

    Set<Event> events = Set<Event>();

    Set<String> processedEventIdSet = new HashSet();
    for (Ticket ticket in tickets) {
      if (!processedEventIdSet.contains(ticket.eventId)) {
        Event event = forceRefresh ? await fetchEventByIdViaNetwork(ticket.eventId) : await fetchEventByIdViaDatabase(ticket.eventId);
        events.add(event);
        processedEventIdSet.add(ticket.eventId);
      }
    }

    return events;
  }

  ///
  /// Loads event information specified by eventId via API.
  /// Stores in local db for offline use.
  ///
  /// Throws exception on network error.
  ///
  Future<Event> fetchEventByIdViaNetwork(String eventId) async {

    if (eventId == null || eventId.isEmpty) {
      return null;
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

    debugPrint("EventId: $eventId loaded from network.");
    _databaseUtils.storeEvent(event);

    return event;
  }

  ///
  /// Loads event information specified by eventId via the database.
  /// Throws an exception if not found.
  ///
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
