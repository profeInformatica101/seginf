#!/bin/bash

# Definir direcciones a comprobar
ENDIAN_PUBLIC_IP="10.0.5.15"  # IP WAN de Endian
DMZ_IP="192.168.2.100"
PUBLIC_WEB="10.0.5.15"  # IP pública o dominio del servicio web
LAN_TEST_IP="192.168.1.1"

# Prueba de conectividad con Endian
echo "[+] Probando conectividad con la IP pública de Endian..."
ping -c 4 $ENDIAN_PUBLIC_IP

# Verificar acceso a la DMZ mediante NAT
echo "[+] Probando acceso a la DMZ ($DMZ_IP) desde WAN..."
ping -c 4 $DMZ_IP

# Probar acceso a la página web pública
echo "[+] Probando acceso a la página web en $PUBLIC_WEB..."
curl -I http://$PUBLIC_WEB

# Validar que la LAN no es accesible desde la WAN
echo "[+] Comprobando que la LAN no es accesible desde la WAN..."
ping -c 4 $LAN_TEST_IP && echo "[!] Advertencia: Acceso a LAN permitido" || echo "[✔] Acceso a LAN bloqueado (correcto)"

echo "[+] Pruebas finalizadas." 