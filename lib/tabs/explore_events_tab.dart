import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foria/providers/event_provider.dart';
import 'package:foria/utils/configuration.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/errors/image_unavailable.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

///
/// Sets up the provider for the discover events tab and shows spinner when loading
///
class ExploreEventsTab extends StatefulWidget {

  @override
  _ExploreEventsTabState createState() => _ExploreEventsTabState();
}

enum _LoadingState {

  INITIAL_LOAD,
  NETWORK_ERROR,
  EVENTS_LOADED,
  NO_EVENTS_AVAILABLE
}

class _ExploreEventsTabState extends State<ExploreEventsTab> with AutomaticKeepAliveClientMixin<ExploreEventsTab> {

  EventProvider _eventProvider;
  _LoadingState _currentState;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    _eventProvider = GetIt.instance<EventProvider>();
    _currentState = _LoadingState.INITIAL_LOAD;
    super.initState();
  }

  ///
  /// Fires network call to load and cache events.
  ///
  Future<void> _loadEvents() async {

    try {
      List<Event> events = await _eventProvider.getAllEvents();
      setState(() {
        if (events == null || events.isEmpty) {
          _currentState = _LoadingState.NO_EVENTS_AVAILABLE;
        } else {
          _currentState = _LoadingState.EVENTS_LOADED;
        }
      });
    } catch (e) {
      setState(() {
        _currentState = _LoadingState.NETWORK_ERROR;
      });
    }
  }

  /// Displayed in error case.
  Widget _error (){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(textOops,
                  style: Theme.of(context).textTheme.title,
                  textAlign: TextAlign.center,),
                sizedBoxH3,
                GestureDetector(
                  child: Text(tryAgain,
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: constPrimaryColor),
                    textAlign: TextAlign.center,
                  ),
                  onTap: _loadEvents,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    super.build(context);

    final MessageStream messageStream = GetIt.instance<MessageStream>();
    messageStream.addListener((errorMessage) {
      Scaffold.of(context).showSnackBar(
          SnackBar(
            backgroundColor: snackbarColor,
            elevation: 0,
            content: FlatButton(
              child: Text(errorMessage.body),
              onPressed: () => Scaffold.of(context).hideCurrentSnackBar(),
            ),
          )
      );
    });

    Widget child;
    if (_currentState == _LoadingState.INITIAL_LOAD) {
      child = CupertinoActivityIndicator(radius: 15);
      _loadEvents();
    } else if (_currentState == _LoadingState.EVENTS_LOADED) {
      child = EventList();
    } else if (_currentState == _LoadingState.NO_EVENTS_AVAILABLE) {
      child = NoEvent();
    } else {
      child = _error();
    }

    return ChangeNotifierProvider<EventProvider>.value(value: _eventProvider, child: child);
  }
}

///
/// Shown if events API returned no results.
///
class NoEvent extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(noEventsAvailable,
                  style: Theme.of(context).textTheme.title,
                  textAlign: TextAlign.center,),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class EventList extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    final eventData = Provider.of<EventProvider>(context, listen: true);
    final Duration timezoneOffset = DateTime.now().timeZoneOffset;
    final Duration timeDiff = new Duration(hours: timezoneOffset.inHours, minutes: timezoneOffset.inMinutes % 60);

    return ListView.builder(
            itemCount: eventData.events.length,
            itemBuilder: (context, index) {
              DateTime serverStartTime = eventData.events[index].startTime;
              DateTime localStartTime = serverStartTime.add(timeDiff);
              EventAddress addr = eventData.events[index].address;
              final String eventUrl = (Configuration.eventUrl as String).replaceAll('{eventId}', eventData.events[index].id);
              final String imageUrl = eventData.events[index].imageUrl;
              final List<TicketTypeConfig> ticketTiers = eventData.events[index].ticketTypeConfig;
              //TODO add capability for multiple currencies

              double min;
              double max;
              String priceOutput;

              for (TicketTypeConfig tier in ticketTiers) {

                if(tier.amountRemaining <= 0){
                  continue;
                }

                double faceValue = double.tryParse(tier.price);
                double fee = double.tryParse(tier.calculatedFee);
                double price = faceValue + fee;

                if(price == null){
                  continue;
                } else if(min == null){
                  min = price;
                  max = price;
                } else if (min == price){
                  continue;
                } else if(min > price) {
                  min = price;
                } else if(max < price){
                  max = price;
                }
              }

              if(max == null || min == null){
                priceOutput = textSoldOut;
              } else if(min < 0.01 && max < 0.01){
                priceOutput = textFreeEvent;
              } else if(min == max){
                priceOutput = '\$'+(min).toStringAsFixed(0);
              } else {
                priceOutput = 'From \$' + min.toStringAsFixed(0);
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: GestureDetector(
                  key: Key(eventData.events[index].id),
                  onTap: () async {
                    if (await canLaunch(eventUrl)) {
                      await launch(eventUrl);
                    } else {
                      print("Failed to load eventUrl");
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        height: 150,
                        width: double.infinity,
                        child: Stack(children: <Widget>[
                          DiscoverEventImage(imageUrl),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white.withOpacity(0.9),
                              ),
                              child: Text(priceOutput,style: foriaBodyTwo),
                            ),
                          )
                        ],alignment: Alignment.bottomLeft,
                        )
                      ),
                      sizedBoxH3,
                      Text(
                        eventData.events[index].name,
                        style: Theme.of(context).textTheme.title,
                      ),
                      sizedBoxH3,
                      Text(
                        dateFormatDay.format(localStartTime),
                        style: Theme.of(context).textTheme.body2,
                      ),
                      sizedBoxH3,
                      Text(
                        addr.city + ', ' + addr.state,
                        style: Theme.of(context).textTheme.body2,
                      ),
                    ],
                  ),
                ),
              );
            });
  }
}

class DiscoverEventImage extends StatelessWidget {

  final String _imageUrl;


  DiscoverEventImage(this._imageUrl);

  @override
  Widget build(BuildContext context) {
    return _imageUrl == null ? Container() : CachedNetworkImage(
      placeholder: (context, url) =>
          CupertinoActivityIndicator(),
      errorWidget: (context, url, error) {
        return ImageUnavailable();
      },
      imageUrl: _imageUrl,
      imageBuilder: (context, imageProvider) =>
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(2)),
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
    );
  }
}


