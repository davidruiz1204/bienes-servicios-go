import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/servicio_api.dart';
import 'pantalla_perfil_proveedor.dart';

class PantallaResultados extends StatefulWidget {
  final String oficio;
  final String nombre;

  const PantallaResultados({
    super.key,
    required this.oficio,
    required this.nombre,
  });

  @override
  State<PantallaResultados> createState() => _EstadoPantallaResultados();
}

class _EstadoPantallaResultados extends State<PantallaResultados> {
  static const Color _verde = Color(0xFF0D9488);
  static const Color _amarillo = Color(0xFFF59E0B);
  static const Color _oscuro = Color(0xFF0F172A);

  List<Map<String, dynamic>> _proveedores = [];
  bool _cargando = true;
  String _municipioFiltro = 'Todos';
  String _ordenFiltro = 'calificacion';
  final _controladorBusqueda = TextEditingController();

  static const List<String> _municipios = [
    'Todos', 'Girardot', 'Flandes', 'Melgar', 'Espinal', 'Ricaurte', 'Agua de Dios'
  ];

  @override
  void initState() {
    super.initState();
    _controladorBusqueda.text = widget.oficio == 'Todos los oficios' ? '' : widget.oficio;
    _buscar();
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() => _cargando = true);
    final resultado = await ServicioApi.buscarProveedores(
      oficio: _controladorBusqueda.text.trim().isEmpty ? 'Todos los oficios' : _controladorBusqueda.text.trim(),
      nombre: widget.nombre,
      municipio: _municipioFiltro,
    );
    List<Map<String, dynamic>> lista = List<Map<String, dynamic>>.from(resultado['proveedores'] ?? []);
    if (_ordenFiltro == 'calificacion') {
      lista.sort((a, b) => (b['calificacion'] as num).compareTo(a['calificacion'] as num));
    } else if (_ordenFiltro == 'trabajos') {
      lista.sort((a, b) => (b['trabajos_completados'] as num).compareTo(a['trabajos_completados'] as num));
    }
    setState(() {
      _proveedores = lista;
      _cargando = false;
    });
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
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: _verde))
                : _proveedores.isEmpty
                    ? _vistaSinResultados()
                    : _listaProveedores(),
          ),
        ],
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF0D9488)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila top: atrás + título
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.oficio == 'Todos los oficios' ? 'Todos los proveedores' : widget.oficio,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        if (!_cargando)
                          Text(
                            '${_proveedores.length} resultado${_proveedores.length != 1 ? 's' : ''}',
                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Barra de búsqueda
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(Icons.search, color: _verde, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controladorBusqueda,
                        onSubmitted: (_) => _buscar(),
                        style: const TextStyle(fontSize: 14, color: _oscuro),
                        decoration: const InputDecoration(
                          hintText: 'Buscar por oficio o nombre...',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _buscar,
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _verde,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Buscar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Filtros
              Row(
                children: [
                  // Municipio
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _municipioFiltro,
                          dropdownColor: _oscuro,
                          iconEnabledColor: Colors.white70,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: _municipios.map((m) => DropdownMenuItem(
                            value: m,
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: _verde),
                                const SizedBox(width: 6),
                                Text(m, style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ],
                            ),
                          )).toList(),
                          onChanged: (v) {
                            setState(() => _municipioFiltro = v!);
                            _buscar();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Ordenar
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _ordenFiltro,
                          dropdownColor: _oscuro,
                          iconEnabledColor: Colors.white70,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: const [
                            DropdownMenuItem(value: 'calificacion', child: Row(children: [Icon(Icons.star, size: 14, color: _amarillo), SizedBox(width: 6), Text('Mejor calificación', style: TextStyle(color: Colors.white, fontSize: 13))])),
                            DropdownMenuItem(value: 'trabajos', child: Row(children: [Icon(Icons.work_outline, size: 14, color: _verde), SizedBox(width: 6), Text('Más trabajos', style: TextStyle(color: Colors.white, fontSize: 13))])),
                          ],
                          onChanged: (v) {
                            setState(() => _ordenFiltro = v!);
                            _buscar();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vistaSinResultados() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20)],
            ),
            child: const Icon(Icons.search_off, size: 48, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 20),
          const Text('Sin resultados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _oscuro)),
          const SizedBox(height: 8),
          const Text('Intenta con otro oficio o municipio', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Volver', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _verde,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listaProveedores() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _proveedores.length,
      itemBuilder: (_, i) => _tarjetaProveedor(_proveedores[i], i),
    );
  }

  Widget _tarjetaProveedor(Map<String, dynamic> p, int index) {
    final calificacion = (p['calificacion'] as num?)?.toDouble() ?? 0.0;
    final disponible = p['disponible'] ?? true;
    final fotoUrl = p['foto_url']?.toString() ?? '';
    final trabajos = p['trabajos_completados'] ?? 0;
    final experiencia = p['experiencia'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Banda superior de color
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              gradient: LinearGradient(
                colors: disponible
                    ? [const Color(0xFF0D9488), const Color(0xFF34D399)]
                    : [const Color(0xFF94A3B8), const Color(0xFFCBD5E1)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: _verde.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _imgProvider(fotoUrl) != null
                            ? Image(image: _imgProvider(fotoUrl)!, fit: BoxFit.cover)
                            : Container(
                                color: _verde.withValues(alpha: 0.12),
                                child: Center(
                                  child: Text(
                                    p['nombre'].toString().isNotEmpty ? p['nombre'].toString()[0].toUpperCase() : '?',
                                    style: const TextStyle(color: _verde, fontSize: 28, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    // Indicador disponibilidad
                    Positioned(
                      bottom: 4, right: 4,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: disponible ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Info principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(p['nombre'] ?? '',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _oscuro)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: disponible ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              disponible ? 'Disponible' : 'Ocupado',
                              style: TextStyle(
                                color: disponible ? const Color(0xFF15803D) : const Color(0xFF94A3B8),
                                fontSize: 11, fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _verde.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(p['oficio'] ?? '',
                            style: const TextStyle(color: _verde, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 8),
                      // Stats row
                      Row(
                        children: [
                          _statChip(Icons.star, _amarillo, calificacion == 0 ? 'Nuevo' : calificacion.toStringAsFixed(1)),
                          const SizedBox(width: 10),
                          _statChip(Icons.work_outline, const Color(0xFF3B82F6), '$trabajos trabajos'),
                          const SizedBox(width: 10),
                          _statChip(Icons.calendar_today_outlined, const Color(0xFF8B5CF6), '$experiencia años'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 13, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(p['ciudad'] ?? 'Girardot',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          const SizedBox(width: 12),
                          const Icon(Icons.attach_money, size: 13, color: Color(0xFF94A3B8)),
                          Expanded(
                            child: Text(p['precio'] ?? 'Consultar',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      if ((p['descripcion'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(p['descripcion'],
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.4),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Botones acción
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: _botonAccion(
                    icono: Icons.chat,
                    etiqueta: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    fondo: const Color(0xFFDCFCE7),
                    onTap: () async {
                      final tel = p['telefono']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
                      if (tel.isNotEmpty) {
                        final uri = Uri.parse('https://wa.me/57$tel');
                        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _botonAccion(
                    icono: Icons.person_outline,
                    etiqueta: 'Ver perfil completo',
                    color: Colors.white,
                    fondo: _verde,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaPerfilProveedor(proveedor: p))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icono, Color color, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 13, color: color),
        const SizedBox(width: 3),
        Text(texto, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _botonAccion({
    required IconData icono,
    required String etiqueta,
    required Color color,
    required Color fondo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 15, color: color),
            const SizedBox(width: 6),
            Text(etiqueta, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}