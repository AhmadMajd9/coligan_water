import 'dart:async';

import 'package:coligan_water/main.dart';
import 'package:coligan_water/models/customer_view.dart';
import 'package:coligan_water/models/delivery_lines.dart';
import 'package:coligan_water/models/response.dart';
import 'package:coligan_water/models/sheets_view.dart';
import 'package:coligan_water/network/network_calls.dart';
import 'package:coligan_water/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:coligan_water/map_request.dart'; // Stores the Google Maps API Key
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:location/location.dart' as Loc;
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:coligan_water/location_service.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;

class MapView extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> implements HomeScreenContract {
  CameraPosition _initialLocation = CameraPosition(target: LatLng(0.0, 0.0));
  late GoogleMapController mapController;

  late Position _currentPosition;
  String? _currentAddress;

  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  final startAddressFocusNode = FocusNode();
  final desrinationAddressFocusNode = FocusNode();

  String? _startAddress = '';
  String _destinationAddress = '';
  String? _placeDistance;

  Set<Marker> markers = {};

  late PolylinePoints polylinePoints;
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  RestDatasource api = new RestDatasource();

  // the user's initial location and current location
// as it moves
  late Loc.LocationData currentLocation;
// a reference to the destination location
  Loc.LocationData? destinationLocation;
// wrapper around the location API
  Loc.Location? location;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late HomeScreenPresenter _presenter;
  _MapViewState() {
    _presenter = HomeScreenPresenter(this);
  }
  Widget _textField({
    TextEditingController? controller,
    FocusNode? focusNode,
    String? label,
    String? hint,
    required double width,
    Icon? prefixIcon,
    Widget? suffixIcon,
    Function(String)? locationCallback,
  }) {
    return Container(
      width: width * 0.8,
      child: TextField(
        onChanged: (value) {
          locationCallback!(value);
        },
        controller: controller,
        focusNode: focusNode,
        decoration: new InputDecoration(
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.grey[400]!,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.blue[300]!,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.all(15),
          hintText: hint,
        ),
      ),
    );
  }

