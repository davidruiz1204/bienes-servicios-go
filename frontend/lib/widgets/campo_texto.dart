import 'package:flutter/material.dart';

class CampoTexto extends StatelessWidget {
  final TextEditingController controlador;
  final String sugerencia;
  final IconData icono;
  final bool ocultarTexto;
  final Widget? iconoDerecho;
  final TextInputType? tipoPadre;

  const CampoTexto({
    super.key,
    required this.controlador,
    required this.sugerencia,
    required this.icono,
    this.ocultarTexto = false,
    this.iconoDerecho,
    this.tipoPadre,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controlador,
      obscureText: ocultarTexto,
      keyboardType: tipoPadre,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: sugerencia,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        prefixIcon: Icon(icono, color: Colors.white60, size: 20),
        suffixIcon: iconoDerecho,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF34C759), width: 1.5),
        ),
      ),
    );
  }
}