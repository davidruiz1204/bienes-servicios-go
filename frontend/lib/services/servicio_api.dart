import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ResultadoLogin {
  final bool exito;
  final String mensaje;
  final Map<String, dynamic>? usuario;
  ResultadoLogin({required this.exito, required this.mensaje, this.usuario});
}

class ResultadoRegistro {
  final bool exito;
  final String mensaje;
  ResultadoRegistro({required this.exito, required this.mensaje});
}

class ServicioApi {
  static const String _baseUrl = 'http://localhost:8000/api/auth';

  static Future<ResultadoLogin> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ResultadoLogin(exito: true, mensaje: data['mensaje'], usuario: data['usuario']);
      }
      return ResultadoLogin(exito: false, mensaje: data['error'] ?? 'Error al iniciar sesion.');
    } catch (e) {
      return ResultadoLogin(exito: false, mensaje: 'No se pudo conectar al servidor.');
    }
  }

  static Future<ResultadoRegistro> registrar({
    required String tipo,
    required String nombre,
    required String correo,
    required String contrasena,
    required String telefono,
    required String cedula,
    String? oficio,
    String? negocio,
    String? descripcion,
    Uint8List? fotoBytes,
    String? fotoNombre,
    Uint8List? informeBytes,
    String? informeNombre,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/registro/');
      final request = http.MultipartRequest('POST', uri);
      request.fields['tipo'] = tipo;
      request.fields['nombre'] = nombre;
      request.fields['correo'] = correo;
      request.fields['contrasena'] = contrasena;
      request.fields['telefono'] = telefono;
      request.fields['cedula'] = cedula;
      if (oficio != null) request.fields['oficio'] = oficio;
      if (negocio != null) request.fields['negocio'] = negocio;
      if (descripcion != null) request.fields['descripcion'] = descripcion;
      if (fotoBytes != null && fotoNombre != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'foto', fotoBytes, filename: fotoNombre, contentType: MediaType('image', 'jpeg'),
        ));
      }
      if (informeBytes != null && informeNombre != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'informe_laboral', informeBytes, filename: informeNombre, contentType: MediaType('application', 'pdf'),
        ));
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) return ResultadoRegistro(exito: true, mensaje: data['mensaje']);
      return ResultadoRegistro(exito: false, mensaje: data['error'] ?? 'Error al registrarse.');
    } catch (e) {
      return ResultadoRegistro(exito: false, mensaje: 'No se pudo conectar al servidor.');
    }
  }

  static Future<Map<String, dynamic>> buscarProveedores({
    String oficio = 'Todos los oficios',
    String nombre = '',
    String municipio = 'Todos',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/buscar/').replace(queryParameters: {
        if (oficio != 'Todos los oficios') 'oficio': oficio,
        if (nombre.isNotEmpty) 'nombre': nombre,
        if (municipio != 'Todos') 'municipio': municipio,
      });
      final response = await http.get(uri);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'proveedores': [], 'total': 0};
    } catch (e) {
      return {'proveedores': [], 'total': 0};
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerCategorias() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categorias/'));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body)['categorias']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/estadisticas/'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'proveedores': 0, 'servicios_completados': 0, 'clientes': 0, 'ciudades': 10};
    } catch (e) {
      return {'proveedores': 0, 'servicios_completados': 0, 'clientes': 0, 'ciudades': 10};
    }
  }

  static Future<Map<String, dynamic>> obtenerDatosDashboard({
    required String correo,
    required String tipo,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/dashboard/')
          .replace(queryParameters: {'correo': correo, 'tipo': tipo});
      final response = await http.get(uri);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return _datosDashboardVacios(tipo);
    } catch (e) {
      return _datosDashboardVacios(tipo);
    }
  }

  static Map<String, dynamic> _datosDashboardVacios(String tipo) {
    if (tipo == 'proveedor') {
      return {
        'ingresos_totales': 0, 'este_mes': 0, 'trabajos_hechos': 0,
        'calificacion': 0.0, 'disponible': true,
        'ultimas_calificaciones': [], 'solicitudes': [], 'mensajes': [],
        'ingresos_mensuales': List.filled(12, 0),
      };
    }
    return {
      'contrataciones': 0, 'servicios_activos': 0, 'favoritos': 0,
      'gasto_total': 0, 'historial': [], 'mensajes': [],
      'proveedores_favoritos': [],
    };
  }

  static Future<bool> responderSolicitud({required dynamic id, required String estado}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/solicitud/$id/responder/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': estado}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> obtenerPerfil(String correo) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/perfil/$correo/'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {};
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> editarPerfil({
    required String correo,
    required Map<String, String> campos,
    Uint8List? fotoBytes,
    String? fotoNombre,
    Uint8List? informeBytes,
    String? informeNombre,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/perfil/$correo/editar/');
      final request = http.MultipartRequest('POST', uri);
      campos.forEach((k, v) => request.fields[k] = v);
      if (fotoBytes != null && fotoNombre != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'foto', fotoBytes, filename: fotoNombre, contentType: MediaType('image', 'jpeg'),
        ));
      }
      if (fotoBytes == null && (campos['quitar_foto'] ?? '') == 'true') {
        request.fields['quitar_foto'] = 'true';
      }
      if (informeBytes != null && informeNombre != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'informe_laboral', informeBytes, filename: informeNombre, contentType: MediaType('application', 'pdf'),
        ));
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'error': 'Error al actualizar perfil.'};
    } catch (e) {
      return {'error': 'No se pudo conectar.'};
    }
  }

  static Future<bool> enviarMensaje({
    required String correoRemitente,
    required String correoDestinatario,
    required String contenido,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/mensaje/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo_remitente': correoRemitente,
          'correo_destinatario': correoDestinatario,
          'contenido': contenido,
        }),
      );
      return response.statusCode == 201;
    } catch (_) { return false; }
  }

  static Future<bool> eliminarMensaje({required dynamic id}) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/mensaje/$id/eliminar/'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> crearSolicitud({
    required String correoCliente,
    required dynamic idProveedor,
    required String titulo,
    required String descripcion,
    required String direccion,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/solicitud/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo_cliente': correoCliente,
          'id_proveedor': idProveedor,
          'titulo': titulo,
          'descripcion': descripcion,
          'direccion': direccion,
        }),
      );
      return response.statusCode == 201;
    } catch (_) { return false; }
  }

  static Future<Map<String, dynamic>?> subirFotoPortafolioConId({
    required String correo,
    required Uint8List fotoBytes,
    required String fotoNombre,
    String descripcion = '',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/perfil/$correo/portafolio/');
      final request = http.MultipartRequest('POST', uri);
      request.fields['descripcion'] = descripcion;
      request.files.add(http.MultipartFile.fromBytes(
        'foto', fotoBytes, filename: fotoNombre, contentType: MediaType('image', 'jpeg'),
      ));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (streamed.statusCode == 201) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> eliminarFotoPortafolio({required dynamic id}) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/portafolio/$id/eliminar/'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ─── FAVORITOS EN SERVIDOR ─────────────────────────────────────────────────
  static Future<bool> obtenerEsFavorito({
    required String correoCliente,
    required dynamic idProveedor,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/favorito/').replace(queryParameters: {
        'correo_cliente': correoCliente,
        'id_proveedor': idProveedor.toString(),
      });
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['favorito'] == true;
      }
      return false;
    } catch (_) { return false; }
  }

  static Future<bool> toggleFavorito({
    required String correoCliente,
    required dynamic idProveedor,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/favorito/toggle/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo_cliente': correoCliente, 'id_proveedor': idProveedor}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) { return false; }
  }

  // ─── RESEÑAS ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> crearResena({
    required String correoCliente,
    required dynamic idProveedor,
    required dynamic idSolicitud,
    required int estrellas,
    required String comentario,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/resena/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo_cliente': correoCliente,
          'id_proveedor': idProveedor,
          'id_solicitud': idSolicitud,
          'estrellas': estrellas,
          'comentario': comentario,
        }),
      );
      if (response.statusCode == 201) return {'exito': true};
      return {'exito': false, 'error': jsonDecode(response.body)['error'] ?? 'Error al crear reseña.'};
    } catch (_) { return {'exito': false, 'error': 'No se pudo conectar.'}; }
  }

  // ─── POLLING MENSAJES ──────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> obtenerMensajesProveedor(String correo) async {
    try {
      final uri = Uri.parse('$_baseUrl/mensajes/proveedor/').replace(queryParameters: {'correo': correo});
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body)['mensajes'] ?? []);
      }
      return [];
    } catch (_) { return []; }
  }
}