import 'package:flutter/material.dart';

import '../models/consultation.dart';
import '../services/consultation_service.dart';

class EditConsultationScreen extends StatefulWidget {
  final Consultation consultation;

  const EditConsultationScreen({
    super.key,
    required this.consultation,
  });

  @override
  State<EditConsultationScreen> createState() =>
      _EditConsultationScreenState();
}

class _EditConsultationScreenState
    extends State<EditConsultationScreen> {
  final ConsultationService _consultationService =
      ConsultationService();

  late TextEditingController chiefComplaintController;

  late TextEditingController temperatureController;
  late TextEditingController pulseController;
  late TextEditingController respiratoryController;
  late TextEditingController bpController;
  late TextEditingController oxygenController;
  late TextEditingController weightController;
  late TextEditingController heightController;

  late TextEditingController investigationsController;
  late TextEditingController diagnosisController;
  late TextEditingController treatmentController;
  late TextEditingController labController;
  late TextEditingController remarksController;

  @override
  void initState() {
    super.initState();

    final c = widget.consultation;

    chiefComplaintController =
        TextEditingController(text: c.chiefComplaint);

    temperatureController =
        TextEditingController(text: c.temperature);

    pulseController =
        TextEditingController(text: c.pulseRate);

    respiratoryController =
        TextEditingController(text: c.respiratoryRate);

    bpController =
        TextEditingController(text: c.bloodPressure);

    oxygenController =
        TextEditingController(text: c.oxygenSaturation);

    weightController =
        TextEditingController(text: c.weight);

    heightController =
        TextEditingController(text: c.height);

    investigationsController =
        TextEditingController(text: c.investigations);

    diagnosisController =
        TextEditingController(text: c.diagnosis);

    treatmentController =
        TextEditingController(text: c.treatment);

    labController =
        TextEditingController(text: c.labFeedback);

    remarksController =
        TextEditingController(text: c.remarks);
  }

  @override
  void dispose() {
    chiefComplaintController.dispose();

    temperatureController.dispose();
    pulseController.dispose();
    respiratoryController.dispose();
    bpController.dispose();
    oxygenController.dispose();
    weightController.dispose();
    heightController.dispose();

    investigationsController.dispose();
    diagnosisController.dispose();
    treatmentController.dispose();
    labController.dispose();
    remarksController.dispose();

    super.dispose();
  }

  Future<void> updateConsultation() async {
    final updated = Consultation(
      id: widget.consultation.id,
      patientId: widget.consultation.patientId,
      doctorId: widget.consultation.doctorId,
      doctorEmail: widget.consultation.doctorEmail,

      chiefComplaint:
          chiefComplaintController.text.trim(),

      temperature:
          temperatureController.text.trim(),

      pulseRate:
          pulseController.text.trim(),

      respiratoryRate:
          respiratoryController.text.trim(),

      bloodPressure:
          bpController.text.trim(),

      oxygenSaturation:
          oxygenController.text.trim(),

      weight:
          weightController.text.trim(),

      height:
          heightController.text.trim(),

      bmi: widget.consultation.bmi,

      investigations:
          investigationsController.text.trim(),

      diagnosis:
          diagnosisController.text.trim(),

      treatment:
          treatmentController.text.trim(),

      labFeedback:
          labController.text.trim(),

      remarks:
          remarksController.text.trim(),

      createdAt: widget.consultation.createdAt,
    );

    await _consultationService.updateConsultation(
      updated,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Consultation Updated",
        ),
      ),
    );

    Navigator.pop(context);
  }

  Widget buildField(
    String label,
    TextEditingController controller, {
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Consultation"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildField(
              "Chief Complaint",
              chiefComplaintController,
              lines: 2,
            ),

            buildField(
              "Temperature",
              temperatureController,
            ),

            buildField(
              "Pulse Rate",
              pulseController,
            ),

            buildField(
              "Respiratory Rate",
              respiratoryController,
            ),

            buildField(
              "Blood Pressure",
              bpController,
            ),

            buildField(
              "Oxygen Saturation",
              oxygenController,
            ),

            buildField(
              "Weight",
              weightController,
            ),

            buildField(
              "Height",
              heightController,
            ),

            buildField(
              "Investigations",
              investigationsController,
              lines: 3,
            ),

            buildField(
              "Diagnosis",
              diagnosisController,
              lines: 3,
            ),

            buildField(
              "Treatment",
              treatmentController,
              lines: 3,
            ),

            buildField(
              "Lab Feedback",
              labController,
              lines: 3,
            ),

            buildField(
              "Remarks",
              remarksController,
              lines: 3,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text(
                  "Update Consultation",
                ),
                onPressed: updateConsultation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}