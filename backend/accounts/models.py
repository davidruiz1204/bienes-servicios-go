from django.db import models
import os


class Perfil(models.Model):
    TIPO_CHOICES = [
        ('cliente', 'Cliente'),
        ('proveedor', 'Proveedor'),
    ]
    tipo = models.CharField(max_length=10, choices=TIPO_CHOICES)
    nombre = models.CharField(max_length=100)
    correo = models.EmailField(unique=True)
    contrasena = models.CharField(max_length=255)
    telefono = models.CharField(max_length=20)
    cedula = models.CharField(max_length=11)
    oficio = models.CharField(max_length=100, blank=True, null=True)
    negocio = models.CharField(max_length=200, blank=True, null=True)
    descripcion = models.TextField(blank=True, null=True)
    # Foto de perfil guardada en servidor
    foto = models.ImageField(upload_to='fotos_perfil/', blank=True, null=True)
    foto_url = models.URLField(blank=True, null=True)
    ciudad = models.CharField(max_length=100, default='Girardot')
    direccion = models.CharField(max_length=300, blank=True, null=True)
    horario = models.CharField(max_length=100, blank=True, null=True)
    precio = models.CharField(max_length=100, blank=True, null=True)
    experiencia = models.IntegerField(default=0)
    disponible = models.BooleanField(default=True)
    # PDF informe laboral
    informe_laboral = models.FileField(upload_to='informes_laborales/', blank=True, null=True)
    fecha_registro = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.nombre} ({self.tipo})'

    def get_foto_url(self, request=None):
        if self.foto:
            if request:
                return request.build_absolute_uri(self.foto.url)
            return self.foto.url
        return self.foto_url or ''

    def get_informe_url(self, request=None):
        if self.informe_laboral:
            if request:
                return request.build_absolute_uri(self.informe_laboral.url)
            return self.informe_laboral.url
        return ''

    @property
    def calificacion_promedio(self):
        resenas = self.resenas_recibidas.all()
        if not resenas.exists():
            return 0.0
        return round(sum(r.estrellas for r in resenas) / resenas.count(), 1)

    @property
    def trabajos_completados(self):
        return Solicitud.objects.filter(proveedor=self, estado='completada').count()


class FotoPortafolio(models.Model):
    proveedor = models.ForeignKey(
        Perfil, on_delete=models.CASCADE, related_name='fotos_portafolio'
    )
    foto = models.ImageField(upload_to='portafolio/')
    descripcion = models.CharField(max_length=200, blank=True)
    fecha = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'Foto de {self.proveedor.nombre}'


class Solicitud(models.Model):
    ESTADO_CHOICES = [
        ('pendiente', 'Pendiente'),
        ('aceptada', 'Aceptada'),
        ('rechazada', 'Rechazada'),
        ('completada', 'Completada'),
    ]
    cliente = models.ForeignKey(
        Perfil, on_delete=models.CASCADE, related_name='solicitudes_enviadas'
    )
    proveedor = models.ForeignKey(
        Perfil, on_delete=models.CASCADE, related_name='solicitudes_recibidas'
    )
    titulo = models.CharField(max_length=200)
    descripcion = models.TextField()
    direccion = models.CharField(max_length=200)
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='pendiente')
    precio = models.IntegerField(null=True, blank=True)
    fecha = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.titulo} - {self.estado}'


class Resena(models.Model):
    proveedor = models.ForeignKey(
        Perfil, on_delete=models.CASCADE, related_name='resenas_recibidas'
    )
    cliente = models.ForeignKey(
        Perfil, on_delete=models.CASCADE, related_name='resenas_hechas'
    )
    solicitud = models.ForeignKey(
        Solicitud, on_delete=models.SET_NULL, null=True, blank=True
    )
    estrellas = models.IntegerField(default=5)
    comentario = models.TextField()
    fecha = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'Resena de {self.cliente.nombre} a {self.proveedor.nombre}'


class Favorito(models.Model):
    cliente = models.ForeignKey(
        Perfil, on_delete=models.CASCADE, related_name='favoritos'
    )
    proveedor = models.ForeignKey(
        Perfil, on_delete=models.CASCADE, related_name='guardado_por'
    )
    fecha = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('cliente', 'proveedor')

    def __str__(self):
        return f'{self.cliente.nombre} - {self.proveedor.nombre}'


class Mensaje(models.Model):
    remitente = models.ForeignKey(
        Perfil, on_delete=models.CASCADE, related_name='mensajes_enviados'
    )
    destinatario = models.ForeignKey(
        Perfil, on_delete=models.CASCADE, related_name='mensajes_recibidos'
    )
    contenido = models.TextField()
    leido = models.BooleanField(default=False)
    fecha = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.remitente.nombre} a {self.destinatario.nombre}'