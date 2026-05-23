from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response
from rest_framework import status
from django.db import IntegrityError
from django.contrib.auth.hashers import make_password, check_password
from django.utils import timezone
from .models import Perfil, Solicitud, Resena, Favorito, Mensaje, FotoPortafolio
from .serializers import PerfilSerializer
import base64, os


def _img64(path):
    try:
        if path and os.path.exists(str(path)):
            with open(str(path), 'rb') as f:
                data = f.read()
            if not data:
                return ''
            ext = os.path.splitext(str(path))[1].lower().lstrip('.')
            if ext == 'jpg':
                ext = 'jpeg'
            if ext not in ('jpeg', 'png', 'gif', 'webp', 'AVIF'):
                ext = 'jpeg'
            encoded = base64.b64encode(data).decode('utf-8')
            return f'data:image/{ext};base64,{encoded}'
    except Exception as e:
        print(f'Error _img64: {e}')
    return ''


def _foto_perfil(perfil):
    if perfil.foto:
        b64 = _img64(perfil.foto.path)
        return b64 if b64 else (perfil.foto_url or '')
    return perfil.foto_url or ''


@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def registrar_usuario(request):
    datos = request.data.copy()
    if datos.get('tipo') == 'proveedor':
        descripcion = datos.get('descripcion', '').strip()
        palabras = len(descripcion.split())
        if palabras < 20:
            return Response({'error': f'La descripcion debe tener al menos 25 palabras. Tienes {palabras}.'}, status=400)
    if 'contrasena' in datos:
        datos['contrasena'] = make_password(datos['contrasena'])
    serializer = PerfilSerializer(data=datos)
    if serializer.is_valid():
        try:
            perfil = serializer.save()
            if 'foto' in request.FILES:
                perfil.foto = request.FILES['foto']
                perfil.save()
            if 'informe_laboral' in request.FILES:
                perfil.informe_laboral = request.FILES['informe_laboral']
                perfil.save()
            return Response({'mensaje': 'Registro exitoso'}, status=201)
        except IntegrityError:
            return Response({'error': 'Este correo ya esta registrado.'}, status=400)
    return Response(serializer.errors, status=400)


@api_view(['POST'])
def iniciar_sesion(request):
    correo = request.data.get('correo', '')
    contrasena = request.data.get('contrasena', '')
    try:
        usuario = Perfil.objects.get(correo=correo)
        if check_password(contrasena, usuario.contrasena):
            return Response({
                'mensaje': 'Login exitoso',
                'usuario': {
                    'id': usuario.id,
                    'nombre': usuario.nombre,
                    'correo': usuario.correo,
                    'tipo': usuario.tipo,
                    'foto_url': _foto_perfil(usuario),
                    'oficio': usuario.oficio or '',
                    'ciudad': usuario.ciudad,
                }
            })
        return Response({'error': 'Correo o contrasena incorrectos.'}, status=401)
    except Perfil.DoesNotExist:
        return Response({'error': 'Correo o contrasena incorrectos.'}, status=401)


@api_view(['GET'])
def buscar_proveedores(request):
    oficio = request.query_params.get('oficio', '')
    nombre = request.query_params.get('nombre', '')
    proveedores = Perfil.objects.filter(tipo='proveedor')
    if oficio and oficio != 'Todos los oficios':
        proveedores = proveedores.filter(oficio__icontains=oficio)
    if nombre:
        proveedores = proveedores.filter(nombre__icontains=nombre)
    proveedores = proveedores.order_by('nombre')
    resultado = []
    for p in proveedores:
        resenas_list = []
        for r in p.resenas_recibidas.select_related('cliente').order_by('-fecha')[:5]:
            resenas_list.append({
                'cliente': r.cliente.nombre,
                'foto_url': _foto_perfil(r.cliente),
                'estrellas': r.estrellas,
                'comentario': r.comentario,
                'fecha': r.fecha.strftime('%d %b %Y'),
            })
        fotos = []
        for f in p.fotos_portafolio.all()[:6]:
            b64 = _img64(f.foto.path)
            if b64:
                fotos.append(b64)
        resultado.append({
            'id': p.id,
            'nombre': p.nombre,
            'oficio': p.oficio or '',
            'descripcion': p.descripcion or '',
            'telefono': p.telefono,
            'correo': p.correo,
            'ciudad': p.ciudad,
            'direccion': p.direccion or '',
            'foto_url': _foto_perfil(p),
            'informe_url': request.build_absolute_uri(p.informe_laboral.url) if p.informe_laboral else '',
            'calificacion': p.calificacion_promedio,
            'disponible': p.disponible,
            'experiencia': p.experiencia,
            'trabajos_completados': p.trabajos_completados,
            'horario': p.horario or 'Lun - Dom: 8:00 AM - 6:00 PM',
            'precio': p.precio or 'Consultar',
            'resenas': resenas_list,
            'portafolio': fotos,
            'servicios': [],
        })
    return Response({'proveedores': resultado, 'total': len(resultado)})


