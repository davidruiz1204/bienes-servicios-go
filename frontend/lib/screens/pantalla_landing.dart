import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/pantalla_login.dart';
import '../screens/pantalla_registro.dart';
import '../screens/pantalla_resultados.dart';
import '../services/servicio_api.dart';

class PantallaLanding extends StatefulWidget {
  const PantallaLanding({super.key});

  @override
  State<PantallaLanding> createState() => _PantallaLandingState();
}

class _PantallaLandingState extends State<PantallaLanding> {
  final ScrollController _scrollController = ScrollController();
  String _oficioSeleccionado = 'Todos los oficios';

  static const Color _verde = Color(0xFF0D9488);
  static const Color _amarillo = Color(0xFFF59E0B);
  static const Color _oscuro = Color(0xFF0F172A);
  static const Color _grisClaro = Color(0xFFF8FAFC);

  Map<String, dynamic> _estadisticas = {
    'proveedores': 0,
    'servicios_completados': 0,
    'clientes': 0,
    'ciudades': 10,
  };
  List<Map<String, dynamic>> _categorias = [];
  final _controladorBusqueda = TextEditingController();

  // ─── KEYS PARA SCROLL ──────────────────────────────────────────────────────
  final _keyHero = GlobalKey();
  final _keyCategorias = GlobalKey();
  final _keyComoFunciona = GlobalKey();
  final _keyEstadisticas = GlobalKey();
  final _keyUnete = GlobalKey();
  final _keyFooter = GlobalKey();

