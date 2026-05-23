import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sesion_usuario.dart';
import '../services/servicio_api.dart';

class PantallaPerfilProveedor extends StatefulWidget {
  final Map<String, dynamic> proveedor;
  const PantallaPerfilProveedor({super.key, required this.proveedor});
  @override
  State<PantallaPerfilProveedor> createState() => _EstadoPantallaPerfilProveedor();
}

class _EstadoPantallaPerfilProveedor extends State<PantallaPerfilProveedor>
    with SingleTickerProviderStateMixin {
  static const Color _verde = Color(0xFF0D9488);
  static const Color _amarillo = Color(0xFFF59E0B);
  static const Color _oscuro = Color(0xFF0F172A);

  late TabController _tabController;
  bool _esFavorito = false;
  bool _cargandoFavorito = true;
  // Solicitudes completadas del cliente con este proveedor (para reseñas)
  List<Map<String, dynamic>> _solicitudesCompletadas = [];
  bool _cargandoSolicitudes = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarFavorito();
    _cargarSolicitudesCompletadas();
  }

  Future<void> _cargarFavorito() async {
    if (SesionUsuario.correo == null || SesionUsuario.tipo != 'cliente') {
      setState(() => _cargandoFavorito = false);
      return;
    }
    final esFav = await ServicioApi.obtenerEsFavorito(
      correoCliente: SesionUsuario.correo!,
      idProveedor: p['id'],
    );
    if (mounted) setState(() { _esFavorito = esFav; _cargandoFavorito = false; });
  }

  Future<void> _cargarSolicitudesCompletadas() async {
    if (SesionUsuario.correo == null || SesionUsuario.tipo != 'cliente') {
      setState(() => _cargandoSolicitudes = false);
      return;
    }
    try {
      final datos = await ServicioApi.obtenerDatosDashboard(
        correo: SesionUsuario.correo!,
        tipo: 'cliente',
      );
      final historial = List<Map<String, dynamic>>.from(datos['historial'] ?? []);
      final completadas = historial.where((h) =>
        h['proveedor_id'] == p['id'] || h['proveedor'] == p['nombre']
      ).toList();
      if (mounted) setState(() { _solicitudesCompletadas = completadas; _cargandoSolicitudes = false; });
    } catch (_) {
      if (mounted) setState(() => _cargandoSolicitudes = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get p => widget.proveedor;

  ImageProvider? _imgProvider(String url) {
    if (url.startsWith('data:image')) {
      try { return MemoryImage(base64Decode(url.split(',').last)); } catch (_) {}
    } else if (url.isNotEmpty) {
      return NetworkImage(url);
    }
    return null;
  }

  Widget _imgWidget(String url, double size) {
    final provider = _imgProvider(url);
    if (provider != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image(image: provider, fit: BoxFit.cover, width: size, height: size,
            errorBuilder: (_, __, ___) => _avatarLetra()),
      );
    }
    return _avatarLetra();
  }

  Future<void> _toggleFavorito() async {
    if (SesionUsuario.correo == null) return;
    setState(() => _cargandoFavorito = true);
    final ok = await ServicioApi.toggleFavorito(
      correoCliente: SesionUsuario.correo!,
      idProveedor: p['id'],
    );
    if (ok && mounted) {
      setState(() { _esFavorito = !_esFavorito; _cargandoFavorito = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_esFavorito ? 'Agregado a favoritos ❤️' : 'Eliminado de favoritos'),
        backgroundColor: _esFavorito ? Colors.redAccent : const Color(0xFF64748B),
      ));
    } else {
      setState(() => _cargandoFavorito = false);
    }
  }

  Future<void> _abrirWhatsApp() async {
    final tel = (p['telefono'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
    if (tel.isNotEmpty) {
      final uri = Uri.parse('https://wa.me/57$tel');
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _enviarMensaje() {
    showDialog(context: context, builder: (_) => _DialogoMensaje(proveedor: p));
  }

  void _solicitarServicio() {
    if (SesionUsuario.correo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesion para solicitar un servicio.'), backgroundColor: Colors.red),
      );
      return;
    }
    showDialog(context: context, builder: (_) => _DialogoSolicitud(proveedor: p));
  }

  void _dejarResena() {
    if (_solicitudesCompletadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo puedes dejar una reseña después de completar un servicio con este proveedor.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(context: context, builder: (_) => _DialogoResena(proveedor: p, solicitudesCompletadas: _solicitudesCompletadas));
  }

  @override
  Widget build(BuildContext context) {
    final calificacion = (p['calificacion'] as num?)?.toDouble() ?? 0.0;
    final trabajos = p['trabajos_completados'] ?? 0;
    final experiencia = p['experiencia'] ?? 0;
    final disponible = p['disponible'] ?? true;
    final fotoUrl = p['foto_url']?.toString() ?? '';
    final resenas = List<Map<String, dynamic>>.from(p['resenas'] ?? []);
    final portafolioRaw = p['portafolio'] ?? [];
    final portafolio = (portafolioRaw as List).map((f) {
      if (f is Map) return f['url']?.toString() ?? '';
      return f.toString();
    }).where((s) => s.isNotEmpty).toList();
    final servicios = List<String>.from(p['servicios'] ?? []);
    final direccion = p['direccion']?.toString() ?? '';
    final ciudad = p['ciudad']?.toString() ?? 'Girardot';
    final esCliente = SesionUsuario.tipo == 'cliente';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: _oscuro, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  fotoUrl.isNotEmpty
                      ? Builder(builder: (_) {
                          final provider = _imgProvider(fotoUrl);
                          return provider != null
                              ? Image(image: provider, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fondoGradiente())
                              : _fondoGradiente();
                        })
                      : _fondoGradiente(),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.white],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (fotoUrl.isNotEmpty) {
                                showDialog(context: context, builder: (_) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: InteractiveViewer(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: _imgWidget(fotoUrl, 300))),
                                  ),
                                ));
                              }
                            },
                            child: Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10)],
                              ),
                              child: _imgWidget(fotoUrl, 80),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(child: Text(p['nombre'] ?? '',
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _oscuro))),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: disponible ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(disponible ? 'Disponible ahora' : 'Ocupado',
                                          style: TextStyle(
                                            color: disponible ? const Color(0xFF15803D) : const Color(0xFF94A3B8),
                                            fontSize: 10, fontWeight: FontWeight.w700,
                                          )),
                                    ),
                                  ],
                                ),
                                Text('${p['oficio'] ?? ''}',
                                    style: const TextStyle(color: _verde, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    ...List.generate(5, (i) => Icon(Icons.star, size: 14,
                                        color: i < calificacion.floor() ? _amarillo : const Color(0xFFE2E8F0))),
                                    const SizedBox(width: 6),
                                    Text('$calificacion (${resenas.length} reseñas)',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    const SizedBox(width: 12),
                                    Text('$trabajos trabajos',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    const SizedBox(width: 12),
                                    Text('$experiencia años exp.',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Corazón favorito → guarda en servidor
                          if (esCliente)
                            GestureDetector(
                              onTap: _cargandoFavorito ? null : _toggleFavorito,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF8FAFC)),
                                child: _cargandoFavorito
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _verde))
                                    : Icon(
                                        _esFavorito ? Icons.favorite : Icons.favorite_border,
                                        color: _esFavorito ? Colors.redAccent : const Color(0xFF94A3B8),
                                        size: 20,
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: [
                      _chip(Icons.location_city, ciudad),
                      if (direccion.isNotEmpty) _chip(Icons.location_on, direccion),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _abrirWhatsApp,
                          icon: const Icon(Icons.chat, size: 16),
                          label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _verde, foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _enviarMensaje,
                          icon: const Icon(Icons.message_outlined, size: 16),
                          label: const Text('Enviar mensaje', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _verde, foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _solicitarServicio,
                          icon: const Icon(Icons.handshake_outlined, size: 16),
                          label: const Text('Solicitar servicio', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _amarillo, foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      if (esCliente) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _dejarResena,
                            icon: const Icon(Icons.star_outline, size: 16),
                            label: const Text('Dejar reseña', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _cargandoSolicitudes
                                  ? const Color(0xFF94A3B8)
                                  : (_solicitudesCompletadas.isNotEmpty ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8)),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sobre ${(p['nombre'] ?? '').split(' ').first}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _oscuro)),
                            const SizedBox(height: 10),
                            Text(
                              p['descripcion'] ?? 'Profesional con experiencia en ${p['oficio'] ?? 'servicios generales'}.',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.6),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              height: 220,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F4F8), borderRadius: BorderRadius.circular(16)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.location_on, color: _verde, size: 48),
                                          const SizedBox(height: 8),
                                          Text(
                                            direccion.isNotEmpty ? '$direccion\n$ciudad, Cundinamarca' : '$ciudad, Cundinamarca',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(color: _oscuro, fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 12, right: 12,
                                      child: GestureDetector(
                                        onTap: () async {
                                          final query = Uri.encodeComponent(
                                            direccion.isNotEmpty ? '$direccion, $ciudad, Cundinamarca, Colombia' : '$ciudad, Cundinamarca, Colombia',
                                          );
                                          final uri = Uri.parse('https://www.google.com/maps/search/$query');
                                          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white, borderRadius: BorderRadius.circular(8),
                                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.directions, color: _verde, size: 14),
                                              SizedBox(width: 4),
                                              Text('Como llegar', style: TextStyle(color: _verde, fontSize: 11, fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 220,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('INFORMACION',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _oscuro, letterSpacing: 0.5)),
                            const SizedBox(height: 12),
                            _infoItem(Icons.access_time, _verde, 'Horario', p['horario'] ?? 'Lun - Dom: 8:00 AM - 6:00 PM'),
                            _infoItem(Icons.attach_money, _amarillo, 'Precio', p['precio'] ?? 'Consultar'),
                            _infoItem(Icons.location_on, _verde, 'Ubicacion', ciudad),
                            _infoItem(Icons.calendar_today, Colors.redAccent, 'Experiencia', '${p['experiencia'] ?? 0} años'),
                            _infoItem(Icons.work_outline, const Color(0xFF3B82F6), 'Trabajos', '${p['trabajos_completados'] ?? 0} completados'),
                            const SizedBox(height: 16),
                            const Text('Contacto directo',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF64748B))),
                            const SizedBox(height: 8),
                            _contactoItem(Icons.phone, '+57 ${p['telefono'] ?? ''}'),
                            _contactoItem(Icons.email_outlined, p['correo'] ?? ''),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: _verde,
                          unselectedLabelColor: const Color(0xFF94A3B8),
                          indicatorColor: _verde,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          tabs: [
                            const Tab(icon: Icon(Icons.photo_library_outlined, size: 16), text: 'Portafolio'),
                            const Tab(icon: Icon(Icons.build_outlined, size: 16), text: 'Servicios'),
                            Tab(icon: const Icon(Icons.star_outline, size: 16), text: 'Reseñas (${resenas.length})'),
                          ],
                        ),
                        AnimatedBuilder(
                          animation: _tabController,
                          builder: (_, __) {
                            switch (_tabController.index) {
                              case 1: return _tabServicios(servicios);
                              case 2: return _tabResenas(resenas);
                              default: return _tabPortafolio(portafolio);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabPortafolio(List<dynamic> portafolio) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trabajos realizados (${portafolio.length})',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _oscuro)),
          const SizedBox(height: 16),
          if (portafolio.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20),
                child: Text('Sin trabajos en portafolio aún.', style: TextStyle(color: Color(0xFF94A3B8)))))
          else
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: portafolio.length,
              itemBuilder: (_, i) {
                final url = portafolio[i].toString();
                final provider = _imgProvider(url);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: provider != null
                      ? Image(image: provider, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF1F5F9),
                              child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8))))
                      : Container(color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8))),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _tabServicios(List<String> servicios) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: servicios.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(20),
              child: Text('Sin servicios listados.', style: TextStyle(color: Color(0xFF94A3B8)))))
          : Column(
              children: servicios.map((s) => ListTile(
                leading: const Icon(Icons.check_circle_outline, color: _verde, size: 18),
                title: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                dense: true,
              )).toList(),
            ),
    );
  }

  Widget _tabResenas(List<Map<String, dynamic>> resenas) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: resenas.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(20),
              child: Text('Sin reseñas aún.', style: TextStyle(color: Color(0xFF94A3B8)))))
          : Column(
              children: resenas.map((r) {
                final estrellas = (r['estrellas'] ?? 5) as int;
                final fotoUrl = r['foto_url']?.toString() ?? '';
                final provider = _imgProvider(fotoUrl);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: _verde.withValues(alpha: 0.15),
                        backgroundImage: provider,
                        child: provider == null
                            ? Text(r['cliente'].toString().isNotEmpty ? r['cliente'].toString()[0].toUpperCase() : '?',
                                style: const TextStyle(color: _verde, fontSize: 11))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(r['cliente'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                Text(r['fecha'] ?? '', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                              ],
                            ),
                            Row(children: List.generate(5, (i) => Icon(Icons.star, size: 12,
                                color: i < estrellas ? _amarillo : const Color(0xFFE2E8F0)))),
                            Text(r['comentario'] ?? '',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _fondoGradiente() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [const Color(0xFF0D9488).withValues(alpha: 0.8), const Color(0xFF0F172A).withValues(alpha: 0.9)],
        ),
      ),
      child: const Center(child: Icon(Icons.build_outlined, size: 80, color: Colors.white24)),
    );
  }

  Widget _avatarLetra() {
    final nombre = p['nombre']?.toString() ?? '';
    return Container(
      color: const Color(0xFF0D9488).withValues(alpha: 0.15),
      child: Center(
        child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
            style: const TextStyle(color: Color(0xFF0D9488), fontSize: 28, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _chip(IconData icono, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCCFBF1)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, size: 12, color: _verde), const SizedBox(width: 5),
        Text(texto, style: const TextStyle(color: _verde, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _infoItem(IconData icono, Color color, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icono, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(etiqueta, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              Text(valor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _oscuro)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _contactoItem(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icono, size: 14, color: _verde), const SizedBox(width: 8),
        Expanded(child: Text(texto,
            style: const TextStyle(color: _oscuro, fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

// ─── Dialogo Mensaje ──────────────────────────────────────────────────────────
class _DialogoMensaje extends StatefulWidget {
  final Map<String, dynamic> proveedor;
  const _DialogoMensaje({required this.proveedor});
  @override
  State<_DialogoMensaje> createState() => _EstadoDialogoMensaje();
}

class _EstadoDialogoMensaje extends State<_DialogoMensaje> {
  static const Color _verde = Color(0xFF0D9488);
  static const Color _oscuro = Color(0xFF0F172A);
  final _ctrl = TextEditingController();
  bool _enviando = false;
  bool _enviado = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _enviar() async {
    if (_ctrl.text.trim().isEmpty) return;
    if (SesionUsuario.correo == null) { Navigator.pop(context); return; }
    setState(() => _enviando = true);
    final ok = await ServicioApi.enviarMensaje(
      correoRemitente: SesionUsuario.correo!,
      correoDestinatario: widget.proveedor['correo'] ?? '',
      contenido: _ctrl.text.trim(),
    );
    setState(() { _enviando = false; _enviado = ok; });
    if (ok) Future.delayed(const Duration(seconds: 2), () { if (mounted) Navigator.pop(context); });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.message_outlined, color: _verde, size: 22),
              const SizedBox(width: 10),
              Text('Mensaje a ${widget.proveedor['nombre'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _oscuro)),
              const Spacer(),
              GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Color(0xFF94A3B8))),
            ]),
            const SizedBox(height: 16),
            if (_enviado)
              const Center(child: Column(children: [
                Icon(Icons.check_circle, color: _verde, size: 40),
                SizedBox(height: 8),
                Text('Mensaje enviado correctamente', style: TextStyle(color: _verde, fontWeight: FontWeight.w700)),
              ]))
            else ...[
              TextField(
                controller: _ctrl, maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Escribe tu mensaje...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true, fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _verde, width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _enviar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _verde, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _enviando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Enviar mensaje', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Dialogo Solicitud ────────────────────────────────────────────────────────
class _DialogoSolicitud extends StatefulWidget {
  final Map<String, dynamic> proveedor;
  const _DialogoSolicitud({required this.proveedor});
  @override
  State<_DialogoSolicitud> createState() => _EstadoDialogoSolicitud();
}

class _EstadoDialogoSolicitud extends State<_DialogoSolicitud> {
  static const Color _verde = Color(0xFF0D9488);
  static const Color _amarillo = Color(0xFFF59E0B);
  static const Color _oscuro = Color(0xFF0F172A);
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();
  final _direccion = TextEditingController();
  bool _enviando = false;
  bool _enviado = false;
  String? _error;

  @override
  void dispose() { _titulo.dispose(); _descripcion.dispose(); _direccion.dispose(); super.dispose(); }

  Future<void> _solicitar() async {
    if (_titulo.text.trim().isEmpty || _descripcion.text.trim().isEmpty) {
      setState(() => _error = 'Completa el titulo y la descripcion.');
      return;
    }
    setState(() { _enviando = true; _error = null; });
    final ok = await ServicioApi.crearSolicitud(
      correoCliente: SesionUsuario.correo ?? '',
      idProveedor: widget.proveedor['id'],
      titulo: _titulo.text.trim(),
      descripcion: _descripcion.text.trim(),
      direccion: _direccion.text.trim(),
    );
    setState(() { _enviando = false; _enviado = ok; });
    if (!ok) setState(() => _error = 'Error al enviar la solicitud.');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.handshake_outlined, color: _amarillo, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text('Solicitar servicio a ${widget.proveedor['nombre'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _oscuro))),
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Color(0xFF94A3B8))),
              ]),
              const SizedBox(height: 16),
              if (_enviado)
                const Center(child: Column(children: [
                  Icon(Icons.check_circle, color: _verde, size: 48),
                  SizedBox(height: 12),
                  Text('¡Solicitud enviada!', style: TextStyle(color: _verde, fontWeight: FontWeight.w800, fontSize: 18)),
                  SizedBox(height: 8),
                  Text('El proveedor recibira tu solicitud y te respondera pronto.',
                      textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B))),
                ]))
              else ...[
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                _campoTexto('Titulo del servicio *', _titulo, 'Ej: Instalacion electrica completa'),
                const SizedBox(height: 12),
                _campoTexto('Descripcion *', _descripcion, 'Describe lo que necesitas...', maxLines: 3),
                const SizedBox(height: 12),
                _campoTexto('Direccion', _direccion, 'Donde se realizara el servicio'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _enviando ? null : _solicitar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _amarillo, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _enviando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Enviar solicitud', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoTexto(String etiqueta, TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl, maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            filled: true, fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _verde, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

// ─── Dialogo Reseña ───────────────────────────────────────────────────────────
class _DialogoResena extends StatefulWidget {
  final Map<String, dynamic> proveedor;
  final List<Map<String, dynamic>> solicitudesCompletadas;
  const _DialogoResena({required this.proveedor, required this.solicitudesCompletadas});
  @override
  State<_DialogoResena> createState() => _EstadoDialogoResena();
}

class _EstadoDialogoResena extends State<_DialogoResena> {
  static const Color _verde = Color(0xFF0D9488);
  static const Color _amarillo = Color(0xFFF59E0B);
  static const Color _oscuro = Color(0xFF0F172A);
  final _comentario = TextEditingController();
  int _estrellas = 5;
  bool _enviando = false;
  bool _enviado = false;
  String? _error;
  dynamic _solicitudSeleccionada;

  @override
  void initState() {
    super.initState();
    if (widget.solicitudesCompletadas.isNotEmpty) {
      _solicitudSeleccionada = widget.solicitudesCompletadas.first['id'];
    }
  }

  @override
  void dispose() { _comentario.dispose(); super.dispose(); }

  Future<void> _enviar() async {
    if (_comentario.text.trim().isEmpty) {
      setState(() => _error = 'Escribe un comentario.');
      return;
    }
    setState(() { _enviando = true; _error = null; });
    final resultado = await ServicioApi.crearResena(
      correoCliente: SesionUsuario.correo ?? '',
      idProveedor: widget.proveedor['id'],
      idSolicitud: _solicitudSeleccionada,
      estrellas: _estrellas,
      comentario: _comentario.text.trim(),
    );
    setState(() { _enviando = false; });
    if (resultado['exito'] == true) {
      setState(() => _enviado = true);
    } else {
      setState(() => _error = resultado['error'] ?? 'Error al enviar reseña.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                const Icon(Icons.star, color: _amarillo, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text('Reseña para ${widget.proveedor['nombre'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _oscuro))),
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Color(0xFF94A3B8))),
              ]),
              const SizedBox(height: 16),
              if (_enviado)
                const Column(children: [
                  Icon(Icons.check_circle, color: _verde, size: 48),
                  SizedBox(height: 12),
                  Text('¡Reseña enviada!', style: TextStyle(color: _verde, fontWeight: FontWeight.w800, fontSize: 18)),
                ])
              else ...[
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                // Estrellas
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => GestureDetector(
                    onTap: () => setState(() => _estrellas = i + 1),
                    child: Icon(Icons.star, size: 36, color: i < _estrellas ? _amarillo : const Color(0xFFE2E8F0)),
                  )),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _comentario, maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Cuéntanos tu experiencia...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    filled: true, fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _verde, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _enviando ? null : _enviar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _amarillo, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _enviando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Enviar reseña', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}