import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class LocationResult {
  final String displayName;
  final double latitude;
  final double longitude;

  LocationResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

class LocationSearchDialog extends StatefulWidget {
  const LocationSearchDialog({super.key});

  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<LocationResult> _results = [];
  bool _isLoading = false;
  Timer? _debounce;
  String _error = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query.trim());
      } else {
        setState(() {
          _results = [];
          _error = '';
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final client = HttpClient();
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}');
      final request = await client.getUrl(uri);
      
      // Nominatim requires a user-agent for API usage
      request.headers.set('User-Agent', 'PassItOnApp/1.0');
      
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final List<dynamic> data = jsonDecode(responseBody);

        final results = data.map((json) {
          return LocationResult(
            displayName: json['display_name'] ?? 'Unknown Location',
            latitude: double.tryParse(json['lat'].toString()) ?? 0.0,
            longitude: double.tryParse(json['lon'].toString()) ?? 0.0,
          );
        }).toList();

        setState(() {
          _results = results;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to search location (Error ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred while searching.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search for a location...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF8B8B8B),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF8B8B8B),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xFF8B8B8B)),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF0F4C3A),
                  ),
                ),
              )
            else if (_error.isNotEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _error,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_results.isEmpty && _searchController.text.isNotEmpty)
              const Expanded(
                child: Center(
                  child: Text('No results found.'),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: Color(0xFFE8EBE9),
                  ),
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      leading: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF0F4C3A),
                      ),
                      title: Text(
                        result.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1C1E),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context, result);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
