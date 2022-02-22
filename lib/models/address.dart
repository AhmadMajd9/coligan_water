class Address {
  String? _address;
  String? _id;
  bool? _completed;
  String? _mobile;
  String? _phone;
  String? _price;
  String? _quantity;
  String? _internalId;
  String? _order;
  Location? _location;
  String? _info;
  List<String>? _mobileNumbers;
  String? get address => _address;
  String? get id => _id;
  String? get mobile => _mobile;
  String? get phone => _phone;
  String? get price => _price;
  String? get quantity => _quantity;
  String? get internalId => _internalId;
  String? get order => _order;
  String? get info => _info;
  Location? get location => _location;
  bool? get completed => _completed;
  List<String>? get mobileNumbers => _mobileNumbers;

  Address.map(dynamic  obj) {
    this._address = obj["address"];
    this._id = obj["id"];
    this._completed = obj["completed"];
    this._mobile = obj["mobile"];
    this._phone = obj["phone"];
    this._price = obj["price"];
    this._quantity = obj["quantity"];
    this._internalId = obj["internalId"];
    this._order = obj["order"];
    this._info = obj["info"];
    this._location = Location.map(obj["location"]);
    _mobileNumbers= obj['_mobileNumbers'];

   /* for (var i = 0; i < items.length; i++) {
      _items.add(SheetItem.map(items[i]));
    }*/
  }
}

class Location {
  String? _latitude;
  String? _longitude;

  String? get latitude => _latitude;
  String? get longitude => _longitude;

  Location.map(dynamic  obj) {
    this._latitude = obj["latitude"];
    this._longitude = obj["longitude"];
  }
}