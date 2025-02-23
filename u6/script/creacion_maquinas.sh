#!/bin/bash
# Script para configurar Máquinas Virtuales en VirtualBox
# Con verificación y reintentos de descarga de ISOs hasta que sean válidos.

# 📌 Directorios
VM_DIR="$HOME/VirtualBox VMs"
ISO_DIR="$HOME/ISOs"

# 📌 Parámetros generales
RAM_FIREWALL=2048
RAM_SERVER=2048
RAM_CLIENT=2048
RAM_PCINTERNET=1024
RAM_SECURITY=2048
CPUS=2

# 📌 Lista de máquinas a crear
# - Endian_UTM: Firewall
# - PCINTERNET: ParrotOS_64 (para Red Team)
# - Public_Web: Debian
# - PC1_LAN: Linux Lite
# - Security_Onion: Solución de monitoreo
MACHINES=(
    "Endian_UTM Linux26_64 $RAM_FIREWALL 10000 $ISO_DIR/Endian-Community-Edition.iso"
    "PCINTERNET ParrotOS_64 $RAM_PCINTERNET 10000 $ISO_DIR/parrot-security.iso"
    "Public_Web Debian_64 $RAM_SERVER 20000 $ISO_DIR/debian-12.9.0-amd64-netinst.iso"
    "PC1_LAN Ubuntu_64 $RAM_CLIENT 18000 $ISO_DIR/linux-lite-7.2-64bit.iso"
    "Security_Onion Ubuntu_64 $RAM_SECURITY 100000 $ISO_DIR/securityonion.iso"
)

# 📌 URLs de descarga
ENDIAN_URL="https://sourceforge.net/projects/efw/files/latest/download"
DEBIAN_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.9.0-amd64-netinst.iso"
LINUX_LITE_URL="https://fosszone.csd.auth.gr/linuxlite/isos/7.2/linux-lite-7.2-64bit.iso"
# URL para Parrot Security 6.3.2 (64-bit)
PARROT_URL="https://deb.parrot.sh/parrot/iso/6.3.2/Parrot-security-6.3.2_amd64.iso"
# URL para Security Onion (versión 2.4.120, fecha 20250212)
SECURITY_ONION_URL="https://download.securityonion.net/file/securityonion/securityonion-2.4.120-20250212.iso"

# 📌 Función para imprimir mensajes en color
print_color() {
    local color=$1
    local mensaje=$2
    case $color in
        red)    echo -e "\033[31m$mensaje\033[0m" ;;
        green)  echo -e "\033[32m$mensaje\033[0m" ;;
        yellow) echo -e "\033[33m$mensaje\033[0m" ;;
        *)      echo "$mensaje" ;;
    esac
}

# 📌 Función para verificar que un archivo sea un ISO válido (ISO 9660)
check_iso_valid() {
    local iso_file="$1"
    if [ ! -f "$iso_file" ]; then
        return 1
    fi
    local file_output
    file_output=$(file "$iso_file")
    if echo "$file_output" | grep -qi "ISO 9660"; then
        return 0
    else
        return 1
    fi
}

# 📌 Función para descargar ISOs con reintentos hasta que el archivo sea válido
descargar_iso() {
    local url=$1
    local output=$2
    while true; do
        print_color "yellow" "🔽 Descargando $output..."
        # Para Parrot, usamos --no-check-certificate para evitar problemas de certificado
        if [[ "$url" == *"parrot"* ]]; then
            wget --no-check-certificate -O "$output" "$url"
        else
            wget -O "$output" "$url"
        fi
        # Verificamos que el archivo descargado sea un ISO válido
        if check_iso_valid "$output"; then
            print_color "green" "✅ ISO descargado y verificado: $output"
            break
        else
            print_color "red" "❌ El archivo $output no es un ISO válido. Reintentando en 10 segundos..."
            rm -f "$output"
            sleep 10
        fi
    done
}

# 📌 Verificar si VBoxManage está instalado
if ! command -v VBoxManage &> /dev/null; then
    print_color "red" "❌ Error: VBoxManage no está instalado. Instala VirtualBox primero."
    exit 1
fi

# Crear carpetas necesarias
mkdir -p "$VM_DIR"
mkdir -p "$ISO_DIR"

# 📌 Descargar ISOs (se reintentará hasta obtener un archivo válido)
if [ ! -f "$ISO_DIR/Endian-Community-Edition.iso" ]; then
    descargar_iso "$ENDIAN_URL" "$ISO_DIR/Endian-Community-Edition.iso"
fi

if [ ! -f "$ISO_DIR/debian-12.9.0-amd64-netinst.iso" ]; then
    descargar_iso "$DEBIAN_URL" "$ISO_DIR/debian-12.9.0-amd64-netinst.iso"
fi

if [ ! -f "$ISO_DIR/linux-lite-7.2-64bit.iso" ]; then
    descargar_iso "$LINUX_LITE_URL" "$ISO_DIR/linux-lite-7.2-64bit.iso"
fi

if [ ! -f "$ISO_DIR/parrot-security.iso" ]; then
    descargar_iso "$PARROT_URL" "$ISO_DIR/parrot-security.iso"
fi

if [ ! -f "$ISO_DIR/securityonion.iso" ]; then
    descargar_iso "$SECURITY_ONION_URL" "$ISO_DIR/securityonion.iso"
fi

