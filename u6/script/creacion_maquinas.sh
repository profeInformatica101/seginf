#!/bin/bash
# Script para configurar Máquinas Virtuales en VirtualBox

# 📌 Directorios
VM_DIR="$HOME/VirtualBox VMs"
ISO_DIR="$HOME/ISOs"

# 📌 Parámetros generales
RAM_FIREWALL=2048
RAM_SERVER=2048
RAM_CLIENT=2048
RAM_PCINTERNET=1024
CPUS=2

# 📌 Lista de máquinas a crear
MACHINES=(
    "Endian_UTM Linux26_64 $RAM_FIREWALL 10000 $ISO_DIR/Endian-Community-Edition.iso"
    "PCINTERNET Debian_64 $RAM_PCINTERNET 10000 $ISO_DIR/debian-12.9.0-amd64-netinst.iso"
    "Public_Web Debian_64 $RAM_SERVER 20000 $ISO_DIR/debian-12.9.0-amd64-netinst.iso"
    "PC1_LAN Ubuntu_64 $RAM_CLIENT 18000 $ISO_DIR/linux-lite-7.2-64bit.iso"
)

# 📌 Función para imprimir mensajes en color
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

# 📌 Verificar si VBoxManage está instalado
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

if [ ! -f "$ISO_DIR/linux-lite-7.2-64bit.iso" ]; then
    descargar_iso "https://fosszone.csd.auth.gr/linuxlite/isos/7.2/linux-lite-7.2-64bit.iso" "$ISO_DIR/linux-lite-7.2-64bit.iso"
fi

# 📌 Función para eliminar discos huérfanos
eliminar_disco() {
    local DISK_PATH=$1
    if VBoxManage list hdds | grep -q "$DISK_PATH"; then
        print_color "yellow" "⚠️ Eliminando disco huérfano en '$DISK_PATH'..."
        local DISK_UUID=$(VBoxManage list hdds | grep -B3 "$DISK_PATH" | grep UUID | awk '{print $2}')
        VBoxManage closemedium disk "$DISK_UUID" --delete
    fi
}

# 📌 Crear redes Host-Only si no existen
crear_red_hostonly() {
    local IP=$1
    local INTERFACE_NAME=$(VBoxManage list hostonlyifs | grep -B3 "$IP" | grep "Name" | awk '{print $2}')

    if [ -z "$INTERFACE_NAME" ]; then
        print_color "yellow" "⚠️ Creando una nueva interfaz Host-Only para la IP $IP..."
        VBoxManage hostonlyif create
        INTERFACE_NAME=$(VBoxManage list hostonlyifs | tail -n1 | awk '{print $2}')
        VBoxManage hostonlyif ipconfig "$INTERFACE_NAME" --ip "$IP" --netmask 255.255.255.0
        print_color "green" "✅ Red Host-Only creada: $INTERFACE_NAME ($IP)"
    else
        print_color "green" "✅ Red existente: $INTERFACE_NAME ($IP)"
    fi
}

# 📌 Crear las redes necesarias
crear_red_hostonly "vboxnet0" "192.168.1.1"  # GREEN (LAN)
crear_red_hostonly "vboxnet1" "192.168.2.1"  # ORANGE (DMZ)
crear_red_hostonly "vboxnet2" "192.168.3.1"  # BLUE (WiFi)
crear_red_hostonly "vboxnet3" "192.168.4.1"  # WAN INTERNA (opcional)




