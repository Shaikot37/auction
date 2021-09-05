import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'Bids.dart';
import 'HomePage.dart';
import 'Posts.dart';
import 'UsersItem.dart';

class ItemDetails extends StatefulWidget {
  @override
  _ItemDetailsState createState() => _ItemDetailsState();
}

class _ItemDetailsState extends State<ItemDetails> {
  List<Bids> bidsList = [];
  final bid = TextEditingController();
  String post_auction_id;
  int flag = 0;
  int winner = 0;
  String _bidWinner = "No bidder yet";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final databaseRef = FirebaseDatabase.instance.reference().child("User");
  final DatabaseReference bidsRef =
      FirebaseDatabase.instance.reference().child("Bid");
  FirebaseStorage storage = FirebaseStorage.instance;
  User user;
  bool isloggedin = false;
  final Future<FirebaseApp> _future = Firebase.initializeApp();

  checkAuthentification() async {
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        Navigator.of(context).pushReplacementNamed("start");
      }
    });
  }

  @override
  void initState() {
    super.initState();
    this.checkAuthentification();
    this.getUser();

    bidsRef.once().then((DataSnapshot snap) {
      var KEYS = snap.value.keys;
      var DATA = snap.value;

      bidsList.clear();

      for (var individualKey in KEYS) {
        Bids bids = new Bids(
          DATA[individualKey]['AuctionID'],
          DATA[individualKey]['User_name'],
          DATA[individualKey]['Bid'],
          DATA[individualKey]['UserID'],
        );

        final Posts todo = ModalRoute.of(context).settings.arguments;
        post_auction_id = todo.AuctionID;

        if (DATA[individualKey]['AuctionID'] == post_auction_id) {
          int initValue = int.parse(DATA[individualKey]['Bid']);

          if (initValue > winner) {
            _bidWinner = DATA[individualKey]['User_name'];
            winner = initValue;
          }
          bidsList.add(bids);
        }
        print(_bidWinner);
      }

      setState(() {
        print('Length : ${bidsList.length}');
      });
    });
  }

  getUser() async {
    User firebaseUser = _auth.currentUser;
    await firebaseUser?.reload();
    firebaseUser = _auth.currentUser;

    if (firebaseUser != null) {
      setState(() {
        this.user = firebaseUser;
        this.isloggedin = true;
      });
    }
  }

  signOut() async {
    _auth.signOut();

    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
  }

  void printFirebase() {
    databaseRef.once().then((DataSnapshot snapshot) {
      print('Data : ${snapshot.value}');
    });
  }

  showPopupMenu() {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(25.0, 25.0, 0.0, 0.0),
      //position where you want to show the menu on screen
      items: [
        PopupMenuItem<String>(child: const Text('My posted items'), value: '1'),
        PopupMenuItem<String>(child: const Text('Logout'), value: '3'),
      ],
      elevation: 8.0,
    ).then<void>((String itemSelected) {
      if (itemSelected == null) return;

      if (itemSelected == "1") {
        userItems();
      } else {
        //code here
        signOut();
      }
    });
  }

  void userItems() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return new UsersItem();
    }));
  }

  void addBid(String bid) {
    if (flag == 0) {
      final Posts todo = ModalRoute.of(context).settings.arguments;
      bidsRef.push().set({
        'Bid': bid,
        'User_name': user.displayName,
        'AuctionID': todo.AuctionID,
        'UserID': user.uid
      });
      refresh();
    } else {
      _showDialog("You have already bid for this auction");
    }
  }

  void refresh() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return new HomePage();
    }));
  }

  void _showDialog(String txt) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Sorry!!"),
          content: new Text(txt),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new TextButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  bool isNumber(String string) {
    // Null or empty string is not a number
    if (string == null || string.isEmpty) {
      return false;
    }
    final number = num.tryParse(string);

    if (number == null) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final Posts todo = ModalRoute.of(context).settings.arguments;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          centerTitle: true,
          title: Text('Item Details'),
          leading: IconButton(
            onPressed: () {
              debugPrint("Form button clicked");
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return HomePage();
              }));
            },
            icon: Icon(Icons.home),
          ),
          actions: [
            IconButton(
              onPressed: showPopupMenu,
              icon: Icon(Icons.more_vert),
            ),
          ],
        ),
        body: SingleChildScrollView(
            child: Column(children: <Widget>[
          Container(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Image.network(
                          todo.ImageURL,
                          height: 300.0,
                          width: 300.0,
                          alignment: Alignment.center,
                        ),
                      ),

                      //child: Text("For",style: TextStyle(color:Colors.black,fontSize:25),),
                    ],
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                ]),
          ),
          Container(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        "Name: ",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      //child: Text("Geeks",style: TextStyle(color:Colors.black,fontSize:25),),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                        todo.Name,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      //child: Text("For",style: TextStyle(color:Colors.black,fontSize:25),),
                    ],
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                ]),
          ),
          Container(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        "Description: ",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      //child: Text("Geeks",style: TextStyle(color:Colors.black,fontSize:25),),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                        todo.Description,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      //child: Text("For",style: TextStyle(color:Colors.black,fontSize:25),),
                    ],
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                ]),
          ),
          Container(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        "Minimum Bid Price: ",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      //child: Text("Geeks",style: TextStyle(color:Colors.black,fontSize:25),),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                        "${todo.Minimum_Bid_Price} Taka",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      //child: Text("For",style: TextStyle(color:Colors.black,fontSize:25),),
                    ],
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                ]),
          ),
          Container(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        "End Date: ",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      //child: Text("Geeks",style: TextStyle(color:Colors.black,fontSize:25),),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                        todo.End_Date,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      //child: Text("For",style: TextStyle(color:Colors.black,fontSize:25),),
                    ],
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                ]),
          ),
          Container(
              child: Column(children: <Widget>[
            Padding(
              padding: EdgeInsets.all(10.0),
              child: TextField(
                  controller: bid,
                  decoration: InputDecoration(
                    hintText: 'Bid Amount..',
                  )),
            ),
            SizedBox(height: 20.0),
            Center(
              child: ElevatedButton(
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.blueGrey)),
                child: Text("Bid"),
                onPressed: () {
                  if (isNumber(bid.text)) {
                    addBid(bid.text);
                  } else {
                    _showDialog("Please enter the amount correctly");
                  }
                },
              ),
            ),
          ])),
          Container(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        "Bid Winner ",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      //child: Text("Geeks",style: TextStyle(color:Colors.black,fontSize:25),),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text(_bidWinner,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                backgroundColor: Colors.lightGreenAccent)),
                      ),

                      //child: Text("For",style: TextStyle(color:Colors.black,fontSize:25),),
                    ],
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                ]),
          ),
          bidsList.length == 0
              ? new Text("")
              : new ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: bidsList.length,
                  itemBuilder: (_, index) {
                    if (bidsList[index].UserID ==
                        FirebaseAuth.instance.currentUser.uid) {
                      flag = 1;
                    }

                    return PostUI(bidsList[index].AuctionID,
                        bidsList[index].Bid, bidsList[index].User_name);
                  }),
        ])));
  }

  Widget PostUI(String auctionID, String user_name, String bid) {
    return new Container(
        child: Card(
      elevation: 10.0,
      margin: EdgeInsets.all(7.0),
      child: new Container(
        padding: new EdgeInsets.all(14.0),
        child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  new Text(
                    user_name,
                    style: Theme.of(context).textTheme.subtitle1,
                    textAlign: TextAlign.center,
                  ),
                  new Text(
                    "${bid} Taka",
                    style: Theme.of(context).textTheme.subtitle1,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ]),
      ),
    ));
  }
}
