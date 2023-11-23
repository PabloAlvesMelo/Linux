#!/bin/bash
# Autor : Pablo Melo
# Data  : 01/04/2016
# Funcao: Backup sistema SG, em multiplo volumes. 
#
# Descritivo : 
###########################################################
# Fazer backup dos arquivos selecionados, criando um backup de multiplo volumes (localmente).
# Separa os backup por data, manter no maximo xx dias de backup no storage e xx dias no servidor.
# Fazer backup em FTP.
# Montar unidade de rede, para fazer a transferecia dos arquivos, apos transferecia rodar script de limpeza e desmontar a unidade.
# Fazer limpeza no backup do servidor 
# Envio de email apos procedimento.
###########################################################
# Cuidado com o preenchimento dos parametros
###########################################################

#Parametros 

#Backup
# Data atual
HORA="$(date +%H:%M:%S)"
DATA="$(date +%d-%m-%y)"
AGORA="$(date +%y.%m.%d_%H.%M)"
# Pasta do sistema
BASE="/sg/sgs/ser"
# Extesao
ARQ="$BASE/*.dbf $BASE/*.ini"
# Nome do backup
TAR="backup.tar.gz"
# Diretorio backup
DIR_BACKUP="/sg/sgs/backup"
# Tamanho do arquivo backup em MB
TAM='1024m'
# Limpeza
L_SRV='+2'    # Servidor sistema
L_SMB='+10'   # Servidor samba

###########################################################
# FTP 
FTP='10.0.0.1'
User='usuario'
Pwd='senha'
Pasta='diretorio'

###########################################################
# Samba
Usuario='usuario'
Senha='senha'
IP_SMB='10.0.0.1/backup'
DIR_SMB='/mnt/backup'
SMB="mount -t cifs -o rw,username=${Usuario},password=${Senha} //${IP_SMB} ${DIR_SMB}"

###########################################################
# Nao Mexer!!!!!!!!!!!!!!!!!!!!!!
# Script

function BackupSG(){
# Verifica Diretorio do backup, se nao tiver cria a pasta.
if [ ! -d $DIR_BACKUP ]; then mkdir -p $DIR_BACKUP ; fi
cd $DIR_BACKUP
mkdir -p $AGORA
cd $AGORA
echo "Compactando arquivos" 
tar czv $ARQ | split -b $TAM - $TAR
}

function ApagaArquivos(){
#Verifica se o diretorio existe, antes de realizar a exclusao dos arquivos
find $DIR_BACKUP/* -ctime $L_SRV -exec rm -rf {} \;
}

function CopiaFtp(){
# Inicia copia para o FTP
cd $DIR_BACKUP/$AGORA
lftp <<End
open $FTP
user $User $Pwd
cd $Pasta
mkdir $AGORA
cd $AGORA
mput backup.tar.gz*
bye
End
}

function CopiaSmb(){
# Inicia copia para o Samba
if [ ! -d $DIR_SMB ]; then mkdir -p $DIR_SMB ; fi
$SMB
cd $DIR_SMB
mkdir -p $AGORA
cp $DIR_BACKUP/$AGORA/backup.tar.gz* $AGORA
find $DIR_SMB/* -ctime $L_SMB -exec rm -rf {} \;
cd $DIR_BACKUP
umount $DIR_SMB
}

function Internet(){
# Teste de internet 
ping -q -c1 8.8.8.8 >/dev/null; if [ ! $? -eq 0 ];then echo "Falha de intenet"; fi
}

function Parame(){
# Atualizacao do parame.ini
cd $BASE
V=`cat -n parame.ini | grep ultbackp|cut -c 4-6`
sed -i "$V d" parame.ini
sed -i $V'i\ultbackp='"$DATA"'\' parame.ini
}

###########################################################
BackupSG
Parame
ApagaArquivos
Internet
CopiaFtp
CopiaSmb

###########################################################
# Descompactar o backup
#
# cat prefixo.tar.gz.* | tar vzxf - 
# ex: cat backup.tar.gz* | tar -vzxf -
###########################################################

