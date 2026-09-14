import 'package:flutter/material.dart';

import 'custom_textfield.dart';
import 'primary_button.dart';

class ConsultationFormCard extends StatelessWidget {
  final TextEditingController chiefComplaintController;

  // Vitals
  final TextEditingController temperatureController;
  final TextEditingController pulseController;
  final TextEditingController respiratoryController;
  final TextEditingController bpController;
  final TextEditingController oxygenController;
  final TextEditingController weightController;
  final TextEditingController heightController;

  // Consultation
  final TextEditingController investigationsController;
  final TextEditingController diagnosisController;
  final TextEditingController treatmentController;
  final TextEditingController labController;
  final TextEditingController remarksController;

  final VoidCallback onSave;

  const ConsultationFormCard({
    super.key,
    required this.chiefComplaintController,

    required this.temperatureController,
    required this.pulseController,
    required this.respiratoryController,
    required this.bpController,
    required this.oxygenController,
    required this.weightController,
    required this.heightController,

    required this.investigationsController,
    required this.diagnosisController,
    required this.treatmentController,
    required this.labController,
    required this.remarksController,

    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ==========================
            /// CHIEF COMPLAINT
            /// ==========================

            const Text(
              "Chief Complaint",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 12),

            CustomTextField(
              controller: chiefComplaintController,
              label: "Chief Complaint",
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            /// ==========================
            /// VITAL SIGNS
            /// ==========================

            const Text(
              "Vital Signs",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: temperatureController,
                    label: "Temperature (°C)",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: pulseController,
                    label: "Pulse",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: respiratoryController,
                    label: "Respiratory Rate",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: bpController,
                    label: "Blood Pressure",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: oxygenController,
                    label: "Oxygen %",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: weightController,
                    label: "Weight (kg)",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            CustomTextField(
              controller: heightController,
              label: "Height (cm)",
            ),

            const SizedBox(height: 24),

            /// ==========================
            /// CLINICAL NOTES
            /// ==========================

            const Text(
              "Clinical Notes",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 12),

            CustomTextField(
              controller: investigationsController,
              label: "Investigations",
              maxLines: 3,
            ),

            const SizedBox(height: 12),

            CustomTextField(
              controller: diagnosisController,
              label: "Diagnosis",
              maxLines: 3,
            ),

            const SizedBox(height: 12),

            CustomTextField(
              controller: treatmentController,
              label: "Treatment",
              maxLines: 3,
            ),

            const SizedBox(height: 12),

            CustomTextField(
              controller: labController,
              label: "Lab Feedback",
              maxLines: 3,
            ),

            const SizedBox(height: 12),

            CustomTextField(
              controller: remarksController,
              label: "Remarks",
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: "Save Consultation",
                onPressed: onSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}