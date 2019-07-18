import 'package:flutter/material.dart';

import '../screens/selected_ticket.dart';

class MyPassesTab extends StatelessWidget {

  static List<String> date = ['day 1', 'day 2'];
  static List<String> artists = ['Griz', 'Rufus', 'Rufus3', 'Rufus4', 'Rufus5', 'Rufus6', 'Rufus7', 'Rufus8'];
  static List<String> photos = ['assets/ui_elements/griz.jpg', 'assets/ui_elements/rufus.jpg', 'assets/ui_elements/rufus.jpg', 'assets/ui_elements/rufus.jpg', 'assets/ui_elements/rufus.jpg', 'assets/ui_elements/rufus.jpg', 'assets/ui_elements/rufus.jpg', 'assets/ui_elements/rufus.jpg'];

  @override
  Widget build(BuildContext context) {

        return ListView.builder(
                itemCount: artists.length +1,
                itemBuilder: (context, index) {
                  if (index == artists.length){
                    print('final $index');
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        height: 80,
                        child: Column(children: <Widget>[
                          Text(
                            'Missing your tickets?',
                            style: Theme.of(context).textTheme.title,
                          ),
                          Text('Contact Us',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 14,
                              )),
                        ],
                        ),
                      ),
                    );
                  } else {
                    print('index: $index');
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: GestureDetector(
                        onTap: () {
//                          Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => MyTicket()));
                          Navigator.of(context).pushNamed(
                            SelectedTicket.routeName,
                            arguments: null,
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 3,
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 60,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      "Apr",
                                      style: Theme.of(context).textTheme.title,
                                    ),
                                    Text(
                                      "20",
                                      style: Theme.of(context).textTheme.title,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      artists[index],
                                      style: Theme.of(context).textTheme.title,
                                    ),
                                    Text(
                                      '8:00PM - Late',
                                      style: Theme.of(context).textTheme.body1,
                                    ),
                                  ],

                                ),
                              ),
                              Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                  ),
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: AssetImage(photos[1]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );}
                });
  }
}