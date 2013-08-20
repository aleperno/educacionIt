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

customlog(){
	logger -t "script" -p local7."$1" "$2" 2> /tmp/error.log
} 

#Manejo de la pass requerida por sudo
sudoPassword(){
	local value
	exec 3>&1
	value=$(dialog --title "Password Required" --insecure --passwordbox\
			"Ingrese password" 0 0 2>&1 1>&3)
	exec 3<&-
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
		dialog --infobox "Ingrese contraseña" 3 50; sleep 1;
		sudoPassword
		local pass1=$sudoPassword
		dialog --infobox "Repita contraseña" 3 50; sleep 1;
		sudoPassword
		local pass2=$sudoPassword
		if coinciden $pass1 $pass2; then
			exit=0
		else
			dialog --infobox "Las contraseñas no coinciden" 3 50; sleep 1;
		fi
	done
	dialog --infobox "Contraseña guardada" 3 50; sleep 1;
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

#Verifica si el grupo existe o no
checkGrupo(){
	if [ "$(cut -d ':' -f 1 /etc/group | grep "$1")" = "" ]; then
		dialog --title "info" --infobox "El grupo $1 no existe, se creará" 3 80; sleep 1;
		sudo groupadd $1
	fi
}

#Encripta la pass ingresada para ser utilizada en useradd
encriptPass(){
	encriptPass=$(perl -e 'print crypt($ARGV[0], "password")' $1)
}

addUser(){
	local shell="/bin/bash"
	local groups="nogroup"
	local user=""
	local home="/home/"

	exec 5>&1
	local VALUES=$(dialog --ok-label "Submit" \
    	  --backtitle "Linux User Managment" \
	      --title "Useradd" \
    	  --form "Create a new user" \
	15 50 0 \
    	"Username:" 1 1 "$user"     1 10 10 0 \
	    "Shell:"    2 1 "$shell"    2 10 15 0 \
    	"Group:"    3 1 "$groups"   3 10 8 0 \
	2>&1 1>&5)
	exec 5<&-
	local TEST=$(echo "$VALUES" | tr '\n' ':')
	local USUARIO=$(echo "$TEST" | cut -d ':' -f 1)
	local SHELL=$(echo "$TEST" | cut -d ':' -f 2)
	local GROUP=$(echo "$TEST" | cut -d ':' -f 3)

	if [ "$USUARIO" = "" ]; then
		dialog --title "ERROR" --infobox "No se permite usuario en blanco" 0 0; sleep 1;
		return
	elif ! checkUsuario $USUARIO; then
		dialog --title "ERROR" --infobox "El usuario ya existe" 0 0; sleep 1;
		return
	fi
	ingresePass
	if estaSeguro "Crear usuario $USUARIO con grupo $GROUP y shell $SHELL"; then
		encriptPass $ingresePass
		checkGrupo $GRUPO
		sudo useradd $USUARIO -p $encriptPass -g $GROUP -s $SHELL -m
	else
		dialog --infobox "Los datos seran descartados" 3 50;sleep 1;
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

#Principio del script
customlog "info" "Inicia el script"
exit=1
until [ $exit -eq 0 ]; do

	exec 4>&1
	opcion=$(dialog --menu 'Seleccione una opcion' 0 0 0 \
		1 'Apagar el equipo'\
		2 'Reiniciar el equipo'\
		3 'Agregar usuario'\
		4 'Ver ultimos 4 usuarios'\
		5 'Ver ultimos 10 mensajes criticos'\
		0 'Salir'\
		2>&1 1>&4)
	exec 4<&-


	case $opcion in

		1) if estaSeguro "Apagar equipo"; then
			apagar h
			customlog "info" "Se apaga el equipo"
		 fi ;;
		2) if estaSeguro "Reiniciar equipo"; then
			apagar r
			customlog "info" "Se reinicia el equipo"
		fi ;;
		3) addUser
			customlog "info" "Se crea un usuario";;
			#crearUsuario;;
		4) 	tail -n4 /etc/passwd > /tmp/output.dat
			dialog --textbox /tmp/output.dat 0 0
			customlog "info" "Se muestra el /etc/passwd";;
		5) cat /var/log/messages  > /tmp/output.dat
			 dialog --textbox /tmp/output0.dat 0 0
			customlog "info" "Se muestra el log de mensajes";;
		0) exit=0;;
		*) exit=0;;
	esac
done
VALOR=$(./signature.sh)
dialog --title "Credits" --infobox "$VALOR" 0 0; sleep 1
customlog "info" "Finaliza el script"