@api_view(['GET'])
def categorias_con_conteo(request):
    oficios = ['Electricista', 'Plomero', 'Carpintero', 'Pintor', 'Tecnico', 'Jardineria', 'Cerrajero', 'Lavanderia', 'Aseo', 'Cuidado mascotas']
    resultado = [{'oficio': o, 'conteo': Perfil.objects.filter(tipo='proveedor', oficio__icontains=o).count()} for o in oficios]
    return Response({'categorias': resultado})


@api_view(['GET'])
def estadisticas(request):
    # Clientes satisfechos = clientes que tienen al menos una reseña con estrellas >= 4
    clientes_satisfechos = Perfil.objects.filter(
        tipo='cliente',
        resenas_hechas__estrellas__gte=4
    ).distinct().count()
    return Response({
        'proveedores': Perfil.objects.filter(tipo='proveedor').count(),
        'servicios_completados': Solicitud.objects.filter(estado='completada').count(),
        'clientes': clientes_satisfechos,
        'ciudades': 10,
    })


@api_view(['GET'])
def dashboard(request):
    correo = request.query_params.get('correo', '')
    tipo = request.query_params.get('tipo', 'cliente')
    try:
        usuario = Perfil.objects.get(correo=correo)
    except Perfil.DoesNotExist:
        return Response({'error': 'Usuario no encontrado.'}, status=404)
    if tipo == 'proveedor':
        return Response(_datos_proveedor(usuario, request))
    return Response(_datos_cliente(usuario, request))


def _datos_proveedor(usuario, request):
    solicitudes_qs = Solicitud.objects.filter(proveedor=usuario).select_related('cliente')
    completadas = solicitudes_qs.filter(estado='completada')
    ingresos_totales = sum(s.precio or 0 for s in completadas)
    hoy = timezone.now()
    inicio_mes = hoy.replace(day=1, hour=0, minute=0, second=0)
    este_mes = sum(s.precio or 0 for s in completadas if s.fecha >= inicio_mes)
    ingresos_mensuales = [0] * 12
    for s in completadas:
        ingresos_mensuales[s.fecha.month - 1] += s.precio or 0
    calificaciones = []
    for r in usuario.resenas_recibidas.select_related('cliente').order_by('-fecha')[:5]:
        calificaciones.append({
            'cliente': r.cliente.nombre,
            'foto_url': _foto_perfil(r.cliente),
            'estrellas': r.estrellas,
            'comentario': r.comentario,
            'fecha': r.fecha.strftime('%d %b %Y'),
            'servicio': r.solicitud.titulo if r.solicitud else '',
        })
    solicitudes_data = []
    for s in solicitudes_qs.order_by('-fecha')[:10]:
        solicitudes_data.append({
            'id': s.id,
            'titulo': s.titulo,
            'descripcion': s.descripcion,
            'cliente': s.cliente.nombre,
            'foto_url': _foto_perfil(s.cliente),
            'direccion': s.direccion,
            'estado': s.estado,
            'precio': s.precio,
            'hora': _formatear_tiempo(s.fecha),
        })

    # ─── MENSAJES RECIBIDOS POR EL PROVEEDOR ──────────────────────────────────
    mensajes_qs = Mensaje.objects.filter(
        destinatario=usuario
    ).select_related('remitente').order_by('-fecha')

    mensajes_proveedor = []
    for m in mensajes_qs[:20]:
        mensajes_proveedor.append({
            'id': m.id,
            'remitente_correo': m.remitente.correo,
            'remitente_nombre': m.remitente.nombre,
            'foto_url': _foto_perfil(m.remitente),
            'contenido': m.contenido,
            'leido': m.leido,
            'tiempo': _formatear_tiempo(m.fecha),
        })

    return {
        'ingresos_totales': ingresos_totales,
        'este_mes': este_mes,
        'trabajos_hechos': completadas.count(),
        'calificacion': usuario.calificacion_promedio,
        'disponible': usuario.disponible,
        'ultimas_calificaciones': calificaciones,
        'solicitudes': solicitudes_data,
        'ingresos_mensuales': ingresos_mensuales,
        'foto_url': _foto_perfil(usuario),
        'mensajes': mensajes_proveedor,  # ← NUEVO
    }


