import 'dart:ui';

import 'package:coligan_water/network/network_calls.dart';
import 'package:flutter/material.dart';
import 'package:coligan_water/network/auth.dart';
import 'package:coligan_water/data/database_helper.dart';
import 'package:coligan_water/models/user.dart';
//import 'package:login_app/screens/login/login_screen_presenter.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new LoginScreenState();
  }
}

class LoginScreenState extends State<LoginScreen>
    implements LoginScreenContract, AuthStateListener {
  BuildContext? _ctx;

  bool _isLoading = false;
  final formKey = new GlobalKey<FormState>();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String? _password, _username;

  late LoginScreenPresenter _presenter;

  LoginScreenState() {
    _presenter = new LoginScreenPresenter(this);
    var authStateProvider = new AuthStateProvider();
    authStateProvider.subscribe(this);
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void _submit() {
    final form = formKey.currentState!;

    if (form.validate()) {
      setState(() => _isLoading = true);
      form.save();

      _presenter.doLogin(_username, _password,_ctx);
    }
  }

  void _showSnackBar(String text) {
    scaffoldKey.currentState!
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  onAuthStateChanged(AuthState state) {
    if (state == AuthState.LOGGED_IN)
      Navigator.of(context).pushReplacementNamed("/home");
  }

  @override
  Widget build(BuildContext context) {
    _ctx = context;
    var loginBtn = new RaisedButton(
      onPressed: _submit,
      child: new Text("LOGIN"),
      color: Theme.of(context).primaryColor,
    );
    var loginForm = Padding(
        padding: const EdgeInsets.all(8.0),
        child: new Column(
          children: <Widget>[
            new Text(
              "Login App",
              textScaleFactor: 2.0,
            ),
            new Form(
              key: formKey,
              child: new Column(
                children: <Widget>[
                  new Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: new TextFormField(
                      onSaved: (val) => _username = val,
                      validator: (val) {
                        return val!.length < 5
                            ? "Username must have at least 5 chars"
                            : null;
                      },
                      decoration: new InputDecoration(labelText: "Username"),
                    ),
                  ),
                  new Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: new TextFormField(
                      obscureText: true,
                      onSaved: (val) => _password = val,
                      validator: (val) {
                        return val!.length < 5
                            ? "Password must have at least 5 chars"
                            : null;
                      },
                      decoration: new InputDecoration(labelText: "Password"),
                    ),
                  ),
                ],
              ),
            ),
            _isLoading ? new CircularProgressIndicator() : loginBtn
          ],
          crossAxisAlignment: CrossAxisAlignment.center,
        ));

    return new Scaffold(
      appBar: null,
      key: scaffoldKey,
      body: new Container(
        decoration: new BoxDecoration(
          image: new DecorationImage(
              image: new AssetImage("assets/bg.jpg"), fit: BoxFit.cover),
        ),
        child: new Center(
          child: new Padding(
              padding: const EdgeInsets.all(16.0),
              child: new ClipRect(
                child: new BackdropFilter(
                  filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: new Container(
                    child: loginForm,
                    height: 300.0,
                    width: 300.0,
                    decoration: new BoxDecoration(
                        color: Colors.grey.shade200.withOpacity(0.5)),
                  ),
                ),
              )),
        ),
      ),
    );
  }

  @override
  void onLoginError(String errorTxt) {
    _showSnackBar(errorTxt);
    setState(() => _isLoading = false);
  }

  var authStateProvider = new AuthStateProvider();

  @override
  void onLoginSuccess(User user) async {
    _showSnackBar(user.toString());
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.saveUser(user);

    authStateProvider.notify(AuthState.LOGGED_IN);
  }
}

abstract class LoginScreenContract {
  void onLoginSuccess(User user);

  void onLoginError(String errorTxt);
}

class LoginScreenPresenter {
  LoginScreenContract _view;
  RestDatasource api = new RestDatasource();

  LoginScreenPresenter(this._view);

  doLogin(String? username, String? password,BuildContext? context) {
    api.login(username, password).then((User user) {

        Navigator.of(context!).pushReplacementNamed("/home");
     // _view.onLoginSuccess(user);
    }).catchError((Object error) => _view.onLoginError(error.toString()));
  }
}
