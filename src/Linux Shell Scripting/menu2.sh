#!/bin/bash

<<COMMENT
       _                                  
      | |                                 
  __ _| | ___ _ __   ___ _ __ _ __   ___  
 / _` | |/ _ \ '_ \ / _ \ '__| '_ \ / _ \ 
| (_| | |  __/ |_) |  __/ |  | | | | (_) |
 \__,_|_|\___| .__/ \___|_|  |_| |_|\___/ 
             | |                          
             |_|                          

© Alejandro Pernin | blog.aleperno.com.ar | @alepernin

COMMENT


#Manejo de la pass requerida por sudo
sudoPassword(){
	local value
	exec 3>&1
	value=$(dialog --title "Password Required" --passwordbox\
			"Ingrese password" 0 0 2>&1 1>&3)
	exec 3>&-
	sudoPassword=$value
}
#Manejo de pregunta Si/No
estaSeguro(){

	dialog --title "$1" --yesno 'Esta usted seguro?' 0 0
	return $?
}

#Verifica que dos variables coincidan, se utiliza para strings.
# ¿Es lo mismo $1 = $2 ?
coinciden(){
	if [ "$1" = "$2" ]; then
		return 0
	else
		return 1
	fi
}

#Maneja el ingreso de pass
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

#Verifica que el usuario no exista ya
checkUsuario(){
	for i in `cat /etc/passwd | cut -d ':' -f 1`
		do
			if [ "$1" = "$i" ]; then
				return 1
			fi
		done
	return 0
}

#Maneja el ingreso del nombre de usuario
ingreseUsuario(){
	local usuario
	until [ "$usuario" != "" ]; do
		echo "Ingrese nombre de  usuario (no vacio)"
		read usuario
		if ! checkUsuario $usuario; then
			echo "El usuario ya existe, ingrese otro"
			usuario=""
		fi
	done
	ingreseUsuario=$usuario
}

#Verifica si el grupo existe o no
checkGrupo(){
	if [ "$(cut -d ':' -f 1 /etc/group | grep "$1")" = "" ]; then
    	echo "El grupo $1 no existe, se creará"
		groupadd $1
	else
    	echo "el grupo existe"
	fi
}

#Maneja el ingreso del nombre edl grupo
ingreseGrupo(){
	local grupo
	until [ "$grupo" != "" ]; do
		echo "Ingrese nombre del grupo, de no existir se creará"
		read grupo
	done
	ingreseGrupo=$grupo
}

#Encripta la pass ingresada para ser utilizada en useradd 
encriptPass(){
	encriptPass=$(perl -e 'print crypt($ARGV[0], "password")' $1)
}

#Maneja la creacion del usuario
crearUsuario(){
	local usuario pass
	ingreseUsuario
	ingresePass
	ingreseGrupo
	echo "Crear usuario $ingreseUsuario con pass $ingresePass y grupo $ingreseGrupo?"
	if estaSeguro; then
		encriptPass $ingresePass
		checkGrupo $ingreseGrupo
		sudo useradd $ingreseUsuario -p $encriptPass -g $ingreseGrupo -s /bin/bash
	else
		echo "Los datos seran descartados"
	fi
}

#Funcion encargada de apagar/reiniciar
apagar(){
	sudoPassword
	echo $sudoPassword | sudo -S shutdown -$1 now -k 
	if [ $? -eq 1 ]; then
		echo "ERROR" >> /tmp/log
		dialog --title "Error" --infobox "Contraseña incorrecta" 0 0;sleep 2
	fi
}

exit=1
until [ $exit -eq 0 ]; do
#	clear
#	echo -e "\n\n\n"
#	echo "Seleccione una opcion"
#	echo "1) Apagar el equipo"
#	echo "2) Reiniciar el equipo"
#	echo "3) Agregar usuario"
#	echo "4) Ver ultimos 4 usuarios"
#	echo "5) Ver ultimos 10 mensajes criticos"	
#	echo "0) Salir"
#	read opcion
	dialog --menu 'Seleccione una opcion' 0 0 0 \
		1 'Apagar el equipo'\
		2 'Reiniciar el equipo'\
		3 'Agregar usuario'\
		4 'Ver ultimos 4 usuarios'\
		5 'Ver ultimos 10 mensajes criticos'\
		0 'Salir'\
		2> /tmp/menu.dat

	opcion=`cat /tmp/menu.dat`


	case $opcion in

		1) if estaSeguro "Apagar equipo"; then
			apagar h
		 fi ;;
		2) if estaSeguro "Reiniciar equipo"; then
			apagar r
		fi ;;
		3) crearUsuario;;
		4) 	tail -n4 /etc/passwd > /tmp/output.dat
			 dialog --textbox /tmp/output.dat 0 0;;
		5) cat /var/log/messages | grep crit | tail -n 10  > /tmp/output.dat
			 dialog --textbox /tmp/output.dat 0 0;;
		0) exit=0;;
		*) exit=0;;
	esac

done
VALOR=$(./signature.sh)
dialog --title "Credits" --infobox "$VALOR" 0 0; sleep 1
