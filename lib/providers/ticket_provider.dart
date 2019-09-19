import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:foria/utils/auth_utils.dart';
import 'package:foria/utils/database_utils.dart';
import 'package:foria/utils/error_stream.dart';
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

  DatabaseUtils _databaseUtils = new DatabaseUtils();
  AuthUtils _authUtils = new AuthUtils();
  FlutterSecureStorage _secureStorage = new FlutterSecureStorage();

  EventApi _eventApi;
  TicketApi _ticketApi;
  UserApi _userApi;

  final Set<Event> _eventSet = new HashSet();
  final Set<Ticket> _ticketSet = new HashSet();

  final ErrorStream errorStream = GetIt.instance<ErrorStream>();

  bool _ticketsActiveOnOtherDevice = false;

  UnmodifiableListView<Event> get eventList => UnmodifiableListView(_eventSet);
  bool get ticketsActiveOnOtherDevice => _ticketsActiveOnOtherDevice;
  UnmodifiableListView<Ticket> get userTicketList => UnmodifiableListView(_ticketSet);

  set authUtils(AuthUtils value) {
    _authUtils = value;
  }

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
      ApiClient foriaApiClient = await _authUtils.obtainForiaApiClient();
      _userApi = new UserApi(foriaApiClient);
    }

    Set<Ticket> tickets;
    try {
      tickets = (await _userApi.getTickets()).toSet();
    } on ApiException catch (ex, stackTrace) {
      print("### FORIA SERVER ERROR: getTickets ###");
      print("HTTP Status Code: ${ex.code} - Error: ${ex.message}");

      errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, ex, stackTrace));

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
      errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, ex, stackTrace));
      throw new Exception(ex.message);
    } catch (e) {
      debugPrint("### NETWORK ERROR: redeemTicket Msg: ${e.toString()} ###");
      errorStream.announceError(ForiaNotification.error(MessageType.NETWORK_ERROR, netConnectionError, null, null, null));
      rethrow;
    }

    debugPrint("TicketId: ${redemptionRequest.ticketId} reedeemed with result: ${result.status}");
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

    if (! await _authUtils.isUserLoggedIn(true)) {
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
      errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, ex, stackTrace));
      return;
    } catch (e) {
      debugPrint("### NETWORK ERROR: registerToken Msg: ${e.toString()} ###");
      errorStream.announceError(ForiaNotification.error(MessageType.NETWORK_ERROR, textGenericError, null, null, null));
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
      errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, ex, stackTrace));
      rethrow;
    } catch (e) {
      debugPrint("### NETWORK ERROR: cancelTransfer Msg: ${e.toString()} ###");
      errorStream.announceMessage(ForiaNotification.message(MessageType.ERROR, netConnectionError, null));
      rethrow;
    }

    _ticketSet.remove(currentTicket); //Remove stale ticket. Status is out of date.

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
  Future<void> transferTicket(final Ticket currentTicket, final String email) async {

    if (currentTicket == null || email == null) {
      return;
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
      errorStream.announceError(ForiaNotification.error(MessageType.ERROR, textGenericError, null, ex, stackTrace));
      return;
    } catch (e) {
      debugPrint("### NETWORK ERROR: transferTicket Msg: ${e.toString()} ###");
      errorStream.announceMessage(ForiaNotification.message(MessageType.ERROR, netConnectionError, null));
      return;
    }

    _ticketSet.remove(currentTicket); //Remove stale ticket. Status is out of date.

    if (updatedTicket != null) {

      _ticketSet.add(updatedTicket);
      errorStream.announceError(ForiaNotification.message(MessageType.MESSAGE, textTransferPending, null));
      debugPrint('Ticket Id: ${currentTicket.id} submitted for transfer. New status: ${updatedTicket.status}');

    } else {
      errorStream.announceError(ForiaNotification.message(MessageType.MESSAGE, textTransferComplete, null));
      debugPrint('Ticket Id: ${currentTicket.id} completed transfer. Ticket removed for user.');
    }

    await _databaseUtils.storeTicketSet(_ticketSet);
    notifyListeners();
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
//        errorStream.announceError(new Notification.error("### FORIA SERVER ERROR ###", textGenericError, ex, stackTrace));
        rethrow;
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
      ApiClient foriaApiClient = await _authUtils.obtainForiaApiClient();
      _eventApi = new EventApi(foriaApiClient);
    }

    Event event;
    try {
      event = await _eventApi.getEvent(eventId);
    } on ApiException catch (ex, stackTrace) {
      print("### FORIA SERVER ERROR: getEventById ###");
      print("HTTP Status Code: ${ex.code} - Error: ${ex.message}");
//      errorStream.announceError(new Notification.error("### FORIA SERVER ERROR ###", textGenericError, ex, stackTrace));
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
