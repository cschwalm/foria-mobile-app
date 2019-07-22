import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:foria/main.dart';

class StepTitle extends StatelessWidget {
  final String index;
  final String title;

  StepTitle(
    this.index,
    this.title,
  );

  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Stack(
          children: <Widget>[
            Container(
              height: 35,
              width: 35,
              decoration: new BoxDecoration(
                color: shapeGrey,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              height: 35,
              width: 35,
              alignment: Alignment.center,
              child: Text(
                "$index",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Text(
            '$title',
            style: Theme.of(context).textTheme.title,
          ),
        ),
      ],
    );
  }
}

class StepOne extends StatelessWidget {
  StepOne({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StepTitle('1', 'Verify your account'),
        Padding(
          padding: EdgeInsets.only(left: 45),
          child: RichText(
            text: TextSpan(children: <TextSpan>[
              TextSpan(
                  text: 'For the safety of our customers, we require a ',
                  style: Theme.of(context).textTheme.body1),
              TextSpan(
                  text: 'goverment issued photo ID ',
                  style: Theme.of(context).textTheme.title),
              TextSpan(
                  text: 'to transfer tickets.',
                  style: Theme.of(context).textTheme.body1),
            ]),
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.add_a_photo),
              SizedBox(
                width: 10,
              ),
              Text(
                'Frontside photo of your ID',
                style: Theme.of(context).textTheme.button,
              ),
            ],
          ),
          color: Theme.of(context).primaryColor,
          onPressed: () {},
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.add_a_photo),
              SizedBox(
                width: 10,
              ),
              Text(
                'Backside photo of your ID',
                style: Theme.of(context).textTheme.button,
              ),
            ],
          ),
          color: Theme.of(context).primaryColor,
          onPressed: () {},
        ),
      ],
    );
  }
}

class StepTwo extends StatelessWidget {
  const StepTwo({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            StepTitle('2', 'Who should receive your ticket?'),
            Padding(
              padding: const EdgeInsets.only(left: 45),
              child: Text(
                'Note: transfers are not reversible',
                style: Theme.of(context).textTheme.body2,
              ),
            )
          ],
        ),
        Padding(
            padding: const EdgeInsets.only(left: 45),
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                      filled: true,
                      labelText: 'Email',
                      fillColor: Color(0xFFF2F2F2),
                      contentPadding: EdgeInsets.all(10.0),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            width: 16.0, color: Colors.lightBlue.shade50),
                        borderRadius: BorderRadius.circular(15.0),
                      )),
                  keyboardType: TextInputType.emailAddress,
                  onFieldSubmitted: (_) {},
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter an email address.';
                    }
                    return null;
                  },
                  onSaved: (value) {},
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  'If this person doesn’t have a Foria account they will be prompted to create one.',
                  style: Theme.of(context).textTheme.body2,
                ),
              ],
            )),
      ],
    );
  }
}

class ProcessTransfer extends StatelessWidget {
  const ProcessTransfer({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        SizedBox(
          height: 20,
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Process transfer',
                style: Theme.of(context).textTheme.button,
              ),
            ],
          ),
          color: Theme.of(context).primaryColor,
          onPressed: () {},
        ),
        SizedBox(
          height: 10,
        ),
        Text(
          'Verification can take up to 24 hours',
          style: Theme.of(context).textTheme.body2,
        ),
      ],
    );
  }
}

class RegisterAndTransferScreen extends StatelessWidget {
  static const routeName = '/transfer-screen';

  @override
  Widget build(BuildContext context) => new Scaffold(
        //App Bar
        appBar: new AppBar(
          title: new Text(
            'Transfer Steps',
            style: new TextStyle(
              fontSize: Theme.of(context).platform == TargetPlatform.iOS
                  ? 17.0
                  : 20.0,
            ),
          ),
          elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
        ),

        //Content of tabs
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(child: StepOne(),flex: 2,),
              Expanded(child: StepTwo(),flex: 2,),
              Expanded(child: ProcessTransfer(),flex: 1,),
            ],
          ),
        ),
      );
}
