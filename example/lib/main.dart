import 'package:flutter/material.dart';
import 'package:swipe_card/swipe_card.dart';

void main() => runApp(new MyApp());

/// Example app to demonstrate the use of the [SwipeCard] widget and the [CardsDeck] helper.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Swipe Cards Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Swipe Cards Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // The deck helps manage the cards as they are swiped out.
  final CardsDeck deck = new CardsDeck();
  int _cardNumber = 0;
  String _infoText = "Get swippin!";

  initState() {
    super.initState();
    deck.addBottom(_createNewCard());
    deck.addBottom(_createNewCard());
  }

  SwipeCard _createNewCard() {
    return new SwipeCard(
      child: new Container(
        child: new Center(
          child: new Text((_cardNumber++).toString(),
              style: new TextStyle(fontSize: 32.0)),
        ),
        width: 300.0,
        height: 300.0,
        decoration: new BoxDecoration(
          color: new Color.fromARGB(255, 50, 153, 255),
          border: new Border.all(
            color: new Color.fromARGB(255, 0, 115, 229),
            width: 10.0,
          ),
          borderRadius: new BorderRadius.circular(8.0),
        ),
      ),
      onSwipe: (int direction) {
        if (direction == SwipeCard.leftSwipe) {
          _infoText = "Swipped left";
        } else {
          _infoText = "Swipped right";
        }
        setState(() {});
      },
      onAnimationDone: () {
        deck.addBottom(_createNewCard());
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Column(
        children: <Widget>[
          new Padding(
              padding: const EdgeInsets.only(top: 32.0),
              child: new Text(
                _infoText,
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w900,
                ),
              )),
          new Expanded(
            child: new Center(
              // A stack is a good way to have the cards on top of each other.
              child: new Stack(
                  alignment: Alignment.center, children: deck.topTwoCards()),
            ),
          ),
        ],
      ),
    );
  }
}