# 📌 Función para crear una máquina virtual
crear_vm() {
    local NAME=$1
    local OS_TYPE=$2
    local RAM=$3
    local DISK_SIZE=$4
    local ISO=$5
    local VM_PATH="$VM_DIR/$NAME"
    local VDI_PATH="$VM_PATH/$NAME.vdi"

    # Verificar si la máquina ya existe
    if VBoxManage list vms | grep -q "\"$NAME\""; then
        print_color "yellow" "⚠️ La máquina virtual '$NAME' ya existe. Saltando..."
        return
    fi

    print_color "green" "🛠️ Creando máquina virtual: $NAME"

    # Crear la VM
    VBoxManage createvm --name "$NAME" --ostype "$OS_TYPE" --register

    # Configurar memoria y CPUs
    VBoxManage modifyvm "$NAME" --memory "$RAM" --cpus "$CPUS"

    # Asegurar que la carpeta de la VM existe
    mkdir -p "$VM_PATH"

    # Eliminar disco si hay conflicto
    eliminar_disco "$VDI_PATH"

    # Crear disco virtual si no existe
    if [ ! -f "$VDI_PATH" ]; then
        VBoxManage createmedium disk --filename "$VDI_PATH" --size "$DISK_SIZE" --format VDI
    else
        print_color "yellow" "⚠️ El disco '$VDI_PATH' ya existe. Usando el existente."
    fi

    # Agregar controlador SATA y adjuntar el disco
    VBoxManage storagectl "$NAME" --name "SATA Controller" --add sata --controller IntelAHCI
    VBoxManage storageattach "$NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VDI_PATH"

    # Adjuntar ISO si existe
    if [ -f "$ISO" ]; then
        VBoxManage storageattach "$NAME" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium "$ISO"
    else
        print_color "red" "❌ ISO no encontrada: $ISO"
    fi

    print_color "green" "✅ Máquina virtual '$NAME' creada correctamente."
}

# 📌 Configurar la red de cada máquina virtual
# 📌 Configurar la red de cada máquina virtual
configurar_redes() {
    print_color "yellow" "🔧 Configurando redes en VirtualBox..."

# 🛡️ Configuración de Endian UTM con las interfaces correctas
VBoxManage modifyvm "$VM_NAME" --nic1 hostonly --hostonlyadapter1 "vboxnet0" \  # GREEN (LAN)
                               --nic2 hostonly --hostonlyadapter2 "vboxnet1" \  # ORANGE (DMZ)
                               --nic3 hostonly --hostonlyadapter3 "vboxnet2" \  # BLUE (WAN INTERNA)
                               --nic4 nat                                       # NAT (salida a Internet)


# 🔌 Habilitar modo promiscuo en Endian para permitir tráfico de red en LAN, DMZ y WAN INTERNA
for i in 1 2 3; do
    VBoxManage modifyvm "$VM_NAME" --nicpromisc$i allow-all
done

# 💻 PC1_LAN - Conectado a la LAN (GREEN)
VBoxManage modifyvm "$PC1_LAN" --nic1 hostonly --hostonlyadapter1 "vboxnet0"

# 🌐 Public_Web - Conectado a la DMZ (ORANGE)
VBoxManage modifyvm "$PUBLIC_WEB" --nic1 hostonly --hostonlyadapter1 "vboxnet1"

# 🛜 PCINTERNET - 🔄 Configurado en NAT para acceso directo a Internet
VBoxManage modifyvm "$PCINTERNET" --nic1 nat

    print_color "green" "✅ Redes configuradas correctamente."
}


# 📌 Crear todas las máquinas virtuales
for MACHINE in "${MACHINES[@]}"; do
    IFS=' ' read -r NAME OS_TYPE RAM DISK_SIZE ISO <<< "$MACHINE"
    crear_vm "$NAME" "$OS_TYPE" "$RAM" "$DISK_SIZE" "$ISO"
done

# 📌 Verificar si las interfaces están listas antes de asignarlas
for i in {0..2}; do
    while ! VBoxManage list hostonlyifs | grep -q "vboxnet$i"; do
        print_color "yellow" "⏳ Esperando que vboxnet$i esté disponible..."
        sleep 2
    done
done

configurar_redes


# 📌 Mensaje final
print_color "green" "✅ Todas las máquinas virtuales han sido creadas correctamente en VirtualBox."
print_color "yellow" "🔄 Ahora instala los sistemas operativos en cada máquina."
