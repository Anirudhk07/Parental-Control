import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:parental_monitor/setCategoryLimit.dart';

class Categories extends StatefulWidget{
  String child;

  Categories(String child){
    this.child = child;
  }

  @override
  State<StatefulWidget> createState() {
    return CategoriesState();
  }
}

void displayPopUp(String message, BuildContext context){
  showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: new Text("Empty List"),
          content: new Text("There is no website in this category yet!"),
        );
      }
  );
}

class CategoriesState extends State<Categories>{
  final DatabaseReference db = FirebaseDatabase.instance.reference();
  List<String> categoryList = ['Educational','Entertainment','Restricted','Social'];
  var categoryDict;

  void getData(String category) async{
    DatabaseReference dbTemp = db.child("Internet Usage").child("child1").child("Categories").child(category);
    await dbTemp.once().then((DataSnapshot snapshot){
      categoryDict = snapshot.value;
      print(categoryDict);
      Navigator.push(context, MaterialPageRoute(
          builder: (context)=> SetCategoryLimit(widget.child, category, categoryDict)
      ));

    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: Text("Categories"),
      ),
      body: Container(
        decoration: new BoxDecoration(boxShadow: [
          new BoxShadow(
            color: Colors.grey[200],
            blurRadius: 10.0,
          ),
        ]),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: categoryList.length,
                itemBuilder: (BuildContext ctxt, int i){
                  return forCard(categoryList[i]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget forCard(String category) {
    return Container(
      child: Card(
        margin: EdgeInsets.all(15),
        child: ListTile(
          title: new Text(
            category,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 25),
          ),
          onTap: (){
            getData(category);
          },
        ),
      ),
    );
  }
}