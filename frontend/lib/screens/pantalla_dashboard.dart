import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sesion_usuario.dart';
import '../services/servicio_api.dart';
import 'pantalla_landing.dart';
import 'pantalla_perfil_proveedor.dart';
import 'pantalla_editar_perfil.dart';

class PantallaDashboard extends StatefulWidget {
  const PantallaDashboard({super.key});
  @override
  State<PantallaDashboard> createState() => _EstadoPantallaDashboard();
}

class _EstadoPantallaDashboard extends State<PantallaDashboard> {
  static const Color _verde = Color(0xFF0D9488);
  static const Color _amarillo = Color(0xFFF59E0B);
  static const Color _oscuro = Color(0xFF0F172A);

  String _seccionActual = 'inicio';
  Map<String, dynamic> _datosDashboard = {};
  List<Map<String, dynamic>> _proveedores = [];
  bool _cargando = true;
  final _controladorBusqueda = TextEditingController();
  final _controladorBusquedaTop = TextEditingController();
  bool _mostrandoNotificaciones = false;
  String _municipioSeleccionado = 'Todos';
  Timer? _pollingTimer;

  static const List<String> _municipios = [
    'Todos', 'Girardot', 'Flandes', 'Melgar', 'Espinal', 'Ricaurte', 'Agua de Dios'
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    // Polling cada 15 segundos
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) => _polling());
  }

  Future<void> _polling() async {
    if (!mounted) return;
    final correo = SesionUsuario.correo ?? '';
    final tipo = SesionUsuario.tipo ?? 'cliente';
    if (tipo == 'proveedor') {
      final mensajes = await ServicioApi.obtenerMensajesProveedor(correo);
      if (mounted) {
        setState(() => _datosDashboard['mensajes'] = mensajes);
      }
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final tipo = SesionUsuario.tipo ?? 'cliente';
    final correo = SesionUsuario.correo ?? '';
    final datos = await ServicioApi.obtenerDatosDashboard(correo: correo, tipo: tipo);
    final proveedores = await ServicioApi.buscarProveedores();
    if (mounted) {
      setState(() {
        _datosDashboard = datos;
        _proveedores = List<Map<String, dynamic>>.from(proveedores['proveedores'] ?? []);
        _cargando = false;
      });
    }
  }

  Future<void> _buscarProveedores(String texto, {String? municipio}) async {
    setState(() => _cargando = true);
    final muni = municipio ?? _municipioSeleccionado;
    final resultado = await ServicioApi.buscarProveedores(
      nombre: texto,
      municipio: muni,
    );
    if (mounted) {
      setState(() {
        _proveedores = List<Map<String, dynamic>>.from(resultado['proveedores'] ?? []);
        _cargando = false;
      });
    }
  }

  void _cerrarSesion() {
    SesionUsuario.cerrar();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PantallaLanding()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controladorBusqueda.dispose();
    _controladorBusquedaTop.dispose();
    super.dispose();
  }

  Widget _imgWidget(String url, double radius) {
    if (url.startsWith('data:image')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return CircleAvatar(radius: radius, backgroundImage: MemoryImage(bytes));
      } catch (_) {}
    } else if (url.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(url));
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _verde.withValues(alpha: 0.15),
      child: Text(
        (SesionUsuario.nombre ?? 'U')[0].toUpperCase(),
        style: TextStyle(color: _verde, fontWeight: FontWeight.w800, fontSize: radius * 0.7),
      ),
    );
  }

  ImageProvider? _imgProvider(String url) {
    if (url.startsWith('data:image')) {
      try { return MemoryImage(base64Decode(url.split(',').last)); } catch (_) {}
    } else if (url.isNotEmpty) {
      return NetworkImage(url);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final esProveedor = SesionUsuario.tipo == 'proveedor';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          _buildSidebar(esProveedor),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(esProveedor),
                Expanded(
                  child: _cargando
                      ? const Center(child: CircularProgressIndicator(color: _verde))
                      : _buildContenido(esProveedor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SIDEBAR ───────────────────────────────────────────────────────────────
  Widget _buildSidebar(bool esProveedor) {
    final items = esProveedor
        ? [
            ('inicio', Icons.dashboard_outlined, 'Inicio'),
            ('solicitudes', Icons.work_outline, 'Solicitudes'),
            ('mensajes_proveedor', Icons.chat_bubble_outline, 'Mensajes'), // ← NUEVO
            ('calificaciones', Icons.star_outline, 'Calificaciones'),
            ('historial', Icons.history_outlined, 'Historial'),
            ('perfil', Icons.person_outline, 'Mi Perfil'),
          ]
        : [
            ('inicio', Icons.dashboard_outlined, 'Inicio'),
            ('buscar', Icons.search, 'Buscar'),
            ('favoritos', Icons.favorite_border, 'Favoritos'),
            ('historial', Icons.history_outlined, 'Historial'),
            ('mensajes', Icons.chat_bubble_outline, 'Mensajes'),
          ];

    final fotoUrl = _datosDashboard['foto_url']?.toString() ?? '';

    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _verde, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.home_work_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _oscuro),
                    children: [
                      TextSpan(text: 'Bienes y Servicios '),
                      TextSpan(text: 'GO', style: TextStyle(color: _amarillo)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          ...items.map((item) => _navItem(item.$1, item.$2, item.$3)),
          const Spacer(),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                fotoUrl.isNotEmpty
                    ? _imgWidget(fotoUrl, 20)
                    : CircleAvatar(
                        radius: 20,
                        backgroundColor: _verde.withValues(alpha: 0.15),
                        child: Text(
                          (SesionUsuario.nombre ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(color: _verde, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _truncar(SesionUsuario.nombre ?? '', 18),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _oscuro),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        esProveedor ? 'Proveedor' : 'Cliente',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: _BotonHover(
              onTap: _cerrarSesion,
              child: const Row(
                children: [
                  Icon(Icons.logout, size: 16, color: Color(0xFF94A3B8)),
                  SizedBox(width: 8),
                  Text('Cerrar sesion', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(String id, IconData icono, String etiqueta) {
    final activo = _seccionActual == id;
    return _BotonHover(
      onTap: () => setState(() => _seccionActual = id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: activo ? _verde.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icono, size: 18, color: activo ? _verde : const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Text(
              etiqueta,
              style: TextStyle(
                color: activo ? _verde : const Color(0xFF64748B),
                fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(bool esProveedor) {
    final solicitudesPendientes = esProveedor
        ? ((_datosDashboard['solicitudes'] as List?)?.where((s) => s['estado'] == 'pendiente').length ?? 0)
        : 0;
    final tieneMensajes = !esProveedor &&
        (_datosDashboard['mensajes'] as List? ?? []).isNotEmpty;
    final tieneNotif = solicitudesPendientes > 0 || tieneMensajes;

    String tituloSeccion = _seccionActual[0].toUpperCase() + _seccionActual.substring(1);
    if (_seccionActual == 'inicio') tituloSeccion = 'Inicio';
    if (_seccionActual == 'mensajes_proveedor') tituloSeccion = 'Mensajes';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      child: Row(
        children: [
          Text(tituloSeccion,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _oscuro)),
          const Spacer(),
          Container(
            width: 280,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controladorBusquedaTop,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Buscar por oficio...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (v) {
                      setState(() => _seccionActual = 'buscar');
                      _buscarProveedores(v);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _BotonHover(
            onTap: () => setState(() => _mostrandoNotificaciones = !_mostrandoNotificaciones),
            child: Stack(
              children: [
                const Icon(Icons.notifications_outlined, size: 22, color: _oscuro),
                if (tieneNotif)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
          if (_mostrandoNotificaciones)
            _panelNotificaciones(esProveedor, solicitudesPendientes, tieneMensajes),
        ],
      ),
    );
  }

  Widget _panelNotificaciones(bool esProveedor, int pendientes, bool tieneMensajes) {
    final solicitudes = esProveedor
        ? ((_datosDashboard['solicitudes'] as List?) ?? [])
            .where((s) => s['estado'] == 'pendiente')
            .take(3)
            .toList()
        : [];
    final mensajes = !esProveedor
        ? ((_datosDashboard['mensajes'] as List?) ?? []).take(3).toList()
        : [];

    return Positioned(
      right: 16, top: 60,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Notificaciones',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _oscuro)),
              const SizedBox(height: 12),
              if (solicitudes.isEmpty && mensajes.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Aun no tienes notificaciones.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  ),
                )
              else ...[
                if (solicitudes.isNotEmpty) ...[
                  const Text('Solicitudes pendientes',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...solicitudes.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _amarillo.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.work_outline, color: _amarillo, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['titulo'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _oscuro)),
                              Text(s['cliente'] ?? '',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
                if (mensajes.isNotEmpty) ...[
                  const Text('Mensajes nuevos',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...mensajes.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _verde.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.message_outlined, color: _verde, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m['nombre'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _oscuro)),
                              Text(m['mensaje'] ?? '',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── CONTENIDO PRINCIPAL ───────────────────────────────────────────────────
  Widget _buildContenido(bool esProveedor) {
    if (esProveedor) {
      switch (_seccionActual) {
        case 'solicitudes': return _seccionSolicitudes();
        case 'mensajes_proveedor': return _seccionMensajesProveedor(); // ← NUEVO
        case 'calificaciones': return _seccionCalificaciones();
        case 'historial': return _seccionHistorialProveedor();
        case 'perfil': return _seccionMiPerfil();
        case 'portafolio': return _seccionPortafolio();
        default: return _dashboardProveedor();
      }
    } else {
      switch (_seccionActual) {
        case 'buscar': return _seccionBuscar();
        case 'favoritos': return _seccionFavoritos();
        case 'historial': return _seccionHistorialCliente();
        case 'mensajes': return _seccionMensajes();
        default: return _dashboardCliente();
      }
    }
  }

  // ─── SECCIONES PROVEEDOR ───────────────────────────────────────────────────

  Widget _seccionSolicitudes() {
    final solicitudes = List<Map<String, dynamic>>.from(_datosDashboard['solicitudes'] ?? []);
    final pendientes = solicitudes.where((s) => s['estado'] == 'pendiente').toList();
    final otras = solicitudes.where((s) => s['estado'] != 'pendiente').toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Solicitudes de trabajo',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _oscuro)),
          Text('${pendientes.length} solicitudes pendientes',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
          const SizedBox(height: 24),
          if (solicitudes.isEmpty)
            _tarjetaVacia('No tienes solicitudes aun.', Icons.work_outline)
          else ...[
            if (pendientes.isNotEmpty) ...[
              const Text('PENDIENTES',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 12),
              ...pendientes.map((s) => _itemSolicitudPendiente(s)),
            ],
            if (otras.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('OTRAS SOLICITUDES',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 12),
              ...otras.map((s) => _itemSolicitudOtra(s)),
            ],
          ],
        ],
      ),
    );
  }

  // ─── CONFIRMAR ELIMINAR MENSAJE ────────────────────────────────────────────
  void _confirmarEliminar(dynamic id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar mensaje',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Text('¿Seguro que quieres eliminar este mensaje? Esta acción no se puede deshacer.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarMensaje(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─── ELIMINAR MENSAJE ──────────────────────────────────────────────────────
  Future<void> _eliminarMensaje(dynamic id) async {
    final ok = await ServicioApi.eliminarMensaje(id: id);
    if (ok && mounted) {
      setState(() {
        final mensajes = List<Map<String, dynamic>>.from(_datosDashboard['mensajes'] ?? []);
        mensajes.removeWhere((m) => m['id'] == id);
        _datosDashboard['mensajes'] = mensajes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensaje eliminado'), backgroundColor: Colors.red),
      );
    }
  }

  // ─── NUEVA SECCIÓN: MENSAJES PROVEEDOR ─────────────────────────────────────
  Widget _seccionMensajesProveedor() {
    final mensajes = List<Map<String, dynamic>>.from(_datosDashboard['mensajes'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mensajes recibidos',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _oscuro)),
          Text('${mensajes.length} mensaje${mensajes.length != 1 ? 's' : ''}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
          const SizedBox(height: 24),
          if (mensajes.isEmpty)
            _tarjetaVacia('No tienes mensajes aún.', Icons.chat_bubble_outline)
          else
            ...mensajes.map((m) => _tarjetaMensajeProveedor(m)),
        ],
      ),
    );
  }

  Widget _tarjetaMensajeProveedor(Map<String, dynamic> m) {
    final fotoUrl = m['foto_url']?.toString() ?? '';
    final leido = m['leido'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: leido ? const Color(0xFFE2E8F0) : _verde.withValues(alpha: 0.4),
          width: leido ? 1 : 1.5,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        children: [
          // Cabecera
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _verde.withValues(alpha: 0.15),
                      backgroundImage: _imgProvider(fotoUrl),
                      child: _imgProvider(fotoUrl) == null
                          ? Text(
                              m['remitente_nombre'].toString().isNotEmpty
                                  ? m['remitente_nombre'].toString()[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: _verde, fontWeight: FontWeight.w800),
                            )
                          : null,
                    ),
                    if (!leido)
                      Positioned(
                        right: 0, top: 0,
                        child: Container(
                          width: 10, height: 10,
                          decoration: const BoxDecoration(color: _verde, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(m['remitente_nombre'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14, color: _oscuro)),
                          Text(m['tiempo'] ?? '',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(m['contenido'] ?? '',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                // Botón eliminar
                _BotonHover(
                  onTap: () => _confirmarEliminar(m['id']),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  ),
                ),
              ],
            ),
          ),
          // Área de respuesta
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: _AreaRespuesta(
              correoDestinatario: m['remitente_correo'] ?? '',
              nombreDestinatario: m['remitente_nombre'] ?? '',
              onEnviado: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Respuesta enviada ✓'),
                    backgroundColor: _verde,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccionCalificaciones() {
    final calificaciones = List<Map<String, dynamic>>.from(_datosDashboard['ultimas_calificaciones'] ?? []);
    final calificacion = _datosDashboard['calificacion'] ?? 0.0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Calificaciones',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _oscuro)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _amarillo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: _amarillo, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${calificacion is double ? calificacion.toStringAsFixed(1) : calificacion} promedio',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _oscuro),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (calificaciones.isEmpty)
            _tarjetaVacia('Aun no tienes calificaciones.', Icons.star_outline)
          else
            ...calificaciones.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
              ),
              child: _itemCalificacion(c),
            )),
        ],
      ),
    );
  }

  Widget _seccionHistorialProveedor() {
    final solicitudes = List<Map<String, dynamic>>.from(_datosDashboard['solicitudes'] ?? [])
        .where((s) => s['estado'] == 'completada').toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historial de trabajos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _oscuro)),
          const SizedBox(height: 24),
          if (solicitudes.isEmpty)
            _tarjetaVacia('No hay trabajos completados aun.', Icons.history)
          else
            ...solicitudes.map((s) => _itemSolicitudOtra(s)),
        ],
      ),
    );
  }

  Widget _seccionMiPerfil() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: FutureBuilder<Map<String, dynamic>>(
        future: ServicioApi.obtenerPerfil(SesionUsuario.correo ?? ''),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: _verde));
          }
          final p = snapshot.data!;
          final fotoUrl = p['foto_url']?.toString() ?? '';
          final portafolio = List<String>.from(
            (p['portafolio'] as List? ?? []).map((f) => f is Map ? f['url'] ?? '' : f.toString())
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mi Perfil',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _oscuro)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: _verde.withValues(alpha: 0.15),
                          backgroundImage: _imgProvider(fotoUrl),
                          child: _imgProvider(fotoUrl) == null
                              ? Text((p['nombre'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(color: _verde, fontSize: 28, fontWeight: FontWeight.w800))
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['nombre'] ?? '',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _oscuro)),
                              Text(p['oficio'] ?? '',
                                  style: const TextStyle(color: _verde, fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: _amarillo, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${p['calificacion'] ?? 0}',
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.work_outline, size: 16, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text('${p['trabajos_completados'] ?? 0} trabajos',
                                      style: const TextStyle(color: Color(0xFF64748B))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _BotonHover(
                          onTap: () async {
                            final perfil = await ServicioApi.obtenerPerfil(SesionUsuario.correo ?? '');
                            if (!mounted) return;
                            final ok = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PantallaEditarPerfil(perfilActual: perfil)),
                            );
                            if (ok == true) setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: _verde,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Editar perfil',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    _filaInfo(Icons.description_outlined, 'Descripcion', p['descripcion'] ?? 'Sin descripcion'),
                    _filaInfo(Icons.location_on_outlined, 'Ubicacion', '${p['direccion'] ?? ''}, ${p['ciudad'] ?? ''}'),
                    _filaInfo(Icons.access_time, 'Horario', p['horario'] ?? 'No especificado'),
                    _filaInfo(Icons.attach_money, 'Precio', p['precio'] ?? 'No especificado'),
                    _filaInfo(Icons.calendar_today_outlined, 'Experiencia', '${p['experiencia'] ?? 0} años'),
                    _filaInfo(Icons.phone_outlined, 'Telefono', p['telefono'] ?? ''),
                    if (p['informe_url'] != null && p['informe_url'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _BotonHover(
                        onTap: () async {
                          final uri = Uri.parse(p['informe_url']);
                          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCCFBF1)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf, color: _verde, size: 18),
                              SizedBox(width: 8),
                              Text('Ver informe laboral PDF',
                                  style: TextStyle(color: _verde, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (portafolio.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Portafolio',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _oscuro)),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
                        ),
                        itemCount: portafolio.length,
                        itemBuilder: (_, i) {
                          final url = portafolio[i];
                          if (url.startsWith('data:image')) {
                            try {
                              final bytes = base64Decode(url.split(',').last);
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(bytes, fit: BoxFit.cover),
                              );
                            } catch (_) {}
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(url, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFF1F5F9),
                                  child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
                                )),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filaInfo(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: _verde),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                Text(valor, style: const TextStyle(color: _oscuro, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECCIONES CLIENTE ─────────────────────────────────────────────────────

  Widget _seccionBuscar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Buscar proveedores',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _oscuro)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _controladorBusqueda,
                  onSubmitted: (v) => _buscarProveedores(v),
                  decoration: InputDecoration(
                    hintText: 'Busca por oficio, nombre...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _verde, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _municipioSeleccionado,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on, color: Color(0xFF94A3B8), size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _verde, width: 1.5)),
                  ),
                  items: _municipios.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) {
                    setState(() => _municipioSeleccionado = v!);
                    _buscarProveedores(_controladorBusqueda.text, municipio: v!);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_proveedores.isEmpty)
            _tarjetaVacia('No se encontraron proveedores.', Icons.search_off)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 2.2,
              ),
              itemCount: _proveedores.length,
              itemBuilder: (_, i) => _tarjetaProveedorDash(_proveedores[i]),
            ),
        ],
      ),
    );
  }

  Widget _seccionFavoritos() {
    final favs = List<Map<String, dynamic>>.from(_datosDashboard['proveedores_favoritos'] ?? []);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Proveedores favoritos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _oscuro)),
          const SizedBox(height: 24),
          if (favs.isEmpty)
            _tarjetaVacia('Aun no tienes favoritos.', Icons.favorite_border)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 2.5,
              ),
              itemCount: favs.length,
              itemBuilder: (_, i) => _tarjetaFavorito(favs[i]),
            ),
        ],
      ),
    );
  }

  Widget _seccionHistorialCliente() {
    final historial = List<Map<String, dynamic>>.from(_datosDashboard['historial'] ?? []);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historial de servicios',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _oscuro)),
          const SizedBox(height: 24),
          if (historial.isEmpty)
            _tarjetaVacia('No hay servicios completados aun.', Icons.history)
          else
            ...historial.map((h) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
              ),
              child: _itemHistorial(h),
            )),
        ],
      ),
    );
  }

  Widget _seccionMensajes() {
    final mensajes = List<Map<String, dynamic>>.from(_datosDashboard['mensajes'] ?? []);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mensajes',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _oscuro)),
          const SizedBox(height: 24),
          if (mensajes.isEmpty)
            _tarjetaVacia('No tienes mensajes aun.', Icons.chat_bubble_outline)
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
              ),
              child: Column(
                children: mensajes.map((m) => _itemMensaje(m)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tarjetaVacia(String mensaje, IconData icono) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icono, size: 48, color: const Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          Text(mensaje, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
        ],
      ),
    );
  }

  // ─── DASHBOARD CLIENTE ─────────────────────────────────────────────────────
  Widget _dashboardCliente() {
    final nombre = (SesionUsuario.nombre ?? '').split(' ').first;
    final contrataciones = _datosDashboard['contrataciones'] ?? 0;
    final serviciosActivos = _datosDashboard['servicios_activos'] ?? 0;
    final favoritos = _datosDashboard['favoritos'] ?? 0;
    final gastoTotal = _datosDashboard['gasto_total'] ?? 0;
    final historial = List<Map<String, dynamic>>.from(_datosDashboard['historial'] ?? []);
    final mensajes = List<Map<String, dynamic>>.from(_datosDashboard['mensajes'] ?? []);
    final proveedoresFav = List<Map<String, dynamic>>.from(_datosDashboard['proveedores_favoritos'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hola, $nombre',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _oscuro)),
          const Text('Aqui tienes un resumen de tu actividad',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
          const SizedBox(height: 24),
          Row(
            children: [
              _tarjetaStat(Icons.work_outline, '$contrataciones', 'Contrataciones', const Color(0xFF3B82F6)),
              const SizedBox(width: 16),
              _tarjetaStat(Icons.refresh, '$serviciosActivos', 'Servicios activos', _amarillo),
              const SizedBox(width: 16),
              _tarjetaStat(Icons.favorite_border, '$favoritos', 'Favoritos', Colors.redAccent),
              const SizedBox(width: 16),
              _tarjetaStatTexto('\$${_formatearPrecio(gastoTotal)}', 'Gasto total', _verde),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Buscar proveedores',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _oscuro)),
                const SizedBox(height: 16),
                TextField(
                  controller: _controladorBusqueda,
                  onSubmitted: _buscarProveedores,
                  decoration: InputDecoration(
                    hintText: 'Busca por oficio, nombre o ciudad...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _verde, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),
                if (_proveedores.isEmpty)
                  const Center(child: Text('No hay proveedores registrados aún.', style: TextStyle(color: Color(0xFF94A3B8))))
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 2.2,
                    ),
                    itemCount: _proveedores.length > 6 ? 6 : _proveedores.length,
                    itemBuilder: (_, i) => _tarjetaProveedorDash(_proveedores[i]),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Historial reciente',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _oscuro)),
                          _BotonHover(
                            onTap: () => setState(() => _seccionActual = 'historial'),
                            child: const Text('Ver todo', style: TextStyle(color: _verde, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (historial.isEmpty)
                        const Text('Sin historial aún.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13))
                      else
                        ...historial.take(3).map((h) => _itemHistorial(h)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mensajes recientes',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _oscuro)),
                          _BotonHover(
                            onTap: () => setState(() => _seccionActual = 'mensajes'),
                            child: const Text('Ver todo', style: TextStyle(color: _verde, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (mensajes.isEmpty)
                        const Text('Sin mensajes aún.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13))
                      else
                        ...mensajes.take(3).map((m) => _itemMensaje(m)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Proveedores favoritos',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _oscuro)),
                    _BotonHover(
                      onTap: () => setState(() => _seccionActual = 'favoritos'),
                      child: const Text('Ver todo', style: TextStyle(color: _verde, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (proveedoresFav.isEmpty)
                  const Text('Aún no tienes favoritos.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13))
                else
                  Row(
                    children: proveedoresFav.take(3).map((p) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _tarjetaFavorito(p),
                      ),
                    )).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── DASHBOARD PROVEEDOR ───────────────────────────────────────────────────
  Widget _dashboardProveedor() {
    final nombre = (SesionUsuario.nombre ?? '').split(' ').first;
    final ingresosTotales = _datosDashboard['ingresos_totales'] ?? 0;
    final estesMes = _datosDashboard['este_mes'] ?? 0;
    final trabajosHechos = _datosDashboard['trabajos_hechos'] ?? 0;
    final calificacion = _datosDashboard['calificacion'] ?? 0.0;
    final calificaciones = List<Map<String, dynamic>>.from(_datosDashboard['ultimas_calificaciones'] ?? []);
    final solicitudes = List<Map<String, dynamic>>.from(_datosDashboard['solicitudes'] ?? []);
    final disponible = _datosDashboard['disponible'] ?? true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hola, $nombre',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _oscuro)),
                  const Text('Asi va tu negocio hoy',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: disponible ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: disponible ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: disponible ? const Color(0xFF22C55E) : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      disponible ? 'Disponible para trabajos' : 'No disponible',
                      style: TextStyle(
                        color: disponible ? const Color(0xFF15803D) : Colors.red,
                        fontWeight: FontWeight.w600, fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _tarjetaStatTexto('\$${_formatearPrecio(ingresosTotales)}', 'Ingresos totales', _verde),
              const SizedBox(width: 16),
              _tarjetaStatTexto('\$${_formatearPrecio(estesMes)}', 'Este mes', const Color(0xFF3B82F6)),
              const SizedBox(width: 16),
              _tarjetaStat(Icons.work_outline, '$trabajosHechos', 'Trabajos hechos', _amarillo),
              const SizedBox(width: 16),
              _tarjetaStat(Icons.star, '${calificacion is double ? calificacion.toStringAsFixed(1) : calificacion} ★', 'Calificacion', Colors.orange),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ingresos mensuales',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _oscuro)),
                          Text('2026', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildGraficoBarras(_datosDashboard['ingresos_mensuales']),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ultimas calificaciones',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _oscuro)),
                          _BotonHover(
                            onTap: () => setState(() => _seccionActual = 'calificaciones'),
                            child: const Text('Ver todo', style: TextStyle(color: _verde, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (calificaciones.isEmpty)
                        const Text('Sin calificaciones aún.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13))
                      else
                        ...calificaciones.take(3).map((c) => _itemCalificacion(c)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Solicitudes de trabajo',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _oscuro)),
                        Text(
                          '${solicitudes.where((s) => s['estado'] == 'pendiente').length} solicitudes pendientes',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                    _BotonHover(
                      onTap: () => setState(() => _seccionActual = 'solicitudes'),
                      child: const Text('Ver todo', style: TextStyle(color: _verde, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Builder(
                  builder: (context) {
                    if (solicitudes.isEmpty) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No tienes solicitudes aún.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                      ));
                    }
                    final pendientes = solicitudes.where((s) => s['estado'] == 'pendiente').toList();
                    final otras = solicitudes.where((s) => s['estado'] != 'pendiente').toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (pendientes.isNotEmpty) ...[
                          const Text('PENDIENTES', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                          const SizedBox(height: 12),
                          ...pendientes.map((s) => _itemSolicitudPendiente(s)),
                        ],
                        if (otras.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('OTRAS SOLICITUDES', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                          const SizedBox(height: 12),
                          ...otras.map((s) => _itemSolicitudOtra(s)),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _accionRapida(Icons.person_outline, 'Editar perfil', () async {
                  final perfil = await ServicioApi.obtenerPerfil(SesionUsuario.correo ?? '');
                  if (!mounted) return;
                  final ok = await Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaEditarPerfil(perfilActual: perfil)));
                  if (ok == true) _cargarDatos();
                }),
                _accionRapida(Icons.photo_library_outlined, 'Ver portafolio', () => setState(() => _seccionActual = 'portafolio')),
                _accionRapida(Icons.share_outlined, 'Compartir perfil', () async {
                  final correo = SesionUsuario.correo ?? '';
                  await Clipboard.setData(ClipboardData(text: 'http://localhost:60107/#/proveedor/$correo'));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enlace copiado al portapapeles ✓'), backgroundColor: _verde),
                    );
                  }
                }),
                _accionRapida(Icons.headset_mic_outlined, 'Soporte', () async {
                  final uri = Uri.parse('https://wa.me/573134649686?text=Hola,%20necesito%20soporte%20con%20Bienes%20y%20Servicios%20GO');
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── WIDGETS REUTILIZABLES ─────────────────────────────────────────────────
  Widget _tarjetaStat(IconData icono, String valor, String etiqueta, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icono, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(valor, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _oscuro)),
            const SizedBox(height: 4),
            Text(etiqueta, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaStatTexto(String valor, String etiqueta, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.attach_money, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(valor, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _oscuro), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(etiqueta, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaProveedorDash(Map<String, dynamic> p) {
    final disponible = (p['disponible'] ?? true) as bool;
    final fotoUrl = p['foto_url']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _verde.withValues(alpha: 0.15),
                backgroundImage: _imgProvider(fotoUrl),
                child: _imgProvider(fotoUrl) == null
                    ? Text(p['nombre'].toString().isNotEmpty ? p['nombre'].toString()[0].toUpperCase() : '?',
                        style: const TextStyle(color: _verde, fontWeight: FontWeight.w800, fontSize: 12))
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_truncar(p['nombre'] ?? '', 16),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _oscuro),
                        overflow: TextOverflow.ellipsis),
                    Text(p['oficio'] ?? '', style: const TextStyle(color: _verde, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: disponible ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  disponible ? 'Disponible' : 'Ocupado',
                  style: TextStyle(color: disponible ? const Color(0xFF15803D) : const Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: _amarillo, size: 12),
              const SizedBox(width: 3),
              Text(p['calificacion'].toString() == '0' ? 'Nuevo' : p['calificacion'].toString(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              const Icon(Icons.location_on, size: 11, color: Color(0xFF94A3B8)),
              Expanded(child: Text(p['ciudad'] ?? 'Girardot',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _BotonHover(
                  onTap: () async {
                    final tel = p['telefono']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
                    if (tel.isNotEmpty) {
                      final uri = Uri.parse('https://wa.me/57$tel');
                      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                    child: const Center(child: Text('WhatsApp', style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.w700))),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _BotonHover(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaPerfilProveedor(proveedor: p))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCCFBF1)),
                    ),
                    child: const Center(child: Text('Ver perfil', style: TextStyle(color: _verde, fontSize: 10, fontWeight: FontWeight.w700))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemHistorial(Map<String, dynamic> h) {
    final fotoUrl = h['foto_url']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _verde.withValues(alpha: 0.15),
            backgroundImage: _imgProvider(fotoUrl),
            child: _imgProvider(fotoUrl) == null
                ? Text(h['proveedor'].toString().isNotEmpty ? h['proveedor'].toString()[0].toUpperCase() : '?',
                    style: const TextStyle(color: _verde, fontSize: 12, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h['servicio'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _oscuro)),
                Text('${h['proveedor']} · ${h['fecha']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                child: const Text('Completado', style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              Text('\$${_formatearPrecio(h['precio'] ?? 0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemMensaje(Map<String, dynamic> m) {
    final fotoUrl = m['foto_url']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _verde.withValues(alpha: 0.15),
                backgroundImage: _imgProvider(fotoUrl),
                child: _imgProvider(fotoUrl) == null
                    ? Text(m['nombre'].toString().isNotEmpty ? m['nombre'].toString()[0].toUpperCase() : '?',
                        style: const TextStyle(color: _verde, fontSize: 12, fontWeight: FontWeight.w700))
                    : null,
              ),
              if (m['en_linea'] == true)
                Positioned(right: 0, bottom: 0,
                    child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(m['nombre'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _oscuro)),
                    Text(m['tiempo'] ?? '', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
                Text(m['mensaje'] ?? '', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaFavorito(Map<String, dynamic> p) {
    final fotoUrl = p['foto_url']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _verde.withValues(alpha: 0.15),
            backgroundImage: _imgProvider(fotoUrl),
            child: _imgProvider(fotoUrl) == null
                ? Text(p['nombre'].toString().isNotEmpty ? p['nombre'].toString()[0].toUpperCase() : '?',
                    style: const TextStyle(color: _verde, fontSize: 12, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['nombre'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _oscuro), overflow: TextOverflow.ellipsis),
                Text(p['oficio'] ?? '', style: const TextStyle(color: _verde, fontSize: 11)),
                Row(
                  children: [
                    const Icon(Icons.star, color: _amarillo, size: 12),
                    const SizedBox(width: 3),
                    Text(p['calificacion']?.toString() ?? '0', style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 6),
                    Text('| ${p['ciudad'] ?? 'Girardot'}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.favorite, color: Colors.redAccent, size: 18),
        ],
      ),
    );
  }

  Widget _itemCalificacion(Map<String, dynamic> c) {
    final estrellas = (c['estrellas'] ?? 5) as int;
    final fotoUrl = c['foto_url']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _verde.withValues(alpha: 0.15),
            backgroundImage: _imgProvider(fotoUrl),
            child: _imgProvider(fotoUrl) == null
                ? Text(c['cliente'].toString().isNotEmpty ? c['cliente'].toString()[0].toUpperCase() : '?',
                    style: const TextStyle(color: _verde, fontSize: 12, fontWeight: FontWeight.w700))
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
                    Text(c['cliente'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _oscuro)),
                    Text(c['fecha'] ?? '', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
                Row(children: List.generate(5, (i) => Icon(Icons.star, size: 13, color: i < estrellas ? _amarillo : const Color(0xFFE2E8F0)))),
                const SizedBox(height: 4),
                Text(c['comentario'] ?? '', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                if (c['servicio'] != null)
                  Text(c['servicio'], style: const TextStyle(color: _verde, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemSolicitudPendiente(Map<String, dynamic> s) {
    final fotoUrl = s['foto_url']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _amarillo.withValues(alpha: 0.2),
            backgroundImage: _imgProvider(fotoUrl),
            child: _imgProvider(fotoUrl) == null
                ? Text(s['cliente'].toString().isNotEmpty ? s['cliente'].toString()[0].toUpperCase() : '?',
                    style: const TextStyle(color: _oscuro, fontSize: 12, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s['titulo'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _oscuro)),
                    Text(s['hora'] ?? '', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(s['descripcion'] ?? '', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(s['cliente'] ?? '', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Expanded(child: Text(s['direccion'] ?? '', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              _BotonHover(
                onTap: () => _responderSolicitud(s['id'], 'aceptada'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: _verde, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Aceptar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 6),
              _BotonHover(
                onTap: () => _responderSolicitud(s['id'], 'rechazada'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text('Rechazar', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemSolicitudOtra(Map<String, dynamic> s) {
    final estado = s['estado'] ?? '';
    Color colorEstado = const Color(0xFF94A3B8);
    Color bgEstado = const Color(0xFFF1F5F9);
    if (estado == 'aceptada') { colorEstado = _verde; bgEstado = const Color(0xFFDCFCE7); }
    if (estado == 'completada') { colorEstado = const Color(0xFF3B82F6); bgEstado = const Color(0xFFEFF6FF); }
    final fotoUrl = s['foto_url']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _verde.withValues(alpha: 0.15),
            backgroundImage: _imgProvider(fotoUrl),
            child: _imgProvider(fotoUrl) == null
                ? Text(s['cliente'].toString().isNotEmpty ? s['cliente'].toString()[0].toUpperCase() : '?',
                    style: const TextStyle(color: _verde, fontSize: 12, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['titulo'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _oscuro)),
                Text('${s['cliente']} · ${s['direccion']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(s['hora'] ?? '', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: bgEstado, borderRadius: BorderRadius.circular(6)),
                child: Text(estado.isNotEmpty ? estado[0].toUpperCase() + estado.substring(1) : '',
                    style: TextStyle(color: colorEstado, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
              if (s['precio'] != null) ...[
                const SizedBox(height: 4),
                Text('\$${_formatearPrecio(s['precio'])}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _oscuro)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _accionRapida(IconData icono, String etiqueta, VoidCallback onTap) {
    return _BotonHover(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icono, color: const Color(0xFF64748B), size: 24),
          ),
          const SizedBox(height: 8),
          Text(etiqueta, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildGraficoBarras(dynamic datos) {
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    List<double> valores = List.filled(12, 0);
    if (datos is List) {
      for (var i = 0; i < datos.length && i < 12; i++) {
        valores[i] = (datos[i] as num?)?.toDouble() ?? 0;
      }
    }
    final maxValor = valores.reduce((a, b) => a > b ? a : b);
    const alturaMax = 80.0;
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(12, (i) {
          final altura = maxValor > 0 ? (valores[i] / maxValor) * alturaMax : 4.0;
          final esActual = i == DateTime.now().month - 1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: altura < 4 ? 4 : altura,
                    decoration: BoxDecoration(
                      color: esActual ? _verde : _verde.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(meses[i], style: TextStyle(
                    fontSize: 9,
                    color: esActual ? _verde : const Color(0xFF94A3B8),
                    fontWeight: esActual ? FontWeight.w700 : FontWeight.w400,
                  )),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _formatearPrecio(dynamic valor) {
    final n = (valor as num?)?.toInt() ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    final s = n.toString();
    final result = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return result.toString();
  }

  String _truncar(String texto, int max) =>
      texto.length > max ? '${texto.substring(0, max)}...' : texto;

  Future<void> _responderSolicitud(dynamic id, String estado) async {
    if (id == null) return;
    final ok = await ServicioApi.responderSolicitud(id: id, estado: estado);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(estado == 'aceptada' ? 'Solicitud aceptada ✓' : 'Solicitud rechazada'),
          backgroundColor: estado == 'aceptada' ? _verde : Colors.red,
        ),
      );
      _cargarDatos();
    }
  }

  Widget _seccionPortafolio() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ServicioApi.obtenerPerfil(SesionUsuario.correo ?? ''),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _verde));
        final fotos = List<String>.from(
          (snapshot.data!['portafolio'] as List? ?? []).map((f) => f is Map ? f['url'] ?? '' : f.toString())
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mi Portafolio', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _oscuro)),
              const SizedBox(height: 24),
              if (fotos.isEmpty)
                _tarjetaVacia('No tienes fotos en tu portafolio aun.', Icons.photo_library_outlined)
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12,
                  ),
                  itemCount: fotos.length,
                  itemBuilder: (_, i) {
                    final url = fotos[i];
                    Widget img;
                    if (url.startsWith('data:image')) {
                      try {
                        final bytes = base64Decode(url.split(',').last);
                        img = Image.memory(bytes, fit: BoxFit.cover);
                      } catch (_) { img = _iconoImagen(); }
                    } else {
                      img = Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _iconoImagen());
                    }
                    return ClipRRect(borderRadius: BorderRadius.circular(12), child: img);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _iconoImagen() => Container(
    color: const Color(0xFFF1F5F9),
    child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
  );
}

// ─── Widget área de respuesta ──────────────────────────────────────────────────
class _AreaRespuesta extends StatefulWidget {
  final String correoDestinatario;
  final String nombreDestinatario;
  final VoidCallback onEnviado;

  const _AreaRespuesta({
    required this.correoDestinatario,
    required this.nombreDestinatario,
    required this.onEnviado,
  });

  @override
  State<_AreaRespuesta> createState() => _EstadoAreaRespuesta();
}

class _EstadoAreaRespuesta extends State<_AreaRespuesta> {
  static const Color _verde = Color(0xFF0D9488);
  final _ctrl = TextEditingController();
  bool _enviando = false;
  bool _expandido = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _enviando = true);
    final ok = await ServicioApi.enviarMensaje(
      correoRemitente: SesionUsuario.correo ?? '',
      correoDestinatario: widget.correoDestinatario,
      contenido: _ctrl.text.trim(),
    );
    setState(() { _enviando = false; _expandido = false; });
    _ctrl.clear();
    if (ok) widget.onEnviado();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _expandido ? _vistaExpandida() : _vistaColapsada(),
      ),
    );
  }

  Widget _vistaColapsada() {
    return _BotonHover(
      onTap: () => setState(() => _expandido = true),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCCFBF1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.reply, color: _verde, size: 16),
            const SizedBox(width: 8),
            Text('Responder a ${widget.nombreDestinatario}',
                style: const TextStyle(color: _verde, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _vistaExpandida() {
    return Column(
      children: [
        TextField(
          controller: _ctrl,
          maxLines: 3,
          autofocus: true,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Escribe tu respuesta...',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _verde, width: 1.5)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _BotonHover(
              onTap: () => setState(() { _expandido = false; _ctrl.clear(); }),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            ),
            const Spacer(),
            _BotonHover(
              onTap: _enviando ? () {} : _enviar,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: _verde,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _enviando
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(
                        children: [
                          Icon(Icons.send, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('Enviar', style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Botón Hover ───────────────────────────────────────────────────────────────
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
          scale: _presionado ? 0.96 : 1.0,
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