  // Method for retrieving the current location
  _getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;
        print('CURRENT POS: $_currentPosition');
      });
      //await _getAddress();
      setState(() {
        /* mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15.0,
            ),
          ),
        );*/
      });
      Timer.periodic(Duration(minutes: 1), (tick) {
        print("update");
        _presenter.updateUserLocation(
            currentLocation.longitude, currentLocation.latitude);
      });
    }).catchError((e) {
      print(e);
    });
  }

  void _onLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
              padding: EdgeInsets.all(16.0),
              child: new Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  new CircularProgressIndicator(),
                  new Text("Loading"),
                ],
              )),
        );
      },
    );
    new Future.delayed(new Duration(seconds: 3), () {
      Navigator.pop(context); //pop dialog
      // _login();
    });
  }

  // Method for retrieving the address
  _getAddress() async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
        startAddressController.text = _currentAddress!;
        _startAddress = _currentAddress;
      });
    } catch (e) {
      print(e);
    }
  }

  // Method for calculating the distance between two places
  Future<bool> _calculateDistance(SheetsView sheetView) async {
    try {
      // Retrieving placemarks from addresses
      if (sheetView.items!.length > 0) {
        polylineCoordinates.clear();
        markers.clear();
        setState(() {});
        SheetItem sheetItem = sheetView.items![0];
        double long = double.parse(sheetItem.address!.location!.longitude!);
        double lat = double.parse(sheetItem.address!.location!.latitude!);
        //List<Location> startPlacemark = await locationFromAddress("$lat, $long");
        //if(startPlacemark != null)
        //{
        Position startCoordinates = Position(
            latitude: _currentPosition.latitude,
            longitude: _currentPosition.longitude);
        Position destinationCoordinates =
            Position(latitude: lat, longitude: long);
        Marker startMarker = Marker(
          markerId: MarkerId('Start Pin'),
          position: LatLng(
            startCoordinates.latitude,
            startCoordinates.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Start',
            snippet: _startAddress,
          ),
          icon: BitmapDescriptor.defaultMarker,
        );
        // Destination Location Marker
        Marker destinationMarker = Marker(
          markerId: MarkerId('$destinationCoordinates'),
          position: LatLng(
            destinationCoordinates.latitude,
            destinationCoordinates.longitude,
          ),
          infoWindow: InfoWindow(
            title: sheetItem.address!.address,
            snippet: _destinationAddress,
          ),
          icon: sheetView.nextItem!.id == sheetItem.id
              ? BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueYellow)
              : sheetItem.address!.completed!
                  ? BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen)
                  : BitmapDescriptor.defaultMarker,
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) =>
                  _buildPopupDialog(context, sheetItem),
            );
            print("clickkkkk: $startCoordinates");
            //Your code here...
          },
        );
        //markers.add(startMarker);
        markers.add(destinationMarker);
        Position _northeastCoordinates;
        Position _southwestCoordinates;

        // Calculating to check that the position relative
        // to the frame, and pan & zoom the camera accordingly.
        double miny =
            (startCoordinates.latitude <= destinationCoordinates.latitude)
                ? startCoordinates.latitude
                : destinationCoordinates.latitude;
        double minx =
            (startCoordinates.longitude <= destinationCoordinates.longitude)
                ? startCoordinates.longitude
                : destinationCoordinates.longitude;
        double maxy =
            (startCoordinates.latitude <= destinationCoordinates.latitude)
                ? destinationCoordinates.latitude
                : startCoordinates.latitude;
        double maxx =
            (startCoordinates.longitude <= destinationCoordinates.longitude)
                ? destinationCoordinates.longitude
                : startCoordinates.longitude;

        _southwestCoordinates = Position(latitude: miny, longitude: minx);
        _northeastCoordinates = Position(latitude: maxy, longitude: maxx);

        // Accommodate the two locations within the
        // camera view of the map
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target:
                  LatLng(_currentPosition.latitude, _currentPosition.longitude),
              zoom: 15.0,
            ),
          ),
        );
        await _createPolylines(startCoordinates, destinationCoordinates);
        for (int i = 1; i < sheetView.items!.length; i++) {
          startCoordinates = destinationCoordinates;
          SheetItem sheetItem = sheetView.items![i];
          double long = double.parse(sheetItem.address!.location!.longitude!);
          double lat = double.parse(sheetItem.address!.location!.latitude!);
          if (long != null && lat != null) {
            /*List<Location> endPlacemark = await locationFromAddress(
                      "$lat, $long");*/
            //if (endPlacemark != null) {
            destinationCoordinates = Position(latitude: lat, longitude: long);
            Marker destinationMarker = Marker(
              markerId: MarkerId('$destinationCoordinates'),
              position: LatLng(
                destinationCoordinates.latitude,
                destinationCoordinates.longitude,
              ),
              infoWindow: InfoWindow(
                title: sheetItem.address!.address,
                snippet: _destinationAddress,
              ),
              icon: sheetView.nextItem!.id == sheetItem.id
                  ? BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueYellow)
                  : sheetItem.address!.completed!
                      ? BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen)
                      : BitmapDescriptor.defaultMarker,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) =>
                      _buildPopupDialog(context, sheetItem),
                );
                print("clickkkkk: $startCoordinates");
                //Your code here...
              },
            );

            markers.add(destinationMarker);
            //  await _createPolylines(startCoordinates, destinationCoordinates);

            print("startt:$startCoordinates");
            print("dest:$destinationCoordinates");
            //}
          }
        }

        setState(() {});
        // }
        //print("START startPlacemark: $startPlacemark");
      }
      List<Location> startPlacemark =
          await locationFromAddress("31.9082965, 35.3038551");
      List<Location> secondPlacemark =
          await locationFromAddress("31.9082965, 35.2538551");
      List<Location> destinationPlacemark =
          await locationFromAddress("31.9082965, 35.2038551");

      /* if (startPlacemark != null && destinationPlacemark != null && secondPlacemark != null) {
        // Use the retrieved coordinates of the current position,
        // instead of the address if the start position is user's
        // current position, as it results in better accuracy.
        Position startCoordinates = _startAddress == _currentAddress
            ? Position(latitude: _currentPosition.latitude, longitude: _currentPosition.longitude)
            : Position(
            latitude: startPlacemark[0].latitude, longitude: startPlacemark[0].longitude);
        Position destinationCoordinates = Position(
            latitude: destinationPlacemark[0].latitude,
            longitude: destinationPlacemark[0].longitude);
        Position secondCoordinates = Position(
            latitude: secondPlacemark[0].latitude,
            longitude: secondPlacemark[0].longitude);
        // Start Location Marker
        Marker startMarker = Marker(
          markerId: MarkerId('$startCoordinates'),
          position: LatLng(
            startCoordinates.latitude,
            startCoordinates.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Start',
            snippet: _startAddress,
          ),
          icon: BitmapDescriptor.defaultMarker,
        );

        // Destination Location Marker
        Marker destinationMarker = Marker(
          markerId: MarkerId('$destinationCoordinates'),
          position: LatLng(
            destinationCoordinates.latitude,
            destinationCoordinates.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: _destinationAddress,
          ),
          icon: BitmapDescriptor.defaultMarker,
        );
        Marker secondMarker = Marker(
          markerId: MarkerId('second'),
          position: LatLng(
            secondCoordinates.latitude,
            secondCoordinates.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: _destinationAddress,
          ),
          icon: BitmapDescriptor.defaultMarker,
        );
        // Adding the markers to the list
        markers.add(startMarker);
        markers.add(secondMarker);
        markers.add(destinationMarker);

        print('START COORDINATES: $startCoordinates');
        print('DESTINATION COORDINATES: $destinationCoordinates');

        Position _northeastCoordinates;
        Position _southwestCoordinates;

        // Calculating to check that the position relative
        // to the frame, and pan & zoom the camera accordingly.
        double miny = (startCoordinates.latitude <= destinationCoordinates.latitude)
            ? startCoordinates.latitude
            : destinationCoordinates.latitude;
        double minx = (startCoordinates.longitude <= destinationCoordinates.longitude)
            ? startCoordinates.longitude
            : destinationCoordinates.longitude;
        double maxy = (startCoordinates.latitude <= destinationCoordinates.latitude)
            ? destinationCoordinates.latitude
            : startCoordinates.latitude;
        double maxx = (startCoordinates.longitude <= destinationCoordinates.longitude)
            ? destinationCoordinates.longitude
            : startCoordinates.longitude;

        _southwestCoordinates = Position(latitude: miny, longitude: minx);
        _northeastCoordinates = Position(latitude: maxy, longitude: maxx);

        // Accommodate the two locations within the
        // camera view of the map
        mapController.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              northeast: LatLng(
                _northeastCoordinates.latitude,
                _northeastCoordinates.longitude,
              ),
              southwest: LatLng(
                _southwestCoordinates.latitude,
                _southwestCoordinates.longitude,
              ),
            ),
            100.0,
          ),
        );

        // Calculating the distance between the start and the end positions
        // with a straight path, without considering any route
        // double distanceInMeters = await Geolocator().bearingBetween(
        //   startCoordinates.latitude,
        //   startCoordinates.longitude,
        //   destinationCoordinates.latitude,
        //   destinationCoordinates.longitude,
        // );
        await _createPolylines(startCoordinates, secondCoordinates);

        double totalDistance = 0.0;

        // Calculating the total distance by adding the distance
        // between small segments
        for (int i = 0; i < polylineCoordinates.length - 1; i++) {
          totalDistance += _coordinateDistance(
            polylineCoordinates[i].latitude,
            polylineCoordinates[i].longitude,
            polylineCoordinates[i + 1].latitude,
            polylineCoordinates[i + 1].longitude,
          );
        }
        await _createPolylines(secondCoordinates, destinationCoordinates);

        totalDistance = 0.0;

        // Calculating the total distance by adding the distance
        // between small segments
        for (int i = 0; i < polylineCoordinates.length - 1; i++) {
          totalDistance += _coordinateDistance(
            polylineCoordinates[i].latitude,
            polylineCoordinates[i].longitude,
            polylineCoordinates[i + 1].latitude,
            polylineCoordinates[i + 1].longitude,
          );
        }

        setState(() {
          _placeDistance = totalDistance.toStringAsFixed(2);
          print('DISTANCE: $_placeDistance km');
        });
*/
      EasyLoading.dismiss();
      return true;
      //}
    } catch (e) {
      EasyLoading.dismiss();
      print(e);
    }
    return false;
  }

  // Formula for calculating distance between two coordinates
  // https://stackoverflow.com/a/54138876/11910277
  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos as double Function(num?);
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  // Create the polylines for showing the route between two places
  var i = 0;
  _createPolylines(Position start, Position destination) async {
    polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      Secrets.API_KEY, // Google Maps API Key
      PointLatLng(start.latitude, start.longitude),
      PointLatLng(destination.latitude, destination.longitude),
      travelMode: TravelMode.walking,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    var idS = start.latitude;
    setState(() {
      PolylineId id = PolylineId('poly$idS');
      Polyline polyline = Polyline(
        polylineId: PolylineId("poly$i"),
        color: Colors.red,
        points: polylineCoordinates,
        width: 6,
      );
      polylines.add(polyline);
      i += 1;
    });
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    filteredList = fooList;
    // create an instance of Location
    location = new Loc.Location();
    polylinePoints = PolylinePoints();

    // subscribe to changes in the user's location
    // by "listening" to the location's onLocationChanged event
    try {
      location!.onLocationChanged.listen((cLoc) {
        // cLoc contains the lat and long of the
        // current user's position in real time,
        // so we're holding on to it
        print("here:$cLoc");
        currentLocation = cLoc;
        updatePinOnMap();
      });
    } on Exception catch (_) {}
    // set custom marker pins
    //setSourceAndDestinationIcons();
    // set the initial location
    //setInitialLocation();
  }

  void updatePinOnMap() async {
    // create a new CameraPosition instance
    // every time the location changes, so the camera
    // follows the pin as it moves with an animation
    CameraPosition cPosition = CameraPosition(
      zoom: 15,
      target: LatLng(currentLocation.latitude!, currentLocation.longitude!),
    );
    //  final GoogleMapController controller = await _controller.future;
    //   mapController.animateCamera(CameraUpdate.newCameraPosition(cPosition));
    // do this inside the setState() so Flutter gets notified
    // that a widget update is due
    // updated position
    var pinPosition =
        LatLng(currentLocation.latitude!, currentLocation.longitude!);

    // the trick is to remove the marker (by id)
    // and add it again at the updated location
    /*   markers.removeWhere(
            (m) => m.markerId.value == 'Start Pin');
    markers.add(Marker(
      markerId: MarkerId('Start Pin'),
      position: pinPosition, // updated position
      icon: BitmapDescriptor.defaultMarker,
    ));*/
    setState(() {});
  }

  String? textVal;
  _openPopup(context, remainingOnly) {
    showDialog(
        context: context,
        builder: (_) {
          return MyDialog(customerView: _presenter.customerView);
        }).then((value) => {
          if (value != null)
            {
              print("presenter $value"),
              _updateLocation(value),
            }
        });
  }

  _openPopup2(context, remainingOnly) {
    showDialog(
        context: context,
        builder: (_) {
          return MyDialog2(
              customerView: _presenter.sheetsView, flag: remainingOnly);
        }).then((value) => {
          if (value != null)
            {
              print("valueeee:$value"),
              showDialog(
                context: context,
                builder: (BuildContext context) =>
                    _buildPopupDialog(context, value),
              ),
            }
        });
  }

  _updateLocation(dynamic value) async {
    await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium)
        .then((Position position) async {
      setState(() {
        //  _onLoading();
        print("presenter ${_presenter.sheetsView!.deliveryLine!.id}");
        print("presenter ${position.longitude}");
        print("presenter ${position.latitude}");
        print("presenter ${value}");
        _currentPosition = position;

        _presenter.updateCustomerViews(
          _presenter.sheetsView!.deliveryLine!.id!,
          value,
          _currentPosition.longitude,
          _currentPosition.latitude,
        );

        print('presenter POS: $_currentPosition');
      });
      await _getAddress();
      setState(() {});
    }).catchError((e) {
      print(e);
    });
  }

  List fooList = ['one', 'two', 'three', 'four', 'five'];
  List filteredList = [];
  void filter(String inputString) {
    filteredList =
        fooList.where((i) => i.toLowerCase().contains(inputString)).toList();
    setState(() {});
  }

  bool init = true;
  @override
  void didChangeDependencies() {
    if (init) {
      _presenter.getDeliveryLines();

      init = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    var userLocation = Provider.of<UserLocation>(context);
    return Container(
      height: height,
      width: width,
      child: Scaffold(
        key: _scaffoldKey,
        body: Stack(
          children: <Widget>[
            // Map View
            GoogleMap(
              markers: markers != null ? Set<Marker>.from(markers) : Set(),
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              polylines: polylines,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),
            // Show zoom buttons
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ClipOval(
                      child: Material(
                        color: Colors.blue[100], // button color
                        child: InkWell(
                          splashColor: Colors.blue, // inkwell color
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.add),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomIn(),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ClipOval(
                      child: Material(
                        color: Colors.blue[100], // button color
                        child: InkWell(
                          splashColor: Colors.blue, // inkwell color
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.remove),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomOut(),
                            );
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            // Show the place input fields & button for
            // showing the route,
            (_presenter.sheetsView != null &&
                    _presenter.sheetsView!.sheetCounts != null)
                ? SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.all(
                              Radius.circular(20.0),
                            ),
                          ),
                          width: width * 0.9,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(top: 10.0, bottom: 10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                RaisedButton(
                                  onPressed: (_presenter.sheetsView != null &&
                                          _presenter.sheetsView!.sheetCounts !=
                                              null)
                                      ? () async {
                                          _openPopup2(context, false);
                                        }
                                      : null,
                                  color: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'كل العناوين' +
                                          " : " +
                                          _presenter.sheetsView!.items!.length
                                              .toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20.0,
                                      ),
                                    ),
                                  ),
                                ),
                                (_presenter.sheetsView != null &&
                                        _presenter.sheetsView!.sheetCounts !=
                                            null)
                                    ? Row(children: <Widget>[
                                        Expanded(
                                            child: Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: RaisedButton(
                                                  onPressed: (_presenter
                                                                  .sheetsView !=
                                                              null &&
                                                          _presenter.sheetsView!
                                                                  .sheetCounts !=
                                                              null)
                                                      ? () async {
                                                          _openPopup(
                                                              context, true);
                                                        }
                                                      : null,
                                                  color: Colors.blueGrey,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.0),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            4.0),
                                                    child: Text(
                                                      'غير محدد' +
                                                          " : " +
                                                          (_presenter.sheetsView !=
                                                                  null
                                                              ? _presenter.sheetsView!
                                                                          .sheetCounts !=
                                                                      null
                                                                  ? _presenter
                                                                      .sheetsView!
                                                                      .sheetCounts!
                                                                      .unassigned
                                                                      .toString()
                                                                  : "_"
                                                              : ""),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20.0,
                                                      ),
                                                    ),
                                                  ),
                                                ))),
                                        Expanded(
                                            child: Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: RaisedButton(
                                                  onPressed: (_presenter
                                                                  .sheetsView !=
                                                              null &&
                                                          _presenter.sheetsView!
                                                                  .sheetCounts !=
                                                              null)
                                                      ? () async {
                                                          _openPopup2(
                                                              context, true);
                                                        }
                                                      : null,
                                                  color: Colors.blueGrey,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.0),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            4.0),
                                                    child: Text(
                                                      'المتبقي' +
                                                          " : " +
                                                          (_presenter.sheetsView !=
                                                                  null
                                                              ? _presenter.sheetsView!
                                                                          .sheetCounts !=
                                                                      null
                                                                  ? _presenter
                                                                      .sheetsView!
                                                                      .sheetCounts!
                                                                      .remaining
                                                                      .toString()
                                                                  : "_"
                                                              : ""),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20.0,
                                                      ),
                                                    ),
                                                  ),
                                                )))
                                      ])
                                    : Divider(
                                        height: 1.0,
                                      )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : SizedBox(height: 0),
            // Show current location button
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 15.0, bottom: 60.0),
                  child: ClipOval(
                    child: Material(
                      color: Colors.orange[100], // button color
                      child: InkWell(
                        splashColor: Colors.orange, // inkwell color
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(Icons.my_location),
                        ),
                        onTap: () {
                          mapController.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(
                                  _currentPosition.latitude,
                                  _currentPosition.longitude,
                                ),
                                zoom: 15.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton:
            buildSpeedDial() /*FloatingActionButton(
          onPressed: () {
            //EasyLoading.show();
            _onLoading();
            _presenter.getDeliveryLines();

      // Add your onPressed code here!
    },
      child: Icon(Icons.play_arrow),
      backgroundColor: Colors.green,
    )*/
        ,
      ),
    );
  }

  SpeedDial buildSpeedDial() {
    return SpeedDial(
      /// both default to 16

      // animatedIcon: AnimatedIcons.menu_close,
      // animatedIconTheme: IconThemeData(size: 22.0),
      /// This is ignored if animatedIcon is non null
      icon: Icons.add,
      activeIcon: Icons.remove,
      // iconTheme: IconThemeData(color: Colors.grey[50], size: 30),

      /// The label of the main button.
      // label: Text("Open Speed Dial"),
      /// The active label of the main button, Defaults to label if not specified.
      // activeLabel: Text("Close Speed Dial"),
      /// Transition Builder between label and activeLabel, defaults to FadeTransition.
      // labelTransitionBuilder: (widget, animation) => ScaleTransition(scale: animation,child: widget),
      /// The below button size defaults to 56 itself, its the FAB size + It also affects relative padding and other elements
      buttonSize: Size(56.0, 56.0),
      visible: true,

      /// If true user is forced to close dial manually
      /// by tapping main button and overlay is not rendered.
      closeManually: false,
      curve: Curves.bounceIn,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      onOpen: () => print('OPENING DIAL'),
      onClose: () => print('DIAL CLOSED'),
      tooltip: 'Speed Dial',
      heroTag: 'speed-dial-hero-tag',
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 8.0,
      shape: CircleBorder(),
      // orientation: SpeedDialOrientation.Up,
      // childMarginBottom: 2,
      // childMarginTop: 2,
      children: [
        SpeedDialChild(
          child: Icon(Icons.play_arrow),
          backgroundColor: Colors.green,
          label: 'بدأ التسليم',
          labelStyle: TextStyle(fontSize: 18.0),
          onTap: () => {
            //_onLoading(),
            _presenter.getDeliveryLines()
          },
          onLongPress: () => print('FIRST CHILD LONG PRESS'),
        ),
        SpeedDialChild(
          child: Icon(Icons.logout),
          backgroundColor: Colors.lightBlue,
          label: 'تسجيل الخروج',
          labelStyle: TextStyle(fontSize: 18.0),
          onTap: () => {_logout()},
          onLongPress: () => print('FIRST CHILD LONG PRESS'),
        )
      ],
    );
  }

  Widget _buildPopupDialog(BuildContext context, SheetItem sheetItem) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.padding),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context, sheetItem),
    );
  }

  contentBox(context, SheetItem sheetItem) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(
              left: Constants.padding,
              top: Constants.avatarRadius + Constants.padding,
              right: Constants.padding,
              bottom: Constants.padding),
          margin: EdgeInsets.only(top: Constants.avatarRadius),
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(Constants.padding),
              boxShadow: [
                BoxShadow(
                    color: Colors.black, offset: Offset(0, 10), blurRadius: 10),
              ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                sheetItem.customer_company_name!,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              SizedBox(
                height: 15,
              ),
              Text(
                " العنوان:" + sheetItem.address!.address!,
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.start,
              ),
              SizedBox(
                height: 15,
              ),
              Text(
                " رقم الهاتف:" + sheetItem.address!.phone!,
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.start,
              ),
              SizedBox(
                height: 15,
              ),
              Text(
                " رقم الموبايل:",
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.start,
              ),
              sheetItem.address!.mobileNumbers != null
                  ? Expanded(
                      child: ListView.separated(
                        separatorBuilder: (BuildContext context, int index) =>
                            Divider(
                          color: Colors.black,
                          endIndent: 10,
                          indent: 10,
                        ),
                        itemCount: sheetItem.address!.mobileNumbers!.length,
                        itemBuilder: (context, index) {
                          return RaisedButton(
                            child:
                                Text(sheetItem.address!.mobileNumbers![index]),
                            onPressed: () {
                              UrlLauncher.launch(
                                  'tel:+${sheetItem.address!.mobileNumbers![index]}');
                            },
                          );
                        },
                      ),
                    )
                  : RaisedButton(
                      child: Text(sheetItem.address!.mobile!),
                      onPressed: () {
                        //   FlutterPhoneDirectCaller.callNumber(
                        //       sheetItem.address.mobile);
                      },
                    ),
              SizedBox(
                height: 15,
              ),
              Text(
                " الكمية:" + sheetItem.address!.quantity!,
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.start,
              ),
              SizedBox(
                height: 15,
              ),
              Text(
                " المجموع:" + sheetItem.address!.price!,
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.start,
              ),
              SizedBox(
                height: 22,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FlatButton(
                      color: Colors.white,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _launchUniversalLinkIos(
                            "https://www.google.com/maps/dir//${sheetItem.address!.location!.latitude},${sheetItem.address!.location!.longitude}");
                      },
                      child: Text(
                        "عرض الاتجاهات",
                        style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).primaryColor),
                      )),
                  FlatButton(
                      color: Theme.of(context).primaryColor,
                      onPressed: () {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            // return object of type Dialog
                            return AlertDialog(
                              title: new Text("توصيل الطلبية",
                                  textAlign: TextAlign.center),
                              content: new Text(
                                sheetItem.customer_company_name!,
                                textAlign: TextAlign.center,
                              ),
                              actions: <Widget>[
                                new FlatButton(
                                  child: new Text("لا"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                // usually buttons at the bottom of the dialog
                                new FlatButton(
                                  child: new Text("تم"),
                                  onPressed: () {
                                    _presenter.updateDeliveryItem(sheetItem);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text(
                        "تم توصيل الطلبية",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ))
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FlatButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        mapController.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: LatLng(
                                  double.parse(
                                      sheetItem.address!.location!.latitude!),
                                  double.parse(
                                      sheetItem.address!.location!.longitude!)),
                              zoom: 17.0,
                            ),
                          ),
                        );
                      },
                      color: Theme.of(context).primaryColor,
                      child: Text("عرض التفاصيل",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                          textAlign: TextAlign.center)),
                  FlatButton(
                    color: Colors.white,
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/customer');
                    },
                    child: Text("انتقال الى المكان",
                        style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).primaryColor),
                        textAlign: TextAlign.center),
                  )
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: Constants.padding,
          right: Constants.padding,
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: Constants.avatarRadius,
            child: ClipRRect(
                borderRadius:
                    BorderRadius.all(Radius.circular(Constants.avatarRadius)),
                child: Image.asset("assets/location-pin.png")),
          ),
        ),
      ],
    );
  }

  Future<void> _logout() async {
    sharedPrefs.token = "";
    location = null;
    exit(0);
  }

  Future<void> _launchUniversalLinkIos(String url) async {
    if (await canLaunch(url)) {
      final bool nativeAppLaunchSucceeded = await launch(
        url,
        forceSafariVC: false,
        universalLinksOnly: true,
      );
      if (!nativeAppLaunchSucceeded) {
        await launch(
          url,
          forceSafariVC: true,
        );
      }
    }
  }

  @override
  void onDataError(String errorTxt) {
    setState(() {});
  }

  @override
  void onDataSuccess(DeliveryLines deliverLines) {
    setState(() {
      if (_presenter.customerView == null) {
        _presenter.getCustomerViews(deliverLines.items!.first.id!);
      }
      _presenter.getDeliveryViews(deliverLines.items!.first.id!);
    });
  }

  @override
  void onDataSheetsSuccess(SheetsView sheetsView) {
    setState(() {
      _calculateDistance(sheetsView).then((isCalculated) {});
    });
  }
}

