import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parental_monitor/homePage.dart';

class AuthPage extends StatefulWidget {
  AuthPageState createState() => AuthPageState();
}

enum FormTypes { logIn, signUp }

class AuthPageState extends State<AuthPage> {
  final formKey = new GlobalKey<FormState>();
  String _email = "";
  String _password = "";
  FormTypes _formType = FormTypes.logIn;
  DatabaseReference db = FirebaseDatabase.instance.reference();
  final _auth=FirebaseAuth.instance;//reference of database

  void shiftToSignUp() {
                                                                                // For toggling between pages
    formKey.currentState.reset();
    setState(() {
      _formType = FormTypes.signUp;
    });
  }

  void shiftToLogIn() {
                                                                                // For toggling between pages
    formKey.currentState.reset();
    setState(() {
      _formType = FormTypes.logIn;
    });
  }

  bool validateForm() {
                                                                                // Local Form Validation.
    var form = formKey.currentState;

    if (!(form.validate())) {
      print("Validation Error");
      print("Email: $_email");
      return false;
    } else {
      form.save();
      print("Validation done");
      print("Email: $_email");
    }
    return true;
  }

  void validateCredentials() async {
    // Firebase credentials validation
    FirebaseUser user;
    try {
      if (_formType == FormTypes.logIn) {                                       // Log in with given credentials

        print("Sign In Page");
        user = (await _auth
            .signInWithEmailAndPassword(email: _email, password: _password))
            .user;
      } else if(_formType == FormTypes.signUp) {
        // Create a user with given credentials
        user = (await _auth
            .createUserWithEmailAndPassword(email: _email, password: _password))
            .user;
      }
    } catch (e) {
      print("In catch");
      print(e.toString());
    } finally {
      if (user != null) {
        print("Successful");                                                    // Go to homePage by passing the current user details.

        String userName = user.email.replaceAll(RegExp(r'@\w+.\w+'), "");
        List<String> childrenList;

        db = db.child("Internet Usage").child(userName).child("Children");
        db.once().then((DataSnapshot childSnapShot) {
          var childrenDict = childSnapShot.value;
          try{
            for (String childNumber in childrenDict.keys) {
              if (childrenList == null) {
                childrenList = [childrenDict[childNumber]];
              } else {
                childrenList.add(childrenDict[childNumber]);
              }
            }
            childrenList.sort((a, b) {
              return a.toLowerCase().compareTo(b.toLowerCase());
            });
          }
          catch(e){
            childrenList = [];
          }
          print(userName);
          print(childrenList);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => new HomePage(user, childrenList)));
        });
      } else {
        print("Error");
        if (_formType == FormTypes.logIn)
          logInErrorBox("EmailId or Password doesn't match with database");
        else
          logInErrorBox("These credentials cannot work.");
      }
    }
  }

  void logInErrorBox(String msg) {
                                                                                // Show the error box with the given msg
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(msg),
            content: Text('Enter valid EmailId or Password'),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parental Monitor System'),
        backgroundColor: Colors.cyan,
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: ListView(
              children: singleImage() + inputForms() + buttons(),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> singleImage(){
    return [
      Image.asset("assets/images/Welcome.jpg"),


    ];
  }

  List<Widget> inputForms() {
    return [
      new TextFormField(
        decoration: InputDecoration(labelText: 'Email'),
        validator: validateEmail,    //Email Check
        onSaved: (value) => _email = value,
      ),
      new TextFormField(
          decoration: InputDecoration(labelText: 'Password'),
          validator: validatePassword,
          obscureText: true,
          onSaved: (value) => _password = value),
    ];
  }
  String validateEmail(String value) {                                          // For Validating Email
    String pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = new RegExp(pattern);
    if (value.length == 0) {
      return "Email is Required";
    } else if(!regExp.hasMatch(value)){
      return "Invalid Email";
    }else {
      return null;
    }
  }
  String validatePassword(String value) {                                       //For Validating Password
    String patttern = r'(^[a-zA-Z0-9]*$)';
    RegExp regExp = new RegExp(patttern);
    if (value.length <= 5) {
      return "Password of atleast 5 digit/number is Required";
    } else if (!regExp.hasMatch(value)) {
      return "Password must be a-z OR A-Z OR 0-9 ";
    }
    return null;
  }
  List<Widget> buttons() {
    if (_formType == FormTypes.logIn) {
      return [
        new RaisedButton(
          shape: new RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(30.0)),
          color: Colors.cyan,
          child: Text('Log In',
              style: TextStyle(fontSize: 20, color: Colors.black)),
          onPressed: () {


            Future<FirebaseUser> getFirebaseUser() async {
              FirebaseUser user = await _auth.currentUser();
              print(user != null ? user : null);
              return user != null ? user : null;
            }
            getFirebaseUser().then((value){
              print(value);
            });
            print("Going to validateCredentials");
            if (validateForm()){
              validateCredentials();
            }
          },
        ),
        new RaisedButton(
          shape: new RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(30.0)),
          color: Colors.cyan,
          child: Text('Create new User',
              style: TextStyle(fontSize: 20, color: Colors.black)),
          onPressed: () {
            shiftToSignUp();
          },
        ),
      ];
    }
    return [
      new RaisedButton(
        shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(30.0)),
        color: Colors.cyan,
        child: Text('Create New User', style: TextStyle(fontSize: 20)),
        onPressed: () {
          formKey.currentState.reset();
          setState(() {
            _formType = FormTypes.signUp;
          });
          validateCredentials();

        },
      ),
      new RaisedButton(
        shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(30.0)),
        color: Colors.cyan,
        child: Text('Already a User? Log In', style: TextStyle(fontSize: 20)),
        onPressed: () {
          shiftToLogIn();
        },
      ),
    ];
  }
}