#!/bin/bash

# Verificar versão do kernel
required_kernel="5.15.0"
current_kernel=$(uname -r | cut -d'-' -f1)
dir="/root/hamster_dx/"

# Verificar se a distribuição é Ubuntu 20.04
os_version=$(grep '^VERSION_ID' /etc/os-release | cut -d'=' -f2 | tr -d '"')
if [ "$os_version" != "20.04" ]; then
  echo "Este script requer Ubuntu 20.04. Você está usando o Ubuntu $os_version."
  exit 1
fi

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute este script como root."
  exit 1
fi

# Função para exibir mensagem e reiniciar
reboot_msg() {
    echo ""
    echo "Seu Linux será reiniciado para a atualização do kernel."
    echo "Por favor, reinicie o processo de instalação após o reinício."
    read -p "Pressione Enter para reiniciar..."
    reboot
}

# Validar e instalar os pacotes necessários
check_package() {
    dpkg -l | grep -q "^ii  $1 " && echo "$1 já está instalado." || {
        echo "$1 não está instalado. Instalando..."
        apt-get install -y "$1" || { echo "Falha ao instalar $1"; exit 1; }
    }
}

# Atualizar pacotes e corrigir dependências
kernel_update() {
    # Instalação de pacotes necessários
    apt-get update  && apt-get --fix-broken install -y

    # Comparar versões do kernel
    if [ "$(printf '%s\n' "$required_kernel" "$current_kernel" | sort -V | head -n1)" != "$required_kernel" ]; then
        echo "Kernel atual ($current_kernel) é inferior a $required_kernel. Atualizando kernel..."
        apt install --install-recommends linux-generic-hwe-20.04 -y
        reboot_msg
    else
        echo "Kernel atual ($current_kernel) é igual ou superior a $required_kernel. Nenhuma atualização necessária."
    fi
    apt_install
}

# Instalar pacotes necessários
apt_install() {
    check_package "linux-headers-$(uname -r)"
    check_package "build-essential"
    check_package "wget"
    check_package "unzip"

    driver_download
}

# Download dos drivers do leitor biométrico
driver_download() {
    if [ -f /usr/include/linux/VenusDrv.h ]; then
        echo "Driver do leitor biométrico já está instalado."
        echo "Caso deseje reinstalar, execute novamente o script com o parametro remove."
        echo "Exemplo: ./install_hamster_dx.sh remove"
        exit 1 
        #/lib/modules/5.15.0-126-generic/kernel/drivers/usb/misc/VenusDrv.ko
        #/usr/include/linux/VenusDrv.h
        #/etc/udev/rules.d/99-Nitgen-VenusDrv.rules
    fi

    if [ ! -d "$dir" ]; then
        mkdir -p $dir
    fi
    
    # Wget para baixar os arquivos
    # download=( "VenusDrv-v1.0.4-5.1.zip" "eNBSP-1.8.5-1.tar.gz" "libNBioBSP_x64.so" )
    download=( "hamster_ubuntu20.tar.gz" )
    for file in "${download[@]}"; do
        echo "Baixando $file..."
        wget --timestamping "ftp://util:util@ftp.sgsistemas.com.br/util/leitor_biometrico/Hamster-DX/$file" -O "$dir/$file"
    done
    cd $dir
    tar -vzxf $dir/hamster_ubuntu20.tar.gz
    tar -vzxf $dir/eNBSP-1.8.5-1.tar.gz
    unzip $dir/VenusDrv-v1.0.4-5.1.zip 
    install_leitor
}

install_leitor() {
    # Ajustar permissões dos arquivos
    chmod 777 libNBioBSP_x64.so
    cd VenusDrv-v1.0.4-5.1/
    cp build-ubuntu20.04-x86_64bit/VenusLib.so .
    chmod +x CreateModule
    chmod +x *.{so,sh}
    ./install.sh

    # Configuração do driver e licença do leitor biométrico
    cd $dir/eNBSP-1.8.5-1/
    chmod -R 777 .
./NBioBSP_Signer <<"EOF"
010701-F6B95C1975E63701-22627000F00163FD
EOF

    if [ ! -f /usr/lib/libNBioBSP_x64.so ]; then
      cp $dir/libNBioBSP_x64.so /usr/lib/
    fi

    echo "Configuração e instalação concluídas com sucesso!"
}

remove_leitor() {
    if [ ! -f /usr/include/linux/VenusDrv.h ]; then
        echo "Driver do leitor biométrico nao está instalado."
        echo "Caso deseje instalar, execute novamente o script com o parametro install."
        echo "Exemplo: ./install_hamster_dx.sh install"
        exit 1 
      
    fi
    cd $dir/eNBSP-1.8.5-1
    ./uninstall.sh
    cd $dir/VenusDrv-v1.0.4-5.1
    ./uninstall.sh
    rm -f /usr/lib/libNBioBSP_x64.so
    echo "Driver do leitor biométrico removido  com sucesso!"
}

clear

opcao=$1

case $opcao in
    install)
        kernel_update
        ;;
    remove)
        remove_leitor
        ;;
    *)
        echo "Escolha uma opção para executar:"
        echo "install_hamster_dx.sh install - Instalar o driver do leitor biométrico"
        echo "install_hamster_dx.sh remove - Remover o driver do leitor biométrico"
        echo "install_hamster_dx.sh - Exibir esta mensagem"
        ;;
esac