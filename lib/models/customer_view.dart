import 'package:coligan_water/models/address.dart';
import 'package:coligan_water/models/delivery_lines.dart';

import '../main.dart';
import 'package:coligan_water/models/pagination.dart';

class CustomerView {
  List<CustomerItem>? _items;

  List<CustomerItem>? get items => _items;

  CustomerView.fromJson(Map<String, dynamic> json) {
    try {
      _items = [];
      List<dynamic> items = json['items'];
      for (var i = 0; i < items.length; i++) {
        List<dynamic> list = items[i]["addresses"];
        for (var j = 0; j < list.length; j++) {
          Address add = Address.map(list[j]);
          _items!.add(CustomerItem.map(items[i], add));
        }
      }
      // _items = json['items'];
      //_pagination = Pagination.map(json['pagination']);

    } catch (e) {
      print(e.toString());
    }
  }
}

class CustomerItem {
  String? _id;
  String? _addressId;
  String? _address;
  String? _company_name;
  String? _latitude;
  String? _longitude;
  String? get addressId => _addressId;
  String? get company_name => _company_name;
  String? get id => _id;
  String? get address => _address;
  String? get latitude => _latitude;
  String? get longitude => _longitude;
  CustomerItem.map(dynamic obj, Address address) {
    this._addressId = address.id;
    this._id = obj["id"];
    this._address = address.address;
    this._company_name = obj["company_name"];

    this._latitude = address.location!.latitude;

    this._longitude = address.location!.longitude;
  }
}
