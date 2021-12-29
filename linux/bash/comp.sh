#!/bin/bash 
#shc -vf teste.sh
###
dir='exec'
sh='sh'
###
if [ ! -d $dir ]; then mkdir -p exec; fi
rm $dir/* -Rf &> /dev/null

file=$(ls $sh)
for i in $file; do
	echo Copilando $i
	shc -f $sh/$i
	echo Movendo arquivo para destino $(pwd)/$sh
	mv "$sh/$i.x" $dir/$i
done 
rm $sh/*.x.c
exit 0 
