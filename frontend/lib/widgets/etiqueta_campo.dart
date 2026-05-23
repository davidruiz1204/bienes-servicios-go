import 'package:flutter/material.dart';

class EtiquetaCampo extends StatelessWidget {
  final String texto;
  const EtiquetaCampo(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
