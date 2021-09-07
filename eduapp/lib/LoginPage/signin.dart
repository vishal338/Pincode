import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:country_calling_code_picker/country.dart';
import 'package:country_calling_code_picker/country_code_picker.dart';
import 'package:country_calling_code_picker/functions.dart';
import 'package:country_calling_code_picker/picker.dart';

class loginpage extends StatefulWidget {
  const loginpage({key}) : super(key: key);

  @override
  _loginpageState createState() => _loginpageState();
}

class _loginpageState extends State<loginpage> {
  late Country _selectedCountry;
       TextEditingController _phoneNumber = TextEditingController();
        TextEditingController _code = TextEditingController();
       TextEditingController _otp = TextEditingController() ;

   late Future<FirebaseApp> _firebaseApp;

  @override
  void initState() {
    initCountry();
    super.initState();
    // _firebaseApp = Firebase.initializeApp();
  }

  bool isLoggedIn = false;
  late String uid;
  bool otpSent = false;
  var _Auth = FirebaseAuth.instance;
  late String _verificationId ;

  void _verifyOTP() async{

   final credential = PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: _otp.text);
   try{
     await _Auth.signInWithCredential(credential);
     if(FirebaseAuth.instance.currentUser != null ){
       setState(() {
         isLoggedIn = true;
         uid = FirebaseAuth.instance.currentUser.uid;
       });
     }
     }
   catch(e){
     print(e);
   }
  }

  Future<void> _sendOtp() async {

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneNumber.text, 
      timeout: Duration(seconds: 30), 
      verificationCompleted: verificationCompleted, 
      verificationFailed: verificationFailed, 
      codeSent: codeSent, 
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
      setState(() {
        otpSent = true;
      });
  }

  void verificationFailed(exception){

    print(exception.message);
    setState(() {
      
      isLoggedIn = false;
      otpSent = false;
    });
  }

  void codeSent( String verificationId ,[a] ) async {

    //PhoneAuthProvider.getCredential(verificationId: verificationId, smsCode: smsCode)
    setState(() {
      _verificationId = verificationId;
      otpSent = true;
    });
  }

  void codeAutoRetrievalTimeout(String verificationId){

    setState(() {
      _verificationId = verificationId;
      otpSent = true ;
    });
  }

  void verificationCompleted(credential) async {

    await FirebaseAuth.instance.signInWithCredential(credential);
    if(_Auth.currentUser != null){

      setState(() {
        isLoggedIn = true;
        uid = _Auth.currentUser.uid ;
      });
    }
    else{
      print("Failed to Sign In");
    }
  }

  void initCountry() async {
    final country = await getDefaultCountry(context);
    setState(() {
      _selectedCountry = country;
    });
  }

  void _onPressedShowBottomSheet() async {
    final country = await showCountryPickerSheet(
      context,
    );
    if (country != null) {
      setState(() {
        _selectedCountry = country;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final country = _selectedCountry;
    var countrypicker = Container(
      decoration: new BoxDecoration(
        // color: Colors.white,
        border: Border(
          right: BorderSide(width: 0.5, color: Colors.grey),
        ),
      ),
      height: 45.0,
      margin: const EdgeInsets.all(3.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            country == null
                ? Container()
                : Column(
                    children: <Widget>[
                      Image.asset(
                        country.flag,
                        package: countryCodePackageName,
                        width: 50,
                      ),
                      // SizedBox(
                      //   height: 100,
                      // ),
                      // Text(
                      //   '${country.callingCode} ${country.name} (${country.countryCode})',
                      //   textAlign: TextAlign.center,
                      //   style: TextStyle(fontSize: 24),
                      // ),
                    ],
                  ),
            // SizedBox(height: 24,),
            MaterialButton(
              child: Text(
                '${country.callingCode}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
              // color: Colors.white,
              onPressed: _onPressedShowBottomSheet,
            ),
          ],
        ),
      ),
    );
    return Scaffold(
        body: SingleChildScrollView(
      child: FutureBuilder(
        // future: _firebaseApp,
        builder: (context ,Snapshot) { 

          if(Snapshot.connectionState == ConnectionState.waiting) return CircularProgressIndicator();
          return isLoggedIn ? Center(
            child: Text("Welcome User \n Your UID is: $uid"),
          ):otpSent? Column(
            
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               TextFormField(
                      controller: _otp,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'OTP',
                            hintText: 'Enter your OTP'),
                        style: TextStyle(fontSize: 20),
                        autofocus: false),
                    Padding(padding: EdgeInsets.only(top: 20)),
                    ElevatedButton(
                      onPressed: _verifyOTP,
                      style: ElevatedButton.styleFrom(
                          elevation: 10, primary: Colors.red),
                      child: Text("Sign In"),
                    )
            ],
          ) : Container(
          padding: EdgeInsetsDirectional.only(
              top: MediaQuery.of(context).size.height / 2),
          child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 1.25,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phoneNumber,
                        //keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Mobile Number',
                            hintText: 'Enter your mobile number',
                            prefixIcon: countrypicker),
                        style: TextStyle(fontSize: 20),
                        autofocus: false),
                    Padding(padding: EdgeInsets.only(top: 20)),
                    ElevatedButton(
                      onPressed: _sendOtp,
                      style: ElevatedButton.styleFrom(
                          elevation: 10, primary: Colors.red),
                      child: Text("Submit"),
                    )
                  ],
                ),
              )),
        );
        },
      ),
    ));
  }
}
