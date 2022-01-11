#!/bin/bash
#===================================================================
# Parametros:
#===================================================================
ipt='iptables'
# => lan(local)
ethLan='eth0'
ipLan='192.168.3.169'
net='192.168.0.0/22'
#====
# True/False
limparRegras=True
# Se limpar as regras e tiver docker instalado sera necessario reiniciar o docker.
dockerReset=True
#====
portSsh='8899'
portMysql='3306'
sshLimiteCon='20'
acessoFull(10.0.0.1)
acessoSSH=(172.16.0.1)
acessoMySQL=(172.16.0.1)
acessoTcpExt=(21 23 53 80 110 123 443 465 995 10050)
acessoUdpExt=(53)
ipsBloqueados=
#===================================================================
clear
echo -e "\e[31m-> INICIANDO COFIGURACAO DO IPTABLES <-\e[0m"
#===================================================================
if [ $limparRegras == True ]; then
    echo -e "\e[96m-> LIMPANDO AS REGRAS DO IPTABLES ------------------------\e[92m OK \e[0m"
    $ipt -F
    $ipt -X
    $ipt -Z
fi
#====================================================================
echo -e "\e[96m-> BLOQUEANDO TODAS AS REGRAS DEFAULT --------------------\e[92m OK \e[0m"
$ipt -P INPUT DROP
$ipt -P OUTPUT ACCEPT
$ipt -P FORWARD DROP
#====================================================================
echo -e "\e[96m-> CAREGANDO MODULOS -------------------------------------\e[92m OK \e[0m"
modprobe iptable_nat
modprobe iptable_filter
modprobe iptable_mangle
modprobe iptable_raw
modprobe ip_tables
modprobe ip_conntrack
modprobe ipt_LOG
modprobe ipt_MASQUERADE
modprobe ipt_limit
modprobe ipt_state
#====================================================================
echo -e "\e[96m-> BLOQUEIO DE REDE (SEGURANCA) --------------------------\e[92m OK \e[0m"
$ipt -A FORWARD -p tcp --syn -m limit --limit 2/s -j ACCEPT
$ipt -A INPUT -p tcp --dport 80 -m limit --limit 100/minute --limit-burst 200 -j ACCEPT
echo 1 >/proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
echo 1 >/proc/sys/net/ipv4/conf/default/rp_filter
#
$ipt -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
$ipt -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
$ipt -A INPUT -i $ethLan -s $ipLan -j DROP
#====================================================================
echo -e "\e[96m-> ACEITAR PING ------------------------------------------\e[92m OK \e[0m"
$ipt -A INPUT -p icmp -j ACCEPT
#====================================================================
echo -e "\e[96m-> CONEXAO REDE LO ---------------------------------------\e[92m OK \e[0m"
$ipt -A INPUT  -i lo -j ACCEPT
#====================================================================
echo -e "\e[96m-> LIBERAR PORTAS ACESSO EXTERNO TCP----------------------\e[92m OK \e[0m"
for a in "${acessoTcpExt[@]}"; do
    $ipt -A INPUT -i $ethLan -p tcp --dport $a -j ACCEPT
    echo -e "Acesso a porta \e[93m$a\e[0m liberada"
done
#====================================================================
echo -e "\e[96m-> LIBERAR PORTAS ACESSO EXTERNO UDP----------------------\e[92m OK \e[0m"
for a in "${acessoUdpExt[@]}"; do
    $ipt -A INPUT -i $ethLan -p udp --dport $a -j ACCEPT
    echo -e "Acesso a porta \e[93m$a\e[0m liberada"
done
#====================================================================
if [ ! -z $acessoMySQL ]; then
    echo -e "\e[96m-> ACESSO AO BANCO MYSQL ---------------------------------\e[92m OK \e[0m"
    for a in "${acessoMySQL[@]}"; do
       $ipt -A INPUT  -p tcp -s $a --dport $portMysql -j ACCEPT
       echo -e "Acesso pelo ip \e[93m$a\e[0m liberado"
    done
fi
#====================================================================
if [ ! -z $acessoSSH ];then
    echo -e "\e[96m-> ACESSO AO SSH -----------------------------------------\e[92m OK \e[0m"
    for a in "${acessoSSH[@]}";  do
        $ipt -A INPUT  -p tcp -s $a --dport $portSsh -j ACCEPT
        echo -e "Acesso pelo ip \e[93m$a\e[0m liberado"
    done
fi
#====================================================================
echo -e "\e[96m-> ACESSO FULL -------------------------------------------\e[92m OK \e[0m"
for a in "${acessoFull[@]}";  do
    $ipt -A INPUT -p tcp -s $a -j ACCEPT
    $ipt -A INPUT -p udp -s $a -j ACCEPT
    echo -e "Acesso pelo ip \e[93m$a\e[0m liberado"
done
#====================================================================
echo -e "\e[96m-> ESTABILIZA CONEXOES ABERTAS ---------------------------\e[92m OK \e[0m"
$ipt -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 
#====================================================================
echo -e "\e[96m-> LIMITANDO NUMERO DE CONEXAO ---------------------------\e[92m OK \e[0m"
$ipt -A INPUT -p tcp --syn --dport $portSsh -m connlimit --connlimit-above $sshLimiteCon -j REJECT
echo -e "Conexoes simultaneas de um mesmo ip \e[93m$sshLimiteCon\e[0m"
#====================================================================
if [ ! -z $ipsBloqueados ];then
    echo -e "\e[96m-> IPS BLOQUEADOS ----------------------------------------\e[92m OK \e[0m"
    for a in "${ipsBloqueados[@]}";  do
        iptables -A INPUT -s $a -j DROP
        echo -e "Acesso pelo ip \e[93m$a\e[0m bloqueado"
    done
fi
#====================================================================
if [ $dockerReset == True ]; then
    echo -e "\e[96m-> REINICIADO DOCKER -------------------------------------\e[92m OK \e[0m"
    systemctl restart docker
fi