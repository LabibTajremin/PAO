import 'package:flutter/material.dart';

const _icons = <String, IconData>{
  'bolt': Icons.bolt,
  'plug': Icons.electrical_services,
  'electrician': Icons.electrical_services,
  'plumbing': Icons.plumbing,
  'plumber': Icons.plumbing,
  'faucet': Icons.plumbing,
  'water': Icons.water_drop_outlined,
  'ac': Icons.ac_unit,
  'snowflake': Icons.ac_unit,
  'salon': Icons.content_cut,
  'scissors': Icons.content_cut,
  'spa': Icons.spa_outlined,
  'car': Icons.directions_car_outlined,
  'driver': Icons.directions_car_outlined,
  'broom': Icons.cleaning_services_outlined,
  'cleaning': Icons.cleaning_services_outlined,
  'home': Icons.home_repair_service_outlined,
  'paint': Icons.format_paint_outlined,
  'gas': Icons.local_fire_department_outlined,
};

/// The icon for a catalog `iconKey`; admins pick keys freely, so unknown ones
/// fall back to a generic tool.
IconData catalogIcon(String key) => _icons[key] ?? Icons.handyman_outlined;