abstract class HomeScreenContract {
  void onDataSuccess(DeliveryLines deliverLines);
  void onDataSheetsSuccess(SheetsView sheetsView);
  void onDataError(String errorTxt);
}

class HomeScreenPresenter {
  HomeScreenContract _view;
  RestDatasource api = new RestDatasource();
  HomeScreenPresenter(this._view);
  SheetsView? sheetsView;
  CustomerView? customerView;
  getDeliveryLines() {
    api.getDeliveryLines().then((DeliveryLines deliverLines) {
      _view.onDataSuccess(deliverLines);
    }).catchError((Object error) => _view.onDataError(error.toString()));
  }

  updateUserLocation(double? long, double? lat) {
    api
        .updateUserLocation(long, lat)
        .then((bool response) {})
        .catchError((Object error) => _view.onDataError(error.toString()));
  }

  updateDeliveryItem(SheetItem sheetItem) {
    api.updateDeliveryItem(sheetItem).then((Response response) {
      getDeliveryLines();
    }).catchError((Object error) => _view.onDataError(error.toString()));
  }

  getDeliveryViews(String id) {
    api.getDeliveryView(id).then((SheetsView sheetsView) {
      _view.onDataSheetsSuccess(sheetsView);
      this.sheetsView = sheetsView;
    }).catchError((Object error) => _view.onDataError(error.toString()));
  }

