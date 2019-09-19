import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

import 'encrypt_codec.dart';

class DatabaseUtils {

  Database _db;
  StoreRef<String, Map<String, dynamic>> _eventStore = StoreRef<String, Map<String, dynamic>>(eventStoreName);
  StoreRef<String, Map<String, dynamic>> _ticketListStore = StoreRef<String, Map<String, dynamic>>(ticketListStoreName);
  StoreRef<String, String> _ticketSecretStore = StoreRef<String, String>(ticketSecretStoreName);

  final int _dbVersionCode = 1;
  final Random _random = Random.secure();

  static final String _dbFilename = "foria.db";
  static final String _dbCryptoKeyRef = "FORIA_DATABASE_KEY";
  static final String eventStoreName = "events";
  static final String ticketSecretStoreName = "secrets";
  static final String ticketListStoreName = "tickets";

  ///
  /// Attempts to connect to an existing database.
  ///
  /// If one does not exist, an empty one will be created in a secure location
  /// that is not accessible to the user. The database contents will be encrypted
  /// to guard the ticket secrets from misuse. Ensure that ticket secret is not
  /// logged or stored outside of this database!
  ///
  Future<void> _initDatabase() async {

    final Directory supportDir = await getApplicationSupportDirectory();
    final String dbPath = join(supportDir.path, _dbFilename);
    final _storage = new FlutterSecureStorage();

    String cryptoKey = await _storage.read(key: _dbCryptoKeyRef);
    if (cryptoKey == null) {

      cryptoKey = base64Url.encode(List<int>.generate(32, (i) => _random.nextInt(256)));
      await _storage.write(key: _dbCryptoKeyRef, value: cryptoKey);
      debugPrint("Created and stored databse crypto key. Database has been initialized at: $dbPath");
    } else {
      debugPrint("Database has been loaded from: $dbPath");
    }

    // Initialize the encryption codec with a generated key.
    final SembastCodec codec = getEncryptSembastCodec(password: cryptoKey);
    _db = await databaseFactoryIo.openDatabase(dbPath, version: _dbVersionCode, codec: codec);
  }

  ///
  /// WARNING: Deletes the database!
  ///
  /// This should be called on logout, deleting the database will force
  /// user to reactivate tickets.
  ///
  static Future<void> deleteDatabase() async {

    final Directory supportDir = await getApplicationSupportDirectory();
    final String dbPath = join(supportDir.path, _dbFilename);

    await databaseFactoryIo.deleteDatabase(dbPath);
    debugPrint("Database has been DELETED at: $dbPath");
  }

  ///
  /// Returns the entire list of events stored in the database.
  ///
  Future<List<Event>> getAllEvents() async {

    if (_db == null) {
      await _initDatabase();
    }

    List<Event> events = new List();
    List<String> keys = await _eventStore.findKeys(_db);
    for (String key in keys) {
      Map<String, dynamic> json = await _eventStore.record(key).get(_db);
      events.add(Event.fromJson(json));
    }

    return events;
  }

  ///
  /// Returns event if it exists, null otherwise.
  ///
  Future<Event> getEvent(String eventId) async {

    if (eventId == null) {
      return null;
    }

    if (_db == null) {
      await _initDatabase();
    }

    Map<String, dynamic> json = await _eventStore.record(eventId).get(_db);

    if (json == null) {
      print("Event not found with ID: $eventId");
      return null;
    }

    return Event.fromJson(json);
  }

  ///
  /// Store the specified event in the database mapped by the eventId.
  ///
  Future<void> storeEvent(Event event) async {

    if (_db == null) {
      await _initDatabase();
    }

    //Remove child lists.
    event.ticketFeeConfig = null;
    event.ticketTypeConfig = null;

    String eventId = event.id;
    Map<String, dynamic> json = event.toJson();
    await _eventStore.record(eventId).put(_db, json);
    debugPrint("EventId: $eventId stored in database");
  }

  ///
  /// Returns the entire set of a users tickets.
  ///
  Future<Set<Ticket>> getAllTickets() async {

    if (_db == null) {
      await _initDatabase();
    }

    List<String> keys = await _ticketListStore.findKeys(_db);
    if (keys.isEmpty) {
      debugPrint("No stored tickets in offline database.");
      return null;
    }

    Set<Ticket> ticketSet = new Set<Ticket>();
    for (String key in keys) {

      Map<String, dynamic> ticketJson = await _ticketListStore.record(key).get(_db);
      Ticket ticket = Ticket.fromJson(ticketJson);
      ticketSet.add(ticket);
    }

    debugPrint('Loaded ${ticketSet.length} tickets from local storage.');
    return ticketSet;
  }

  ///
  /// Stores ticket secret in database.
  ///
  Future<void> storeTicketSecret(String ticketId, String ticketSecret) async {

    if (ticketId == null || ticketSecret == null) {
      return null;
    }

    if (_db == null) {
      await _initDatabase();
    }

    await _ticketSecretStore.record(ticketId).put(_db, ticketSecret);
    debugPrint('Stored ticket secret with ticketId: $ticketId');
  }

  ///
  /// Obtains ticket secret for stored ticket in database.
  ///
  Future<String> getTicketSecret(String ticketId) async {

    if (ticketId == null) {
      return null;
    }

    if (_db == null) {
      await _initDatabase();
    }

    String ticketSecret = await _ticketSecretStore.record(ticketId).get(_db);
    debugPrint('Obtained ticket secret from database for ticketId: $ticketId.');

    return ticketSecret;
  }

  ///
  /// Returns a set of tickets via their referenced ticket ID.
  ///
  Future<Set<Ticket>> getTicketsForEventId(String eventId) async {

    if (eventId == null) {
      return null;
    }

    if (_db == null) {
      await _initDatabase();
    }

    final Finder eventFinder = Finder(filter: Filter.equals('eventId', eventId));
    List<RecordSnapshot<String, dynamic>> json = await _ticketListStore.find(_db, finder: eventFinder);

    if (json == null) {
      print("Tickets not found with eventI: $eventId");
      return null;
    }

    Set<Ticket> ticketSet = new Set<Ticket>();
    for (RecordSnapshot<String, dynamic> record in json) {

      Map<String, dynamic> ticketJson = record.value;
      Ticket ticket = Ticket.fromJson(ticketJson);
      ticketSet.add(ticket);
    }

    debugPrint('Loaded ${ticketSet.length} tickets from local storage.');
    return ticketSet;
  }

  ///
  /// Stores the entire set of tickets in database and deletes previous entries.
  ///
  Future<void> storeTicketSet(Set<Ticket> ticketSet) async {

    if (_db == null) {
      await _initDatabase();
    }

    final int ticketsDeleted = await _ticketListStore.delete(_db); //Purges entire ticket store every refresh.
    for (Ticket ticket in ticketSet) {

      Map<String, dynamic> ticketJson = ticket.toJson();
      await _ticketListStore.record(ticket.id).put(_db, ticketJson);
    }

    debugPrint('Purged $ticketsDeleted tickets in local storage.');
    debugPrint('Stored ${ticketSet.length} tickets in local storage.');
  }
}