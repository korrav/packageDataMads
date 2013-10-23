#!/bin/bash


function createPartsFile { #функция создания нового архива части
	tar --append -f $fileArch $curPart.tar
	rm $curPart.tar
	curPart=$nParts
	tar -cf $curPart.tar --files-from=/dev/null
	nFiles=0
}


function addToArchive {	#функция добавления файлов данных в архив части
for fileAdd in `ls -lt | grep -vE '\.tar\.gz$|\.tar$' | grep $dateForFunctionArch | awk '{print $8}'`
do
	if [ -f $fileAdd ]
	then
		tar --append -f $curPart.tar $fileAdd
		rm $fileAdd
		nFiles=$[$nFiles + 1]
		if [ $nFiles -ge $MAX_NUM_FILES ]
		then
			nParts=$[$nParts + 1]	
			createPartsFile
		fi
	fi
done	
}


if [ $#  -ne 2 ]
then 
	echo Должно быть два аргумента
	exit 1
fi
#инициализация
dir=$1 #директория, в которой лежат данные предназначенные для архивирования
if ! [ -d $dir ]
then
	echo Каталога $dir не существует
	exit 1
else
	cd $dir
fi	
suf=$2 #номер МАД
echo $$ > /tmp/packageDataMad_$suf.pid
curPart=0 #номер текущего файла части
nParts=0 #счётчик номера файла части
nFiles=0 #счётчик номера файла
MAX_NUM_FILES=10000 #количество файлов в одной части
currentDate=`date +"%d%m%y"`
dateForFunctionArch=`date --date="today" +"%Y-%m-%d"`
fileArch=${currentDate}_$suf.tar
if [ -f $fileArch ]
then
	curPart=`tar -tf $fileArch | awk -F. '/^[0-9]+\.tar$/{print $1}' | sort -n | tail -n 1`
	if [ -z "$curPart" ];then
		curPart=0
	fi	
	nParts=$curPart
fi
while [ 1 ]
do	#перебор по датам
	currentDate=`date +"%d%m%y"`
	dateForFunctionArch=`date --date="today" +"%Y-%m-%d"`
	fileArch=${currentDate}_$suf.tar		
	if ! [ -f $fileArch ] #существует ли файл архива ?
	then
		tar -cf $fileArch --files-from=/dev/null
	fi
	while [ 1 ]
	do	#перебор по файлам текущей даты
		addToArchive
		if [ $currentDate -ne `date +"%d%m%y"` ]
		then
			addToArchive
			nParts=0
			createPartsFile
			gzip $fileArch &
			break
		fi
	done
done