  getCustomerViews(String id) {
    api.getCustomerView(id).then((CustomerView customerView) {
      print("customerView:$customerView");
      // _view.onDataSheetsSuccess(sheetsView);
      this.customerView = customerView;
    }).catchError((Object error) => _view.onDataError(error.toString()));
  }

  updateCustomerViews(String id, String addressId, double long, double lat) {
    api
        .updateCustomerView(id, addressId, long, lat)
        .then((CustomerView customerView) {
      print("customerView:$customerView");
      getDeliveryLines();
    }).catchError((Object error) => _view.onDataError(error.toString()));
  }
}

class Constants {
  Constants._();
  static const double padding = 20;
  static const double avatarRadius = 45;
}

class MyDialog extends StatefulWidget {
  final CustomerView? customerView;

  MyDialog({Key? key, required this.customerView}) : super(key: key);
  @override
  _MyDialogState createState() =>
      new _MyDialogState(customerView: customerView);
}

class _MyDialogState extends State<MyDialog> {
  String? indexID = "";
  List<CustomerItem>? filteredList = [];
  final CustomerView? customerView;
  _MyDialogState({Key? key, required this.customerView});

  @override
  void initState() {
    super.initState();
    filteredList = customerView!.items;
  }

  void filter(String inputString) {
    filteredList = customerView!.items!
        .where((i) => i.company_name!.toLowerCase().contains(inputString))
        .toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        width: double.maxFinite,
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          TextField(
            decoration: InputDecoration(
              hintText: 'Search ',
              hintStyle: TextStyle(
                fontSize: 14,
              ),
            ),
            onChanged: (text) {
              text = text.toLowerCase();
              filter(text);
            },
          ),
          Expanded(
            child: ListView.builder(
                itemCount: filteredList!.length,
                itemBuilder: (BuildContext context, int index) {
                  print("presenter" + filteredList![index].longitude!);
                  print("presenter" + filteredList![index].latitude!);
                  print("presenter" + filteredList![index].address!);
                  print("presenter" + filteredList![index].addressId!);
                  print("presenter" + filteredList![index].company_name!);
                  return ListTile(
                    title: Text(
                      filteredList![index].company_name!,
                      textAlign: TextAlign.right,
                    ),
                    subtitle: Text(filteredList![index].address!,
                        textAlign: TextAlign.right),
                    leading: Icon(Icons.location_pin,
                        color: (filteredList![index].longitude != null &&
                                filteredList![index].latitude != null)
                            ? Colors.red
                            : Colors.grey),
                    onTap: () {
                      indexID = filteredList![index].addressId;
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          // return object of type Dialog
                          return AlertDialog(
                            title: new Text("هل انت متأكد انك تريد حفظ الموقع",
                                textAlign: TextAlign.center),
                            actions: <Widget>[
                              new FlatButton(
                                child: new Text("لا"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              // usually buttons at the bottom of the dialog
                              new FlatButton(
                                child: new Text("تم"),
                                onPressed: () {
                                  Navigator.of(context).pop(indexID);
                                  Navigator.of(context).pop(indexID);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                }),
          ),
          Divider(
            height: 1.0,
          ),
        ]),
      ),
    );
  }
}

class MyDialog2 extends StatefulWidget {
  final SheetsView? customerView;
  final bool flag;
  MyDialog2({Key? key, required this.customerView, required this.flag})
      : super(key: key);
  @override
  _MyDialogState2 createState() => new _MyDialogState2(
        customerView: customerView,
        flag: flag,
      );
}

class _MyDialogState2 extends State<MyDialog2> {
  String? indexID = "";
  List<SheetItem>? filteredList = [];
  final SheetsView? customerView;
  final bool flag;
  _MyDialogState2({
    Key? key,
    required this.customerView,
    required this.flag,
  });

  @override
  void initState() {
    super.initState();
    if (flag == true) {
      filteredList = customerView!.items!
          .where((element) => element.address!.completed == false)
          .toList();
    } else {
      filteredList = customerView!.items;
    }
  }

  void filter(String inputString) {
    var temp = customerView!.items!
        .where(
            (i) => i.customer_company_name!.toLowerCase().contains(inputString))
        .toList();
    if (flag == true) {
      filteredList =
          temp.where((element) => element.address!.completed == false).toList();
    } else {
      filteredList = temp;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        width: double.maxFinite,
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          TextField(
            decoration: InputDecoration(
              hintText: 'Search ',
              hintStyle: TextStyle(
                fontSize: 14,
              ),
            ),
            onChanged: (text) {
              text = text.toLowerCase();
              filter(text);
            },
          ),
          Expanded(
            child: ListView.builder(
                itemCount: filteredList!.length,
                itemBuilder: (BuildContext context, int index) {
                  bool showNoteText = false;
                  return Column(
                    children: [
                      ListTile(
                        title: Text(
                          filteredList![index].customer_company_name!,
                          textAlign: TextAlign.right,
                        ),
                        subtitle: Text(filteredList![index].address!.address!,
                            textAlign: TextAlign.right),
                        leading: Icon(Icons.location_pin, color: Colors.red),
                        onTap: () {
                          print(filteredList![index].address);
                          print(filteredList![index].customer_company_name);
                          print(filteredList![index].id);
                          indexID = filteredList![index].addressId;

                          Navigator.of(context).pop(filteredList![index]);
                        },
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.01,
                      ),
                      if (filteredList![index].showText == null ||
                          filteredList![index].showText == false)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              print("cliekct Text");
                              filteredList![index].showText = true;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.note_alt_outlined),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.02,
                              ),
                              Text("Add note"),
                            ],
                          ),
                        ),
                      if (filteredList![index].showText != null &&
                          filteredList![index].showText == true)
                        TextField(
                          decoration: InputDecoration(
                              // border: OutlineInputBorder(),
                              hintText: 'Enter a search term',
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    filteredList![index].showText = false;
                                  });
                                },
                                icon: Icon(Icons.send),
                              )),
                        ),
                      Divider(),
                    ],
                  );
                }),
          ),
          Divider(
            height: 1.0,
          ),
        ]),
      ),
    );
  }
}
