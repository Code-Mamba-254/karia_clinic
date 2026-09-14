import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../enums/sex.dart';

class PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;

  const PatientCard({
    super.key,
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            child: Text(
              patient.name.isNotEmpty
                  ? patient.name[0].toUpperCase()
                  : "?",
            ),
          ),
          title: Text(patient.name),
          subtitle: Text(
            "${patient.sex == Sex.male ? "Male" : "Female"} • ${patient.ageInYears} years",
          ),
          trailing: const Icon(Icons.arrow_forward_ios),
        ),
      ),
    );
  }
}