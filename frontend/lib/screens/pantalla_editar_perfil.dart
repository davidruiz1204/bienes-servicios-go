import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sesion_usuario.dart';
import '../services/servicio_api.dart';

class PantallaEditarPerfil extends StatefulWidget {
  final Map<String, dynamic> perfilActual;
  const PantallaEditarPerfil({super.key, required this.perfilActual});

  @override
  State<PantallaEditarPerfil> createState() => _EstadoPantallaEditarPerfil();
}

class _EstadoPantallaEditarPerfil extends State<PantallaEditarPerfil> {
  static const Color _verde = Color(0xFF0D9488);
  static const Color _oscuro = Color(0xFF0F172A);

  late TextEditingController _nombre;
  late TextEditingController _telefono;
  late TextEditingController _oficio;
  late TextEditingController _descripcion;
  late TextEditingController _ciudad;
  late TextEditingController _direccion;
  late TextEditingController _horario;
  late TextEditingController _precio;
  late TextEditingController _experiencia;
  bool _disponible = true;
  bool _guardando = false;
  bool _quitarFoto = false;
  String? _mensajeError;
  String? _mensajeExito;

  Uint8List? _fotoBytes;
  String? _fotoNombre;
  Uint8List? _informeBytes;
  String? _informeNombre;
  String _fotoUrlActual = '';
  String _informeUrlActual = '';

  // Portafolio con ID y url
  List<Map<String, dynamic>> _fotosPortafolio = [];
  bool _subiendoFoto = false;
  String _ultimaDireccion = '';
  String _ultimaCiudad = '';

  @override
  void initState() {
    super.initState();
    final p = widget.perfilActual;
    _nombre = TextEditingController(text: p['nombre'] ?? '');
    _telefono = TextEditingController(text: p['telefono'] ?? '');
    _oficio = TextEditingController(text: p['oficio'] ?? '');
    _descripcion = TextEditingController(text: p['descripcion'] ?? '');
    _ciudad = TextEditingController(text: p['ciudad'] ?? 'Girardot');
    _direccion = TextEditingController(text: p['direccion'] ?? '');
    _horario = TextEditingController(text: p['horario'] ?? '');
    _precio = TextEditingController(text: p['precio'] ?? '');
    _experiencia = TextEditingController(text: p['experiencia']?.toString() ?? '0');
    _disponible = p['disponible'] ?? true;
    _fotoUrlActual = p['foto_url'] ?? '';
    _informeUrlActual = p['informe_url'] ?? '';
    // Portafolio puede venir como lista de maps {id, url} o lista de strings
    final rawPortafolio = p['portafolio'] ?? [];
    _fotosPortafolio = (rawPortafolio as List).map((f) {
      if (f is Map) return Map<String, dynamic>.from(f);
      return {'id': null, 'url': f.toString()};
    }).toList();
    _ultimaDireccion = p['direccion'] ?? '';
    _ultimaCiudad = p['ciudad'] ?? 'Girardot';
  }

  @override
  void dispose() {
    _nombre.dispose(); _telefono.dispose(); _oficio.dispose();
    _descripcion.dispose(); _ciudad.dispose(); _direccion.dispose();
    _horario.dispose(); _precio.dispose(); _experiencia.dispose();
    super.dispose();
  }

