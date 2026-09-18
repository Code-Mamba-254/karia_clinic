import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/edit_consultation_screen.dart';
import '../models/consultation.dart';

class ConsultationCard extends StatelessWidget {
  final Consultation consultation;

  const ConsultationCard({super.key, required this.consultation});

  Widget buildSection(String title, String value) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat(
                        "dd MMM yyyy • hh:mm a",
                      ).format(consultation.createdAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recorded by ${consultation.recordingDoctorLabel}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSection("Chief Complaint", consultation.chiefComplaint),

                buildSection("Diagnosis", consultation.diagnosis),

                buildSection("Investigations", consultation.investigations),

                buildSection("Treatment", consultation.treatment),

                buildSection("Lab Feedback", consultation.labFeedback),

                if (consultation.temperature.isNotEmpty ||
                    consultation.pulseRate.isNotEmpty ||
                    consultation.bloodPressure.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Vital Signs",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text("Temperature: ${consultation.temperature} °C"),
                        Text("Pulse: ${consultation.pulseRate} bpm"),
                        Text(
                          "Respiratory Rate: ${consultation.respiratoryRate}/min",
                        ),
                        Text("Blood Pressure: ${consultation.bloodPressure}"),
                        Text("Oxygen: ${consultation.oxygenSaturation}%"),
                        Text("Weight: ${consultation.weight} kg"),
                        Text("Height: ${consultation.height} cm"),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditConsultationScreen(
                            consultation: consultation,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
                buildSection("Remarks", consultation.remarks),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
