from rest_framework import serializers
from .models import Perfil, Solicitud, Resena, Favorito, Mensaje


class PerfilSerializer(serializers.ModelSerializer):
    class Meta:
        model = Perfil
        fields = [
            'id', 'tipo', 'nombre', 'correo', 'contrasena',
            'telefono', 'cedula', 'oficio', 'descripcion',
            'foto_url', 'ciudad', 'horario', 'precio',
            'experiencia', 'disponible', 'fecha_registro',
        ]
        extra_kwargs = {
            'contrasena': {'write_only': True},
            'fecha_registro': {'read_only': True},
        }


class SolicitudSerializer(serializers.ModelSerializer):
    cliente_nombre = serializers.CharField(source='cliente.nombre', read_only=True)
    proveedor_nombre = serializers.CharField(source='proveedor.nombre', read_only=True)

    class Meta:
        model = Solicitud
        fields = [
            'id', 'cliente', 'cliente_nombre', 'proveedor', 'proveedor_nombre',
            'titulo', 'descripcion', 'direccion', 'estado', 'precio', 'fecha',
        ]
        extra_kwargs = {'fecha': {'read_only': True}}


class ResenaSerializer(serializers.ModelSerializer):
    cliente_nombre = serializers.CharField(source='cliente.nombre', read_only=True)
    proveedor_nombre = serializers.CharField(source='proveedor.nombre', read_only=True)

    class Meta:
        model = Resena
        fields = [
            'id', 'proveedor', 'proveedor_nombre', 'cliente', 'cliente_nombre',
            'solicitud', 'estrellas', 'comentario', 'fecha',
        ]
        extra_kwargs = {'fecha': {'read_only': True}}


class FavoritoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Favorito
        fields = ['id', 'cliente', 'proveedor', 'fecha']
        extra_kwargs = {'fecha': {'read_only': True}}


class MensajeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Mensaje
        fields = ['id', 'remitente', 'destinatario', 'contenido', 'leido', 'fecha']
        extra_kwargs = {'fecha': {'read_only': True}}