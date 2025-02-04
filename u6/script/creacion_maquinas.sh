#!/bin/bash
# Script para configurar Máquinas Virtuales en VirtualBox para Endian

# Directorios
VM_DIR="$HOME/VirtualBox VMs"
ISO_DIR="$HOME/ISOs"

# Parámetros de las máquinas virtuales
RAM_FIREWALL=2048
RAM_SERVER=2048
RAM_CLIENT=2048
RAM_PCINTERNET=1024
RAM_MINT=2048
CPUS=2
# Función para mostrar mensajes en colores
print_color() {
    local color=$1
    local mensaje=$2
    case $color in
        red) echo -e "\033[31m$mensaje\033[0m" ;;
        green) echo -e "\033[32m$mensaje\033[0m" ;;
        yellow) echo -e "\033[33m$mensaje\033[0m" ;;
        *) echo "$mensaje" ;;
    esac
}

# Función para descargar ISOs con manejo de errores
descargar_iso() {
    local url=$1
    local output=$2
    echo "🔽 Descargando $output..."
    if ! wget -O "$output" "$url"; then
        print_color "red" "❌ Error: No se pudo descargar $output desde $url."
        exit 1
    fi
}

# Función para configurar adaptadores de red
configurar_adaptadores_red() {
    for i in {0..2}; do
        if ! VBoxManage list hostonlyifs | grep -q "vboxnet$i"; then
            echo "➕ Creando adaptador vboxnet$i..."
            VBoxManage hostonlyif create
            VBoxManage hostonlyif ipconfig "vboxnet$i" --ip "192.168.$((i+1)).1"
        else
            echo "✅ Adaptador vboxnet$i ya existe."
        fi
    done
}

# Función para crear una máquina virtual
crear_vm() {
    local NAME=$1
    local OS_TYPE=$2
    local RAM=$3
    local DISK_SIZE=$4
    local ISO=$5
    local VM_PATH="$VM_DIR/$NAME"

    if VBoxManage list vms | grep -q "\"$NAME\""; then
        print_color "yellow" "⚠️ La máquina virtual '$NAME' ya existe. Saltando..."
        return
    fi

    echo "🛠️ Creando máquina virtual: $NAME"

    # Crear la VM
    VBoxManage createvm --name "$NAME" --ostype "$OS_TYPE" --register

    # Configurar memoria y CPUs
    VBoxManage modifyvm "$NAME" --memory "$RAM" --cpus "$CPUS"

    # Crear disco virtual
    VBoxManage createhd --filename "$VM_PATH/$NAME.vdi" --size "$DISK_SIZE"

    # Agregar controlador SATA y adjuntar el disco
    VBoxManage storagectl "$NAME" --name "SATA Controller" --add sata --controller IntelAHCI
    VBoxManage storageattach "$NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VM_PATH/$NAME.vdi"

    # Adjuntar ISO
    VBoxManage storageattach "$NAME" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium "$ISO"

    print_color "green" "✅ Máquina virtual '$NAME' creada correctamente."
}

# Verificar si VBoxManage está instalado
if ! command -v VBoxManage &> /dev/null; then
    print_color "red" "❌ Error: VBoxManage no está instalado. Instala VirtualBox primero."
    exit 1
fi

# Crear carpetas necesarias
mkdir -p "$VM_DIR"
mkdir -p "$ISO_DIR"

# Descargar ISOs si no existen
if [ ! -f "$ISO_DIR/Endian-Community-Edition.iso" ]; then
    descargar_iso "https://sourceforge.net/projects/efw/files/latest/download" "$ISO_DIR/Endian-Community-Edition.iso"
fi

if [ ! -f "$ISO_DIR/debian-12.9.0-amd64-netinst.iso" ]; then
    descargar_iso "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.9.0-amd64-netinst.iso" "$ISO_DIR/debian-12.9.0-amd64-netinst.iso"
fi

if [ ! -f "$ISO_DIR/linux-lite-6.4-64bit.iso" ]; then
    descargar_iso "https://fosszone.csd.auth.gr/linuxlite/isos/7.2/linux-lite-7.2-64bit.iso" "$ISO_DIR/linux-lite-6.4-64bit.iso"
fi

# Configurar adaptadores de red
configurar_adaptadores_red

# Crear máquinas virtuales
crear_vm "Endian_UTM" "Linux26_64" "$RAM_FIREWALL" 10000 "$ISO_DIR/Endian-Community-Edition.iso"
VBoxManage modifyvm "Endian_UTM" --nic1 nat --nic2 hostonly --hostonlyadapter2 vboxnet0 --nic3 hostonly --hostonlyadapter3 vboxnet1 --nic4 hostonly --hostonlyadapter4 vboxnet2

crear_vm "PCINTERNET" "Debian_64" "$RAM_PCINTERNET" 10000 "$ISO_DIR/debian-12.9.0-amd64-netinst.iso"
VBoxManage modifyvm "PCINTERNET" --nic1 hostonly --hostonlyadapter1 vboxnet2

crear_vm "Public_Web" "Debian_64" "$RAM_SERVER" 20000 "$ISO_DIR/debian-12.9.0-amd64-netinst.iso"
VBoxManage modifyvm "Public_Web" --nic1 hostonly --hostonlyadapter1 vboxnet1

crear_vm "PC1_LAN" "LinuxLite_64" "$RAM_CLIENT" 15000 "$ISO_DIR/linux-lite-6.4-64bit.iso"
VBoxManage modifyvm "PC1_LAN" --nic1 hostonly --hostonlyadapter1 vboxnet0

# Mensaje final
print_color "green" "✅ Todas las máquinas virtuales han sido creadas correctamente en VirtualBox."
print_color "yellow" "🔄 Ahora instala los sistemas operativos en cada máquina."