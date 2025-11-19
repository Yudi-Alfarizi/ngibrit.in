import 'package:flutter/material.dart';

class MapPin extends StatelessWidget {
  const MapPin({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.location_on,
      size: 42,
      color: Color(0xff4A1DFF),
    );
  }
}
