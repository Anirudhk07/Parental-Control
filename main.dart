import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:parental_monitor/usage.dart';

class DataDisplay extends StatelessWidget
{
  List<Usage> usageList;
  DataDisplay(usageList)
  {
    this.usageList = usageList;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Total usage of sites is"),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: usageList.length,
              itemBuilder: (BuildContext ctxt, int i){
                return forCard(usageList[i].site.replaceAll("_", "."), usageList[i].totalUsage);
              },
            ),
          )
        ],
      ),
    );
  }

  Widget forCard(String site, int totalUsage) {
    return new Card(
      elevation: 30,
      margin: EdgeInsets.all(15),
      child: new Container(
        padding: new EdgeInsets.all(14),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new Text(
                  site=site.replaceAll(RegExp('/^((https?|ftp|smtp):\/\/)?(www.)'), ""),
                  textAlign: TextAlign.center,
                ),
                new Text(
                  (totalUsage~/60).toString()+" Mins",
                  //style: Theme.of(context).textTheme.subtitle,
                  textAlign: TextAlign.center,
                )
              ],
            ),
            SizedBox(
              height: 10,
            ),


          ],
        ),
      ),
    );
  }

}
