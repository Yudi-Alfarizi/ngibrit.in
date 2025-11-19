import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class SearchLocationPage extends StatefulWidget {
  final Function(LatLng latLng, String address) onSelected;

  const SearchLocationPage({super.key, required this.onSelected});

  @override
  State<SearchLocationPage> createState() => _SearchLocationPageState();
}

class _SearchLocationPageState extends State<SearchLocationPage> {
  final TextEditingController searchC = TextEditingController();
  List<dynamic> results = [];
  Timer? debounce;

  void searchLocation(String query) {
    if (debounce?.isActive ?? false) debounce!.cancel();

    debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() => results = []);
        return;
      }

      final url =
          "https://nominatim.openstreetmap.org/search"
          "?format=json"
          "&q=$query"
          "&countrycodes=id"
          "&addressdetails=1"
          "&limit=10"
          "&accept-language=id";

      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {"User-Agent": "MyFlutterApp"},
        );

        if (response.statusCode == 200) {
          results = jsonDecode(response.body);
          if (mounted) setState(() {});
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: StatefulBuilder(
          builder: (context, setAppBarState) {
            return TextField(
              controller: searchC,
              autofocus: true,
              onChanged: (txt) {
                setAppBarState(() {}); // update tombol X
                searchLocation(txt);
              },
              decoration: InputDecoration(
                hintText: "Cari lokasi...",
                border: InputBorder.none,
                suffixIcon: searchC.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          searchC.clear();
                          setAppBarState(() {});
                          setState(() => results = []);
                        },
                        child: const Icon(Icons.close, color: Colors.black),
                      )
                    : null,
              ),
            );
          },
        ),
      ),

      body: results.isEmpty
          ? const Center(
              child: Text(
                "Ketik untuk mencari lokasi...",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              itemCount: results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final item = results[i];
                final lat = double.tryParse(item["lat"] ?? "0") ?? 0;
                final lon = double.tryParse(item["lon"] ?? "0") ?? 0;

                final display =
                    item["display_name"] ??
                    "${item["address"]?["road"] ?? ""} ${item["address"]?["city"] ?? ""}";

                return ListTile(
                  title: Text(
                    display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    FocusScope.of(context).unfocus(); // penting!
                    widget.onSelected(LatLng(lat, lon), display);
                    Navigator.pop(context);
                  },
                );
              },
            ),
    );
  }
}
