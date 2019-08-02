import 'package:flutter/foundation.dart';
import 'package:foria_flutter_client/api.dart';

class SelectedTicketProvider extends ChangeNotifier {

  final Event _event;
  final Set<Ticket> _eventTickets;

  SelectedTicketProvider(this._event, this._eventTickets);

  List<Ticket> get eventTickets => List.unmodifiable(_eventTickets);
  Event get event => _event;
}