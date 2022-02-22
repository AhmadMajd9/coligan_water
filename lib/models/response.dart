import '../main.dart';
class Response {
  bool? _status;
  String? _message;
  String? get message => _message;
  bool? get status => _status;


  Response.fromJson(Map<String, dynamic> json) {
    try {

      _status = json['status'];
      _message = json['message'];

    } catch (e) {
      print(e.toString());
    }
  }

}