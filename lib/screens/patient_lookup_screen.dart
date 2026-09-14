import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../services/patient_service.dart';
import '../widgets/patient_card.dart';

import 'patient_registration_screen.dart';
import 'consultation_screen.dart';

class PatientLookupScreen extends StatefulWidget {
  const PatientLookupScreen({super.key});

  @override
  State<PatientLookupScreen> createState() =>
      _PatientLookupScreenState();
}

class _PatientLookupScreenState
    extends State<PatientLookupScreen> {
  final PatientService _patientService =
      PatientService();

  final TextEditingController searchController =
      TextEditingController();

  String searchText = "";

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,

        appBar: AppBar(
          title: const Text("Patient Lookup"),
        ),

        floatingActionButton:
            FloatingActionButton.extended(
          icon: const Icon(Icons.person_add),
          label: const Text("New Patient"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const PatientRegistrationScreen(),
              ),
            );
          },
        ),

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search patient...",
                    prefixIcon:
                        const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchText = value.trim();
                    });
                  },
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: searchText.isEmpty
                      ? const Center(
                          child: Text(
                            "Start typing to search for a patient",
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        )
                      : StreamBuilder<List<Patient>>(
                          stream: _patientService
                              .searchPatients(
                            searchText,
                          ),
                          builder:
                              (context, snapshot) {
                            if (snapshot
                                    .connectionState ==
                                ConnectionState
                                    .waiting) {
                              return const Center(
                                child:
                                    CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  "Error: ${snapshot.error}",
                                ),
                              );
                            }

                            final patients =
                                snapshot.data ?? [];

                            if (patients.isEmpty) {
                              return const Center(
                                child: Text(
                                  "No patient found.",
                                ),
                              );
                            }

                            return ListView.separated(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior
                                      .onDrag,
                              itemCount:
                                  patients.length,
                              separatorBuilder:
                                  (_, __) =>
                                      const SizedBox(
                                height: 8,
                              ),
                              itemBuilder:
                                  (context, index) {
                                final patient =
                                    patients[index];

                                return PatientCard(
                                  patient: patient,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ConsultationScreen(
                                          patient:
                                              patient,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}