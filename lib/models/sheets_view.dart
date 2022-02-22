import 'package:coligan_water/models/address.dart';
import 'package:coligan_water/models/delivery_lines.dart';

import '../main.dart';
import 'package:coligan_water/models/pagination.dart';

class SheetsView {
  List<SheetItem>? _items;
  DeliveryLine? _deliveryLine;
  SheetCounts? _sheetCounts;
  Sheet? _sheet;
  SheetItem? _nextItem;
  List<SheetItem>? get items => _items;
  DeliveryLine? get deliveryLine => _deliveryLine;
  SheetCounts? get sheetCounts => _sheetCounts;
  Sheet? get sheet => _sheet;
  SheetItem? get nextItem => _nextItem;
  SheetsView.fromJson(Map<String, dynamic> json) {
    try {
      _items = [];
      List<dynamic> items = json['items'];
      for (var i = 0; i < items.length; i++) {
        _items!.add(SheetItem.map(items[i]));
      }
      // _items = json['items'];
      //_pagination = Pagination.map(json['pagination']);
      _sheet = Sheet.map(json['sheet']);
      _deliveryLine = DeliveryLine.map(json['deliveryLine']);
      _sheetCounts = SheetCounts.map(json['counts']);
      _nextItem = SheetItem.map(json['nextItem']);
    } catch (e) {
      print(e.toString());
    }
  }
}

class Sheet {
  String? _title;
  String? _id;
  bool? _completed;
  String? get title => _title;
  String? get id => _id;
  bool? get completed => _completed;
  Sheet.map(Map<String, dynamic> obj) {
    this._title = obj["title"];
    this._id = obj["id"];
    this._completed = obj["completed"];
  }
}

class SheetCounts {
  int? _remaining;
  int? _unassigned;

  int? get remaining => _remaining;
  int? get unassigned => _unassigned;

  SheetCounts.map(Map<String, dynamic> obj) {
    this._remaining = obj["remaining"];
    this._unassigned = obj["unassigned"];
  }
}

class SheetItem {
  String? _addressId;
  String? _id;
  Address? _address;
  String? _customer_company_name;
  String? get addressId => _addressId;
  String? get customer_company_name => _customer_company_name;
  bool? showText = false;

  String? get id => _id;
  Address? get address => _address;

  SheetItem.map(dynamic obj) {
    this._addressId = obj["addressId"];
    this._id = obj["id"];
    this.showText = obj["showText"];
    this._address = Address.map(obj["address"]);
    this._customer_company_name = obj["customer_company_name"];
  }
}
