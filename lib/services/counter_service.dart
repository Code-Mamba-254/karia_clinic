import 'package:cloud_firestore/cloud_firestore.dart';

class CounterService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<String> generateClinicNumber() async {
    final year = DateTime.now().year;

    final counterRef = _firestore
        .collection('counters')
        .doc('patient_counter');

    return _firestore.runTransaction((transaction) async {
      final snapshot =
          await transaction.get(counterRef);

      int currentNumber = 0;

      if (snapshot.exists) {
        currentNumber =
            snapshot['value'] as int;
      }

      currentNumber++;

      transaction.set(
        counterRef,
        {
          'value': currentNumber,
        },
      );

      return "CLN-$year-${currentNumber.toString().padLeft(6, '0')}";
    });
  }
}