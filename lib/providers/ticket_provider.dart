import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/database_utils.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';

///
/// Provides access to Ticket related data from the Foria backend.
///
/// Utils packages abstracts away token retrieval and this provider uses generated
/// API clients and models to expose data from the underlying REST API.
///
class TicketProvider extends ChangeNotifier {

  final String _fcmTokenKey = 'FCM_TOKEN';

  DatabaseUtils _databaseUtils;
  AuthUtils _authUtils;
  FlutterSecureStorage _secureStorage = new FlutterSecureStorage();

  EventApi _eventApi;
  TicketApi _ticketApi;
  UserApi _userApi;

  final Set<Event> _eventSet = new HashSet();
  final Set<Ticket> _ticketSet = new HashSet();

  final MessageStream _errorStream = GetIt.instance<MessageStream>();

  bool _ticketsActiveOnOtherDevice = false;

  UnmodifiableListView<Event> get eventList => UnmodifiableListView(_eventSet);
  bool get ticketsActiveOnOtherDevice => _ticketsActiveOnOtherDevice;
  UnmodifiableListView<Ticket> get userTicketList => UnmodifiableListView(_ticketSet);

  TicketProvider() {
    _authUtils = GetIt.instance<AuthUtils>();
    _databaseUtils = GetIt.instance<DatabaseUtils>();
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
      ApiClient foriaApiClient = await _authUtils.obtainForiaApiClient();
      _userApi = new UserApi(foriaApiClient);
    }

    Set<Ticket> tickets;
    try {
      tickets = (await _userApi.getTickets()).toSet();
    } on ApiException catch (ex, stackTrace) {

      debugPrint("### FORIA SERVER ERROR: getTickets ###");
      debugPrint("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
      debugPrint(stackTrace.toString());

      _errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, ex, stackTrace));

