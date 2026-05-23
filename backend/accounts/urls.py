from django.urls import path
from . import views

urlpatterns = [
    # Auth
    path('registro/', views.registrar_usuario),
    path('login/', views.iniciar_sesion),

    # Busqueda
    path('buscar/', views.buscar_proveedores),
    path('categorias/', views.categorias_con_conteo),
    path('estadisticas/', views.estadisticas),

    # Dashboard
    path('dashboard/', views.dashboard),

    # Perfil
    path('perfil/<str:correo>/', views.obtener_perfil),
    path('perfil/<str:correo>/editar/', views.editar_perfil),
    path('perfil/<str:correo>/portafolio/', views.subir_foto_portafolio),
    path('portafolio/<int:foto_id>/eliminar/', views.eliminar_foto_portafolio),

    # Solicitudes
    path('solicitud/', views.crear_solicitud),
    path('solicitud/crear/', views.crear_solicitud),
    path('solicitud/<int:pk>/responder/', views.responder_solicitud),

    # Mensajes
    path('mensaje/', views.enviar_mensaje),
    path('mensaje/<int:mensaje_id>/eliminar/', views.eliminar_mensaje),
    path('mensajes/proveedor/', views.mensajes_proveedor),

    # Favoritos
    path('favorito/', views.obtener_favorito),
    path('favorito/toggle/', views.toggle_favorito),

    # Reseñas
    path('resena/', views.crear_resena),
]