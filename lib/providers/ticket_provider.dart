import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:foria/utils.dart';
import 'package:foria_flutter_client/api.dart';

class TicketProvider extends ChangeNotifier {

  final List<Ticket> _ticketList = [];

  UnmodifiableListView<Ticket> get userTicketList => UnmodifiableListView(_ticketList);

  TicketProvider() {
    fetchUserTickets();
  }

  ///
  /// Obtains the latest set of Tickets for the authenticated user.
  ///
  void fetchUserTickets() async {

    ApiClient foriaApiClient = await obtainForiaApiClient();

    UserApi userApi = new UserApi(foriaApiClient);
    _ticketList.addAll(await userApi.getTickets());
    notifyListeners();
  }
}