      if (ex.code == HttpStatus.unauthorized || ex.code == HttpStatus.forbidden) {
        debugPrint('Logging user out due to bad token.');
        await _authUtils.logout();
        return;
      }
      rethrow;
    } catch (e) {
      print("### UNKNOWN ERROR: getTickets Msg: ${e.toString()} ###");
      rethrow;
    }

    await checkAndSetDataFromNetwork(tickets);

    debugPrint("Loaded ${_ticketSet.length} tickets from Foria API.");

    await _activateAllIssuedTickets(_ticketSet);
    await _databaseUtils.storeTicketSet(_ticketSet);

    final bool areTicketsActiveElsewhere = await _areTicketsActiveElsewhere(_ticketSet);
    if (areTicketsActiveElsewhere) {
      _ticketsActiveOnOtherDevice = true;
    }

    notifyListeners();
  }

  ///
  /// Removes any tickets that are missing one or more important fields.
  /// Individually pulls via network all events for valid tickets. No duplicated events.
  /// Removes any events that are missing one or more important fields. When an event is removed
  /// all associated tickets would be removed too.
  ///
  /// One UI error displayed if any event or ticket is removed
  ///
  /// As a result of this method, _ticketSet and _eventSet are checked and set
  ///
  Future<void> checkAndSetDataFromNetwork(Set<Ticket> tickets) async {
    bool isError = false;

    Set<Ticket> checkedTickets = Set<Ticket>();
    Set<String> processedEventIdSet = new HashSet();

    _ticketSet.clear();
    _eventSet.clear();

    // Checks tickets
    for (Ticket ticket in tickets) {
      if (_isValidTicket(ticket)) {
        checkedTickets.add(ticket);
        _ticketSet.add(ticket);
      } else {
        debugPrint('Error: Ticket invalid');
        isError = true;
      }
    }

    // Checks events and removes tickets for invalid events
    for (Ticket ticket in checkedTickets) {
      if (processedEventIdSet.contains(ticket.eventId)) {
        continue;
      }
      Event event = await fetchEventByIdViaNetwork(ticket.eventId);
      if (_isValidEvent(event)) {
        _eventSet.add(event);
        processedEventIdSet.add(ticket.eventId);
      } else {
        isError = true;
        debugPrint('Error: Event invalid');
        _ticketSet.removeWhere((t) => t.id == ticket.id);
      }
    }

    if (isError){
      _errorStream.announceMessage(ForiaNotification.message(MessageType.MESSAGE, myPassesLoadError, null,));
    }
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
    _eventSet.addAll(await _buildEventSetFromLocalDatabase(tickets));
    notifyListeners();
  }

  ///
  /// Calling this allows the user to access new ticket secrets causing the
  /// old device to lose access to tickets.
  ///
  Future<void> reactivateTickets() async {

    if (_ticketApi == null) {
      ApiClient foriaApiClient = await _authUtils.obtainForiaApiClient();
      _ticketApi = new TicketApi(foriaApiClient);
    }

    if (!ticketsActiveOnOtherDevice) {
      return;
    }

    Set<Ticket> newTickets = new Set<Ticket>();
    for (Ticket ticket in _ticketSet) {

      if (ticket.status != ticketStatusActive && ticket.status != ticketStatusTransferPending) {
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
      ApiClient foriaApiClient = await _authUtils.obtainForiaApiClient();
      _ticketApi = new TicketApi(foriaApiClient);
    }

    RedemptionResult result;
    try {
      result = await _ticketApi.redeemTicket(redemptionRequest);
    } on ApiException catch (ex, stackTrace) {
      debugPrint("### FORIA SERVER ERROR: redeemTicket ###");
      debugPrint("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
      _errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, ex, stackTrace));
      throw new Exception(ex.message);
    } catch (e) {
      debugPrint("### NETWORK ERROR: redeemTicket Msg: ${e.toString()} ###");
      _errorStream.announceError(ForiaNotification.error(MessageType.NETWORK_ERROR, netConnectionError, null, null, null));
      rethrow;
    }

    debugPrint("TicketId: ${redemptionRequest.ticketId} reedeemed with result: ${result.status}");
    return result;
  }

  ///
  /// Manually redeems a user ticket for an authenticated venue device without the scanner.
  ///
  /// If there is no exception and the returned Ticket status is REDEEMED,
  /// the ticket has been redeemed in the backend system.
  ///
  Future<Ticket> manualRedeemTicket(final String ticketId) async {

    if (ticketId == null) {
      return null;
    }

    if (_ticketApi == null) {
      ApiClient foriaApiClient = await _authUtils.obtainForiaApiClient();
      _ticketApi = new TicketApi(foriaApiClient);
    }

    Ticket result;
    try {
      result = await _ticketApi.manualRedeemTicket(ticketId);
    } on ApiException catch (ex, stackTrace) {
      debugPrint("### FORIA SERVER ERROR: manualRedeemTicket ###");
      debugPrint("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
      _errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, ex, stackTrace));
      throw new Exception(ex.message);
    } catch (e) {
      debugPrint("### NETWORK ERROR: manualRedeemTicket Msg: ${e.toString()} ###");
      _errorStream.announceError(ForiaNotification.error(MessageType.NETWORK_ERROR, netConnectionError, null, null, null));
      rethrow;
    }

    debugPrint("TicketId: $ticketId reedeemed. manualRedeemTicket resulted in ticket status: ${result.status}");
    return result;
  }

  ///
  /// Stores the FCM token in Foria database. This should only be called for new tokens.
  ///
  void registerDeviceToken(final String token) async {

    if (token == null) {
      return;
    }

    final String savedToken = await _secureStorage.read(key: _fcmTokenKey);
    if (token == savedToken) {
      return;
    }

    if (!await _authUtils.isUserLoggedIn(true)) {
      return;
    }

    if (_userApi == null) {
      ApiClient foriaApiClient = await _authUtils.obtainForiaApiClient();
      _userApi = new UserApi(foriaApiClient);
    }

    DeviceToken deviceToken = new DeviceToken();
    deviceToken.token = token;

    try {
      await _userApi.registerToken(deviceToken);
    } on ApiException catch (ex, stackTrace) {
      debugPrint("### FORIA SERVER ERROR: registerToken ###");
      debugPrint("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
      _errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, ex, stackTrace));
      return;
    } catch (e) {
      debugPrint("### NETWORK ERROR: registerToken Msg: ${e.toString()} ###");
      _errorStream.announceError(ForiaNotification.error(MessageType.NETWORK_ERROR, textGenericError, null, null, null));
      return;
    }

    await _secureStorage.write(key: _fcmTokenKey, value: token);
    debugPrint("FCM token sucessfully registered on server: $token");
  }

  ///
  /// Attempts to cancel the ticket transfer. This call is only successful if the ticket status is
  /// TRANSFER_PENDING. Do NOT call it otherwise.
  ///
  /// If this call is successful, the ticket status goes back to ACTIVE.
  /// Throws exception on network error.
  ///
  Future<void> cancelTicketTransfer(final Ticket currentTicket) async {

    if (currentTicket == null) {
      return;
    }

    if (_ticketApi == null) {
      ApiClient foriaApiClient = await _authUtils.obtainForiaApiClient();
      _ticketApi = new TicketApi(foriaApiClient);
    }

    try {
      await _ticketApi.cancelTransfer(currentTicket.id);
    } on ApiException catch (ex, stackTrace) {
      print("### FORIA SERVER ERROR: cancelTransfer ###");
      print("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
      _errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, ex, stackTrace));
      rethrow;
    } catch (e) {
      debugPrint("### NETWORK ERROR: cancelTransfer Msg: ${e.toString()} ###");
      _errorStream.announceError(ForiaNotification.error(MessageType.NETWORK_ERROR, netConnectionError, null, null, null));
      rethrow;
    }

    _ticketSet.removeWhere((ticket) => ticket.id == currentTicket.id); //Remove stale ticket. Status is out of date.

    currentTicket.status = 'ACTIVE';
    _ticketSet.add(currentTicket);

    await _databaseUtils.storeTicketSet(_ticketSet);
    notifyListeners();

    debugPrint('Ticket Id: ${currentTicket.id} ticket transfer canceled. Ticket set to ACTIVE.');
  }

  ///
  /// Attempts to transfer a ticket to an email address. If the ticket can't complete the transfer it will go in PENDING
  /// status. If the network call is successful, expect the new ticket status to be ISSUED indicating a new user owns it
  /// or TRANSFER_PENDING indicating the transfer will complete in future or be canceled.
  ///
  /// Throws exception on network error.
  ///
  /// Returns bool. TRUE is returned if the last ticket for that event has a completed transfer. FALSE if not. NULL if there is an error.
  ///
  Future<bool> transferTicket(final Ticket currentTicket, final String email) async {

    if (currentTicket == null || email == null) {
      _errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, null, null));
      throw new Exception('null passed to transferTicket method');
    }

    if (_ticketApi == null) {
      ApiClient foriaApiClient = await _authUtils.obtainForiaApiClient();
      _ticketApi = new TicketApi(foriaApiClient);
    }

    final TransferRequest transferRequest = new TransferRequest();
    transferRequest.receiverEmail = email;

    Ticket updatedTicket;
    try {
      updatedTicket = await _ticketApi.transferTicket(currentTicket.id, transferRequest: transferRequest);
    } on ApiException catch (ex, stackTrace) {
      debugPrint("### FORIA SERVER ERROR: transferTicket ###");
      debugPrint("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
      _errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, ex, stackTrace));
      throw ex;
    } catch (e) {
      debugPrint("### NETWORK ERROR: transferTicket Msg: ${e.toString()} ###");
      _errorStream.announceError(
          ForiaNotification.error(MessageType.NETWORK_ERROR, netConnectionError, null, null, null));
      throw e;
    }

    _ticketSet.removeWhere((ticket) => ticket.id == currentTicket.id); //Remove stale ticket. Status is out of date.

    if (updatedTicket != null) {
      _ticketSet.add(updatedTicket);
      _errorStream.announceMessage(ForiaNotification.message(MessageType.MESSAGE, textTransferPending, null));
      debugPrint('Ticket Id: ${currentTicket.id} submitted for transfer. New status: ${updatedTicket.status}');
    } else {
      _errorStream.announceMessage(ForiaNotification.message(MessageType.MESSAGE, textTransferComplete, null));
      debugPrint('Ticket Id: ${currentTicket.id} completed transfer. Ticket removed for user.');
    }

    await _databaseUtils.storeTicketSet(_ticketSet);

    if (getTicketsForEventId(currentTicket.eventId).isEmpty) {
      _eventSet.removeWhere((event) => event.id == currentTicket.eventId);
      notifyListeners();
      return true;
    } else {
      notifyListeners();
      return false;
    }
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
      ApiClient foriaApiClient = await _authUtils.obtainForiaApiClient();
      _ticketApi = new TicketApi(foriaApiClient);
    }

    int ticketsActivated = 0;
    for (Ticket ticket in tickets) {

      if (ticket.status != ticketStatusIssued) {
        continue;
      }

      ActivationResult result;
      try {
        result = await _ticketApi.activateTicket(ticket.id);
      } on ApiException catch (ex, stackTrace) {
        debugPrint("### FORIA SERVER ERROR: activateTicket ###");
        debugPrint("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
        _errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, ex, stackTrace));
        rethrow;
      } catch (e) {
        debugPrint("### NETWORK ERROR: activateTicket Msg: ${e.toString()} ###");
        _errorStream.announceError(ForiaNotification.error(MessageType.NETWORK_ERROR, netConnectionError, null, null, null));
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
        debugPrint('Server ticketId: ${ticket
            .id} hash: $actualTicketSecretHex does not equal stored hash: $loadedTicketSecretHashHex');
        return true;
      }
    }

    debugPrint('All tickets are ACTIVE and valid on this device.');
    return false;
  }

  ///
  /// Create a list of unique events for the set of user tickets.
  ///
  Future<Set<Event>> _buildEventSetFromLocalDatabase(Set<Ticket> tickets) async {
    Set<Event> events = Set<Event>();

    Set<String> processedEventIdSet = new HashSet();
    for (Ticket ticket in tickets) {
      if (!processedEventIdSet.contains(ticket.eventId)) {
        Event event = await fetchEventByIdViaDatabase(ticket.eventId);
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

  ///
  /// If any variables related to an event are null, method returns false
  ///
  bool _isValidTicket(Ticket ticket) {
    if (ticket == null) {
      _errorStream.reportError('Error in ticket_provider: A ticket is null', null);
      return false;
    }
    if (ticket.id == null) {
      _errorStream.reportError('Error in ticket_provider: A ticket ID is null', null);
      return false;
    }
    if (ticket.status == null) {
      _errorStream.reportError('Error in ticket_provider: Ticket ID ${ticket.id} has status null', null);
      return false;
    }
    if (ticket.ticketTypeConfig == null) {
      _errorStream.reportError('Error in ticket_provider: Ticket ID ${ticket.id} has ticketTypeConfig null', null);
      return false;
    }
    if (ticket.ticketTypeConfig.name == null) {
      _errorStream.reportError('Error in ticket_provider: Ticket ID ${ticket.id} has ticketTypeConfig.name null', null);
      return false;
    }
    return true;
  }

  ///
  /// If any variables related to an event are null, method returns false
  /// T
  ///
  bool _isValidEvent(Event event) {
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
    if (event.address == null) {
      _errorStream.reportError('Error in event_provider: Event ID ${event.id} has address null',null);
      return false;
    }
    if (event.imageUrl == null) {
      _errorStream.reportError('Error in event_provider: Event ID ${event.id} has imageUrl null',null);
      return false;
    }
    return true;
  }
}