# 📌 Función para eliminar discos huérfanos
eliminar_disco() {
    local DISK_PATH=$1
    if VBoxManage list hdds | grep -q "$DISK_PATH"; then
        print_color "yellow" "⚠️ Eliminando disco huérfano en '$DISK_PATH'..."
        local DISK_UUID
        DISK_UUID=$(VBoxManage list hdds | grep -B3 "$DISK_PATH" | grep UUID | awk '{print $2}')
        VBoxManage closemedium disk "$DISK_UUID" --delete
    fi
}

# 📌 Función para crear redes Host-Only si no existen
crear_red_hostonly() {
    local IP=$1
    local INTERFACE_NAME
    INTERFACE_NAME=$(VBoxManage list hostonlyifs | grep -B3 "$IP" | grep "Name" | awk '{print $2}')
    if [ -z "$INTERFACE_NAME" ]; then
        print_color "yellow" "⚠️ Creando una nueva interfaz Host-Only para la IP $IP..."
        VBoxManage hostonlyif create
        local NEW_NAME
        NEW_NAME=$(VBoxManage list hostonlyifs | tail -n1 | awk '{print $2}')
        VBoxManage hostonlyif ipconfig "$NEW_NAME" --ip "$IP" --netmask 255.255.255.0
        print_color "green" "✅ Red Host-Only creada: $NEW_NAME ($IP)"
    else
        print_color "green" "✅ Red existente: $INTERFACE_NAME ($IP)"
    fi
}

# 📌 Crear las redes necesarias
crear_red_hostonly "192.168.1.1"  # GREEN (LAN)
crear_red_hostonly "192.168.2.1"  # ORANGE (DMZ)
crear_red_hostonly "192.168.3.1"  # BLUE (WAN INTERNA)

# 📌 Función para crear una máquina virtual
crear_vm() {
    local NAME=$1
    local OS_TYPE=$2
    local RAM=$3
    local DISK_SIZE=$4
    local ISO=$5
    local VM_PATH="$VM_DIR/$NAME"
    local VDI_PATH="$VM_PATH/$NAME.vdi"

    if VBoxManage list vms | grep -q "\"$NAME\""; then
        print_color "yellow" "⚠️ La máquina virtual '$NAME' ya existe. Saltando..."
        return
    fi

    print_color "green" "🛠️ Creando máquina virtual: $NAME"
    VBoxManage createvm --name "$NAME" --ostype "$OS_TYPE" --register
    VBoxManage modifyvm "$NAME" --memory "$RAM" --cpus "$CPUS"
    mkdir -p "$VM_PATH"
    eliminar_disco "$VDI_PATH"

    if [ ! -f "$VDI_PATH" ]; then
        VBoxManage createmedium disk --filename "$VDI_PATH" --size "$DISK_SIZE" --format VDI
    else
        print_color "yellow" "⚠️ El disco '$VDI_PATH' ya existe. Usando el existente."
    fi

    VBoxManage storagectl "$NAME" --name "SATA Controller" --add sata --controller IntelAHCI
    VBoxManage storageattach "$NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VDI_PATH"

    if [ -f "$ISO" ]; then
        if check_iso_valid "$ISO"; then
            VBoxManage storageattach "$NAME" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium "$ISO"
        else
            print_color "red" "❌ El archivo ISO $ISO no es válido. Instálalo manualmente."
        fi
    else
        print_color "red" "❌ ISO no encontrada: $ISO"
    fi

    print_color "green" "✅ Máquina virtual '$NAME' creada correctamente."
}

# 📌 Función para configurar redes en cada VM
configurar_redes() {
    print_color "yellow" "🔧 Configurando redes en VirtualBox..."

    VBoxManage modifyvm "Endian_UTM" --nic1 hostonly --hostonlyadapter1 "vboxnet0"
    VBoxManage modifyvm "Endian_UTM" --nic2 hostonly --hostonlyadapter2 "vboxnet1"
    VBoxManage modifyvm "Endian_UTM" --nic3 hostonly --hostonlyadapter3 "vboxnet2"
    VBoxManage modifyvm "Endian_UTM" --nic4 nat
    for i in 1 2 3; do
        VBoxManage modifyvm "Endian_UTM" --nicpromisc$i allow-all
    done

    VBoxManage modifyvm "PC1_LAN" --nic1 hostonly --hostonlyadapter1 "vboxnet0"
    VBoxManage modifyvm "Public_Web" --nic1 hostonly --hostonlyadapter1 "vboxnet1"
    VBoxManage modifyvm "PCINTERNET" --nic1 nat
    VBoxManage modifyvm "Security_Onion" --nic1 nat

    print_color "green" "✅ Redes configuradas correctamente."
}

# 📌 Crear todas las máquinas virtuales
for MACHINE in "${MACHINES[@]}"; do
    IFS=' ' read -r NAME OS_TYPE RAM DISK_SIZE ISO <<< "$MACHINE"
    crear_vm "$NAME" "$OS_TYPE" "$RAM" "$DISK_SIZE" "$ISO"
done

# 📌 Esperar que las interfaces Host-Only estén disponibles
for i in {0..2}; do
    while ! VBoxManage list hostonlyifs | grep -q "vboxnet$i"; do
        print_color "yellow" "⏳ Esperando que vboxnet$i esté disponible..."
        sleep 2
    done
done

configurar_redes

print_color "green" "✅ Todas las máquinas virtuales han sido creadas correctamente en VirtualBox."
print_color "yellow" "🔄 Ahora instala los sistemas operativos en cada máquina."
