import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {

  final Widget child;

  const InfoCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {

    return Card(

      elevation: 2,

      child: Padding(

        padding: const EdgeInsets.all(20),

        child: child,

      ),

    );

  }

}