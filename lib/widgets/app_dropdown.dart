import 'package:flutter/material.dart';

class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String label;
  final IconData icon;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,

      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),

      items: items,

      onChanged: onChanged,
    );
  }
}