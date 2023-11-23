#!/bin/bash
# Script para obter o endereço IP público

# Função para validar o endereço IP
function validar_ip() {
    local ip=$1
    local stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi

    return $stat
}

# Função para verificar se o DNS está funcionando
function verificar_dns() {
    local dns=$(dig +short www.google.com)
    if [ -z "$dns" ]; then
        echo "O DNS não está funcionando corretamente."
        exit 1
    else
        echo "O DNS está funcionando corretamente."
    fi
}

# Função para obter o servidor DNS
function obter_dns() {
    local dns1=$(grep -i '^nameserver' /etc/resolv.conf | cut -d ' ' -f2)
    local dns2=$(ip r|grep default|cut -d' ' -f3)
    if [ -z "$dns1" ] && [ -z "$dns2" ]; then
        echo "Não foi possível obter o servidor DNS."
        exit 1
    else
        echo "O servidor DNS obtido de /etc/resolv.conf é: $dns1"
        echo "O servidor DNS obtido do gateway padrão é: $dns2"
    fi
}

# Função para obter o endereço IP do gateway padrão
function obter_gateway() {
    local gateway=$(ip r|grep default|cut -d' ' -f3)
    if [ -z "$gateway" ]; then
        echo "Não foi possível obter o endereço IP do gateway padrão."
        exit 1
    else
        echo "O endereço IP do gateway padrão é: $gateway"
    fi
}

# Função para obter os endereços IP válidos do computador
function obter_ips_locais() {
    local ips=$(hostname -I)
    if [ -z "$ips" ]; then
        echo "Não foi possível obter os endereços IP locais."
        exit 1
    else
        echo "Os endereços IP locais são: $ips"
    fi
}

# Função para obter o endereço IP público
function obter_ip_publico() {
    # Lista de sites para consultar o endereço IP público
    sites=("ifconfig.me" "icanhazip.com" "ipecho.net/plain")

    for site in "${sites[@]}"; do
      public_ip=$(curl -s "$site")
      
      # Se o comando curl foi bem-sucedido e a variável public_ip não está vazia
      if [ $? -eq 0 ] && [ ! -z "$public_ip" ]; then
        # Validar o endereço IP
        if validar_ip "$public_ip"; then
            echo "Seu endereço IP público é: $public_ip"
            # Verificar se o DNS está funcionando
            verificar_dns
            # Obter o servidor DNS
            obter_dns
            # Obter o endereço IP do gateway padrão
            obter_gateway
            return 0
        fi
      fi
    done

    echo "Não foi possível obter o endereço IP público."
    return 1
}

# Obter os endereços IP válidos do computador
obter_ips_locais

# Obter o endereço IP público
obter_ip_publico
