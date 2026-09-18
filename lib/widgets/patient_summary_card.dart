import 'package:flutter/material.dart';

import '../models/patient.dart';

class PatientSummaryCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback? onEdit;

  const PatientSummaryCard({super.key, required this.patient, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    patient.name.isEmpty ? '?' : patient.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        patient.clinicNumber,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    tooltip: 'Edit patient biodata',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
              ],
            ),

            const Divider(height: 30),

            Row(
              children: [
                const Icon(Icons.person_outline),

                const SizedBox(width: 8),

                Text(
                  "${patient.sex.name == 'male' ? 'Male' : 'Female'} • ${patient.ageLabel()}",
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.home_outlined),

                const SizedBox(width: 8),

                Expanded(child: Text(patient.residence)),
              ],
            ),

            if (patient.idNumber != null && patient.idNumber!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined),

                    const SizedBox(width: 8),

                    Text(patient.idNumber!),
                  ],
                ),
              ),

            if (patient.phoneNumber != null && patient.phoneNumber!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined),

                    const SizedBox(width: 8),

                    Text(patient.phoneNumber!),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
