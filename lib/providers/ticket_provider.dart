import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
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
  TicketApi _ticketApi;
  UserApi _userApi;

  final Set<Event> _eventSet = new HashSet();
  final Set<Ticket> _ticketSet = new HashSet();

  bool _ticketsActiveOnOtherDevice = false;

  UnmodifiableListView<Event> get eventList => UnmodifiableListView(_eventSet);
  bool get ticketsActiveOnOtherDevice => _ticketsActiveOnOtherDevice;
  UnmodifiableListView<Ticket> get userTicketList => UnmodifiableListView(_ticketSet);

  set databaseUtils(DatabaseUtils value) {
    _databaseUtils = value;
  }

  set eventApi(EventApi value) {
    _eventApi = value;
  }

  set ticketApi(TicketApi value) {
    _ticketApi = value;
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
    for (Ticket ticket in _ticketSet) {
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

    await _activateAllIssuedTickets(tickets);
    await _databaseUtils.storeTicketSet(tickets.toSet());

    final bool areTicketsActiveElsewhere = await _areTicketsActiveElsewhere(tickets);
    if (areTicketsActiveElsewhere) {
      _ticketsActiveOnOtherDevice = true;
    }

    _ticketSet.clear();
    _eventSet.clear();

    _ticketSet.addAll(tickets);
    _eventSet.addAll(await _buildEventSet(tickets, true));
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
    _ticketSet.clear();
    _ticketSet.addAll(tickets);
    _eventSet.addAll(await _buildEventSet(tickets, false));
    notifyListeners();
  }

  ///
  /// Calling this allows the user to access new ticket secrets causing the
  /// old device to lose access to tickets.
  ///
  Future<void> reactivateTickets() async {

    if (_ticketApi == null) {
      ApiClient foriaApiClient = await obtainForiaApiClient();
      _ticketApi = new TicketApi(foriaApiClient);
    }

    if (!ticketsActiveOnOtherDevice) {
      return;
    }

    Set<Ticket> newTickets = new Set<Ticket>();
    for (Ticket ticket in _ticketSet) {

      if (ticket.status != 'ACTIVE') {
        continue;
      }

      ActivationResult result;
      try {
        result = await _ticketApi.reactivateTicket(ticket.id);
      } on ApiException catch (ex) {
        debugPrint("### FORIA SERVER ERROR: reactivateTicket ###");
        debugPrint("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
        throw new Exception(ex.message);
      } catch (e) {
        debugPrint("### NETWORK ERROR: reactivateTicket Msg: ${e.toString()} ###");
        rethrow;
      }

      newTickets.add(result.ticket);
      final String ticketSecret = result.ticketSecret;
      await _databaseUtils.storeTicketSecret(ticket.id, ticketSecret);
    }

    _ticketSet.clear();
    _ticketSet.addAll(newTickets);

    debugPrint('Reactivated ${newTickets.length} tickets.');
    _ticketsActiveOnOtherDevice = false;
    notifyListeners();
  }

  ///
  /// Redeems the user ticket for an authenticated venue device.
  /// The result will be passed back to the UI to display to ticket scanner.
  ///
  /// If ALLOW is returned, the ticket has been redeemed in the backend system.
  ///
  Future<RedemptionResult> redeemTicket(final RedemptionRequest redemptionRequest) async {

    if (redemptionRequest == null) {
      return null;
    }

    if (_ticketApi == null) {
      ApiClient foriaApiClient = await obtainForiaApiClient();
      _ticketApi = new TicketApi(foriaApiClient);
    }

    RedemptionResult result;
    try {
     result = await _ticketApi.redeemTicket(redemptionRequest);
    } on ApiException catch (ex) {
      debugPrint("### FORIA SERVER ERROR: redeemTicket ###");
      debugPrint("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
      throw new Exception(ex.message);
    } catch (e) {
      debugPrint("### NETWORK ERROR: redeemTicket Msg: ${e.toString()} ###");
      rethrow;
    }

    debugPrint("TicketId: ${redemptionRequest.ticketId} reedeemed with result: ${result.status}");
    return result;
  }

  ///
  /// Checks the ticket set for tickets that are in ISSUED status.
  /// If tickets are in ISSUED status, tickets are activated and ticket secret
  /// is stored in local database.
  ///
  /// If stored, ticket set is updated to account for new status.
  ///
  Future<void> _activateAllIssuedTickets(final Set<Ticket> tickets) async {

    if (_ticketApi == null) {
      ApiClient foriaApiClient = await obtainForiaApiClient();
      _ticketApi = new TicketApi(foriaApiClient);
    }

    int ticketsActivated = 0;
    for (Ticket ticket in tickets) {

      if (ticket.status != 'ISSUED') {
        continue;
      }

      ActivationResult result;
      try {
        result = await _ticketApi.activateTicket(ticket.id);
      } on ApiException catch (ex) {
        debugPrint("### FORIA SERVER ERROR: activateTicket ###");
        debugPrint("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
        throw new Exception(ex.message);
      } catch (e) {
        debugPrint("### NETWORK ERROR: activateTicket Msg: ${e.toString()} ###");
        rethrow;
      }

      //Remove old ticket object and add new one containing updated status.
      ticket.status = result.ticket.status;

      ticketsActivated++;
      final String ticketSecret = result.ticketSecret;
      await _databaseUtils.storeTicketSecret(ticket.id, ticketSecret);
    }

    debugPrint('Activated $ticketsActivated tickets.');
  }

  ///
  /// Determines if ticket is active on a different device by checking for valid ticket secret.
  ///
  Future<bool> _areTicketsActiveElsewhere(final Set<Ticket> tickets) async {

    for (Ticket ticket in tickets) {

      //Only check tickets that are in active status.
      if (ticket.status != 'ACTIVE') {
        debugPrint('Ticket with ticketId: ${ticket.id} is not ACTIVE. Skipping ticket secret check.');
        continue;
      }

      final actualTicketSecretHex = ticket.secretHash;
      final String loadedTicketSecret = await _databaseUtils.getTicketSecret(ticket.id);

      if (loadedTicketSecret == null) {
        debugPrint('Failed to load ticket secret for ticketId: ${ticket.id}. Ticket is active on another device.');
        return true;
      }

      final List<int> loadedTicketSecretBytes = utf8.encode(loadedTicketSecret);
      final String loadedTicketSecretHashHex = sha512.convert(loadedTicketSecretBytes).toString();

      if (loadedTicketSecretHashHex != actualTicketSecretHex) {
        debugPrint('Server ticketId: ${ticket.id} hash: $actualTicketSecretHex does not equal stored hash: $loadedTicketSecretHashHex');
        return true;
      }
    }

    debugPrint('All tickets are ACTIVE and valid on this device.');
    return false;
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
  @visibleForTesting
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
