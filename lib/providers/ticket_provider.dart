import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:foria/utils/utils.dart';
import 'package:foria_flutter_client/api.dart';

///
/// Provides access to Ticket related data from the Foria backend.
///
/// Utils packages abstracts away token retrieval and this provider uses generated
/// API clients and models to expose data from the underlying REST API.
///
class TicketProvider extends ChangeNotifier {

  EventApi _eventApi;

  final Set<Event> _eventList = new HashSet();
  final Set<Ticket> _ticketList = HashSet();

  final HashMap<String, Event> _eventMap = new HashMap();
  final HashMap<String, Venue> _venueMap = new HashMap();

  UnmodifiableListView<Event> get eventList => UnmodifiableListView(_eventList);
  UnmodifiableListView<Ticket> get userTicketList => UnmodifiableListView(_ticketList);

  set eventApi(EventApi value) {
    _eventApi = value;
  }

  ///
  /// Obtains the latest set of Tickets for the authenticated user.
  ///
  Future<void> fetchUserTickets() async {
    ApiClient foriaApiClient = await obtainForiaApiClient();

    UserApi userApi = new UserApi(foriaApiClient);
    List<Ticket> tickets;

    try {
      tickets = await userApi.getTickets();
    } on ApiException catch (ex) {
      print("### FORIA SERVER ERROR: getTickets ###");
      print("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
      rethrow;
    }
    _ticketList.addAll(tickets);

    //Create a list of unique events for the set of user tickets.
    Set<String> processedEventIdSet = new HashSet();
    for (Ticket ticket in _ticketList) {
      if (!processedEventIdSet.contains(ticket.eventId)) {
        Event event = await fetchEventById(ticket.eventId);
        _eventList.add(event);
        processedEventIdSet.add(ticket.eventId);
      }
    }

    notifyListeners();
  }

  Future<Event> fetchEventById(String eventId) async {
    if (eventId.isEmpty) {
      return null;
    }

    if (_eventMap.containsKey(eventId)) {
      return _eventMap[eventId];
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

    _eventMap[eventId] = event;
    print("Added event to cache with ID: $eventId");
    return event;
  }

  Future<Venue> fetchVenueById(String venueId) async {
    if (venueId.isEmpty) {
      return null;
    }

    if (_venueMap.containsKey(venueId)) {
      return _venueMap[venueId];
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
    _venueMap[venueId] = venue;
    print("Added venue to cache with ID: $venueId");
    return venue;
  }
}
