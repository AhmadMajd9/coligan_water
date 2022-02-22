import '../main.dart';

class User {
  String? _username;
  String? _password;
  String? _id;
  String? _email;
  String? _image;
  User(this._username, this._password);

  User.map(dynamic obj) {
    this._username = obj["username"];
    this._password = obj["password"];
  }

  String? get username => _username;
  String? get password => _password;

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["username"] = _username;
    map["password"] = _password;

    return map;
  }
  User.fromJson(Map<String, dynamic> json) {
    try {
      sharedPrefs.token = json["token"];

      var _userInfo = json["user_info"];
      _username = _userInfo['name'];
      _id = _userInfo['id'];
      _email = _userInfo['email'];
      _image = _userInfo['image'];
      print(sharedPrefs.token);
    } catch (e) {
      print(e.toString());
    }
  }

}