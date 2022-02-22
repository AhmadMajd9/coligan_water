import '../main.dart';
import 'package:coligan_water/models/pagination.dart';

class DeliveryLines {
  List<DeliveryLine>? _items;
  Pagination? _pagination;

  List<DeliveryLine>? get items => _items;
  Pagination? get pagination => _pagination;

  DeliveryLines.fromJson(Map<String, dynamic> json) {
    try {
      _items = [];
      List<dynamic> items = json['items'];
      for (var i = 0; i < items.length; i++) {
        _items!.add(DeliveryLine.map(items[i]));
      }
      // _items = json['items'];
      _pagination = Pagination.map(json['pagination']);
    } catch (e) {
      print(e.toString());
    }
  }
}

class DeliveryLine {
  String? _title;
  String? _id;
  String? get title => _title;
  String? get id => _id;
  DeliveryLine.map(Map<String, dynamic> obj) {
    this._title = obj["title"];
    this._id = obj["id"];
  }
}
