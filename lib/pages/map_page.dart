import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';


class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;
  LatLng? _currentP;
  final Location _locationController = Location();

  final LatLng _pGooglePlex = const LatLng(
    37.42796133580664,
    -122.085749655962,
  );
  final LatLng _pApplePark = const LatLng(37.334900, -122.009020);

  List<LatLng> _polylineCoordinates = [];

  @override
  void initState() {
    super.initState();
    getLocationUpdates();
    getPolylinePoints(); // fetch polyline once locations are set
  }

  Future<void> getLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final locationData = await _locationController.getLocation();
    setState(() {
      _currentP = LatLng(locationData.latitude!, locationData.longitude!);
    });

    _locationController.onLocationChanged.listen((newLoc) {
      setState(() {
        _currentP = LatLng(newLoc.latitude!, newLoc.longitude!);
      });

      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentP!, zoom: 13.5),
          ),
        );
      }
    });
  }

Future<void> getPolylinePoints() async {
  PolylinePoints polylinePoints = PolylinePoints();

  PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
    "YOUR_GOOGLE_MAPS_API_KEY", // replace this with your actual API key
    PointLatLng(_pGooglePlex.latitude, _pGooglePlex.longitude),
    PointLatLng(_pApplePark.latitude, _pApplePark.longitude),
    travelMode: TravelMode.driving,
  );

  if (result.points.isNotEmpty) {
    _polylineCoordinates.clear();
    for (var point in result.points) {
      _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
    }
    setState(() {});
  } else {
    debugPrint('Error retrieving polyline: ${result.errorMessage}');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _currentP == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                onMapCreated: (controller) => mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: _currentP!,
                  zoom: 13.5,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId("currentLocation"),
                    position: _currentP!,
                  ),
                  Marker(
                    markerId: const MarkerId("source"),
                    position: _pGooglePlex,
                  ),
                  Marker(
                    markerId: const MarkerId("destination"),
                    position: _pApplePark,
                  ),
                },
                polylines: {
                  Polyline(
                    polylineId: const PolylineId("route"),
                    points: _polylineCoordinates,
                    color: Colors.blue,
                    width: 6,
                  ),
                },
              ),
    );
  }
}
