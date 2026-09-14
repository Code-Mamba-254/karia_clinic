import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/patient.dart';
import '../models/consultation.dart';

import '../services/consultation_service.dart';

import '../widgets/patient_summary_card.dart';
import '../widgets/consultation_form_card.dart';
import '../widgets/consultation_card.dart';

class ConsultationScreen extends StatefulWidget {
  final Patient patient;

  const ConsultationScreen({
    super.key,
    required this.patient,
  });

  @override
  State<ConsultationScreen> createState() =>
      _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {

  final chiefComplaintController = TextEditingController();

  final temperatureController = TextEditingController();
  final pulseController = TextEditingController();
  final respiratoryController = TextEditingController();
  final bpController = TextEditingController();
  final oxygenController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  final investigationsController = TextEditingController();
  final diagnosisController = TextEditingController();
  final treatmentController = TextEditingController();
  final labController = TextEditingController();
  final remarksController = TextEditingController();

  final ConsultationService _consultationService =
      ConsultationService();

  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<void> saveConsultation() async {

    final doctor = _auth.currentUser;

    if (doctor == null) {
      return;
    }

    final consultation = Consultation(

      id: '',

      patientId: widget.patient.id,

      doctorId: doctor.uid,

      doctorEmail: doctor.email ?? "",

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

      bmi: 0,

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

      createdAt: DateTime.now(),
    );

    await _consultationService.saveConsultation(
      consultation,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Consultation Saved Successfully",
        ),
      ),
    );

    chiefComplaintController.clear();

    temperatureController.clear();
    pulseController.clear();
    respiratoryController.clear();
    bpController.clear();
    oxygenController.clear();
    weightController.clear();
    heightController.clear();

    investigationsController.clear();
    diagnosisController.clear();
    treatmentController.clear();
    labController.clear();
    remarksController.clear();
  }

  @override
  Widget build(BuildContext context) {

    final patient = widget.patient;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Consultation"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            PatientSummaryCard(
              patient: patient,
            ),

            const SizedBox(height: 24),

            const Text(
              "New Consultation",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 12),

            ConsultationFormCard(

              chiefComplaintController:
                  chiefComplaintController,

              temperatureController:
                  temperatureController,

              pulseController:
                  pulseController,

              respiratoryController:
                  respiratoryController,

              bpController:
                  bpController,

              oxygenController:
                  oxygenController,

              weightController:
                  weightController,

              heightController:
                  heightController,

              investigationsController:
                  investigationsController,

              diagnosisController:
                  diagnosisController,

              treatmentController:
                  treatmentController,

              labController:
                  labController,

              remarksController:
                  remarksController,

              onSave: saveConsultation,
            ),

            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 20),

            const Text(
              "Consultation History",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 10),

            StreamBuilder<List<Consultation>>(

              stream: _consultationService
                  .getPatientConsultations(
                      patient.id),

              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final consultations =
                    snapshot.data!;

                if (consultations.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding:
                          EdgeInsets.all(16),
                      child: Text(
                          "No consultations yet."),
                    ),
                  );
                }

                return Column(
                  children: consultations
                      .map(
                        (c) =>
                            ConsultationCard(
                          consultation: c,
                        ),
                      )
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}