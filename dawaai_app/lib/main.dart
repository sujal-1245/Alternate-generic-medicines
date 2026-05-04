// lib/main.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'splash_screen.dart';

const String BASE_URL = "https://alternate-generic-medicines.onrender.com";

void main() {
  runApp(const DawaaiApp());
}

class DawaaiApp extends StatelessWidget {
  const DawaaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dawaai',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _results = [];
  List<dynamic> _suggested = [];
  bool _loading = false;
  String _error = '';

  final List<String> _fallbackImages = [
    "https://wwwnc.cdc.gov/travel/images/travel-with-medicine.jpg",
    "https://static.scientificamerican.com/sciam/cache/file/BC2412FA-1388-43B7-877759A80E201C16_source.jpg?w=1200",
    "https://www.thehastingscenter.org/wp-content/smush-webp/pills.png.webp",
    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSdsUwkcQlgMljrzw6jH17q7d_SwSFUgs88Lg&s",
    "https://images.theconversation.com/files/256057/original/file-20190129-108364-17hlc1x.jpg",
    "https://www.hopkinsmedicine.org/-/media/images/health/3_-wellness/living-with-a-chronic-disease/help-for-managing-multiple-medications-hero.jpg",
    "https://medshadow.org/wp-content/uploads/2012/11/medicine-883x577.jpeg",
    "https://b2976109.smushcdn.com/2976109/wp-content/uploads/2019/04/tablets_750.jpg?lossy=2",
  ];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions({bool retry = true}) async {
    try {
      final url = Uri.parse("$BASE_URL/suggestions");
      final res = await http.get(url).timeout(const Duration(seconds: 30));

      print("SUGGESTIONS STATUS: ${res.statusCode}");
      print("SUGGESTIONS BODY: ${res.body}");

      if (res.statusCode == 200) {
        final jsonBody = json.decode(res.body);
        if (mounted) {
          setState(() {
            _suggested = jsonBody["data"] ?? [];
          });
        }
      }
    } catch (e) {
      print("Suggestions error: $e");

      // 👇 retry only once (important to avoid infinite loop)
      if (retry) {
        print("Retrying suggestions...");
        await Future.delayed(const Duration(seconds: 3));
        return _loadSuggestions(retry: false);
      }

      if (mounted) setState(() => _suggested = []);
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = '';
      _results = [];
    });

    try {
      final url = Uri.parse("$BASE_URL/search");
      final res = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: json.encode({"medicine": query}),
          )
          .timeout(const Duration(seconds: 35));