  Widget _mostrarImagen(String url, {BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('data:image')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return Image.memory(bytes, fit: fit, width: double.infinity, height: double.infinity);
      } catch (_) {}
    } else if (url.isNotEmpty) {
      return Image.network(url, fit: fit, errorBuilder: (_, __, ___) => _iconoImagen());
    }
    return _iconoImagen();
  }

  Widget _iconoImagen() => Container(
    color: const Color(0xFFF1F5F9),
    child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
  );

  ImageProvider? _fotoProvider() {
    if (_fotoBytes != null) return MemoryImage(_fotoBytes!);
    if (_fotoUrlActual.startsWith('data:image')) {
      try { return MemoryImage(base64Decode(_fotoUrlActual.split(',').last)); } catch (_) {}
    } else if (_fotoUrlActual.isNotEmpty) {
      return NetworkImage(_fotoUrlActual);
    }
    return null;
  }

  Future<void> _seleccionarFoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _fotoBytes = result.files.first.bytes;
        _fotoNombre = result.files.first.name;
      });
    }
  }

  Future<void> _seleccionarInforme() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _informeBytes = result.files.first.bytes;
        _informeNombre = result.files.first.name;
      });
    }
  }

  Future<void> _subirFotoPortafolio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() => _subiendoFoto = true);
    final respuesta = await ServicioApi.subirFotoPortafolioConId(
      correo: SesionUsuario.correo ?? '',
      fotoBytes: result.files.first.bytes!,
      fotoNombre: result.files.first.name,
    );
    if (mounted && respuesta != null) {
      setState(() {
        _fotosPortafolio.add({'id': respuesta['id'], 'url': respuesta['url']});
        _subiendoFoto = false;
      });
    } else {
      setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _eliminarFotoPortafolio(int index) async {
    final foto = _fotosPortafolio[index];
    final id = foto['id'];
    // Quitar de la lista local inmediatamente
    setState(() => _fotosPortafolio.removeAt(index));
    // Si tiene ID, borrar en servidor
    if (id != null) {
      await ServicioApi.eliminarFotoPortafolio(id: id);
    }
  }

  Future<void> _guardar() async {
    final palabras = _descripcion.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (palabras < 50) {
      setState(() => _mensajeError = 'La descripcion debe tener al menos 50 palabras. Tienes $palabras.');
      return;
    }
    setState(() { _guardando = true; _mensajeError = null; _mensajeExito = null; });
    final resultado = await ServicioApi.editarPerfil(
      correo: SesionUsuario.correo ?? '',
      campos: {
        'nombre': _nombre.text.trim(),
        'telefono': _telefono.text.trim(),
        'oficio': _oficio.text.trim(),
        'descripcion': _descripcion.text.trim(),
        'ciudad': _ciudad.text.trim(),
        'direccion': _direccion.text.trim(),
        'horario': _horario.text.trim(),
        'precio': _precio.text.trim(),
        'experiencia': _experiencia.text.trim(),
        'disponible': _disponible.toString(),
        'quitar_foto': (_quitarFoto && _fotoBytes == null).toString(),
      },
      fotoBytes: _fotoBytes,
      fotoNombre: _fotoNombre,
      informeBytes: _informeBytes,
      informeNombre: _informeNombre,
    );
    setState(() => _guardando = false);
    if (resultado.containsKey('error')) {
      setState(() => _mensajeError = resultado['error']);
    } else {
      SesionUsuario.nombre = _nombre.text.trim();
      setState(() {
        _mensajeExito = '¡Perfil actualizado correctamente!';
        if (resultado['foto_url'] != null && resultado['foto_url'].toString().isNotEmpty) {
          _fotoUrlActual = resultado['foto_url'];
          _fotoBytes = null;
          _fotoNombre = null;
        }
        _ultimaDireccion = _direccion.text.trim();
        _ultimaCiudad = _ciudad.text.trim();
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context, true);
      });
    }
  }

  Future<void> _abrirEnMaps() async {
    final dir = Uri.encodeComponent('$_ultimaDireccion, $_ultimaCiudad, Cundinamarca, Colombia');
    final uri = Uri.parse('https://www.google.com/maps/search/$dir');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _oscuro),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Editar perfil',
            style: TextStyle(fontWeight: FontWeight.w800, color: _oscuro, fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _guardando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _verde, strokeWidth: 2))
                : _BotonHover(
                    onTap: _guardar,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(color: _verde, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_mensajeExito != null) _banner(_mensajeExito!, Colors.green, Icons.check_circle_outline),
            if (_mensajeError != null) _banner(_mensajeError!, Colors.red, Icons.error_outline),

            // Foto de perfil
            _seccion('Foto de perfil', [
              Center(
                child: Column(
                  children: [
                    _BotonHover(
                      onTap: _seleccionarFoto,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: _verde.withValues(alpha: 0.15),
                            backgroundImage: _fotoProvider(),
                            child: _fotoProvider() == null
                                ? Text((SesionUsuario.nombre ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(color: _verde, fontSize: 32, fontWeight: FontWeight.w800))
                                : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: _verde, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fotoBytes != null ? 'Foto: $_fotoNombre (guarda para subir)' : 'Toca para cambiar foto',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    if (_fotoUrlActual.isNotEmpty || _fotoBytes != null)
                      GestureDetector(
                        onTap: () => setState(() {
                          _fotoBytes = null;
                          _fotoNombre = null;
                          _fotoUrlActual = '';
                          _quitarFoto = true;
                        }),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('Quitar foto', style: TextStyle(color: Colors.red, fontSize: 11)),
                        ),
                      ),
                  ],
                ),
              ),
            ]),

            // Datos básicos
            _seccion('Datos basicos', [
              _campo('Nombre completo', _nombre, Icons.person_outline),
              _campo('Telefono', _telefono, Icons.phone_outlined),
              _campo('Oficio / Especialidad', _oficio, Icons.build_outlined),
              _campo('Anos de experiencia', _experiencia, Icons.calendar_today_outlined, tipo: TextInputType.number),
              _campo('Precio del servicio (ej: \$50.000 - \$200.000)', _precio, Icons.attach_money),
              _campo('Horario (ej: Lun-Vie 8AM-6PM)', _horario, Icons.access_time),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Disponible para trabajos',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _oscuro)),
                  Switch(value: _disponible, onChanged: (v) => setState(() => _disponible = v), activeColor: _verde),
                ],
              ),
            ]),

            // Descripcion
            _seccion('Descripcion profesional *', [
              const Text('Minimo 50 palabras.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: _descripcion,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 14, color: _oscuro),
                decoration: _decoracion('Describe tu experiencia...', Icons.description_outlined),
              ),
              const SizedBox(height: 4),
              Builder(builder: (_) {
                final p = _descripcion.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
                return Text('$p palabras (minimo 50)',
                    style: TextStyle(color: p >= 50 ? _verde : Colors.orange, fontSize: 11));
              }),
            ]),

            // Ubicacion
            _seccion('Ubicacion', [
              _campo('Ciudad', _ciudad, Icons.location_city_outlined),
              _campo('Direccion completa', _direccion, Icons.location_on_outlined),
              const SizedBox(height: 4),
              _BotonHover(
                onTap: () => setState(() {
                  _ultimaDireccion = _direccion.text.trim();
                  _ultimaCiudad = _ciudad.text.trim();
                }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCCFBF1)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, color: _verde, size: 16),
                      SizedBox(width: 6),
                      Text('Ver en mapa', style: TextStyle(color: _verde, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_ultimaDireccion.isNotEmpty)
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, color: _verde, size: 40),
                        const SizedBox(height: 8),
                        Text('$_ultimaDireccion\n$_ultimaCiudad, Cundinamarca',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: _oscuro, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        _BotonHover(
                          onTap: _abrirEnMaps,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: _verde, borderRadius: BorderRadius.circular(8)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.open_in_new, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text('Ver en Google Maps', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 20),
                      SizedBox(height: 4),
                      Text('Escribe tu direccion y presiona "Ver en mapa"',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    ],
                  ),
                ),
            ]),

            // PDF
            _seccion('Informe laboral (PDF)', [
              const Text('Sube un PDF con tus trabajos y experiencia.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              const SizedBox(height: 12),
              _BotonHover(
                onTap: _seleccionarInforme,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _informeBytes != null ? _verde : const Color(0xFFE2E8F0), width: _informeBytes != null ? 2 : 1),
                  ),
                  child: Column(
                    children: [
                      Icon(_informeBytes != null ? Icons.picture_as_pdf : Icons.upload_file,
                          color: _informeBytes != null ? _verde : const Color(0xFF94A3B8), size: 36),
                      const SizedBox(height: 8),
                      Text(
                        _informeBytes != null ? _informeNombre ?? 'PDF seleccionado'
                            : (_informeUrlActual.isNotEmpty ? 'PDF cargado — toca para cambiar' : 'Toca para subir PDF'),
                        style: TextStyle(color: _informeBytes != null ? _verde : const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              if (_informeUrlActual.isNotEmpty && _informeBytes == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _BotonHover(
                    onTap: () async {
                      final uri = Uri.parse(_informeUrlActual);
                      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCCFBF1)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility_outlined, color: _verde, size: 14),
                          SizedBox(width: 6),
                          Text('Ver PDF actual', style: TextStyle(color: _verde, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
            ]),

            // Portafolio
            _seccion('Portafolio de trabajos', [
              const Text('Agrega fotos de tus trabajos realizados.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              const SizedBox(height: 12),
              if (_fotosPortafolio.isEmpty && !_subiendoFoto)
                const Center(child: Text('Sin fotos aun.', style: TextStyle(color: Color(0xFF94A3B8))))
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
                  ),
                  itemCount: _fotosPortafolio.length + (_subiendoFoto ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_subiendoFoto && i == _fotosPortafolio.length) {
                      return Container(
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                        child: const Center(child: CircularProgressIndicator(color: _verde, strokeWidth: 2)),
                      );
                    }
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: _mostrarImagen(_fotosPortafolio[i]['url'] ?? ''),
                          ),
                        ),
                        Positioned(
                          top: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => _eliminarFotoPortafolio(i),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 12),
              _BotonHover(
                onTap: _subirFotoPortafolio,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCCFBF1)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, color: _verde, size: 18),
                      SizedBox(width: 8),
                      Text('Agregar foto al portafolio', style: TextStyle(color: _verde, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo, List<Widget> hijos) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _oscuro)),
          const SizedBox(height: 14),
          ...hijos.map((h) => Padding(padding: const EdgeInsets.only(bottom: 12), child: h)),
        ],
      ),
    );
  }

  Widget _campo(String etiqueta, TextEditingController ctrl, IconData icono, {TextInputType tipo = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl, keyboardType: tipo,
          style: const TextStyle(fontSize: 14, color: _oscuro),
          onChanged: (_) => setState(() {}),
          decoration: _decoracion('', icono),
        ),
      ],
    );
  }

  InputDecoration _decoracion(String hint, IconData icono) {
    return InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      prefixIcon: Icon(icono, color: const Color(0xFF94A3B8), size: 18),
      filled: true, fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _verde, width: 1.5)),
    );
  }

  Widget _banner(String msg, Color color, IconData icono) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icono, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: TextStyle(color: color, fontSize: 13))),
      ]),
    );
  }
}

class _BotonHover extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _BotonHover({required this.child, required this.onTap});
  @override
  State<_BotonHover> createState() => _EstadoBotonHover();
}

class _EstadoBotonHover extends State<_BotonHover> {
  bool _presionado = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _presionado = true),
        onTapUp: (_) { setState(() => _presionado = false); widget.onTap(); },
        onTapCancel: () => setState(() => _presionado = false),
        child: AnimatedScale(
          scale: _presionado ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedOpacity(
            opacity: _presionado ? 0.85 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}