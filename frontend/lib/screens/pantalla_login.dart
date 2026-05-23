import 'package:flutter/material.dart';
import '../screens/pantalla_registro.dart';
import '../screens/pantalla_dashboard.dart';
import '../services/servicio_api.dart';
import '../models/sesion_usuario.dart';
import '../widgets/barra_navegacion.dart';
import '../widgets/campo_texto.dart';
import '../widgets/mensaje_error.dart';
import '../widgets/boton_principal.dart';
import '../widgets/etiqueta_campo.dart';

class PantallaInicioSesion extends StatefulWidget {
  const PantallaInicioSesion({super.key});

  @override
  State<PantallaInicioSesion> createState() => _EstadoPantallaInicioSesion();
}

class _EstadoPantallaInicioSesion extends State<PantallaInicioSesion> {
  final _controladorCorreo = TextEditingController();
  final _controladorContrasena = TextEditingController();
  bool _ocultarContrasena = true;
  bool _cargando = false;
  String? _mensajeError;

  Future<void> _iniciarSesion() async {
    final correo = _controladorCorreo.text.trim();
    final contrasena = _controladorContrasena.text.trim();

    if (correo.isEmpty || contrasena.isEmpty) {
      setState(() => _mensajeError = 'Por favor completa todos los campos.');
      return;
    }

    setState(() { _cargando = true; _mensajeError = null; });

    final resultado = await ServicioApi.iniciarSesion(correo: correo, contrasena: contrasena);

    if (!mounted) return;
    setState(() => _cargando = false);

    if (resultado.exito) {
      SesionUsuario.iniciar(
        correo: correo,
        nombre: resultado.usuario?['nombre'] ?? '',
        tipo: resultado.usuario?['tipo'] ?? 'cliente',
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PantallaDashboard()));
    } else {
      setState(() => _mensajeError = resultado.mensaje);
    }
  }

  void _mostrarDialogoOlvideContrasena() {
    showDialog(context: context, barrierDismissible: false,
        builder: (_) => const DialogoRecuperarContrasena());
  }

  void _irARegistro() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaRegistro()));
  }

  @override
  void dispose() {
    _controladorCorreo.dispose();
    _controladorContrasena.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/girardot.jpg', fit: BoxFit.cover),
          ),
          Column(
            children: [
              const BarraNavegacion(),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: _TarjetaInicioSesion(
                        controladorCorreo: _controladorCorreo,
                        controladorContrasena: _controladorContrasena,
                        ocultarContrasena: _ocultarContrasena,
                        cargando: _cargando,
                        mensajeError: _mensajeError,
                        alCambiarVisibilidad: () => setState(() => _ocultarContrasena = !_ocultarContrasena),
                        alIniciarSesion: _iniciarSesion,
                        alIrARegistro: _irARegistro,
                        alOlvideContrasena: _mostrarDialogoOlvideContrasena,
                      ),
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
}

class _TarjetaInicioSesion extends StatelessWidget {
  final TextEditingController controladorCorreo;
  final TextEditingController controladorContrasena;
  final bool ocultarContrasena;
  final bool cargando;
  final String? mensajeError;
  final VoidCallback alCambiarVisibilidad;
  final VoidCallback alIniciarSesion;
  final VoidCallback alIrARegistro;
  final VoidCallback alOlvideContrasena;

  const _TarjetaInicioSesion({
    required this.controladorCorreo,
    required this.controladorContrasena,
    required this.ocultarContrasena,
    required this.cargando,
    required this.mensajeError,
    required this.alCambiarVisibilidad,
    required this.alIniciarSesion,
    required this.alIrARegistro,
    required this.alOlvideContrasena,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
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
            child: SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                    children: [
                      TextSpan(text: 'Bienvenido, ', style: TextStyle(color: Colors.white)),
                      TextSpan(text: 'Bienes y Servicios GO!', style: TextStyle(color: Color(0xFF34C759))),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Inicia sesión para vivir una experiencia unica y encontrarlo todo en un mismo sitio',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 36),
          const EtiquetaCampo('Correo Electrónico'),
          const SizedBox(height: 8),
          CampoTexto(controlador: controladorCorreo, sugerencia: 'tu@correo.com',
              icono: Icons.email_outlined, tipoPadre: TextInputType.emailAddress),
          const SizedBox(height: 18),
          const EtiquetaCampo('Contraseña'),
          const SizedBox(height: 8),
          CampoTexto(
            controlador: controladorContrasena, sugerencia: '••••••••',
            icono: Icons.lock_outline, ocultarTexto: ocultarContrasena,
            iconoDerecho: IconButton(
              icon: Icon(ocultarContrasena ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white54, size: 20),
              onPressed: alCambiarVisibilidad,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: alOlvideContrasena,
              child: const Text('¿Olvidaste tu contraseña?',
                  style: TextStyle(color: Color(0xFF007AFF), fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 20),
          if (mensajeError != null) ...[
            MensajeError(mensaje: mensajeError!),
            const SizedBox(height: 14),
          ],
          BotonPrincipal(etiqueta: '🏡  Iniciar Sesión', cargando: cargando, alPresionar: alIniciarSesion),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('¿No tienes cuenta? ', style: TextStyle(color: Colors.white60, fontSize: 13)),
                GestureDetector(
                  onTap: alIrARegistro,
                  child: const Text('Regístrate aquí',
                      style: TextStyle(color: Color(0xFF007AFF), fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DialogoRecuperarContrasena extends StatefulWidget {
  const DialogoRecuperarContrasena({super.key});
  @override
  State<DialogoRecuperarContrasena> createState() => _EstadoDialogoRecuperarContrasena();
}

class _EstadoDialogoRecuperarContrasena extends State<DialogoRecuperarContrasena> {
  final _controladorCorreo = TextEditingController();
  bool _enviando = false;
  bool _enviado = false;
  String? _mensajeError;

  void _enviarRecuperacion() async {
    final correo = _controladorCorreo.text.trim();
    if (correo.isEmpty) { setState(() => _mensajeError = 'Ingresa tu correo electrónico.'); return; }
    final esCorreoValido = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$').hasMatch(correo);
    if (!esCorreoValido) { setState(() => _mensajeError = 'Ingresa un correo válido.'); return; }
    setState(() { _enviando = true; _mensajeError = null; });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() { _enviando = false; _enviado = true; });
  }

  @override
  void dispose() { _controladorCorreo.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
          ),
          child: _enviado ? _vistaConfirmacion(context) : _vistaFormulario(),
        ),
      ),
    );
  }

  Widget _vistaFormulario() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_reset_rounded, color: Color(0xFF34C759), size: 48),
        const SizedBox(height: 16),
        const Text('¿Olvidaste tu contraseña?',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Ingresa tu correo y te enviaremos instrucciones.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 24),
        CampoTexto(controlador: _controladorCorreo, sugerencia: 'tu@correo.com',
            icono: Icons.email_outlined, tipoPadre: TextInputType.emailAddress),
        const SizedBox(height: 16),
        if (_mensajeError != null) ...[
          MensajeError(mensaje: _mensajeError!),
          const SizedBox(height: 14),
        ],
        BotonPrincipal(etiqueta: '📧  Enviar instrucciones', cargando: _enviando, alPresionar: _enviarRecuperacion),
        const SizedBox(height: 12),
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60))),
      ],
    );
  }

  Widget _vistaConfirmacion(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mark_email_read_outlined, color: Color(0xFF34C759), size: 48),
        const SizedBox(height: 16),
        const Text('¡Correo enviado!',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text('Revisa tu bandeja en\n${_controladorCorreo.text.trim()}',
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 24),
        BotonPrincipal(etiqueta: '✅  Entendido', cargando: false, alPresionar: () => Navigator.pop(context)),
      ],
    );
  }
}