#===================================================================
# Parametros:
#===================================================================
ipt='iptables'
# => lan(local)
eth1='eth0'
ip1='192.168.3.169'
net='192.168.0.0/22'
# => wan(internet)
eth2='eth1' 
ip2='1.1.1.1'
portSsh='8899'
portMysql='3306'
ncon='20'
#===================================================================
clear
echo -e "\e[31m-> INICIANDO COFIGURACAO DO IPTABLES <-\e[0m"
#===================================================================
echo -e "\e[96m-> LIMPANDO AS REGRAS DO IPTABLES ------------------------\e[92m OK \e[0m"
$ipt -F
$ipt -X
$ipt -Z
#====================================================================
echo -e "\e[96m-> BLOQUEANDO TODAS AS REGRAS DEFAULT --------------------\e[92m OK \e[0m"
$ipt -P INPUT DROP
$ipt -P OUTPUT ACCEPT
#$ipt -P OUTPUT DROP
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
echo -e "\e[96m-> ENCAMINHAMENTO DE PACOTES -----------------------------\e[92m OK \e[0m"
echo 1 >/proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv4/tcp_syncookies
#====================================================================
echo -e "\e[96m-> BLOQUEIO DE REDE (SEGURANCA) --------------------------\e[92m OK \e[0m"
$ipt -A FORWARD -p tcp --syn -m limit --limit 2/s -j ACCEPT
$ipt -A INPUT -p tcp --dport 80 -m limit --limit 100/minute --limit-burst 200 -j ACCEPT
echo 1 >/proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
echo 1 >/proc/sys/net/ipv4/conf/default/rp_filter
#
$ipt -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
$ipt -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
$ipt -A INPUT -i $eth1 -s $ip1 -j DROP
#$ipt -A INPUT -i $eth2 -s $ip2 -j DROP
#====================================================================
echo -e "\e[96m-> ACEITAR PING ------------------------------------------\e[92m OK \e[0m"
$ipt -A INPUT -p icmp -j ACCEPT
#$ipt -A OUTPUT -p icmp -j ACCEPT
#====================================================================
#echo -e "\e[96m-> COMPARTILHAMETO DE WAN --------------------------------\e[92m OK \e[0m"
#$ipt -t nat -A POSTROUTING -s $net -j MASQUERADE
#$ipt -A FORWARD -i $eth1 -j ACCEPT
#====================================================================
echo -e "\e[96m-> CONEXAO REDE LO ---------------------------------------\e[92m OK \e[0m"
$ipt -A INPUT  -i lo -j ACCEPT
#$ipt -A OUTPUT -o lo -j ACCEPT
#$ipt -A OUTPUT -o $eth1 -j ACCEPT
#$ipt -A INPUT  -i $eth1 -j ACCEPT
#====================================================================
echo -e "\e[96m-> LIBERAR PORTAS ACESSO EXTERNO TCP----------------------\e[92m OK \e[0m"
tcp=(
 21   # FTP 
$portSsh # SSH
 23   # TELNET
 53   # DNS
 80   # HTTP 
 110  # POP3
 123  # NTP
 443  # HTTPS
 465  # SMTP
 995  # POP3s
 10050 # ZABBIX
 )
for a in "${tcp[@]}"
do
  $ipt -A INPUT -i $eth1 -p tcp --dport $a -j ACCEPT
  echo -e "Acesso a porta \e[93m$a\e[0m liberada"
done
#====================================================================
echo -e "\e[96m-> LIBERAR PORTAS ACESSO EXTERNO UDP----------------------\e[92m OK \e[0m"
udp=(
 53   # DNS
 )
for a in "${udp[@]}"
do
  $ipt -A INPUT -i $eth1 -p udp --dport $a -j ACCEPT
  echo -e "Acesso a porta \e[93m$a\e[0m liberada"
done
#====================================================================
echo -e "\e[96m-> ACESSO AO BANCO MYSQL ---------------------------------\e[92m OK \e[0m"
#mysql=('10.0.0.0/8' '172.16.0.0/16' '192.168.0.0/16' '177.125.217.137/29' '177.72.161.169' '177.72.161.173' '200.103.144.128' '177.19.238.75')
mysql=(172.16.0.1)
 for a in "${mysql[@]}"
 do
   $ipt -A INPUT  -p tcp -s $a --dport $portMysql -j ACCEPT
#   $ipt -A OUTPUT -p tcp -s $a --dport $portMysql -j ACCEPT
   echo -e "Acesso pelo ip \e[93m$a\e[0m liberado"
 done
#====================================================================
echo -e "\e[96m-> ACESSO AO SSH -----------------------------------------\e[92m OK \e[0m"
#ssh=('10.0.0.0/8' '172.16.0.0/16' '192.168.0.0/16' '177.125.217.137/29' '177.72.161.169' '177.72.161.173' '200.103.144.128' '177.19.238.75')
ssh=(172.16.0.1)
 for a in "${ssh[@]}"
 do
   $ipt -A INPUT  -p tcp -s $a --dport $portSsh -j ACCEPT
   echo -e "Acesso pelo ip \e[93m$a\e[0m liberado"
 done
#====================================================================
echo -e "\e[96m-> ACESSO FULL -------------------------------------------\e[92m OK \e[0m"
all=('10.0.0.0/8' '172.16.0.0/16' '192.168.0.0/16' '177.125.217.137/29' '177.72.161.169' '177.72.161.173' '200.103.144.128' '177.19.238.75')
 for a in "${all[@]}"
 do
   $ipt -A INPUT -p tcp -s $a -j ACCEPT
   $ipt -A INPUT -p udp -s $a -j ACCEPT
   echo -e "Acesso pelo ip \e[93m$a\e[0m liberado"
 done
#====================================================================
echo -e "\e[96m-> ESTABILIZA CONEXOES ABERTAS ---------------------------\e[92m OK \e[0m"
$ipt -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 
#====================================================================
echo -e "\e[96m-> LIMITANDO NUMERO DE CONEXAO ---------------------------\e[92m OK \e[0m"
$ipt -A INPUT -p tcp --syn --dport $portSsh -m connlimit --connlimit-above $ncon -j REJECT
echo -e "Conexoes simultaneas de um mesmo ip \e[93m$ncon\e[0m"
#====================================================================
echo -e "\e[96m-> REDIRECIONAMENTO DE PORTAS ----------------------------\e[92m OK \e[0m"
#$ipt -t nat -A PREROUTING -d $ip2 -p tcp --dport 8291 -j DNAT --to 192.168.1.225
#$ipt -t nat -A POSTROUTING -d 192.168.1.225 -p tcp --dport 8291 -j SNAT --to $ip2

# Bloquieo de MAC
#$ipt -A INPUT -m mac --mac-source 00:00:00:00:00:00 -j DROP
systemctl restart docker