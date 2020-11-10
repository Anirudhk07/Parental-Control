import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:parental_monitor/authPage.dart';
import 'package:parental_monitor/categories.dart';
import 'package:parental_monitor/dataDisplay.dart';
import 'usage.dart';
import 'stats.dart';

class HomePage extends StatefulWidget {
  FirebaseUser user;
  List<String> childrenList;
  HomePage(FirebaseUser user, List<String> childrenList){
    this.user = user;
    this.childrenList = childrenList;
  }

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {

  String currentChild;
  final DatabaseReference db = FirebaseDatabase.instance.reference();
  String currentUser = "";
  String currentUserEmail = "";
  FirebaseAuth auth = FirebaseAuth.instance;
  DateTime _fromDay = new DateTime(DateTime.now().year, DateTime.now().month,
      DateTime.now().day, DateTime.now().hour, DateTime.now().minute);
  DateTime _toDay = new DateTime(DateTime.now().year, DateTime.now().month,
      DateTime.now().day, DateTime.now().hour, DateTime.now().minute);
  TextEditingController childNameController = TextEditingController();
  TextEditingController childEmailController = TextEditingController();
  List<Usage> tempUsageList;
  List<Usage> usageList;
  // This will contain a list of websites and their corresponding usage
  var iterationCount = 0;

  @override
  void initState() {
    super.initState();
    print(widget.user);
    currentUserEmail = widget.user.email;
    currentUser = currentUserEmail.replaceAll(RegExp(r'@\w+.\w+'), "");

    try {
      currentChild = widget.childrenList[0];
    }
    catch (e) {
      currentChild = "NULL";
    }
  }

  void appendDict(newDict) {
    // This function will be called everytime a new usage dict of a particular day is retrieved
    // For every website in the given dictionary:
    //    1. Go to the element in the list "usageList" containing this website
    //    2. Add the current time to the already existing time usage
    //    3. If the element does not exist, append a new element with new website and time usage

    print(newDict);

    newDict.forEach((key, value) {
      // key is the website name and the value is the internet usage
      // Check if this website exists in the "usageList"
      if (usageList != null) {
        int index =
        usageList.indexWhere((element) => element.site.contains(key));
        if (index != -1) {
          // The website already exists in the list.
          usageList[index].totalUsage += value;
        } else {
          // Else create a new key of the new website in the global dictionary
          usageList.add(new Usage(key, value));
        }
      } else {
        // Else create a new key of the new website in the global dictionary
        usageList = [new Usage(key, value)];
      }
    });
  }

  void getDictOfDate(date) async {
    // This function will request firebase RTD for the internet usage for this date.
    String dayString = "";
    String monthString = "";
    if (date.day < 10 && date.day > 0) {
      // The string will be of single digit.
      // Ex. 1-Nov
      // Make it 01-Nov
      dayString = "0" + date.day.toString();
    } else
      dayString = date.day.toString();

    if (date.month > 0 && date.month < 10) {
      // Single digit. Same process
      monthString = "0" + date.month.toString();
    } else
      monthString = date.month.toString();

    DatabaseReference dbTemp = db
        .child("Internet Usage")
        .child(currentChild.replaceAll(RegExp(r'@\w+.\w+'), ""))
        .child(date.year.toString())
        .child(monthString)
        .child(dayString);
    await dbTemp.once().then((DataSnapshot data) {
      // print("Current date is:" + date.month.toString() + " " + date.day.toString());
      // print(data.value.toString());
      // Once the data is retrived, update the global dictionary
      if (data.value != null) appendDict(data.value);
      iterationCount += 1;
    });
  }

  void _showDialog(title, content) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text(title),
            content: new Text(
                content),
          );
        });
  }



  // Implemented Part

  void getData(String str) {
    int days = _toDay.difference(_fromDay).inDays; // The no of days in between.

    if (days == 0)
      getDictOfDate(_toDay);
    else if (days < 0) {
      DateTime temp = _toDay;
      _toDay = _fromDay;
      _fromDay = temp;
      days *= -1;
    } else {
      // Now for each day in between, get the data from firebase.
      for (int i = 0; i < days; i++) {
        var iterationDate = _fromDay.add(new Duration(days: i));
        getDictOfDate(iterationDate);
      }
    }

    // After this iteration, the global dict must have been completely updated
    // Set an periodic interval until the dict gets updated.
    Timer.periodic(Duration(seconds: 2), (timer) {
      print(timer.tick);
      if (iterationCount > 0) {
        if (usageList != null) {
          // First sort the usage list in descending order of the usage
          usageList.sort((b, a) {
            if (a.totalUsage < b.totalUsage)
              return -1;
            else if (a.totalUsage == b.totalUsage) return 0;
            return 1;
          });

          try{
            tempUsageList = usageList.sublist(0, 5);
          }catch(e){
            tempUsageList = usageList.sublist(0, usageList.length);
          }
          // We need only top 5 websites. Not more
          if (str == "graph") {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => new Stats(tempUsageList)));
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => new DataDisplay(usageList)));
          }
        } else {
          _showDialog("Zero Internet Usage", "There is no Internet Usage between the seleteced dates.");
        }
        timer.cancel();
      }
    });
  }

  void addCategory() {
    Alert(
      context: context,
      title: "Add a new Child",
      content: Container(
        padding: EdgeInsets.all(0),
        child: new Column(
          children: <Widget>[
            TextField(
              controller: childNameController,
              decoration: InputDecoration(hintText: "Enter the Name of the Child"),
            ),
            TextField(
              controller: childEmailController,
              decoration: InputDecoration(hintText: "Enter the Email Id of the Child"),
            )
          ],
        ),
      ),
      buttons: [
        DialogButton(
          child: new Text('Ok'),
          onPressed: () {
            DatabaseReference newdb = db.child("Internet Usage").child(currentUser).child("Children");
            setState(() {
              String newChildEmail = childEmailController.text.toString();
              String newChildName = childNameController.text.toString();


              newdb.set({
                newChildName: newChildEmail
              });
            }); // SetState()
            newdb.once().then((DataSnapshot childSnapShot) {
              setState(() {
                var childrenDict = childSnapShot.value;
                try{
                  for (String childNumber in childrenDict.keys) {
                    if (widget.childrenList == null) {
                      widget.childrenList = [childrenDict[childNumber]];
                    } else {
                      widget.childrenList.add(childrenDict[childNumber]);
                    }
                  }
                  currentChild = widget.childrenList[0];
                }
                catch(e){
                  widget.childrenList = [];
                  currentChild = "NULL";
                }
              });
            });
            Navigator.pop(context);
          },
        )
      ],
    ).show();
  }

  // Page Layout

  @override
  Widget build(BuildContext context) {
    // getCurrentUser();
    return Scaffold(
      appBar: AppBar(
        title: Text('Logged In'),
        backgroundColor: Colors.cyan,
      ),
      drawer: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.white,
          primaryColor: Colors.cyan,


          primaryColorBrightness: Brightness.light,
        ),
        child: Drawer(
          child: ListView(
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountName: Text(currentUser),
                accountEmail: Text(currentUserEmail),
                currentAccountPicture: CircleAvatar(
                  backgroundColor:
                  Theme.of(context).platform == TargetPlatform.iOS
                      ? Colors.cyan
                      : Colors.white,
                  child: Text(
                    currentUser.substring(0, 1),
                    style: TextStyle(fontSize: 40.0),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.data_usage),
                title: Text("Get Categories",
                    style: TextStyle(fontSize: 25, color: Colors.black)),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Categories(currentChild)));
                },
              ),
              ExpansionTile(
                  leading: Icon(Icons.child_care),
                  title: Text(
                    "Children",
                    style: TextStyle(fontSize: 25, color: Colors.black),
                  ),
                  children: new List.generate(widget.childrenList.length, (int index){
                    return ListTile(
                      title: Text(
                        widget.childrenList[index],
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                      onTap: (){
                        setState(() {
                          currentChild = widget.childrenList[index];
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  })
                      // After the children, another button is needed. Add Child
                      + [
                        ListTile(
                          title: Text(
                            "Add a Child",
                            style: TextStyle(fontSize: 20, color: Colors.black),
                          ),
                          onTap: (){
                            addCategory();
                          },
                        )
                      ]
              ),
              ListTile(
                leading: Icon(Icons.power_settings_new),
                title: Text(
                  "Log out",
                  style: TextStyle(fontSize: 25, color: Colors.black),
                ),
                onTap: () {
                  FirebaseAuth.instance.signOut();                              //Logging out is called
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => AuthPage()));
                },
              ),
            ],
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          // We will have four rows.
          // 0. Current Child
          // 1. Start Date
          // 2. End Date
          // 3. Submit Button
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: <Widget>[
                    Text(
                        "Current Child: ",
                        style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)
                    ),
                    Text(
                        currentChild,
                        style: TextStyle(fontSize: 20, color: Colors.lightBlue, fontWeight: FontWeight.bold)
                    ),
                  ],
                )
            ),
            SizedBox(
              height: 20,
            ),
            DateTimePicker(
              labelText: 'From Date:',
              selectedDate: _fromDay,
              selectDate: (DateTime date) {
                setState(() {
                  _fromDay = date;
                });
              },
            ),
            SizedBox(
              height: 20,
            ),
            DateTimePicker(
              labelText: 'To Date:',
              selectedDate: _toDay,
              selectDate: (DateTime date) {
                setState(() {
                  _toDay = date;
                });
              },
            ),
            SizedBox(
              height: 20,
            ),
            Divider(),
            new RaisedButton(
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(30.0)),
              color: Colors.lightBlue,
              child: Text('Get Graph',
                  style: TextStyle(fontSize: 20, color: Colors.white)),
              onPressed: () {
                if (currentChild != "NULL")
                  getData("graph");
                else{
                  _showDialog("No Children", "There are no children added to your profile");
                }
              },
            ),
            new RaisedButton(
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(30.0)),
              color: Colors.lightBlue,
              child: Text('Get Data',
                  style: TextStyle(fontSize: 20, color: Colors.white)),
              onPressed: () {
                if (currentChild != "NULL")
                  getData("data");
                else{
                  _showDialog("No Children", "There are no children added to your profile");
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DateTimePicker extends StatelessWidget {
  const DateTimePicker({
    Key key,
    this.labelText,
    this.selectedDate,
    this.selectDate,
  }) : super(key: key);
  final String labelText;
  final DateTime selectedDate;

  final ValueChanged<DateTime> selectDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1960, 1),
      lastDate: DateTime(2050),
    );
    if (picked != null && picked != selectedDate) selectDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle = Theme.of(context).textTheme.title;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          flex: 4,
          child: InputDropdown(
            labelText: labelText,
            valueText: DateFormat.yMMMd().format(selectedDate),
            valueStyle: valueStyle,
            onPressed: () {
              _selectDate(context);
            },
          ),
        ),
        const SizedBox(width: 12.0),
      ],
    );
  }
}

class InputDropdown extends StatelessWidget {
  const InputDropdown({
    Key key,
    this.child,
    this.labelText,
    this.valueText,
    this.valueStyle,
    this.onPressed,
  }) : super(key: key);
  final String labelText;
  final String valueText;

  final TextStyle valueStyle;
  final VoidCallback onPressed;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
        ),
        baseStyle: valueStyle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(valueText, style: valueStyle),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey.shade700
                  : Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}