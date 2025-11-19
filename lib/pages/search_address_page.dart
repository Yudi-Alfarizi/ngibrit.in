// lib/pages/search_address_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/button_primary.dart';

class SearchAddressPage extends StatefulWidget {
  const SearchAddressPage({super.key});

  @override
  State<SearchAddressPage> createState() => _SearchAddressPageState();
}

class _SearchAddressPageState extends State<SearchAddressPage> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode _focus = FocusNode();
  List<Map<String, dynamic>> results = [];
  bool loading = false;
  Timer? _debounce;

  static const _nominatimBase =
      "https://nominatim.openstreetmap.org/search";

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() {
        results = [];
        loading = false;
      });
      return;
    }

    // debounce 500ms
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchAddress(q.trim());
    });
  }

  Future<void> _searchAddress(String query) async {
    setState(() {
      loading = true;
    });

    // Batasi ke Indonesia dengan countrycodes=id
    final url =
        '$_nominatimBase?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=10&countrycodes=id';

    try {
      final res = await http.get(Uri.parse(url), headers: {
        "User-Agent": "ngibrit_in_app/1.0 (your_email@example.com)"
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        final list = data.map<Map<String, dynamic>>((item) {
          return {
            "title": item['display_name'],
            "lat": double.tryParse(item['lat'].toString()) ?? 0.0,
            "lon": double.tryParse(item['lon'].toString()) ?? 0.0,
          };
        }).toList();

        setState(() {
          results = list;
        });
      } else {
        setState(() {
          results = [];
        });
      }
    } catch (e) {
      setState(() {
        results = [];
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    searchController.clear();
    _focus.requestFocus();
    setState(() {
      results = [];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEFEFF0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Color(0xff070623)),
        ),
        title: const Text(
          "Cari Lokasi",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xff070623),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      focusNode: _focus,
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: "Cari lokasi pengambilan motor",
                        border: InputBorder.none,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  // clear button
                  if (searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: _clearSearch,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // hasil
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : results.isEmpty
                    ? const Center(
                        child: Text(
                          "Belum ada hasil",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: results.length,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemBuilder: (context, index) {
                          final item = results[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context, {
                                "address": item["title"],
                                "lat": item["lat"],
                                "lng": item["lon"],
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item["title"],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xff070623),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // bottom button (opsional)
          Padding(
            padding: const EdgeInsets.all(20),
            child: ButtonPrimary(
              text: "Buka Maps",
              onTap: () {
                // beri sinyal ke peta untuk kembali dan fokus (jika diperlukan)
                Navigator.pop(context, {"openMap": true});
              },
            ),
          ),
        ],
      ),
    );
  }
}
