import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class SetCategoryLimit extends StatefulWidget {
  String category;
  String child;
  var categoryDict;
  SetCategoryLimit(String child, String category, var catDict) {
    this.child = child;
    this.category = category;
    this.categoryDict = catDict;
  }
  @override
  State<StatefulWidget> createState() {
    return CategoryLimit();
  }
}

class CategoryLimit extends State<SetCategoryLimit> {
  var categoryList = [];
  TextEditingController webText = TextEditingController();
  TextEditingController timeText = TextEditingController();
  DatabaseReference db = FirebaseDatabase.instance.reference();

  @override
  void initState() {
    super.initState();
    if (widget.categoryDict != null)
      for (var website in widget.categoryDict.keys) {
        categoryList.add([website, widget.categoryDict[website]]);
      }
    print("Inside the limit page.");
    print("The child name is: " + widget.child);
  }

  Widget buildBody() {
    if (categoryList != null) {
      return ListView.builder(
        itemCount: categoryList.length,
        itemBuilder: (BuildContext ctxt, int i) {
          return forCard(categoryList[i][0], categoryList[i][1]);
        },
      );
    }
    return null;
  }

  void addCategory(BuildContext context, String websiteName, String usage) {
    webText.text = websiteName;
    timeText.text = usage;
    Alert(
      context: context,
      title: "Add websites",
      content: Container(
        padding: EdgeInsets.all(0),
        child: new Column(
          children: <Widget>[
            TextField(

              controller: webText,
              decoration: InputDecoration(hintText: "Enter the website"),
            ),
            TextField(
              controller: timeText,
              decoration: InputDecoration(hintText: "Enter the time limit"),
            )
          ],
        ),
      ),
      buttons: [
        DialogButton(
          child: new Text('Ok'),
          onPressed: () {
            setState(() {
              String newWebsite = webText.text.toString();
              int newLimit = int.parse(timeText.text);

              // Add to the list if new website
              int index = categoryList.indexWhere((element) => element[0] == newWebsite);
              if (index == -1)
                categoryList.add([newWebsite, newLimit]);
              else{
                // It already exists
                categoryList[index] = [newWebsite, newLimit];
              }

              if (widget.categoryDict == null){
                widget.categoryDict = {newWebsite: newLimit};
              }
              else
                widget.categoryDict[newWebsite] = newLimit;
              db = db.child("Internet Usage").child(widget.child).child("Categories").child(widget.category);
              db.set({
                newWebsite: newLimit
              });
            });
            Navigator.pop(context);
          },
        )
      ],
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.cyan,
          title: Text(widget.category),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                addCategory(context, "", "");
              },
            )
          ],
        ),
        body: buildBody());
  }

  Widget forCard(String website, int timeLimit) {
    return new Card(
      elevation: 30,
      margin: EdgeInsets.all(15),
      child: ListTile(
        title: Text(
          website,
        ),
        trailing: Text(
          timeLimit.toString(),
        ),
        onTap: (){
          addCategory(context, website, timeLimit.toString());
        },
      ),
    );
  }
}