def _datos_cliente(usuario, request):
    solicitudes_qs = Solicitud.objects.filter(cliente=usuario).select_related('proveedor')
    gasto_total = sum(s.precio or 0 for s in solicitudes_qs.filter(estado='completada'))
    historial = []
    for s in solicitudes_qs.filter(estado='completada').order_by('-fecha')[:5]:
        historial.append({
            'servicio': s.titulo,
            'proveedor': s.proveedor.nombre,
            'foto_url': _foto_perfil(s.proveedor),
            'fecha': s.fecha.strftime('%d %b %Y'),
            'precio': s.precio or 0,
        })
    mensajes_qs = Mensaje.objects.filter(destinatario=usuario).select_related('remitente').order_by('-fecha')
    mensajes = []
    vistos = set()
    for m in mensajes_qs[:10]:
        if m.remitente.id not in vistos:
            vistos.add(m.remitente.id)
            mensajes.append({
                'nombre': m.remitente.nombre,
                'foto_url': _foto_perfil(m.remitente),
                'mensaje': m.contenido,
                'tiempo': _formatear_tiempo(m.fecha),
                'en_linea': False,
            })
        if len(mensajes) >= 3:
            break
    favoritos_qs = Favorito.objects.filter(cliente=usuario).select_related('proveedor')
    proveedores_fav = []
    for f in favoritos_qs[:3]:
        p = f.proveedor
        proveedores_fav.append({
            'id': p.id,
            'nombre': p.nombre,
            'oficio': p.oficio or '',
            'foto_url': _foto_perfil(p),
            'calificacion': p.calificacion_promedio,
            'ciudad': p.ciudad,
        })
    return {
        'contrataciones': solicitudes_qs.count(),
        'servicios_activos': solicitudes_qs.filter(estado='aceptada').count(),
        'favoritos': favoritos_qs.count(),
        'gasto_total': gasto_total,
        'historial': historial,
        'mensajes': mensajes,
        'proveedores_favoritos': proveedores_fav,
        'foto_url': _foto_perfil(usuario),
    }


@api_view(['GET'])
def obtener_perfil(request, correo):
    try:
        p = Perfil.objects.get(correo=correo)
        fotos = []
        for f in p.fotos_portafolio.all():
            b64 = _img64(f.foto.path)
            if b64:
                fotos.append({'id': f.id, 'url': b64})
        return Response({
            'id': p.id,
            'nombre': p.nombre,
            'correo': p.correo,
            'tipo': p.tipo,
            'telefono': p.telefono,
            'oficio': p.oficio or '',
            'descripcion': p.descripcion or '',
            'ciudad': p.ciudad,
            'direccion': p.direccion or '',
            'horario': p.horario or '',
            'precio': p.precio or '',
            'experiencia': p.experiencia,
            'disponible': p.disponible,
            'foto_url': _foto_perfil(p),
            'informe_url': request.build_absolute_uri(p.informe_laboral.url) if p.informe_laboral else '',
            'calificacion': p.calificacion_promedio,
            'trabajos_completados': p.trabajos_completados,
            'portafolio': fotos,
        })
    except Perfil.DoesNotExist:
        return Response({'error': 'Perfil no encontrado.'}, status=404)


