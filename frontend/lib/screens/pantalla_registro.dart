import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/servicio_api.dart';
import '../screens/pantalla_login.dart';
import '../widgets/boton_principal.dart';
import '../widgets/etiqueta_campo.dart';
import '../widgets/mensaje_error.dart';

class PantallaRegistro extends StatefulWidget {
  final String? tipoInicial;
  const PantallaRegistro({super.key, this.tipoInicial});

  @override
  State<PantallaRegistro> createState() => _EstadoPantallaRegistro();
}

class _EstadoPantallaRegistro extends State<PantallaRegistro> {
  String? _tipoSeleccionado;

  @override
  void initState() {
    super.initState();
    _tipoSeleccionado = widget.tipoInicial;
  }
  bool _cargando = false;
  String? _mensajeError;

  final _controladorNombre = TextEditingController();
  final _controladorCorreo = TextEditingController();
  final _controladorContrasena = TextEditingController();
  final _controladorTelefono = TextEditingController();
  final _controladorCedula = TextEditingController();
  final _controladorOficio = TextEditingController();
  final _controladorNegocio = TextEditingController();
  final _controladorDescripcion = TextEditingController();
  bool _ocultarContrasena = true;

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorCorreo.dispose();
    _controladorContrasena.dispose();
    _controladorTelefono.dispose();
    _controladorCedula.dispose();
    _controladorOficio.dispose();
    _controladorNegocio.dispose();
    _controladorDescripcion.dispose();
    super.dispose();
  }

  String _capitalizarNombre(String nombre) {
    return nombre.split(' ').map((palabra) {
      if (palabra.isEmpty) return palabra;
      return palabra[0].toUpperCase() + palabra.substring(1).toLowerCase();
    }).join(' ');
  }

  String? _validarCampos() {
    final nombre = _controladorNombre.text.trim();
    final correo = _controladorCorreo.text.trim();
    final contrasena = _controladorContrasena.text.trim();
    final telefono = _controladorTelefono.text.trim();
    final cedula = _controladorCedula.text.trim();
    final oficio = _controladorOficio.text.trim();

    if (nombre.isEmpty) return 'El nombre es obligatorio.';
    if (nombre.length < 3) return 'El nombre debe tener al menos 3 caracteres.';

    if (correo.isEmpty) return 'El correo electrónico es obligatorio.';
    final partes = correo.split('@');
    if (partes.length != 2) return 'El correo debe tener exactamente un @.';
    if (partes[0].length < 5) return 'El correo debe tener al menos 5 caracteres antes del @.';
    final despuesArroba = partes[1];
    if (despuesArroba.length < 3) return 'El dominio del correo es inválido.';
    if (!despuesArroba.substring(1).contains('.')) return 'El correo debe tener un punto después del @.';

    if (contrasena.isEmpty) return 'La contraseña es obligatoria.';
    if (contrasena.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
    if (contrasena.length > 10) return 'La contraseña debe tener máximo 10 caracteres.';

    if (telefono.isEmpty) return 'El teléfono es obligatorio.';
    if (telefono.length != 10) return 'El teléfono debe tener exactamente 10 dígitos.';
    if (!telefono.startsWith('3')) return 'El teléfono debe empezar con 3.';

    if (cedula.isEmpty) return 'La cédula es obligatoria.';
    if (cedula.length < 6) return 'La cédula debe tener al menos 6 dígitos.';
    if (cedula.length > 11) return 'La cédula debe tener máximo 11 dígitos.';

    if (_tipoSeleccionado == 'proveedor' && oficio.isEmpty) {
      return 'El oficio o especialidad es obligatorio.';
    }

    return null;
  }

  Future<void> _registrar() async {
    final error = _validarCampos();
    if (error != null) {
      setState(() => _mensajeError = error);
      return;
    }

    final nombre = _capitalizarNombre(_controladorNombre.text.trim());
    final correo = _controladorCorreo.text.trim();
    final contrasena = _controladorContrasena.text.trim();
    final telefono = _controladorTelefono.text.trim();
    final cedula = _controladorCedula.text.trim();
    final oficio = _controladorOficio.text.trim();
    final negocio = _controladorNegocio.text.trim();
    final descripcion = _controladorDescripcion.text.trim();

    setState(() {
      _cargando = true;
      _mensajeError = null;
    });

    final resultado = await ServicioApi.registrar(
      tipo: _tipoSeleccionado!,
      nombre: nombre,
      correo: correo,
      contrasena: contrasena,
      telefono: telefono,
      cedula: cedula,
      oficio: _tipoSeleccionado == 'proveedor' ? oficio : null,
      negocio: _tipoSeleccionado == 'proveedor' ? negocio : null,
      descripcion: _tipoSeleccionado == 'proveedor' ? descripcion : null,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (resultado.exito) {
      _mostrarExito();
    } else {
      setState(() => _mensajeError = resultado.mensaje);
    }
  }

  void _mostrarExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF34C759).withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.check_circle_outline, color: Color(0xFF34C759), size: 32),
              ),
              const SizedBox(height: 20),
              const Text('¡Registro exitoso!',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              const Text('Tu cuenta ha sido creada.\nYa puedes iniciar sesión.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF34C759), Color(0xFF007AFF)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const PantallaInicioSesion()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Ir al Login',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo_registro.png', fit: BoxFit.cover),
          ),
          Column(
            children: [
              _buildBarra(),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: _tipoSeleccionado == null
                          ? _vistaSeleccionTipo()
                          : _vistaFormulario(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarra() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.40),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF34C759), borderRadius: BorderRadius.circular(8)),
            child: const Text('UCUNDINAMARCA',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
          ),
          const SizedBox(width: 14),
          const Flexible(
            child: Text('Plataforma para la gestion de Bienes y Servicios',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _vistaSeleccionTipo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.50), blurRadius: 60, offset: const Offset(0, 24))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text('¿Cómo deseas registrarte?',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text('Selecciona el tipo de cuenta que deseas crear',
                style: TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          _tarjetaTipo(icono: Icons.person_outline, titulo: 'Cliente',
              descripcion: 'Busca y contrata servicios generales y técnicos en Girardot.', valor: 'cliente'),
          const SizedBox(height: 16),
          _tarjetaTipo(icono: Icons.build_outlined, titulo: 'Proveedor / Trabajador',
              descripcion: 'Ofrece tus servicios y llega a más clientes en tu ciudad.', valor: 'proveedor'),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text('← Volver al Login',
                  style: TextStyle(color: Color(0xFF007AFF), fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaTipo({required IconData icono, required String titulo, required String descripcion, required String valor}) {
    return GestureDetector(
      onTap: () => setState(() => _tipoSeleccionado = valor),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF34C759).withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icono, color: const Color(0xFF34C759), size: 26),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(descripcion, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _vistaFormulario() {
    final esProveedor = _tipoSeleccionado == 'proveedor';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.50), blurRadius: 60, offset: const Offset(0, 24))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(esProveedor ? '🔧  Registro Proveedor' : '👤  Registro Cliente',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text('Completa tus datos para crear tu cuenta',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          const SizedBox(height: 20),
          const EtiquetaCampo('Nombre completo'),
          const SizedBox(height: 8),
          _campo(_controladorNombre, 'Tu nombre completo', Icons.person_outline),
          const SizedBox(height: 12),
          const EtiquetaCampo('Correo Electrónico'),
          const SizedBox(height: 8),
          _campo(_controladorCorreo, 'tu@correo.com', Icons.email_outlined, tipo: TextInputType.emailAddress),
          const SizedBox(height: 12),
          const EtiquetaCampo('Contraseña'),
          const SizedBox(height: 8),
          _campoContrasena(),
          const SizedBox(height: 12),
          const EtiquetaCampo('Teléfono'),
          const SizedBox(height: 8),
          _campoSoloNumeros(_controladorTelefono, '3XXXXXXXXX', Icons.phone_outlined, maxLength: 10),
          const SizedBox(height: 12),
          const EtiquetaCampo('Cédula'),
          const SizedBox(height: 8),
          _campoSoloNumeros(_controladorCedula, 'Número de cédula', Icons.badge_outlined, maxLength: 11),
          if (esProveedor) ...[
            const SizedBox(height: 12),
            const EtiquetaCampo('Nombre de tu negocio'),
            const SizedBox(height: 8),
            _campo(_controladorNegocio, 'Ej: Electricidad Ramírez, Plomería JC...', Icons.store_outlined),
            const SizedBox(height: 12),
            const EtiquetaCampo('Oficio / Especialidad *'),
            const SizedBox(height: 8),
            _campo(_controladorOficio, 'Ej: Plomero, Electricista, Pintor...', Icons.build_outlined),
            const SizedBox(height: 12),
            const EtiquetaCampo('Descripción '),
            const SizedBox(height: 8),
            _campoMultilinea(),
          ],
          const SizedBox(height: 20),
          if (_mensajeError != null) ...[
            MensajeError(mensaje: _mensajeError!),
            const SizedBox(height: 12),
          ],
          BotonPrincipal(etiqueta: 'Crear cuenta', cargando: _cargando, alPresionar: _registrar),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () => setState(() { _tipoSeleccionado = null; _mensajeError = null; }),
              child: const Text('← Cambiar tipo de cuenta',
                  style: TextStyle(color: Color(0xFF007AFF), fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String hint, IconData icono, {TextInputType? tipo}) {
    return TextField(
      controller: ctrl, keyboardType: tipo,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        prefixIcon: Icon(icono, color: Colors.white60, size: 20),
        filled: true, fillColor: Colors.white.withValues(alpha: 0.10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF34C759), width: 1.5)),
      ),
    );
  }

  Widget _campoSoloNumeros(TextEditingController ctrl, String hint, IconData icono, {required int maxLength}) {
    return TextField(
      controller: ctrl, keyboardType: TextInputType.number,
      maxLength: maxLength,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        prefixIcon: Icon(icono, color: Colors.white60, size: 20),
        counterText: '',
        filled: true, fillColor: Colors.white.withValues(alpha: 0.10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF34C759), width: 1.5)),
      ),
    );
  }

  Widget _campoContrasena() {
    return TextField(
      controller: _controladorContrasena,
      obscureText: _ocultarContrasena,
      maxLength: 10,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white60, size: 20),
        counterText: '',
        suffixIcon: IconButton(
          icon: Icon(_ocultarContrasena ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.white54, size: 20),
          onPressed: () => setState(() => _ocultarContrasena = !_ocultarContrasena),
        ),
        filled: true, fillColor: Colors.white.withValues(alpha: 0.10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF34C759), width: 1.5)),
      ),
    );
  }

  Widget _campoMultilinea() {
    return TextField(
      controller: _controladorDescripcion, maxLines: 2,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Cuéntanos sobre tu experiencia y servicios...',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        filled: true, fillColor: Colors.white.withValues(alpha: 0.10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF34C759), width: 1.5)),
      ),
    );
  }
}