import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:coligan_water/models/customer_view.dart';
import 'package:coligan_water/models/delivery_lines.dart';
import 'package:coligan_water/models/response.dart';
import 'package:coligan_water/models/sheets_view.dart';
import 'package:coligan_water/models/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import '../main.dart';

class NetworkUtil {
  // next three lines makes this class a Singleton
  static NetworkUtil _instance = new NetworkUtil.internal();
  NetworkUtil.internal();
  factory NetworkUtil() => _instance;

  final JsonDecoder _decoder = new JsonDecoder();

  Future<dynamic> get(String url) {
    return http.get(Uri.parse(url)).then((http.Response response) {
      final String res = response.body;
      final int statusCode = response.statusCode;

      if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }
      return _decoder.convert(res);
    });
  }

  Future<dynamic> post(String url, {Map? headers, body, encoding}) {
    return http
        .post(Uri.parse(url), body: body, headers: headers as Map<String, String>?, encoding: encoding)
        .then((http.Response response) {
      final String res = response.body;
      final int statusCode = response.statusCode;

      if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }
      return _decoder.convert(res);
    });
  }
}

class RestDatasource {
  NetworkUtil _netUtil = new NetworkUtil();
  static final BASE_URL = "https://culligan.demo.ps/api/v1";
  static final LOGIN_URL = BASE_URL + "/auth/login";
  static final LINES_URL = BASE_URL + "/delivery-lines/list";
  static final DELIVERY_VIEW = BASE_URL + "/sheets/view/";
  static final DELIVERY_Item = BASE_URL + "/sheets/items/status/update/";
  static final DELIVERY_Customer = BASE_URL + "/delivery-lines/addresses/list/";
  static final Update_DELIVERY_Customer =
      BASE_URL + "/delivery-lines/addresses/update/";
  static final Update_User_Location = BASE_URL + "/driver/location/update";
  Map userHeader = <String, String>{
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization":
        "\$2y\$12\$JVeIGlnT/q/1Orgg8DDYJOn70PkFFaoPcJlPTlK3P5UAlD0wFwLQS",
    "Device-id": "1f493a6a-0d86-49b5-ad1b-ff775bd11582",
    "os": "ios",
    "language": "ar"
  };

  Future<User> login(String? username, String? password) {
    return http
        .post(Uri.parse(LOGIN_URL),
            body: convert.jsonEncode({"email": username, "password": password}),
            headers: userHeader as Map<String, String>?)
        .then((http.Response response) {
      final int statusCode = response.statusCode;

      if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }
      var jsonDic = json.decode(response.body);
      var user = User.fromJson(json.decode(response.body));
      if (jsonDic["status"]) {
        return user;
      } else {
        throw new Exception(jsonDic["message"]);
      }
    });
  }

  Future<DeliveryLines> getDeliveryLines() {
    userHeader["Token"] = sharedPrefs.token;
    return http
        .get(Uri.parse(LINES_URL), headers: userHeader as Map<String, String>?)
        .then((http.Response response) {
      final int statusCode = response.statusCode;

      if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }
      return DeliveryLines.fromJson(json.decode(response.body));
    });
  }

  Future<Response> updateDeliveryItem(SheetItem sheetItem) {
    userHeader["Token"] = sharedPrefs.token;
    var body = convert.jsonEncode({
      "location": {
        "latitude": sheetItem.address!.location!.latitude,
        "longitude": sheetItem.address!.location!.longitude
      }
    });
    return http
        .post(Uri.parse(DELIVERY_Item + sheetItem.id!),
            body: body, headers: userHeader as Map<String, String>?)
        .then((http.Response response) {
      final int statusCode = response.statusCode;

      if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }
      Response resp = Response.fromJson(json.decode(response.body));
      if (resp.status == false) {
        throw new Exception(resp.message);
      }
      return Response.fromJson(json.decode(response.body));
    });
  }

  Future<SheetsView> getDeliveryView(String id) {
    userHeader["Token"] = sharedPrefs.token;
    return http
        .get(Uri.parse(DELIVERY_VIEW + id + "?sheet_id="), headers: userHeader as Map<String, String>?)
        .then((http.Response response) {
      final int statusCode = response.statusCode;

      if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }
      return SheetsView.fromJson(json.decode(response.body));
    });
  }

  Future<CustomerView> getCustomerView(String id) {
    userHeader["Token"] = sharedPrefs.token;
    return http
        .get(Uri.parse(DELIVERY_Customer + id), headers: userHeader as Map<String, String>?)
        .then((http.Response response) {
      final int statusCode = response.statusCode;

      if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }
      return CustomerView.fromJson(json.decode(response.body));
    });
  }

  Future<CustomerView> updateCustomerView(
      String id, String addressId, double long, double lat) {
    final random = Random();
    //long = long + random.nextInt(1000) * 0.0000001;
    //lat = lat + random.nextInt(1000) * 0.0000001;
    userHeader["Token"] = sharedPrefs.token;
    // lat = 31.906436;
    //long =35.2125388;
    var body = convert.jsonEncode({
      "location": {"latitude": lat, "longitude": long}
    });
    return http
        .post(Uri.parse(Update_DELIVERY_Customer + id + "/" + addressId),
            body: body, headers: userHeader as Map<String, String>?)
        .then((http.Response response) {
      final int statusCode = response.statusCode;

      if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }
      print("response.body ${response.body}");
      return CustomerView.fromJson(json.decode(response.body));
    });
  }

  Future<bool> updateUserLocation(double? long, double? lat) {
    userHeader["Token"] = sharedPrefs.token;
    // lat = 31.906436;
    //long =35.2125388;
    var body = convert.jsonEncode({
      "location": {"latitude": lat, "longitude": long}
    });
    return http
        .post(Uri.parse(Update_User_Location), body: body, headers: userHeader as Map<String, String>?)
        .then((http.Response response) {
      final int statusCode = response.statusCode;

      if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }

      return true;
    });
  }
}
