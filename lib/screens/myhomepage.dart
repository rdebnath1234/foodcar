import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:foodcar/profiletab.dart';
import 'package:foodcar/screens/food_order/food_order_screen.dart'; // updated
import 'package:foodcar/screens/dinning/dining.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final Set<Marker> _markers = {};
  String _currentAddress = 'Unknown location';
  User? _currentUser;
  Map<String, dynamic>? _userData;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/');
      });
    } else {
      _getCurrentLocation();
      _loadUserData();
    }
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data();
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location permission permanently denied."),
        ),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final updatedLatLng = LatLng(position.latitude, position.longitude);
      String address = 'Unknown location';

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address =
              '${place.name ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}';
        }
      } catch (e) {
        debugPrint('Error during reverse geocoding: $e');
      }

      setState(() {
        _currentAddress = address;
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: updatedLatLng,
            infoWindow: InfoWindow(title: 'Your Location', snippet: address),
          ),
        );
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(updatedLatLng, 15),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Current location: $address')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.brown[50],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          backgroundColor: Colors.brown[50],
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/food-delivery-app-logo.svg',
                height: 30,
                width: 30,
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                    fontFamily: 'Pacifico'),
              ),
            ],
          ),
          actions: [
            Builder(
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () => Scaffold.of(context).openEndDrawer(),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.brown,
                      backgroundImage: _userData?['profileImage'] != null
                          ? NetworkImage(_userData!['profileImage'])
                          : null,
                      child: _userData?['profileImage'] == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        endDrawer: Drawer(
          child: ListView(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                    color: Color.fromARGB(125, 121, 85, 72)),
                accountName: Text(
                  _userData?['name'] ?? 'User',
                  style: const TextStyle(color: Colors.white),
                ),
                accountEmail: Text(
                  _userData?['email'] ?? 'No email',
                  style: const TextStyle(color: Colors.white70),
                ),
                currentAccountPicture: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileTab()),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.blue,
                    backgroundImage: _userData?['profileImage'] != null
                        ? NetworkImage(_userData!['profileImage'])
                        : null,
                    child: _userData?['profileImage'] == null
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                onTap: () => Navigator.pushNamed(context, '/about'),
              ),
              ListTile(
                leading: const Icon(Icons.contact_mail),
                title: const Text('Contacts'),
                onTap: () => Navigator.pushNamed(context, '/contact'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/');
                },
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.location_on, color: Colors.brown),
                      onPressed: _getCurrentLocation,
                      tooltip: 'Detect Location',
                    ),
                    Expanded(
                      child: Text(
                        _currentAddress,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for restaurants, food, or cuisines',
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.brown),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.brown),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const TabBar(
                indicatorColor: Colors.brown,
                labelColor: Colors.brown,
                unselectedLabelColor: Colors.brown,
                tabs: [
                  Tab(icon: Icon(Icons.fastfood), text: 'Food Order'),
                  Tab(icon: Icon(Icons.restaurant), text: 'Dining'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    FoodOrderScreen(searchQuery: _searchQuery), // modular
                    Dining(searchQuery: _searchQuery),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
