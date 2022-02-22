import 'dart:ffi';

class Pagination {
  int? _current_page;
  int? _next_page;
  int? _total_pages;
  int? _total_items;
  bool? _has_more;
  int? get current_page => _current_page;

  int? get next_page => _next_page;
  int? get total_pages => _total_pages;
  int? get total_items => _total_items;
  bool? get has_more => _has_more;
  Pagination.map(dynamic obj) {
    this._current_page = obj["current_page"];
    this._next_page = obj["next_page"];
    this._total_pages = obj["total_pages"];
    this._total_items = obj["total_items"];
    this._has_more = obj["has_more"];
  }
}