import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        child: Center(
          child: MapWidget(),
        ),
      ),
    );
  }
}

class MapWidget extends StatefulWidget {
  @override
  MapWidgetState createState() => MapWidgetState();
}

class MapWidgetState extends State<MapWidget> {
  LatLng _currentPosition =
      LatLng(-31.5375, -68.536389); // Ubicación predeterminada
  late MapController _mapController;
  bool _hasLocation = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeLocation();
    _startLocationUpdates(); // Inicia la actualización de la ubicación en tiempo real
  }

  void _initializeLocation() async {
    LatLng position = await _determinePosition();
    setState(() {
      _currentPosition = position;
      _hasLocation = true;
    });
  }

  Future<LatLng> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return _currentPosition;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Location permissions are denied.');
        return _currentPosition;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error obtaining location: $e');
      return _currentPosition;
    }
  }

  // Actualiza la ubicación en tiempo real
  void _startLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _mapController.move(
          _currentPosition,
          _mapController.zoom,
        ); // Mueve el mapa junto con el marcador
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final accessToken =
        'pk.eyJ1IjoieWFtaWxzYWFkIiwiYSI6ImNsdnNrbjRsMzBzcWYybG51aTVvandxZncifQ.IfQ7hJid0wPq4pmj4_fmhQ';

    return _hasLocation
        ? FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentPosition,
              zoom: 15,
              minZoom: 5,
              maxZoom: 18,
              onMapReady: () {
                // Mover el mapa a la posición actual una vez que el mapa esté listo
                _mapController.move(_currentPosition, 15);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/256/{z}/{x}/{y}@2x?access_token=$accessToken',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 60,
                    height: 60,
                    point: _currentPosition,
                    child: Icon(
                      Icons.location_on,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          )
        : Center(child: CircularProgressIndicator());
  }
}
