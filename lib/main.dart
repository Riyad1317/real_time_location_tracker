import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // ম্যাপ কন্ট্রোলার
  GoogleMapController? _mapController;

  // বর্তমান লোকেশন রাখার ভেরিয়েবল
  LatLng _initialPosition = const LatLng(23.8103, 90.4125); // Default: Dhaka

  // মার্কার এবং পলিলাইন সেট
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // পলিলাইন আঁকার জন্য লোকেশন লিস্ট
  final List<LatLng> _polylineCoordinates = [];

  // টাইমার (প্রতি ১০ সেকেন্ড আপডেটের জন্য)
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _getUserLocation(); // অ্যাপ চালুর সাথে সাথে লোকেশন নিবে

    // ২. প্রতি ১০ সেকেন্ড পর পর লোকেশন আপডেট করবে (Requirement 2)
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _getUserLocation();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // অ্যাপ বন্ধ হলে টাইমার বন্ধ হবে
    _mapController?.dispose();
    super.dispose();
  }

  // লোকেশন পারমিশন এবং লোকেশন পাওয়ার ফাংশন
  Future<void> _getUserLocation() async {
    // পারমিশন চেক
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // বর্তমান লোকেশন নেওয়া
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    LatLng currentLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _initialPosition = currentLatLng;

      // ৩. পলিলাইন আপডেট (Requirement 3)
      _polylineCoordinates.add(currentLatLng);
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("tracking_route"),
          color: Colors.blue,
          width: 5,
          points: _polylineCoordinates,
        ),
      );

      // ৪. মার্কার আপডেট এবং ইনফো উইন্ডো (Requirement 4)
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId("current_location"),
          position: currentLatLng,
          infoWindow: InfoWindow(
            title: "My current location",
            snippet: "${position.latitude}, ${position.longitude}",
          ),
        ),
      );
    });

    // ১. ম্যাপ এনিমেট করে কারেন্ট লোকেশনে যাবে (Requirement 1)
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(currentLatLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Google Maps Tracker"),
        backgroundColor: Colors.blueAccent,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 15,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: true, // নীল ডট দেখানোর জন্য
        myLocationButtonEnabled: true,
      ),
    );
  }
}