      print("STATUS: ${res.statusCode}");
      print("BODY: ${res.body}");

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body["status"] == "success") {
          List<dynamic> list = body["data"] ?? [];
          list.sort((a, b) {
            double pa = _toPrice(a["Price (₹)"]);
            double pb = _toPrice(b["Price (₹)"]);
            return pb.compareTo(pa);
          });
          setState(() => _results = list);
          Future.delayed(const Duration(milliseconds: 200), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                400,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            }
          });
        } else {
          setState(() => _error = body["message"] ?? "Unknown backend error");
        }
      } else {
        setState(() => _error = "Server error: ${res.statusCode}");
      }
    } catch (e) {
      setState(() => _error = "Network error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _locateMedicine(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text("Locate Medicine"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter city or pincode, or leave empty for nearby search",
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "City or Pincode",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                String location = controller.text.trim();
                if (location.isNotEmpty) {
                  // Search for generic medicine stores near entered location
                  String query = Uri.encodeComponent(
                    "generic medicine store near $location",
                  );
                  final url =
                      "https://www.google.com/maps/search/?api=1&query=$query";
                  await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                } else {
                  // If input empty, search near current location
                  bool serviceEnabled =
                      await Geolocator.isLocationServiceEnabled();
                  if (!serviceEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Location services are disabled"),
                      ),
                    );
                    return;
                  }
                  LocationPermission permission =
                      await Geolocator.checkPermission();
                  if (permission == LocationPermission.denied) {
                    permission = await Geolocator.requestPermission();
                    if (permission == LocationPermission.denied) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Location permission denied"),
                        ),
                      );
                      return;
                    }
                  }
                  if (permission == LocationPermission.deniedForever) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Location permission denied forever"),
                      ),
                    );
                    return;
                  }
                  Position position = await Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high,
                  );
                  final url =
                      "https://www.google.com/maps/search/?api=1&query=generic+medicine+store+near+${position.latitude},${position.longitude}";
                  await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              child: const Text("Search"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  double _toPrice(dynamic raw) {
    try {
      if (raw == null) return 0;
      if (raw is num) return raw.toDouble();
      if (raw is String) {
        final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
        return double.tryParse(cleaned) ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  String _getMedName(dynamic med) {
    return med["Medicine Name"] ??
        med["name"] ??
        med["Name"] ??
        med["medicine"] ??
        "Unknown";
  }

  String _getPriceString(dynamic med) {
    final p = med["Price (₹)"];
    if (p == null) return "N/A";
    return "₹${p.toString()}";
  }

  String _getImageUrl(dynamic med) {
    if (med is Map &&
        med.containsKey("image") &&
        med["image"] != null &&
        med["image"].toString().isNotEmpty) {
      return med["image"];
    }
    final rnd = Random(_getMedName(med).hashCode);
    return _fallbackImages[rnd.nextInt(_fallbackImages.length)];
  }

  void _showDetails(Map<String, dynamic> medicine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, sc) {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: sc,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _getImageUrl(medicine),
                            height: 90,
                            width: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 90,
                              width: 90,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.medical_services,
                                size: 48,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getMedName(medicine),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                medicine["Manufacturer"] ??
                                    "Manufacturer unknown",
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[700],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getPriceString(medicine),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Details
                    const Text(
                      "Details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _detailRow("Type", medicine["Type"]),
                    _detailRow("Pack Size", medicine["Pack Size"]),
                    _detailRow("Symptoms", medicine["Symptoms"]),
                    const SizedBox(height: 18),
                    // Locate Medicine Button
                    ElevatedButton.icon(
                      onPressed: () => _locateMedicine(context),
                      icon: const Icon(Icons.location_on),
                      label: const Text("Locate Medicine"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors
                            .white, // <-- This makes the text and icon white
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    // Close button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                      label: const Text("Close"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 223, 69, 69),
                        foregroundColor: Colors
                            .white, // <-- text and icon color set to white
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value?.toString() ?? "—")),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          // logo + title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Colors.green,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Dawaai",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              _loadSuggestions();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Refreshing suggestions")),
              );
            },
            icon: const Icon(Icons.refresh, color: Colors.grey),
            tooltip: "Refresh suggestions",
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xffe8f7ef), Colors.white],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: "Search medicines, symptoms...",
                  border: InputBorder.none,
                ),
                onSubmitted: (v) => _search(v),
              ),
            ),
            IconButton(
              onPressed: () => _search(_controller.text),
              icon: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.green,
                child: Icon(Icons.search, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF63C8A7), Color(0xFF2FAF7D)],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.network(
                  "https://img.freepik.com/free-vector/flat-medical-students-doctor-professor-with-patient-hospital-room-young-healthcare_88138-1735.jpg?semt=ais_hybrid&w=740&q=80",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Colors.teal[200]);
                  },
                ),
              ),
              // Dark overlay for readability
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.35)),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Left side text + button
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Affordable Medicines",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Find generic alternatives & trusted brands",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Right side image with overlay text
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            "https://images.unsplash.com/photo-1580281657521-7f3d6b97b4b8?auto=format&fit=crop&w=600&q=80",
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                color: Colors.teal[100],
                                child: const Icon(
                                  Icons.medical_services,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.black.withOpacity(0.4),
                          ),
                          alignment: Alignment.center,
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "Generic alternatives\nfor costly medicines",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final List<Map<String, dynamic>> cats = [
      {"title": "Antibiotics", "icon": Icons.healing},
      {"title": "Pain Relief", "icon": Icons.local_hospital},
      {"title": "Vitamins", "icon": Icons.health_and_safety},
      {"title": "Diabetes", "icon": Icons.bloodtype},
      {"title": "Cardiac", "icon": Icons.favorite},
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, i) {
            final c = cats[i];
            return InkWell(
              onTap: () {
                _controller.text = c["title"];
                _search(c["title"]);
              },
              child: Container(
                width: 110,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green[50],
                      child: Icon(c["icon"], color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c["title"],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemCount: cats.length,
        ),
      ),
    );
  }

  Widget _buildSuggested() {
    if (_suggested.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text("No suggestions (server may be waking up...)"),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 18, 16, 6),
          child: Text(
            "Suggested",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _suggested.length,
            itemBuilder: (context, i) {
              final med = _suggested[i] as Map<String, dynamic>;
              final name = med["Medicine Name"] ?? "Unknown";
              final price = med["Price (₹)"] ?? "N/A";
              final img = _getImageUrl(med);

              return GestureDetector(
                onTap: () => _showDetails(Map<String, dynamic>.from(med)),
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            img,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.medical_services,
                                size: 48,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹$price",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      if (_loading) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (_error.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              _error,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    // Sorting logic
    List<Map<String, dynamic>> meds = List<Map<String, dynamic>>.from(_results);

    if (meds.length > 1) {
      // Find costliest item
      meds.sort((a, b) {
        double pa = _toPrice(a["Price (₹)"]);
        double pb = _toPrice(b["Price (₹)"]);
        return pb.compareTo(pa); // Descending order
      });
      Map<String, dynamic> branded = meds.first;
      List<Map<String, dynamic>> generics = meds.sublist(1);
      generics.sort((a, b) {
        double pa = _toPrice(a["Price (₹)"]);
        double pb = _toPrice(b["Price (₹)"]);
        return pa.compareTo(pb); // Ascending order
      });
      meds = [branded, ...generics];
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Search Results",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: meds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final med = meds[i];
              final name = _getMedName(med);
              final price = _getPriceString(med);
              final isBranded = i == 0; // Only the top is branded
              final img = _getImageUrl(med);

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showDetails(Map<String, dynamic>.from(med)),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            img,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 64,
                              height: 64,
                              color: Colors.grey[100],
                              child: const Icon(
                                Icons.medical_services,
                                color: Colors.green,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Text info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                med["Manufacturer"] ?? "Unknown manufacturer",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                price,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tag
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isBranded
                                    ? Colors.green[700]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isBranded ? "Branded" : "Generic",
                                style: TextStyle(
                                  color:
                                      isBranded ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadSuggestions();
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildTopBar()),
              SliverToBoxAdapter(child: _buildSearchCard()),
              SliverToBoxAdapter(child: _buildBanner()),
              SliverToBoxAdapter(child: _buildCategories()),
              SliverToBoxAdapter(child: _buildSuggested()),
              SliverToBoxAdapter(child: _buildResults()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      "© ${DateTime.now().year} Dawaai. All rights reserved.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
