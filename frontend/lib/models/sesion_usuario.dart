class SesionUsuario {
  static String? correo;
  static String? nombre;
  static String? tipo;

  static void iniciar({
    required String correo,
    required String nombre,
    required String tipo,
  }) {
    SesionUsuario.correo = correo;
    SesionUsuario.nombre = nombre;
    SesionUsuario.tipo = tipo;
  }

  static void cerrar() {
    correo = null;
    nombre = null;
    tipo = null;
  }
}