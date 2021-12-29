#!/bin/bash 
dir='/tmp/teste_gravacao'
file="lixo.log"
#
if [ ! -d $dir ]; then mkdir -p $dir; fi
cd $dir
rm -Rf *
fallocate -l $((100*1024*1024)) $file
T=$(ls -lh $file|awk '{print $5}')

for i in {1..10}
 do
 echo "criando diretorio $dir/$i"
 mkdir $i
 echo "Copiando arquivo $dir/$i/$file - $T"
 cp $file $i
done

rm $file
du -sch

