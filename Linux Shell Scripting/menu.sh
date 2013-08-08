#!/bin/bash

if [ "$EUID" != "0" ]; then
	echo "Son necesarios privilegios de root"
	exit 1
fi

estaSeguro(){
	local opcion
	while [ "$opcion" != "si" ] && [ "$opcion" != "no" ]; do
	echo "Esta usted seguro? (si/no)"
	read opcion
	done
	if [ "$opcion" = "si" ]; then
		return 0
	else
		return 1
	fi
}
coinciden(){
	if [ $1 = $2 ]; then
		return 0
	else
		return 1
	fi
}
ingresePass(){
	local exit=1
	until [ $exit -eq 0 ]; do
		echo "Ingrese contrasena"
		read pass1
		echo "Repita contrasena"
		read pass2
#		coinciden $pass1 $pass2
		if coinciden $pass1 $pass2; then
			exit=0
		else
			echo "Las contraseñas no coinciden"
		fi
	done
	ingresePass=$pass1
}

ingreseUsuario(){
	local usuario
	until [ "$usuario" != "" ]; do
		echo "Ingrese nombre de  usuario (no vacio)"
		read usuario
	done
	ingreseUsuario=$usuario
}

checkGrupo(){
	if [ "$(cut -d ':' -f 1 /etc/group | grep "$1")" = "" ]; then
    	echo "El grupo $1 no existe, se creará"
		groupadd $1
	else
    	echo "el grupo existe"
	fi
}

ingreseGrupo(){
	local grupo
	until [ "$grupo" != "" ]; do
		echo "Ingrese nombre del grupo, de no existir se creará"
		read grupo
	done
	ingreseGrupo=$grupo
}

encriptPass(){
	encriptPass=$(perl -e 'print crypt($ARGV[0], "password")' $1)
}
crearUsuario(){
	local usuario pass
	ingreseUsuario
	ingresePass
	ingreseGrupo
	echo "Crear usuario $ingreseUsuario con pass $ingresePass? y grupo $ingreseGrupo?"
	if estaSeguro; then
		encriptPass $ingresePass
		checkGrupo $ingreseGrupo
		useradd $ingreseUsuario -p $encriptPass -g $ingreseGrupo -s /bin/bash
	else
		echo "Los datos seran descartados"
	fi
}
apagar(){
	shutdown -$1 now -k
}

exit=1
until [ $exit -eq 0 ]; do
#	clear
	echo -e "\n\n\n"
	echo "Seleccione una opcion"
	echo "1) Apagar el equipo"
	echo "2) Reiniciar el equipo"
	echo "3) Agregar usuario"
	echo "0) Salir"
	read opcion

	case $opcion in

		1) if estaSeguro; then
			apagar h
		 fi ;;
		2) if estaSeguro; then
			apagar r
		fi ;;
		3) crearUsuario;;
		0) exit=0;;
		*) echo "Opcion invalida";;
	esac
#	sleep 1
done