  void _scrollASeccion(String seccion) {
    GlobalKey? key;
    switch (seccion) {
      case 'Inicio': key = _keyHero; break;
      case 'Servicios': key = _keyCategorias; break;
      case 'Proveedores': key = _keyEstadisticas; break;
      case 'Como funciona': key = _keyComoFunciona; break;
      case 'Contacto': key = _keyFooter; break;
      case 'Ayuda':
        launchUrl(
          Uri.parse('https://wa.me/573134649686?text=Hola,%20necesito%20ayuda%20con%20Bienes%20y%20Servicios%20GO'),
          mode: LaunchMode.externalApplication,
        );
        return;
    }
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  static const List<String> _oficios = [
    'Todos los oficios',
    'Electricista',
    'Plomero',
    'Carpintero',
    'Pintor',
    'Técnico',
    'Jardinería',
    'Transporte',
    'Limpieza',
    'Construcción',
    'Tecnología',
  ];

  static const List<(IconData, String)> _categoriasEstaticas = [
    (Icons.flash_on, 'Electricista'),
    (Icons.water_drop_outlined, 'Plomero'),
    (Icons.handyman_outlined, 'Carpintero'),
    (Icons.format_paint_outlined, 'Pintor'),
    (Icons.computer_outlined, 'Tecnico'),
    (Icons.yard_outlined, 'Jardineria'),
    (Icons.build_outlined, 'Cerrajero'),
    (Icons.local_laundry_service_outlined, 'Lavanderia'),
    (Icons.cleaning_services_outlined, 'Aseo'),
    (Icons.pets_outlined, 'Cuidado mascotas'),
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final stats = await ServicioApi.obtenerEstadisticas();
    final cats = await ServicioApi.obtenerCategorias();
    if (mounted) {
      setState(() {
        _estadisticas = stats;
        _categorias = cats;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controladorBusqueda.dispose();
    super.dispose();
  }

  void _irALogin() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaInicioSesion()));
  }

  void _irARegistro({String? tipo}) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PantallaRegistro(tipoInicial: tipo),
    ));
  }

  Future<void> _abrirMaps(String ciudad) async {
    final uri = Uri.parse('https://www.google.com/maps/search/$ciudad,+Cundinamarca,+Colombia');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _buscar() {
    final texto = _controladorBusqueda.text.trim();
    final oficioFinal = texto.isNotEmpty ? texto : _oficioSeleccionado;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaResultados(oficio: oficioFinal, nombre: ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildNavbar(),
            KeyedSubtree(key: _keyHero, child: _buildHero()),
            KeyedSubtree(key: _keyCategorias, child: _buildCategorias()),
            _buildServiciosMasSolicitados(),
            KeyedSubtree(key: _keyComoFunciona, child: _buildComoFunciona()),
            KeyedSubtree(key: _keyEstadisticas, child: _buildEstadisticas()),
            KeyedSubtree(key: _keyUnete, child: _buildUneteSecciones()),
            _buildTestimonios(),
            KeyedSubtree(key: _keyFooter, child: _buildFooter()),
          ],
        ),
      ),
    );
  }

  Widget _buildNavbar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _verde, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.home_work_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _oscuro),
              children: [
                TextSpan(text: 'Bienes y Servicios '),
                TextSpan(text: 'GO', style: TextStyle(color: _amarillo)),
              ],
            ),
          ),
          const SizedBox(width: 48),
          ..._navLinks(),
          const Spacer(),
          OutlinedButton(
            onPressed: _irALogin,
            style: OutlinedButton.styleFrom(
              foregroundColor: _oscuro,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Iniciar sesion', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _irARegistro(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _verde,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Registrarse', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  List<Widget> _navLinks() {
    final links = ['Inicio', 'Servicios', 'Proveedores', 'Como funciona', 'Contacto', 'Ayuda'];
    return links.map((l) => _BotonNavLink(
      etiqueta: l,
      onTap: () => _scrollASeccion(l),
    )).toList();
  }

  Widget _buildHero() {
    return SizedBox(
      height: 700,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/girardot.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Color(0x44000000)],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: _amarillo, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Girardot y municipios cercanos',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, height: 1.1),
                    children: [
                      TextSpan(text: 'Encuentra el servicio que\n', style: TextStyle(color: Colors.white)),
                      TextSpan(text: 'necesitas', style: TextStyle(color: _amarillo)),
                      TextSpan(text: ' cerca de ti', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Conecta con profesionales de confianza en Girardot.\nRápido, seguro y fácil.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
                ),
                const SizedBox(height: 36),
                Container(
                  width: 700,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.search, size: 20, color: _verde),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _controladorBusqueda,
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                                  decoration: const InputDecoration(
                                    hintText: '¿Qué servicio necesitas?',
                                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _buscar(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _oficioSeleccionado,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            items: _oficios.map((o) => DropdownMenuItem(
                              value: o,
                              child: Text(o),
                            )).toList(),
                            onChanged: (v) => setState(() => _oficioSeleccionado = v!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _buscar,
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Buscar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _verde,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Categorias populares:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(width: 12),
                    ..._categoriasPopulares(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _categoriasPopulares() {
    final cats = _categoriasEstaticas.take(6).toList();
    return cats.map((c) => GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PantallaResultados(oficio: c.$2, nombre: '')),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(c.$1, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(c.$2, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    )).toList();
  }

  Widget _buildCategorias() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF0D9488)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EXPLORA SERVICIOS',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
              children: [
                TextSpan(text: 'Encuentra el oficio que ', style: TextStyle(color: Colors.white)),
                TextSpan(text: 'necesitas', style: TextStyle(color: _amarillo)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Desde reparaciones basicas hasta proyectos especializados, tenemos\nproveedores calificados en cada categoria.',
            style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 40),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
            ),
            itemCount: _categoriasEstaticas.length,
            itemBuilder: (_, i) {
              final nombre = _categoriasEstaticas[i].$2;
              final icono = _categoriasEstaticas[i].$1;
              final conteo = _categorias.isEmpty
                  ? 0
                  : (_categorias.firstWhere(
                      (c) => c['oficio'].toString().toLowerCase() == nombre.toLowerCase(),
                      orElse: () => {'conteo': 0},
                    )['conteo'] as int? ?? 0);
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PantallaResultados(oficio: nombre, nombre: ''),
                  ),
                ),
                child: _tarjetaCategoria(icono, nombre, conteo),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tarjetaCategoria(IconData icono, String nombre, int conteo) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 10),
          Text(nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            '$conteo proveedor${conteo != 1 ? 'es' : ''}',
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildServiciosMasSolicitados() {
    return Container(
      color: _grisClaro,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 64),
      child: Column(
        children: [
          const Text('Servicios mas solicitados',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: _oscuro)),
          const SizedBox(height: 12),
          const Text(
            'Los servicios mas buscados por nuestra comunidad en Girardot y alrededores.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              _tarjetaServicio('Instalacion electrica', 'Electricista', const Color(0xFFF59E0B)),
              const SizedBox(width: 20),
              _tarjetaServicio('Reparacion de plomeria', 'Plomero', const Color(0xFF3B82F6)),
              const SizedBox(width: 20),
              _tarjetaServicio('Pintura interior', 'Pintor', const Color(0xFF8B5CF6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tarjetaServicio(String nombre, String tipo, Color color) {
    return Expanded(
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.8)],
          ),
        ),
        child: Stack(
          children: [
            Center(child: Icon(Icons.image_outlined, size: 60, color: Colors.white.withValues(alpha: 0.3))),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20, left: 20, right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                    child: Text(tipo, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 8),
                  Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComoFunciona() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 64),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFCCFBF1)),
            ),
            child: const Text('Proceso simple', style: TextStyle(color: _verde, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const SizedBox(height: 20),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _oscuro),
              children: [
                TextSpan(text: 'Como funciona '),
                TextSpan(text: 'Bienes y Servicios GO', style: TextStyle(color: _verde)),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _paso(1, Icons.search_rounded, 'Busca el servicio',
                  'Explora cientos de proveedores locales filtrando por categoria, ubicacion o calificacion.'),
              _lineaConectora(),
              _paso(2, Icons.chat_bubble_outline_rounded, 'Contacta al proveedor',
                  'Revisa perfiles, calificaciones y portafolios. Chatea o llama directamente por WhatsApp.'),
              _lineaConectora(),
              _paso(3, Icons.done_all_rounded, 'Contrata facilmente',
                  'Acuerda el precio, agenda el servicio y listo, problema resuelto.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paso(int numero, IconData icono, String titulo, String desc) {
    return Expanded(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(16)),
                child: Icon(icono, color: _verde, size: 32),
              ),
              Positioned(
                bottom: -8, right: -8,
                child: Container(
                  width: 26, height: 26,
                  decoration: const BoxDecoration(color: _amarillo, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$numero', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _oscuro)),
          const SizedBox(height: 12),
          Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  Widget _lineaConectora() {
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Container(width: 60, height: 2, color: const Color(0xFFCCFBF1)),
    );
  }

  Widget _buildEstadisticas() {
    final stats = [
      (_estadisticas['proveedores'].toString(), 'Proveedores registrados'),
      (_estadisticas['servicios_completados'].toString(), 'Servicios completados'),
      (_estadisticas['clientes'].toString(), 'Clientes satisfechos'),
      (_estadisticas['ciudades'].toString(), 'Ciudades cubiertas'),
    ];
    return Container(
      color: _grisClaro,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 48),
      child: Column(
        children: [
          Row(
            children: stats.map((s) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    Text(s.$1, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: _verde)),
                    const SizedBox(height: 8),
                    Text(s.$2, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8, runSpacing: 8,
            children: ['Girardot', 'Flandes', 'Espinal', 'Melgar', 'Ricaurte', 'Nilo', 'Agua de Dios', 'Tocaima', 'Fusagasuga', 'Jerusalen']
                .map((c) => GestureDetector(
                  onTap: () => _abrirMaps(c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFCCFBF1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 14, color: _verde),
                        const SizedBox(width: 4),
                        Text(c, style: const TextStyle(color: _oscuro, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUneteSecciones() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 64),
      child: Column(
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _oscuro),
              children: [
                TextSpan(text: 'Únete a '),
                TextSpan(text: 'Bienes y Servicios GO', style: TextStyle(color: _verde)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Elige cómo quieres ser parte de nuestra comunidad',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
          ),
          const SizedBox(height: 48),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tarjetaUnete(
                icono: Icons.engineering_outlined,
                titulo: 'Únete como proveedor',
                descripcion: 'Miles de clientes en Girardot y alrededores buscan profesionales como tú. Regístrate gratis y empieza a recibir solicitudes.',
                beneficios: [
                  'Registro gratuito y sin comisiones',
                  'Tú decides tu disponibilidad y precios',
                  'Pagos directos de los clientes',
                  'Soporte y visibilidad en tu zona',
                ],
                textoBoton: 'Registrarme como proveedor',
                colorFondo: const Color(0xFF0F4C3A),
                colorIcono: _verde,
                colorBoton: _oscuro,
                tipo: 'proveedor',
              ),
              const SizedBox(width: 24),
              _tarjetaUnete(
                icono: Icons.person_search_outlined,
                titulo: 'Únete como cliente',
                descripcion: 'Encuentra el profesional que necesitas en minutos. Compara perfiles, lee opiniones y contrata con total seguridad.',
                beneficios: [
                  'Acceso gratuito a cientos de profesionales',
                  'Compara precios y calificaciones',
                  'Contratación segura y rápida',
                  'Soporte en todo momento',
                ],
                textoBoton: 'Registrarme como cliente',
                colorFondo: const Color(0xFF1E3A5F),
                colorIcono: _amarillo,
                colorBoton: _verde,
                tipo: 'cliente',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tarjetaUnete({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required List<String> beneficios,
    required String textoBoton,
    required Color colorFondo,
    required Color colorIcono,
    required Color colorBoton,
    required String tipo,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorFondo, colorFondo.withValues(alpha: 0.7)],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(child: Icon(icono, size: 80, color: Colors.white24)),
                    Positioned(
                      bottom: 20, left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorIcono.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colorIcono.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          tipo == 'proveedor' ? 'Para profesionales' : 'Para usuarios',
                          style: TextStyle(color: colorIcono, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _oscuro)),
                    const SizedBox(height: 10),
                    Text(descripcion, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.6)),
                    const SizedBox(height: 20),
                    ...beneficios.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: colorIcono.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check, size: 13, color: colorIcono),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(b, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _oscuro))),
                        ],
                      ),
                    )),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _irARegistro(tipo: tipo),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorBoton,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(textoBoton, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestimonios() {
    return Container(
      color: _grisClaro,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 64),
      child: Column(
        children: [
          const Text('TESTIMONIOS',
              style: TextStyle(color: _verde, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: _oscuro),
              children: [
                TextSpan(text: 'Lo que dicen nuestros '),
                TextSpan(text: 'usuarios', style: TextStyle(fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: _oscuro, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: _amarillo, size: 14),
                      SizedBox(width: 6),
                      Text('5.0', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '"Los testimonios de clientes y proveedores apareceran aqui una vez que comiencen a usar la plataforma. Se el primero en compartir tu experiencia!"',
                  style: TextStyle(fontSize: 18, color: Color(0xFF334155), height: 1.7, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _verde.withValues(alpha: 0.2),
                      child: const Icon(Icons.person, color: _verde),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tu nombre aqui', style: TextStyle(fontWeight: FontWeight.w700, color: _oscuro)),
                        Text('Cliente - Girardot', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: _oscuro,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 48),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: _verde, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.home_work_outlined, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                            children: [
                              TextSpan(text: 'Bienes y Servicios '),
                              TextSpan(text: 'GO', style: TextStyle(color: _amarillo)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'La plataforma lider para conectar clientes con proveedores de servicios locales en Girardot y municipios cercanos.',
                      style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.6),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [Icons.camera_alt_outlined, Icons.facebook_outlined, Icons.play_circle_outline, Icons.chat_outlined]
                          .map((i) => Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(i, color: Colors.white60, size: 18),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              Expanded(child: _columnaFooter('Servicios', ['Electricistas', 'Plomeros', 'Carpinteros', 'Pintores', 'Jardineria'])),
              Expanded(child: _columnaFooter('Empresa', ['Sobre nosotros', 'Como funciona', 'Unete como proveedor', 'Blog', 'Prensa'])),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mantente informado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 8),
                    const Text('Recibe ofertas y novedades de proveedores en tu zona.', style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: const Text('Tu correo', style: TextStyle(color: Colors.white38, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: _verde, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('2026 Bienes y Servicios GO. Todos los derechos reservados.', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const Spacer(),
              ...['Centro de ayuda', 'Terminos y condiciones', 'Politica de privacidad', 'Contacto'].map((t) => Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(t, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              )),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'BIENES Y SERVICIOS GO',
            style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.04), letterSpacing: 4),
          ),
        ],
      ),
    );
  }

  Widget _columnaFooter(String titulo, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 16),
        ...items.map((i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(i, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        )),
      ],
    );
  }
}

// ─── Botón nav con hover ───────────────────────────────────────────────────────
class _BotonNavLink extends StatefulWidget {
  final String etiqueta;
  final VoidCallback onTap;
  const _BotonNavLink({required this.etiqueta, required this.onTap});
  @override
  State<_BotonNavLink> createState() => _EstadoBotonNavLink();
}

class _EstadoBotonNavLink extends State<_BotonNavLink> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            widget.etiqueta,
            style: TextStyle(
              color: _hover ? const Color(0xFF0D9488) : const Color(0xFF475569),
              fontWeight: _hover ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}