@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def editar_perfil(request, correo):
    try:
        p = Perfil.objects.get(correo=correo)
    except Perfil.DoesNotExist:
        return Response({'error': 'Perfil no encontrado.'}, status=404)

    campos = ['nombre', 'negocio', 'telefono', 'oficio', 'descripcion', 'ciudad',
              'direccion', 'horario', 'precio', 'experiencia', 'disponible']
    for campo in campos:
        if campo in request.data:
            val = request.data[campo]
            if campo == 'experiencia':
                try: val = int(val)
                except: val = 0
            elif campo == 'disponible':
                val = str(val).lower() in ('true', '1', 'yes')
            setattr(p, campo, val)

    if 'foto' in request.FILES:
        p.foto = request.FILES['foto']
    elif request.data.get('quitar_foto') == 'true':
        p.foto = None

    if 'informe_laboral' in request.FILES:
        p.informe_laboral = request.FILES['informe_laboral']

    p.save()
    return Response({'mensaje': 'Perfil actualizado.', 'foto_url': _foto_perfil(p)})


@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def subir_foto_portafolio(request, correo):
    try:
        p = Perfil.objects.get(correo=correo)
    except Perfil.DoesNotExist:
        return Response({'error': 'Perfil no encontrado.'}, status=404)
    if 'foto' not in request.FILES:
        return Response({'error': 'No se envio ninguna foto.'}, status=400)
    foto = FotoPortafolio.objects.create(
        proveedor=p,
        foto=request.FILES['foto'],
        descripcion=request.data.get('descripcion', ''),
    )
    b64 = _img64(foto.foto.path)
    return Response({'mensaje': 'Foto subida.', 'url': b64, 'id': foto.id}, status=201)


@api_view(['DELETE'])
def eliminar_foto_portafolio(request, foto_id):
    try:
        foto = FotoPortafolio.objects.get(id=foto_id)
        foto.foto.delete(save=False)
        foto.delete()
        return Response({'mensaje': 'Foto eliminada.'})
    except FotoPortafolio.DoesNotExist:
        return Response({'error': 'Foto no encontrada.'}, status=404)


@api_view(['POST'])
def crear_solicitud(request):
    correo_cliente = request.data.get('correo_cliente', '')
    id_proveedor = request.data.get('id_proveedor')
    titulo = request.data.get('titulo', '')
    descripcion = request.data.get('descripcion', '')
    direccion = request.data.get('direccion', '')
    try:
        cliente = Perfil.objects.get(correo=correo_cliente, tipo='cliente')
        proveedor = Perfil.objects.get(id=id_proveedor, tipo='proveedor')
    except Perfil.DoesNotExist:
        return Response({'error': 'Cliente o proveedor no encontrado.'}, status=404)
    solicitud = Solicitud.objects.create(
        cliente=cliente, proveedor=proveedor,
        titulo=titulo, descripcion=descripcion,
        direccion=direccion, estado='pendiente',
    )
    return Response({'mensaje': 'Solicitud creada.', 'id': solicitud.id}, status=201)


@api_view(['POST'])
def responder_solicitud(request, pk):
    estado = request.data.get('estado', '')
    if estado not in ('aceptada', 'rechazada', 'completada'):
        return Response({'error': 'Estado invalido.'}, status=400)
    try:
        solicitud = Solicitud.objects.get(pk=pk)
        solicitud.estado = estado
        solicitud.save()
        return Response({'mensaje': f'Solicitud {estado}.'})
    except Solicitud.DoesNotExist:
        return Response({'error': 'Solicitud no encontrada.'}, status=404)


@api_view(['POST'])
def enviar_mensaje(request):
    try:
        remitente = Perfil.objects.get(correo=request.data.get('correo_remitente'))
        destinatario = Perfil.objects.get(correo=request.data.get('correo_destinatario'))
        Mensaje.objects.create(
            remitente=remitente,
            destinatario=destinatario,
            contenido=request.data.get('contenido', ''),
        )
        return Response({'mensaje': 'Mensaje enviado.'}, status=201)
    except Perfil.DoesNotExist:
        return Response({'error': 'Usuario no encontrado.'}, status=404)


def _formatear_tiempo(fecha):
    ahora = timezone.now()
    diff = ahora - fecha
    minutos = int(diff.total_seconds() / 60)
    if minutos < 60:
        return f'Hace {minutos} min' if minutos > 1 else 'Hace 1 min'
    horas = minutos // 60
    if horas < 24:
        return f'Hace {horas} hora{"s" if horas > 1 else ""}'
    dias = horas // 24
    if dias == 1: return 'Ayer'
    if dias < 7: return f'Hace {dias} dias'
    return fecha.strftime('%d %b %Y')


@api_view(['DELETE'])
def eliminar_mensaje(request, mensaje_id):
    try:
        mensaje = Mensaje.objects.get(id=mensaje_id)
        mensaje.delete()
        return Response({'mensaje': 'Mensaje eliminado.'})
    except Mensaje.DoesNotExist:
        return Response({'error': 'Mensaje no encontrado.'}, status=404)


@api_view(['POST'])
def toggle_favorito(request):
    try:
        correo_cliente = request.data.get('correo_cliente', '')
        id_proveedor = request.data.get('id_proveedor')
        cliente = Perfil.objects.get(correo=correo_cliente, tipo='cliente')
        proveedor = Perfil.objects.get(id=id_proveedor, tipo='proveedor')
        fav, creado = Favorito.objects.get_or_create(cliente=cliente, proveedor=proveedor)
        if not creado:
            fav.delete()
            return Response({'favorito': False, 'mensaje': 'Eliminado de favoritos.'})
        return Response({'favorito': True, 'mensaje': 'Agregado a favoritos.'}, status=201)
    except Perfil.DoesNotExist:
        return Response({'error': 'Usuario no encontrado.'}, status=404)


@api_view(['GET'])
def obtener_favorito(request):
    correo_cliente = request.query_params.get('correo_cliente', '')
    id_proveedor = request.query_params.get('id_proveedor')
    try:
        cliente = Perfil.objects.get(correo=correo_cliente)
        existe = Favorito.objects.filter(cliente=cliente, proveedor_id=id_proveedor).exists()
        return Response({'favorito': existe})
    except Perfil.DoesNotExist:
        return Response({'favorito': False})


@api_view(['POST'])
def crear_resena(request):
    correo_cliente = request.data.get('correo_cliente', '')
    id_proveedor = request.data.get('id_proveedor')
    id_solicitud = request.data.get('id_solicitud')
    estrellas = request.data.get('estrellas', 5)
    comentario = request.data.get('comentario', '')
    try:
        cliente = Perfil.objects.get(correo=correo_cliente, tipo='cliente')
        proveedor = Perfil.objects.get(id=id_proveedor, tipo='proveedor')
        solicitud = Solicitud.objects.get(id=id_solicitud, cliente=cliente, proveedor=proveedor, estado='completada')
        # Verificar que no exista ya una reseña para esta solicitud
        if Resena.objects.filter(solicitud=solicitud).exists():
            return Response({'error': 'Ya existe una reseña para este servicio.'}, status=400)
        resena = Resena.objects.create(
            cliente=cliente, proveedor=proveedor,
            solicitud=solicitud, estrellas=estrellas, comentario=comentario,
        )
        return Response({'mensaje': 'Reseña creada.', 'id': resena.id}, status=201)
    except Perfil.DoesNotExist:
        return Response({'error': 'Usuario no encontrado.'}, status=404)
    except Solicitud.DoesNotExist:
        return Response({'error': 'Servicio no encontrado o no completado.'}, status=404)


@api_view(['GET'])
def mensajes_proveedor(request):
    correo = request.query_params.get('correo', '')
    try:
        usuario = Perfil.objects.get(correo=correo)
        mensajes_qs = Mensaje.objects.filter(
            destinatario=usuario
        ).select_related('remitente').order_by('-fecha')
        mensajes = []
        for m in mensajes_qs[:20]:
            mensajes.append({
                'id': m.id,
                'remitente_correo': m.remitente.correo,
                'remitente_nombre': m.remitente.nombre,
                'foto_url': _foto_perfil(m.remitente),
                'contenido': m.contenido,
                'leido': m.leido,
                'tiempo': _formatear_tiempo(m.fecha),
            })
        return Response({'mensajes': mensajes})
    except Perfil.DoesNotExist:
        return Response({'mensajes': []})


    try:
        mensaje = Mensaje.objects.get(id=mensaje_id)
        mensaje.delete()
        return Response({'mensaje': 'Mensaje eliminado.'})
    except Mensaje.DoesNotExist:
        return Response({'error': 'Mensaje no encontrado.'}, status=404)