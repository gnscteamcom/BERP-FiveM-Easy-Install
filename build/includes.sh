#!/bin/bash

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# INITIALIZE JQ (REQUIRED DEPENDANCY)
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
initialize() {
  [[ "$1" == "QUIETLY" ]] && loading 1 || echo "Initializing..."
  ####
  # THIS BIT IS NEEDED TO GET THE JSON CONFIG TO WORK
  jqGreet=$( dpkg-query -W -f='${Version}\\n' jq ) # check for jq
  if [ -z "$jqGreet" ]; then # if not found
    apt update && apt -y upgrade && apt -y install jq # install it!
  fi
  jqGreet=$( dpkg-query -W -f='${Version}\\n' jq ) # check for jq
  if [ -z "$jqGreet" ]; then # if not found
	echo "Failed to discover jq and the installation attempt also failed."
  fi
}
###############################################################################################
#-----[ ECO SYSTEM ]-----######################################################################

load_static_defaults() {
	#################################################################
	# DEFAULTS
	#
	# ALTER AT YOUR OWN RISK -- CONFIGURABLE (TECHNICALLY, BUT UNTESTED)
	# If you change this and it doesn't work... sorry.  All up to you now!

	PRIVLY_NAME="BERP-Privly" # this needs to be next to build  |  my expected folder structure:
	CONFIG_NAME="config.json" # this will be in the privly      |  root (name doesn't matter)
	REPO_NAME="BERP-Source"   # this needs to be next to build  |  |
								  # |  |_>build->The scripts
	_SERVICE_ACCOUNT="fivem"                                  # |  |_>BERP-Privly->config.json ( and anything private, including
	_MYSQL_USER="admin"					  # |  |_>BERP-Source                        mysql & txadmin backup )
                                                                  # |             |__> belch.co2
	_STEAM_WEBAPIKEY=""                                       # |             |__> Belcher.sh
	_SV_LICENSEKEY=""

	_RCON_ENABLE="true"
	_RCON_PASSWORD_GEN="true"
	_RCON_PASSWORD_LENGTH="64"
	_RCON_ASK_TO_CONFIRM="false"

	_TXADMIN_BACKUP_FOLDER="data-txadmin"
	_DB_BACKUP_FOLDER="data-mysql"
	_ARTIFACT_BUILD="1868-9bc0c7e48f915c48c6d07eaa499e31a1195b8aec"
	_SOFTWARE_ROOT="/var/software"

	_SERVER_NAME="Beyond Earth Roleplay (BERP)"

	_BELCH_TITLE="B.E.R.P Belcher (FiveM Deployment Tool by Beyond Earth)"
	_BELCH_VERSION="version 1.0"

        _LAST_BUILD_DATE="$(date '+%d/%m/%Y %H:%M:%S')"
        _CONFIG_TIMESTAMP="null"

	_REVIEW_CONFIGS="false"

	_MYSQL_SERVER="localhost"

}

identify_figs() {

	ALLFIGS=(                                                                                                       \
                 BELCH_TITLE BELCH_VERSION LAST_BUILD_DATE SERVICE_ACCOUNT SERVICE_PASSWORD MYSQL_USER MYSQL_PASSWORD  	\
                 RCON_ENABLE RCON_PASSWORD STEAM_WEBAPIKEY SV_LICENSEKEY BLOWFISH_SECRET DB_ROOT_PASSWORD             	\
                 RCON_PASSWORD_GEN RCON_PASSWORD_LENGTH RCON_ASK_TO_CONFIRM SERVER_NAME ARTIFACT_BUILD REPO_NAME      	\
                 SOFTWARE_ROOT TFIVEM TCCORE MAIN GAME RESOURCES GAMEMODES MAPS MYSQL_SERVER                 		\
                 ESX ESEXT ESUI ESSENTIAL ESMOD VEHICLES TXADMIN_BACKUP_FOLDER TXADMIN_BACKUP                     	\
                 DB_BACKUP_FOLDER DB_BACKUPS CONFIG_TIMESTAMP REVIEW_CONFIGS SHOW_ADVANCED RCON_TIMESTAMP             	\
	) ;

	# DEFAULTS IS THE ABOVE MINUS THE BOTTOM (ESSENTIALLY, REMOVE PASSWORDS- FOR VISABLITY REASONS.)
	PWDFIGS=(									                                \
                 SERVICE_PASSWORD MYSQL_PASSWORD RCON_PASSWORD BLOWFISH_SECRET DB_ROOT_PASSWORD                         \
	) ;

	DEFFIGS=("${ALLFIGS[@]}")

	# REMOVE ANY THAT ARE PASSWORDS... FROM DEFAULTS THAT ARE
	# VISUAL ON THE SCREEN, THEY ARE STILL ACCESSABLE AS VARS.

	#echo "=============================================="
	for _pwdfug in "${PWDFIGS[@]}" ;
	do
	#	echo -e "\tremoving $_pwdfug"
		DEFFIGS=( ${DEFFIGS[@]//*$_pwdfug*} ) ;
	done
	#echo "=============================================="
}

identify_branches() {
	# .sys.belch
	jq_BELCH_TITLE=".sys.belch.title"
	jq_BELCH_VERSION=".sys.belch.version"
	jq_LAST_BUILD_DATE=".sys.belch.configured"

	# .sys.config
	jq_CONFIG_TIMESTAMP=".sys.config.timestamp"

	# .sys.acct
	jq_SERVICE_ACCOUNT=".sys.acct.user"
	jq_SERVICE_PASSWORD=".sys.acct.password"

	# .sys.mysql
	jq_MYSQL_SERVER=".sys.mysql.server"
	jq_MYSQL_USER=".sys.mysql.user"
	jq_MYSQL_PASSWORD=".sys.mysql.password"
	jq_DB_ROOT_PASSWORD=".sys.mysql.rootPassword"

	# .sys.rcon
	jq_RCON_ENABLE=".sys.rcon.enable"
	jq_RCON_PASSWORD=".sys.rcon.password"
	jq_RCON_TIMESTAMP=".sys.rcon.timestamp"

	# .sys.rcon.pref
	jq_RCON_PASSWORD_GEN=".sys.rcon.pref.randomlyGenerate"
	jq_RCON_PASSWORD_LENGTH=".sys.rcon.pref.length"
	jq_RCON_ASK_TO_CONFIRM=".sys.rcon.pref.confirm"

	# .sys.php
	jq_BLOWFISH_SECRET=".sys.php.blowfishSecret"

	# .sys.keys
	jq_SV_LICENSEKEY=".sys.keys.fivemLicenseKey"
	jq_STEAM_WEBAPIKEY=".sys.keys.steamWebApiKey"

	# .pref
	jq_SERVER_NAME=".pref.serverName"
	jq_ARTIFACT_BUILD=".pref.artifactBuild"
	#jq_REPO_NAME=".pref.repoName"
	jq_REVIEW_CONFIGS=".pref.reviewConfigs"
	jq_SHOW_ADVANCED=".pref.showAdvancedOptions"

	# .env.private
	jq_TXADMIN_BACKUP=".env.private.txadminBackup"
	jq_TXADMIN_BACKUP_FOLDER=".env.private.txadminBackupFolder"
	jq_DB_BACKUPS=".env.private.dbBackups"
	jq_DB_BACKUP_FOLDER=".env.private.dbBackupFolder"

	# .env.software
	jq_SOFTWARE_ROOT=".env.software.softwareRoot"
	jq_TFIVEM=".env.software.tfivem"
	jq_TCCORE=".env.software.tccore"

	# .env.install
	jq_MAIN=".env.install.main"
	jq_GAME=".env.install.game"
	jq_RESOURCES=".env.install.resources"
	jq_GAMEMODES=".env.install.gamemodes"
	jq_MAPS=".env.install.maps"
	jq_ESX=".env.install.esx"
	jq_ESEXT=".env.install.esext"
	jq_ESUI=".env.install.esui"
	jq_ESSENTIAL=".env.install.essential"
	jq_ESMOD=".env.install.esmod"
	jq_VEHICLES=".env.install.vehicles"
}

collect_figs() {
	[[ "$1" != "QUIETLY" ]] && echo -e "\\nCollecting configuration..."
	#####################################################################
	#
	# IMPORT THE DEPLOYMENT SCRIPT CONFIGURATION
	#echo -e "\t#### I AM COLLECTING THE FIGS..."   ###@2
	identify_branches
	identify_figs
	[[ "$1" == "QUIETLY" ]] && __QUIET_MODE__="1"
	read_figs "${ALLFIGS[@]}"
	[[ "$1" == "QUIETLY" ]] && unset __QUIET_MODE__
	load_user_defaults
}

#####@2
load_user_defaults() {
	local _default ; local _default_name ; local _data
	for _default in "${DEFFIGS[@]:?}" ;
	do

		#echo -e "\\n\\e[93m$_default\\e[0m" ;
		_default_name="$(echo _${_default:?})" ;
		_data="${!_default}" ;

		if [ -n "$_data" ] && [ "$_data" != "null" ] ;
		then
			##@@5
			#echo -e "\\t\\e[92mdefault : \\e[97m$_default_name\\e[0m" ;
			#echo -e "\\t\\e[92mdata : \\e[97m$_data\\e[0m" ;
		        printf -v "${_default_name:?}" '%s' "${_data:?}" ;
		else
			#echo -e "\\e[91mremoving $_default from deffigs...\\e[0m"
			DEFFIGS=( ${DEFFIGS[@]//*$_default*} )
		fi
	done
	unset _default_name ; unset _data ;

}

define_runtime_env() {
	[[ "$1" != "QUIETLY" ]] && echo "Generating runtime environment..."
	load_static_defaults
	##########################################################################
	# WHO THE HECK AM I?!
	# WHERE THE HECK AM I?!!
	# GENERATE RUNTIME VARIABLES - NEEDS TO RUN EACH LOAD
	if [ "__RUNTIME__" != "1" ] ;
	then
		SCRIPT=$(echo "$0" | rev | cut -f1 -d/ | rev)
		THIS_SCRIPT_ROOT=$(dirname $(readlink -f "$0")) ;
		BUILDCHECK=()
		BUILDCHECK+=( $(readlink -f "${THIS_SCRIPT_ROOT:?}/../../build") ) || true
		BUILDCHECK+=( $(readlink -f "${THIS_SCRIPT_ROOT:?}/../build") )    || true
		BUILDCHECK+=( $(readlink -f "${THIS_SCRIPT_ROOT:?}/build") )       || true
		BUILDCHECK+=( $(readlink -f "${THIS_SCRIPT_ROOT:?}") )             || true
		unset THIS_SCRIPT_ROOT ;
		for cf in "${BUILDCHECK[@]:?}" ;
		do
			if [ -d "${cf:?}" ] && [ -f "${cf:?}/build-env.sh" ] ;
			then
				BUILD="${cf:?}"
			fi
		done
		SOURCE_ROOT=$(dirname $(readlink -f "${BUILD:?}" ))
		SCRIPT_FULLPATH=$(readlink -f "$0")
		SCRIPT_ROOT=$(dirname $(readlink -f "${BUILD:?}" ))

		SOURCE="${SOURCE_ROOT:?}/${REPO_NAME:?}"

		PRIVATE="${SOURCE_ROOT:?}/${PRIVLY_NAME:?}"
		CONFIG="${PRIVATE:?}/${CONFIG_NAME:?}"

		__RUNTIME__="1"
	fi
}

get_db_backups() {
#NOT CURRENTLY USING
	##########################################################################
	# DISCOVER DATABASE BACKUPS
	# THIS WILL FIND THE MOST RECENT BACKUP
	# NEEDS TO RUN EACH ENVIRONMENT LOAD.
	if [ -d "${DB_BACKUPS:?}" ] ;
	then
		DB=$(ls -Art "${DB_BACKUPS:?}/" | tail -n 1)
		[[ -z "$DB" ]] && DB="null"
	else
		DB="null"
		[[ -n "$DB_BACKUPS" ]] && mkdir "$DB_BACKUPS" || DB_BACKUPS="null"
	fi
	# END DATABASE BACKUP DISCOVERY
}

#-----[ ECO SYSTEM ]-----######################################################################
###############################################################################################

###############################################################################################
#-----[ CONFIGURES ]-----######################################################################

check_configuration() {
	#####################################################################
	#
	# CHECK FOR A CONFIGURAITON FILE, IF NOT FOUND THEN CREATE IT.
	##
	[[ -z "$__RUNTIME__" ]] && echo "runtime environment not loaded. failed!" && exit 1

	unset _content ;
	can_config "_content" ;
	if [ -n "$CONFIG" ] && [ -f "$CONFIG" ] && [ -n "$_content" ] ;
	then
		__CONFIG__="Config file defined."
		if [ -f "$CONFIG" ] ;
        	then
			__CONFIG__="Config file identified in file system."
			if [ -z "${_content}" ] ;
			then
				rm "$CONFIG" && unset __CONFIG__
				__INVALID_CONFIG__="Zero length config discovered"
				[[ "$1" != "QUIETLY" ]] && echo "$__INVALID_CONFIG__"

			else
				__CONFIG__="Configuration discovered @ ${CONFIG}"
				unset __INVALID_CONFIG__
				[[ "$1" != "QUIETLY" ]] && echo "$__CONFIG__"
			fi
	        else
				unset __CONFIG__
                __INVALID_CONFIG__="No configuration file was discovered..."
		        [[ "$1" != "QUIETLY" ]] && echo "$__INVALID_CONFIG__"
	        fi
	else
		unset __CONFIG__
                __INVALID_CONFIG__="No configuration file defined..."
                [[ "$1" != "QUIETLY" ]] && echo "$__INVALID_CONFIG__"
	fi
	unset _content
}

read_figs() {
	__CONFIG_UNFINISHED__=()
	__SILENTLY_ACCEPT_DEFAULTS__=()
	local _jsd_

	[[ -n "$__INVALID__" ]] && unset __INVALID__ ;  # CYA- PROBABLY REDUNDANT
	[[ ! -f "$CONFIG" ]] && __INVALID__="1" ;       # if config is not defined, skip this and data is invalid

	[[ -z "$__INVALID__" ]] && can_config "_jsd_" ;
	[[ -z "$_jsd_" ]] && __INVALID__="1" ;

	if [ -z "$__INVALID__" ] ;
	then
		for _fig in "$@" ;
		do
			hush=( 										\
				BELCH_TITLE	BELCH_VERSION	LAST_BUILD_DATE	CONFIG_TIMESTAMP 	\
				DB_BACKUPS	TXADMIN_BACKUP						\
			) ;
			#hush=()  # turn off, like so.  You'll need to comment out the above though.

			# hush the above figs from displaying on screen (they are always set)
			unset __SILENT__ ; local __SILENT__ ;
			if [[ " ${hush[@]} " =~ " ${_fig} " ]] ;
			then
				__SILENT__="1"
			else
				unset __SILENT__
			fi

			if [ -z "$__SILENT__" ] && [ -z "$__QUIET_MODE__" ] ;
			then
				color white - bold
				[[ -f "$CONFIG" ]] && echo -n "Importing ${_fig} configuration"
				color - - clearAll
			fi

			[[ -n "$__QUIET_MODE__" ]] && loading 1 CONTINUE

	                if [ -z "${!_fig}" ];
	                then

				local _jq ; # identify branch name
				_jq="$(eval echo \$jq_${_fig})"

				local _def ; # identify default name
				_def="$(eval echo _${_fig})"

				unset _jsData ; local _jsData
				_jsData="$(echo $_jsd_ | jq -r $_jq)"

				# if data is null or blank, it is invalid
				unset __INVALID__ ; local __INVALID__
				if [ -n "$_jsData" ] ;
				then
					case "$_jsData" in
						"null" ) __INVALID_="2" ;;
						     * ) unset __INVALID__ ;;
					esac ;
				else
					__INVALID__="1"
				fi
				[[ -z "$__INVALID__" ]] &&  printf -v "${_fig:?}" '%s' "${_jsData:?}"
				[[ -n "$__INVALID__" ]] && [[ -z "$__SILENT__" ]] &&  __CONFIG_UNFINISHED__+=("$_fig")
				[[ -n "$__INVALID__" ]] && [[ -n "$__SILENT__" ]] &&  __SILENTLY_ACCEPT_DEFAULTS__+=("$_fig")

				local _x_holder
				_x_holder=$(eval echo "_x_${_fig:?}")
				[[ -n "${!_fig}" ]] && printf -v "${_x_holder:?}" '%s' "${!_fig:?}"

				#echo -e "\nfig: $_fig"     ##@4
				#echo -e "val: ${!_fig}\n"
	                fi

			if [ -z "$__SILENT__" ] && [ -z "$__QUIET_MODE__" ] ;  # If this fig is not hushed
			then
				color white - bold
				[[ -f "$CONFIG" ]] && echo -e -n "... "
				color - - clearAll

		                if [ -n "${!_fig}" ] ;
		                then
		                        color green - bold
		                        [[ -f "$CONFIG" ]] && echo "Done."
		                        color - - clearAll
		                else
		                        color red - bold
		                        [[ -f "$CONFIG" ]] && echo "Nothing set!"
		                        color - - clearAll
		                fi
			fi	# OTHERWISE, THIS FIGLET IS ALWAYS SET AT LOAD AND (AS SUCH) IS SILENT AT LOAD

			unset __LOAD_QUIETLY__ ; unset __SILENT__ ; unset __INVALID__ ; unset _jsData ; unset _jq # clean up
	        done
	fi
}

harvest() {
	# COLLECT ALL FIGS FROM USER AND PREPARE TO WRITE

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
	# FIG  dialog:default/display random MIN  MAX #
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

	[[ "$_all_new_" ]] && unset _all_new_ ; _all_new_=()

        if [ "$__CONFIGURE__" ] || [ -z "$SHOW_ADVANCED" ] ;
        then
		PROMPT="Would you like to see advanced configuration options? (probably not)"
		pluck_fig "SHOW_ADVANCED" 11 false
		_all_new_+=("SHOW_ADVANCED")
	fi

	# SERVER_NAME
	if [ "$__CONFIGURE__" ] || [ -z "$SERVER_NAME" ] ;
	then
		PROMPT="What would you like to name the FiveM server?"
		pluck_fig "SERVER_NAME" 0
		_all_new_+=("SERVER_NAME")
	fi

	# SERVICE ACCOUNT
	if [ "$__CONFIGURE__" ] || [ -z "$SERVICE_ACCOUNT" ] ;
	then
		PROMPT="Enter the linux account to be used for FiveM"
		pluck_fig "SERVICE_ACCOUNT" "0" -
		_all_new_+=("SERVICE_ACCOUNT")
	fi
        [[ "$__CONFIGURE__" ]] || [[ -z "$MAIN" ]] &&  MAIN="/home/${SERVICE_ACCOUNT}" && _all_new_+=("MAIN")
        [[ "$__CONFIGURE__" ]] || [[ -z "$GAME" ]] &&  GAME="${MAIN}/server-data" && _all_new_+=("GAME")
        [[ "$__CONFIGURE__" ]] || [[ -z "$RESOURCES" ]] &&  RESOURCES="${GAME}/resources" && _all_new_+=("RESOURCES")
        [[ "$__CONFIGURE__" ]] || [[ -z "$GAMEMODES" ]] &&  GAMEMODES="${RESOURCES}/[gamemodes]" && _all_new_+=("GAMEMODES")
        [[ "$__CONFIGURE__" ]] || [[ -z "$MAPS" ]] &&  MAPS="${GAMEMODES}/[maps]" && _all_new_+=("MAPS")
        [[ "$__CONFIGURE__" ]] || [[ -z "$ESX" ]] &&  ESX="${RESOURCES}/[esx]" && _all_new_+=("ESX")
        [[ "$__CONFIGURE__" ]] || [[ -z "$ESEXT" ]] &&  ESEXT="${ESX}/es_extended" && _all_new_+=("ESEXT")
        [[ "$__CONFIGURE__" ]] || [[ -z "$ESUI" ]] &&  ESUI="${ESX}/[ui]" && _all_new_+=("ESUI")
        [[ "$__CONFIGURE__" ]] || [[ -z "$ESSENTIAL" ]] &&  ESSENTIAL="${RESOURCES}/[essential]" && _all_new_+=("ESSENTIAL")
        [[ "$__CONFIGURE__" ]] || [[ -z "$ESMOD" ]] &&  ESMOD="${ESSENTIAL}/essentialmode" && _all_new_+=("ESMOD")
        [[ "$__CONFIGURE__" ]] || [[ -z "$VEHICLES" ]] &&  VEHICLES="${RESOURCES}/[vehicles]" && _all_new_+=("VEHICLES")

	# SERVICE_PASSWORD
	if [ "$__CONFIGURE__" ] || [ -z "$SERVICE_PASSWORD" ] ;
	then
		PROMPT=$(echo "Enter a password for '$SERVICE_ACCOUNT' service account")
		pluck_fig "SERVICE_PASSWORD" "s:n/y" true 9
		_all_new_+=("SERVICE_PASSWORD")
	fi

	# DB_ROOT_PASSWORD
	if [ "$__CONFIGURE__" ] || [ -z "$DB_ROOT_PASSWORD" ] ;
	then
		PROMPT="Enter a password for the MySQL 'root' account"
		pluck_fig "DB_ROOT_PASSWORD" "s:n/y" true 16
		_all_new_+=("DB_ROOT_PASSWORD")
	fi

	# MYSQL_USER
	if [ "$__CONFIGURE__" ] || [ -z "$MYSQL_USER" ] ;
	then
		echo -e "\\e[91mThis should never be set to 'root' (it may not even work that way)\\e[0m\\n"
		PROMPT="Enter a username for MySQL, that will own the essentialmode database"
		pluck_fig "MYSQL_USER" "0" 0
		_all_new_+=("MYSQL_USER")
	fi

	# MYSQL_PASSWORD
	if [ "$__CONFIGURE__" ] || [ -z "$MYSQL_PASSWORD" ] ;
	then
		PROMPT=$(echo "Enter a password for '$MYSQL_USER' to access MySQL")
		pluck_fig "MYSQL_PASSWORD" "s:n/y" true 16 128
		_all_new_+=("MYSQL_PASSWORD")
	fi

	# BLOWFISH_SECRET
	if [ "$__CONFIGURE__" ] || [ -z "$BLOWFISH_SECRET" ] ;
	then
		PROMPT="Enter a Blowfish Secret for the PHP config"
		pluck_fig "BLOWFISH_SECRET" "s:n/y" true 16
		_all_new_+=("BLOWFISH_SECRET")
	fi

	# STEAM_WEBAPIKEY
	if [ "$__CONFIGURE__" ] || [ -z "$STEAM_WEBAPIKEY" ] ;
	then
		PROMPT="Enter your Steam Web-API key"
		pluck_fig "STEAM_WEBAPIKEY" 0 false
		_all_new_+=("STEAM_WEBAPIKEY")
	fi

	# SV_LICENSEKEY
	if [ "$__CONFIGURE__" ] || [ -z "$SV_LICENSEKEY" ] ;
	then
		PROMPT="Enter your Cfx FiveM license key"
		pluck_fig "SV_LICENSEKEY" 0 false
		_all_new_+=("SV_LICENSEKEY")
	fi

	##########################################################################################
	# RCON DETAILS
	## THESE ARE NOT SETTINGS TO BE CHANGED- DOING SO WILL VOID THE MANUFACTURERS WARRANTY!

	# RCON
	if [ "$__CONFIGURE__" ] || [ -z "$RCON_ENABLE" ] ;
	then
		PROMPT="Enable RCON (probably not needed)?"
		pluck_fig "RCON_ENABLE" 10 false
		_all_new_+=("RCON_ENABLE")
	fi

	if [ "$SHOW_ADVANCED" == "true" ] ;
        then
		# OFFER USER ABILITY TO REVIEW CONFIGURATIONS PRIOR TO COMMIT (THIS IS HELPFUL, SOMETIMES ANNOYING)
		if [ -n "$__CONFIGURE__" ] || [ -z "$REVIEW_CONFIGS" ] ;
		then
			echo -e "\\nWould you like the ability to review changes to config.json before saving them?"
			echo -e "There will still be a confirmation prompt with some heads up info..."
			echo -e "But this will allow for you to fully review the json file. (Advanced Users Will Like)\\n"
			PROMPT="Allow full review of config.json before saving?"
			pluck_fig "REVIEW_CONFIGS" 11
			_all_new_+=("REVIEW_CONFIGS")
		fi
	else
		if [ -n "$__CONFIGURE__" ] || [ -z "$REVIEW_CONFIGS" ] ;
		then
			REVIEW_CONFIGS="$_REVIEW_CONFIGS"
			_all_new_+=("REVIEW_CONFIGS")
		fi
	fi


	if [ "$RCON_ENABLE" == "true" ] ;
        then
		# RCON_PASSWORD_GEN
		if [ "$__CONFIGURE__" ] || [ -z "$RCON_PASSWORD_GEN" ] ;
		then
			PROMPT="(recommended) Allow RCON Passwords to be randomly generated?"
			pluck_fig "RCON_PASSWORD_GEN" 10 false
			_all_new_+=("RCON_PASSWORD_GEN")
		fi
		if [ "$RCON_PASSWORD_GEN" == "true" ] ;
		then
			if [ "$SHOW_ADVANCED" == "true" ] ;
			then
				# RCON_PASSWORD_LENGTH
				if [ "$__CONFIGURE__" ] || [ -z "$RCON_PASSWORD_LENGTH" ] ;
				then
					PROMPT="Number of characters to generate?" ;
					pluck_fig "RCON_PASSWORD_LENGTH" 20 false 20 128 ;
					_all_new_+=("RCON_PASSWORD_LENGTH") ;
				fi

				# RCON_ASK_TO_CONFIRM
				if [ "$__CONFIGURE__" ] || [ -z "$RCON_ASK_TO_CONFIRM" ] ;
				then
					PROMPT="(very verbose) Require manual approval of each randomly generated password" ;
					pluck_fig "RCON_ASK_TO_CONFIRM" 11 false ;
					_all_new_+=("RCON_ASK_TO_CONFIRM") ;
				fi
			else
				if [ "$__CONFIGURE__" ] || [ -z "$RCON_PASSWORD_LENGTH" ] ;
				then
					RCON_PASSWORD_LENGTH="$_RCON_PASSWORD_LENGTH" ;
					_all_new_+=("RCON_PASSWORD_LENGTH") ;
				fi

				if [ "$__CONFIGURE__" ] || [ -z "$RCON_ASK_TO_CONFIRM" ] ;
				then
					RCON_ASK_TO_CONFIRM="$_RCON_ASK_TO_CONFIRM" ;
					_all_new_+=("RCON_ASK_TO_CONFIRM") ;
				fi
			fi

			_all_new_+=("RCON_PASSWORD")

		else
	                RCON_PASSWORD_LENGTH="$_RCON_PASSWORD_LENGTH"
	                RCON_ASK_TO_CONFIRM="$_RCON_ASK_TO_CONFIRM"

			# RCON_PASSWORD
			if [ "$__CONFIGURE__" ] || [ -z "$RCON_PASSWORD" ] ;
			then
				PROMPT="Enter the password for RCON access:"
				pluck_fig "RCON_PASSWORD" "s:n/y" true 30 128
				_all_new_+=("RCON_PASSWORD")
			fi
	        fi
	else  # RCON_ENABLE=false
		[[ "$__CONFIGURE__" ]] || [[ -z "$RCON_PASSWORD_GEN" ]] && RCON_PASSWORD_GEN="$_RCON_PASSWORD_GEN" && _all_new_+=("RCON_PASSWORD_GEN")
		[[ "$__CONFIGURE__" ]] || [[ -z "$RCON_PASSWORD_LENGTH" ]] && RCON_PASSWORD_LENGTH="$_RCON_PASSWORD_LENGTH" && _all_new_+=("RCON_PASSWORD_LENGTH")
		[[ "$__CONFIGURE__" ]] || [[ -z "$RCON_ASK_TO_CONFIRM" ]] && RCON_ASK_TO_CONFIRM="$_RCON_ASK_TO_CONFIRM" && _all_new_+=("RCON_ASK_TO_CONFIRM")
	fi

	if [ "$SHOW_ADVANCED" == "true" ] ;
	then
		# TXADMIN_BACKUP_FOLDER
		if [ "$__CONFIGURE__" ] || [ -z "$TXADMIN_BACKUP_FOLDER" ] ;
		then
			PROMPT="What name would you like for the txAdmin backup folder?"
			pluck_fig "TXADMIN_BACKUP_FOLDER" 0
			_all_new_+=("TXADMIN_BACKUP_FOLDER")

		fi

		# DB_BACKUP_FOLDER
		if [ "$__CONFIGURE__" ] || [ -z "$DB_BACKUP_FOLDER" ] ;
		then
			PROMPT="What name would you like for the MySQL backup folder?"
			pluck_fig "DB_BACKUP_FOLDER" "s:y/n"
			_all_new_+=("DB_BACKUP_FOLDER")
		fi

		# ARTIFACT_BUILD
		if [ -n "$__CONFIGURE__" ] || [ -z "$ARTIFACT_BUILD" ] ;
		then
			printf "\\n" ; color red - bold ; color - - underline
			echo -e -n "**ONLY DO THIS IF YOU KNOW HOW! OTHERWISE, JUST HIT ENTER**\\e[0m\\n\\n"
			color white - bold ; echo -e "What CFX Artifact Build would you like to use?" ; color - - clearAll

			PROMPT="Enter CFX Build Artifact"
			pluck_fig "ARTIFACT_BUILD" 0
			_all_new_+=("ARTIFACT_BUILD")
		fi

		# SOFTWARE_ROOT
		if [ "$__CONFIGURE__" ] || [ -z "$SOFTWARE_ROOT" ] ;
		then
			printf "\\n" ; color yellow - bold ; color - - underline
			echo -e -n "NOTE: This is not the repo.  It's essentially just a cache of temporary downloads.\\e[0m\\n\\n"

			PROMPT="Where would you like to store the downloaded files?"
			pluck_fig "SOFTWARE_ROOT" 0
			_all_new_+=("SOFTWARE_ROOT")
		fi


		# REPO_NAME
		#if [ "$__CONFIGURE__" ] || [ -z "$REPO_NAME" ] ;
		#then
		#	PROMPT="What would you like to name the B.E.R.P. Source Repository?"
		#	pluck_fig "REPO_NAME" 0
		#	_all_new_+=("REPO_NAME")
		#fi
	else
		[[ "$__CONFIGURE__" ]] || [[ -z "$TXADMIN_BACKUP_FOLDER" ]] && TXADMIN_BACKUP_FOLDER="$_TXADMIN_BACKUP_FOLDER" && _all_new_+=("TXADMIN_BACKUP_FOLDER")
		[[ "$__CONFIGURE__" ]] || [[ -z "$DB_BACKUP_FOLDER" ]] && DB_BACKUP_FOLDER="$_DB_BACKUP_FOLDER" &&  _all_new_+=("DB_BACKUP_FOLDER")
		[[ "$__CONFIGURE__" ]] || [[ -z "$ARTIFACT_BUILD" ]] && ARTIFACT_BUILD="$_ARTIFACT_BUILD" &&  _all_new_+=("ARTIFACT_BUILD")
		[[ "$__CONFIGURE__" ]] || [[ -z "$SOFTWARE_ROOT" ]] && SOFTWARE_ROOT="$_SOFTWARE_ROOT" &&  _all_new_+=("SOFTWARE_ROOT")

		#[[ "$__CONFIGURE__" ]] || [[ -z "$REPO_NAME" ]] && REPO_NAME="$_REPO_NAME" &&  _all_new_+=("REPO_NAME")
	fi
	[[ "$__CONFIGURE__" ]] || [[ -z "$TFIVEM" ]] && TFIVEM="${SOFTWARE_ROOT}/fivem" && _all_new_+=("TFIVEM")
        [[ "$__CONFIGURE__" ]] || [[ -z "$TCCORE"  ]] && TCCORE="${TFIVEM}/citizenfx.core.server" && _all_new_+=("TCCORE")

        [[ "$__CONFIGURE__" ]] || [[ -z "$BELCH_TITLE" ]] && BELCH_TITLE="$_BELCH_TITLE" && _all_new_+=("BELCH_TITLE")
        [[ "$__CONFIGURE__" ]] || [[ -z "$BELCH_VERSION" ]] && BELCH_VERSION="$_BELCH_VERSION" &&  _all_new_+=("BELCH_VERSION")
        [[ "$__CONFIGURE__" ]] || [[ -z "$LAST_BUILD_DATE" ]] && LAST_BUILD_DATE="$_LAST_BUILD_DATE" &&  _all_new_+=("LAST_BUILD_DATE")
        [[ "$__CONFIGURE__" ]] || [[ -z "$CONFIG_TIMESTAMP" ]] && CONFIG_TIMESTAMP="$_CONFIG_TIMESTAMP" &&  _all_new_+=("CONFIG_TIMESTAMP")
        [[ "$__CONFIGURE__" ]] || [[ -z "$MYSQL_SERVER" ]] && MYSQL_SERVER="$_MYSQL_SERVER" &&  _all_new_+=("MYSQL_SERVER")
#        [[ "$__CONFIGURE__" ]] || [[ -z "$SOURCE" ]] && _all_new_+=("SOURCE")
#        [[ "$__CONFIGURE__" ]] || [[ -z "$SOURCE_ROOT" ]] &&  _all_new_+=("SOURCE_ROOT")

	# TXADMIN_BACKUP
	if [ -n "$__CONFIGURE__" ] || [ "$TXADMIN_BACKUP" != "$PRIVATE/$TXADMIN_BACKUP_FOLDER" ] ;
	then
		TXADMIN_BACKUP="$PRIVATE/$TXADMIN_BACKUP_FOLDER"
		_all_new_+=("TXADMIN_BACKUP")
	fi

	# DB_BACKUPS
	if [ -n "$__CONFIGURE__" ] || [ -z "$DB_BACKUPS" ] ;
	then
		DB_BACKUPS="$PRIVATE/$DB_BACKUP_FOLDER"
		_all_new_+=("DB_BACKUPS")
	fi

	CFX_BUILD="$(echo $ARTIFACT_BUILD | cut -f1 -d-)"

        if [ -n "$__CONFIG_UNFINISHED__" ] ;
        then
                for _cfug in "${__CONFIG_UNFINISHED__[@]}" ;
                do
                        if [[ ! " ${__CONFIG_UNFINISHED__[@]} " =~ " ${_cfug} " ]];
                        then
                                _all_new_+=("$_cfug")
                        fi
                done
        fi
}

pluck_fig() { # fig // prompt // confirm => 0/1

  local __cached_prompt ; local __prompt ; local __fig_key ; local __verbose
  local __random ; local __min_len ; local __max_len ; local __default

  __cached_prompt="$PROMPT"
  __prompt="$PROMPT" ; unset PROMPT
  __fig_key="$1" ;
  __verbose="$2" ;
  [[ -n "$3" ]] && [[ "$3" != "-" ]] && __random="$3" ;
  [[ -n "$4" ]] && [[ "$4" != "-" ]] && __min_len="$4" ;
  [[ -n "$5" ]] && [[ "$5" != "-" ]] && __max_len="$5" ;
  [[ -n "$6" ]] && [[ "$6" != "-" ]] && __rand_len="$6" || __rand_len="64" ;

  # verbose 20 means this is a number input.  this changes the min max len to min max int value.  This subsequently is skipped.
  if [ -n "$__rand_len" ] && [ "$__verbose" != 20 ] && [ -n "$__min_len" ] || [ -n "$__max_len" ] ;
  then
    if [ -n "$__min_len" ] && [ "$__rand_len" -lt "$__min_len" ] ;
    then
      __rand_len="$__min_len"
    elif [ -n "$__max_len" ] && [ "$__rand_len" -gt "$__max_len" ] ;
    then
      __rand_len="$__max_len"
    fi
  fi

  # verbose 20 means this is a number input.  this changes the min max len to min max int value. portions of this are, as such, skipped.
  if [ -n "$__min_len" ] && [ -n "$__max_len" ] && [ "$__verbose" != 20 ] ;  # if there both a min and max length
  then                                        # it has a minimum & maximum length required- update the prompt to reflect requirement
    __prompt=$(echo -e "$__prompt (\\e[93m\\e[4mlength: $__min_len \\e[2mto\\e[22m $__max_len\\e[24m\\e[39m)")
                                                                                 # 20 will mean they are actually for somthing else.
  elif [ -n "$__min_len" ] && [ -z "$__max_len" ] && [ ! "$__verbose" == 20 ] ;                     # if there is only a min length
  then                                                 # it has a minimum length required- update the prompt to reflrect requirement
    __prompt=$(echo -e "$__prompt (\\e[93m\\e[4mmin length: $__min_len\\e[24m\\e[39m)")
    unset __max_len
  elif [ "$__verbose" != 20 ];                                       # I don't wan to clean these up, if they belong to someone else
  then                                                         # otherwise, do nothing but clean up
    [[ "$__min_len" ]] && unset __min_len ;
    [[ "$__max_len" ]] && unset __max_len ;
  fi

	##@5
  #echo -e "\\n\\nfig key: $__fig_key"
  __default="$(eval echo \$_${__fig_key:?})"                                                         # Pick up the default value
  #echo -e "${__default:?}\\n\\n"
                                                                   # if it is blank, unset the var ; otherwise, add it to the prompt
  local __prompt__
  [[ -n "$__default" ]] && [[ "$__random" != "true" ]] \
    && [[ "$__verbose" != 10 ]] && [[ "$__verbose" != 11 ]] \
    && __prompt__=$(echo -e "$__prompt \\e[32m[$__default]\\e[39m")

  [[ -z "$__default" ]] && unset __default

                                                                  # Assign the prompt (with or without default value)- then clean up
  [[ "${__prompt__:=$__prompt}"  ]] && unset __prompt
				# I store the previous prompt for use later if i need to reform a confirm questions with it.
  if [ -n "$__verbose" ] ;                                       # If the confirmation is enabled
  then    # check if the setting is a valid int (1 = on / 2 = off)
    local __verbose_prompt
    if [[ "$__verbose" =~ '^[0-9]+$' ]] ;                                                     # If this validation checks out okay
    then                                          # this is a number, not a defininition string; Using the on/off assignment
      if [ "$__verbose" -eq 1 ] ;
      then                                         # if it is set to 1, use quick settings- C:N
		__verbose_prompt="C:N"
      elif [ "$__verbose" -eq 10 ] || [ "$__verbose" -eq 11 ] ;
      then
        unset __verbose_prompt
        unset __verbose_display
      else
        unset __verbose_prompt
        unset __verbose_display
        unset __verbose
      fi
    else 								# because this is not a valid int, this prompt has param settings
      __verbose_prompt=$(echo "$__verbose" | cut -f1 -d/) # collect the prompt params
    fi

    if [ "$__verbose" == 10 ] || [ "$__verbose" == 11 ] || [ "$__verbose" == 20 ] ;
    then
	  local __prompt
      __prompt="$__prompt__"   # temporarily reassign the current ongoing prompt building
      unset __prompt__    # unset for reassignment

      if [ "$__verbose" == 20 ] ;
      then
        if [ -n "$__min_len" ] && [ -n "$__max_len" ] ; then
		  local _i ; local __i1 ; local __i2 ; local __i3
          _i="($__min_len to $__max_len)"  # build the prompt addition
          __i1="$__min_len"  # build a default value (using the min val)
          __i2="$__max_len"  # I guess this is redundant... oh well. easier to be consistent (i use this later)
          __i3=$(echo "${#__max_len}")
        fi
		local __prompt__ ; __prompt__="$__prompt $_i"  # build the new prompt and assign to prompt
      fi

      if [ "$__verbose" == 10 ] || [ "$__verbose" == 11 ] ;
      then
	[[ "$__default" == "true" ]] && __verbose=10
	[[ "$__default" == "false" ]] && __verbose=11
		local _q ; local __q
        case "$__verbose" in   # if verbose
          10 ) _q="\\e[93m[Y/\\e[2mn\\e[22m]\\e[39m" ; __q=y ;;  # is 10, make Yes the default
          11 ) _q="\\e[93m[N/\\e[2my\\e[22m]\\e[39m" ; __q=n ;;  # is 11, make No the default
        esac;
        local __prompt__ ; __prompt__="$__prompt $_q"  # build the new prompt and assign to prompt
      fi
      [[ "${__prompt__:=$__prompt}" ]]   # if for some reason, this didn't work... take the previous prompt back
      unset __prompt    # clean up

    elif [ "$__verbose_prompt" != 0 ] || [ "$__verbose" != 0 ] ;
    then
      # string interpetation for verbose:
      # can be configured using the following syntax:
      #        (pos1=Ss/Cc):(pos2=Yy/Nn)/(pos3=Yy/Nn)

      # examples:  s:y/y   c:n/y   ... etc

      # Define the confirmation message
      local _p1 ; local _p2 ; local __p1 ; local __p2
      case $(echo "$__verbose_prompt" | cut -f1 -d:) in
        [Ss]* ) _p1="are you sure?" ; __p1=s ;;
        [Cc]* ) _p1="Continue?" ; __p1=c ;;
            * ) _p1="Continue?" ; __p1=C ;;
      esac;

      case $(echo "$__verbose_prompt" | cut -f2 -d:) in
        [Yy]* ) _p2="\\e[93m[Y/\\e[2mn\\e[22m]\\e[39m" ; __p2=y ;;
        [Nn]* ) _p2="\\e[93m[N/\\e[2my\\e[22m]\\e[39m" ; __p2=n ;;
            * ) _p2="\\e[93m[N/\\e[2my\\e[22m]\\e[39m" ; __p2=N ;;
      esac;
      # End confirmation message definition & building

      # if settings still both exist (this should), then I redefine the prompt settings (just in case catchall)
	  local __verbose_prompt
      [[ -n "$__p1" ]] && [[ -n "$__p2" ]] && __verbose_prompt="$__p1:$__p2" ;
      # If both pieces of the prompt exist, assign the confirmation message to it's var
	  local __question__
      [[ -n "$_p1" ]] && [[ -n "$_p2" ]] && __question__="$_p1 $_p2" ;

      # get the user input feedback display setting or use the default (which is to not display input feedback)
      local __verbose_display ; __verbose_display=$(echo "$__verbose" | cut -f2 -d/) ;
      [[ "${__verbose_display}" == "n" ]] && unset __verbose_display ;  # display is enabled, otherwise unset var
    else  # just clean up
      [[ "$__verbose_prompt" ]] && unset __verbose_prompt ;
      [[ "$__verbose_display" ]] && unset __verbose_display ;
    fi
  else  # more cleaning
    [[ "$__verbose" ]] && unset __verbose ;
  fi  # done with building the confirmation prompt

  [[ "$__return" ]] && unset __return ; # unsetting any potential. this is probably overkill- just making sure
  [[ "$return__" ]] && unset return__ ;

  [[ -z "$__RESALT__" ]] && [[ "$__random" == "true" ]] && [[ -n "${!__fig_key}" ]] && __CURRENT_PASSWORD__="${!__fig_key}"
  local _random_pass ; local _pass   ;

  ################[ BEGIN LOOP ]################


  while [ -z "$return__" ] ;
  do # while no value has been committed

    if [ "$__verbose" == 10 ] || \
       [ "$__verbose" == 11 ] || \
       [ "$__verbose" == 20 ] ;
    then

      #### 10 OR 11 ########################################
      if [ "$__verbose" == 10 ] || \
         [ "$__verbose" == 11 ] ;  # this is a yes / no prompt = true / false output
      then

        # PROMPT THE USER
        ##  -- yes/no question
        color white - bold ;
        echo -e -n "$__prompt__: \\e[s" && read -r -n 1 yn ; # Prompt the user

        [[ -n "$yn" ]] && printf "\\e[2D" || printf "\\e[u\\e[1A\\e[1D" ;
        color - - clearAll ;

        [[ "${yn:=$__q}" ]]  # check user input against default (if blank and has a default)

		local __return
        case "$yn" in
          [Yy]* ) __return=true ; echo -e " Yes.\\n" ;;
          [Nn]* ) __return=false ; echo -e " No.\\n" ;;
              * ) echo -e "\\nPlease answer yes or no (or hit control-c to cancel)\\n" ;;
        esac

      #### 20 #############################################
      elif [ "$__verbose" == 20 ] ; # this is a number input
      then

        # PROMPT THE USER
        ## -- number input
        color white - bold ;
        echo -e -n "$__prompt__: " ;
        read -r -n "$__i3" __return ;
        color - - clearAll ;
      fi

    else

      if [ "$__random" == "true" ] ;
      then
	# Probably a better way, but I'm doing this so i can verify there is a value or error below.
	_pass="$__CURRENT_PASSWORD__"
	_random_pass="$(add_salt $__rand_len 1 date)"

        [[ -z "$__CURRENT_PASSWORD__" ]] && __default="${_random_pass:?}" || __default="${__CURRENT_PASSWORD__:?}"

        if [ -n "$__CURRENT_PASSWORD__" ] ;
        then
          ####################
          # PROMPT THE USER
          ## -- current password detail
          printf "\\e[s\\e[2K\\e\\e[1B\\e[2K\\e\\e[1B\\e[2K\\e\\e[u" \
            && printf "   \\e[97m\\e[1mCurrent Password (Leave Blank to Accept | Can also type 'RANDOM'):\\n\\n"   \
            && echo -e -n "\\t\\e[33m> \\e[32m$__default \\e[33m<\\e[0m\\n\\n"

        else
          ####################
          # PROMPT THE USER
          ## -- random passwords detail
          printf "\\e[s\\e[2K\\e\\e[1B\\e[2K\\e\\e[1B\\e[2K\\e\\e[u" \
            && printf "   \\e[93m\\e[1mRandom Password (Leave Blank to Accept | Can also type 'RANDOM'):\\n\\n"   \
            && echo -e -n "\\t\\e[33m> \\e[31m$__default \\e[33m<\\e[0m\\n\\n"
        fi
      fi
      ####################
      # PROMPT THE USER
      ## -- standard input
      color white - bold ;
      echo -n "$__prompt__: " ; # prompt the user
      color - - clearAll ;
      read -r __return ; # read in the user's response to the prompt

      if [ -n "$__default" ] ;
      then       # if there is a default value,
        [ "${__return:=$__default}" ] ;    # read in input or use default value.
      fi                                    # otherwise, just use the input even if it is blank
      unset _pass ; unset __CURRENT_PASSWORD__
    fi


    ###############################
    # Input Validation
    ##
    if [ -n "$__return" ] && [ "$__return" != "true" ] && [ "$__return" != "false" ] && [ "${__return,,}" != "random" ] ;
    then  # if there is an input that is not zero length
      [[ "$__invalid" ]] && unset __invalid   # clear whatever setting may be set to __invalid (dusting off the equipment)
      local __valid ; __valid=1 # pre-validate the users input
      local __length ; __length=$(expr length "$__return")  # what is the length

      # NUMBER VALIDATION
      if [ "$__verbose" == 20 ] ; # this is a number input
      then
        if [ "$__return" -eq "$__return" ] 2> /dev/null    # check if user entered a valid integer
        then # This is a number
          [[ "$__return" -le "$__i1" ]] && __invalid="You've entered a number less than $__i1..." && unset __valid ;
          [[ "$__return" -ge "$__i2" ]] && __invalid="You've entered a number greater than $__i2..." && unset __valid ;
        else
          __invalid="This input requires you to enter a number."
          unset __valid ;
        fi
      fi
      [[ "$__verbose" == 20 ]] && unset __verbose_prompt  # if this is verbose 20, then there is no need for verbose_prompt


      # LENGTH VALIDATION
      if [ "$__min_len" ] && [ ! "$__length" -ge "$__min_len" ] && [ ! "$__verbose" == 20 ] ;
      then
        local __invalid ; __invalid="Minimum length required."    # invalidated user input with reason
        unset __valid    # revoke validation
      fi

      if [ "$__max_len" ] && [ ! "$__length" -le "$__max_len" ] && [ ! "$__verbose" == 20 ] ;
      then
        local __invalid ; __invalid="Too many characters entered."    # invalidate user input with reason
        unset __valid    # revoke validation
      fi
      unset __length    # clean up
    elif [ "$__return" == "true" ] || [ "$__return" == "false" ] ;
    then
        # do not validate; set the value and move on.
	__valid="1" ;
        unset __verbose_prompt
    elif [ "${__return,,}" == "random" ] ;
    then
      continue
    else
      local __invalid ; __invalid="No user input received from the console."  # invalidate user input with reason
      unset __valid   # revoke any potential validation
    fi  # done validating the users input

    # VALIDATION CHECK (DID THE ABOVE FLAG THIS? IF YES, INVALIDATE)
    [[ "$__return" ]] && [[ "$__invalid" ]] && unset __return  # if invalid, unset
    if [ "$__return" ] && [ "$__valid" ] ;  # if there is input that is not zero length
    then # the input was found and validated
      if [ ! "$__verbose_prompt" ] ;  # If there is no confirmation prompt set (or this is true false statement)
      then # then it has been disabled.
        local return__ ; return__="$__return"  # do not confirm; set the value and move on.

        [[ "$__return" != *$'\\r'* ]] && printf "\\r"
        [[ "$__verbose" != 2 ]] && [[ "$__return" != "true" ]] \
          && [[ "$__return" != "false" ]] && echo -e "Using \"$return__\"...\\n"
        unset __return

        printf -v "${__fig_key}" '%s' "$return__"

      else # otherwise, confirm with console that the value was correctly entered.

        unset __confirm  # unsetting a var before i read in user input
        while true;
        do # loop while

	  # Console display of input (for confirmation)
          if [ -n "$__verbose_display" ] ;
	  then
	    local _qref ; _qref=$(echo "$__cached_prompt" | cut -f 3- -d" ")
	    echo -e -n "\\e[1A\\e[K\\e[1A\\e[K\\e[1A\\e[K\\e[1A\\e[K\\e[1A\\e[K\\e[999D"
            echo -e -n "    \\e[93m For the $_qref, you've entered:\\e[0m\\n\\n"
	    echo -e -n "\\t\\e[92m  $__return  \\n\\n"
	  fi

          # echo the prompt with no newline; read the user input; backup 1 column (before newline)
          color white
          echo -e -n "$__question__: \\e[s" && read -r -n 1 yn
          color - - clearAll

          [[ -n "$yn" ]] && printf "\\e[2D" || printf "\\e[u\\e[1A\\e[1D"
          [[ "$yn" == "n" ]] && printf "\\e[2K\\e[1A\\r"

          [[ "${yn:=$__p2}" ]]  # check user input against default (if blank and has a default)
          case "$yn" in
          [Yy]* ) local __confirm ; __confirm=y ; echo -e " Yes.\\n" ;  break ;;
          [Nn]* ) unset __confirm ; break ;;
              * ) printf "\\e[2B\\e[999D\\e[K\\e[91mPlease answer yes or no (or hit control-c to cancel).\\e[0m" ;;
          esac
        done
        if [ "$__confirm" ] ; then
          local return__ ; return__="$__return"
          unset __return
          printf -v "${__fig_key}" '%s' "$return__"
	  printf "\\n"
        else
	  [[ -n "$__RESET__" ]] && printf "\\e[5A\\n\\e[KOkay, user input cleared... Let's try that again.\\n"
	  [[ -z "$__RESET__" ]] && local __RESET__ && __RESET__="1" \
            && printf "\\n\\e[2K\\r\\e[1A\\e[2K\\r\\e[1A\\e[2K\\r\\e[1A\\e[2K\\r\\e[1A\\e[2K\\r" \
            && printf "Okay, user input cleared... Let's try that again.\\n"
        fi

      fi
    elif [ "${__return,,}" == "random" ] ;
    then
      unset __return
      # User is requesting a random password
                            # reset the screen
      continue
    else

      ########
      # INVALID -- RESPONSE
      ##
      color red - bold
      color - - underline
      echo -e "\\n\\nERROR!\\n"
      color - - noUnderline
      [[ "$__invalid" ]] && echo "$__invalid" && unset __invalid
      echo -e "Input not valid.  Please try again.\\n"
      color clear clear clearAll
    fi
  done
  unset __prompt__ ; unset return__ ;  unset __confirm ; unset __question__ ;

}

can_config() {

	# CAT THE FILE TO A CONTAINER VARIABLE
	# USAGE: can_config "someVarWithoutADollarSignInQuotes"

	local _can ;
	_can="$1" ;

	if [ -z "$CONFIG" ];
	then
		echo "Config canning has failed. No config defined. Sharp eges. Blood everywhere." ;
		exit 1 ;
	fi

	local _figers ;
	_figers=$( cat "$CONFIG" 2>/dev/null ) ;

	if [ -z "$_figers" ] ;
	then
		unset _figers ;
	else
		printf -v "$_can" '%s' "$_figers" ;
	fi
}

jar_config() {
	# SAME AS ABOVE, BUT PIPE CAT INTO JQ, WHICH WILL
	# PRETTY PRINT THE OUTPUT TO THE CONTAINER VARIABLE
	# USAGE: jar_config "someVarWithoutADollarSignInQuotes"

	local _jar; _jar="$1"
	[[ -z "$CONFIG" ]] \
	  && echo "Config jarring has failed. No config defined. Broken glass. Blood everywhere." \
	  && exit 1
	local _figers; _figers=$(cat "$CONFIG" | jq -r . 2>/dev/null)
	[[ -n "$_figers" ]] && printf -v "$_jar" '%s' "$_figers"
	unset _figers
}

rebottle() {
	# dumps whatever content supplied to the defined $CONFIG
        [[ -z "$CONFIG" ]] \
          && echo "Rebottling has failed. I seem to have lost my bottle. Failed." \
          && exit 1

	[[ -z "$1" ]] && echo "no contents supplied.  failed." && exit 1
	[[ -n "$1" ]] && local _wrap &&  _wrap="$1"

	#unwrap and bottle
	if [ -n "${!_wrap}" ] ;
	then
		echo "${!_wrap}" | jq -r . > "$CONFIG"
	fi
}



cook_figs() {
	# GETTING IT ALL HOT AND READY!
        if [ -z "$PRIVATE" ] ;
	then
                echo "Erp. Derp. Problems... I have no private! FAILED @ x0532!"
                exit 1
	elif [ -z "$CONFIG" ] ;
	then
		echo "Config write failed.  No config definition discovered..."
		exit 1
        fi

	unset _content ;
	can_config "_content"  # will produce a conf catted out to _content
	##################################################################################
	if [ ! -d "${CONFIG%/*}" ] || [ ! -f "$CONFIG" ] || [ -z "$_content" ] ;
	then
		[[ "$1" == "QUIETLY" ]] && loading 1 CONTINUE || echo "No valid previous configuration was found.  Building base config..."
		[[ ! -d "${CONFIG%/*}" ]] && mkdir "${CONFIG%/*}"
		[[ -f "$CONFIG" ]] && rm "$CONFIG"
		BASE_CONFIG="{}"
	else
		[[ "$1" == "QUIETLY" ]] && loading 1 CONTINUE

		can_config "BASE_CONFIG"

		if [ "$_all_new_" ] && [ "${#_all_new_[@]}" -gt 0 ] ;
		then
			[[ "$1" == "QUIETLY" ]] && __LOADING_STOPPED__="1" && loading 1 CONFIG && printf "\\n\\n"
		else
			color white - bold
			echo "No changes discovered."
			color - - clearAll
			__UNCHANGED__="1"
		fi
	fi

	identify_branches

	local _cfuggers # The way to chatty list
	_cfuggers=()
	for _slfug in "${__SILENTLY_ACCEPT_DEFAULTS__[@]}" ;
        do
       	        _cfuggers+=("$_slfug")
	done

	local _to_notify
	_to_notify=()

	for _cfug in "${_all_new_[@]}" ;
	do
		#echo "Planting fig: $_cfug"  #@2
		plant_fig "BASE_CONFIG" "$_cfug"

		# blacklist these variables from notifying you about their change.  They are not important to you, trust.
		_cfuggers+=(
			"CONFIG_TIMESTAMP"
			"BELCH_TITLE"
			"BELCH_VERSION"
			"DB_BACKUPS"
			"TXADMIN_BACKUP"
			"LAST_BUILD_DATE"
			"MYSQL_SERVER"
		)

		[[ "$RCON_PASSWORD_GEN" == "true" ]] && _cfuggers+=("RCON_PASSWORD")
		[[ "$RCON_PASSWORD_GEN" == "true" ]] && _cfuggers+=("RCON_TIMESTAMP")

		if [[ ! " ${_cfuggers[@]} " =~ " ${_cfug} " ]] ;
                then
			_x_holder=$(eval echo "_x_${_cfug:?}") ;
			# check to see both are holding values and that they are not the same
			if [ -n "${!_cfug}" ] && [ -n "${!_x_holder}" ] && [ "${!_cfug}" != "${!_x_holder}" ] ;
			then
				_to_notify+=("${_cfug:?}")  ###9

			elif [ -n "${!_cfug}" ]  && [ -z "${!_x_holder:?}" ] ;
			then

				_to_notify+=("${_cfug:?}") 
			fi
		fi
	done

        if [ -d "${CONFIG%/*}" ] && [ -f "$CONFIG" ] && [ -n "$_content" ] \
	&& [ -n "$BASE_CONFIG" ] && [ -n "${_to_notify}" ] && [ "${#_to_notify[@]}" -gt 0 ] ; # && [ $Gift_of_Goats -eq 3 ] && [ -n $Your_Unborn_Child ] ;
        then								 	# Yeah, i know it is a bit clausy... but meh! it works for now.
		color lightYellow - bold
		echo -e "\\nPrevious config found... Rebuilding with new config values...\\n"
		echo -e "This will over-write the current values found in the  config:\\n"
		echo -e "\\t$CONFIG\\n\\n"
		color - - clearAll

		color white - bold
		echo -e "\\nLast chance to cancel...\\n"
		color - - clearAll

		if [ "${#_to_notify[@]}" -gt 0 ] ;
		then
			echo ""
			echo "To Notify: ${_to_notify[*]}"
			echo "#: ${#_to_notify[@]}"
			echo ""
		        while [ -z "$__confirmed__" ] ;
		        do
				ask_to_review "_content" "gray" "original"  #sorry, i know this is confusing...
				ask_to_review "BASE_CONFIG" "red" "revised"  # they got flipped around. BASE is the altered.

				display_array_title red "New or altered values"
				display_array red "${_to_notify[@]}"

				color white - bold
			        echo -n -e "Overwrite belch config with the values above? "
			        color lightYellow - bold
			        echo -n -e "(TYPE 'YES' TO CONTINUE)"
			        color white - bold
				echo -n -e ":"
				color - - clearAll
				unset _confirm ;
				read -r -n 3 _confirm ;
				case "$_confirm" in
			            Yes | yes | YES ) __confirmed__="1" ; unset _confirm ;;
				                  * ) unset _confirm ;;
				esac ;
				if [ -z "$__confirmed__" ] ;
				then
				echo -e "\\n\\e[97mYou did not type 'YES' -- if you'd like to cancel, hit control-c\\e[0m" ; # Fired!
				fi
			done
		fi
	fi
	unset _content

	if [ -n "$BASE_CONFIG" ] ;
	then

		commit "BASE_CONFIG"
	else
		printf "CONFUGGERING FAILED."
		exit 1
	fi

}

ask_to_review() {

	# USAGE:
	# $1 = NAME OF VAR THAT IS HOLDING REVIEW DATA (WITHOUT THE $)
	# $2 = (can be skipped with a - [dash]) COLOR  (eg ask_to_review "data" - )
	# $3 = (can be blank) Type of configuration (eg "new" configuraiton // "existing" configuration

	[[ -z "$1" ]] && echo "Must include data to review" && exit 1 || local _data_holder &&_data_holder="$1"
	[[ -n "$3" ]] && local _type_name && _type_name="$3"

	if [ "$REVIEW_CONFIGS" == "true" ] || [ -z "$REVIEW_CONFIGS" ] ;
	then
		local _head
		if [ -n "$_type_name" ] ;
		then
			PROMPT="Would you like to review the $_type_name configuration?"
			_head="${_type_name^^} CONFIGURATION"
		else
			PROMPT="Would you like to review the configuration?"
			_head="CONFIGURATION"
		fi

		pluck_fig "__REVIEW__" 11 false
		if [ "$__REVIEW__" == "true" ] ;
		then

			unset __REVIEW__
			unset __READY__
			until [ "$__READY__" == "true" ] ;
			do
				[[ -n "$2" ]] && [[ "$2" != "-" ]] && color "$2" - bold || color gray - bold
				echo -e -n "\\n---------------[ $_head ]---------------\\n"
				color - - clearAll
				echo "${!_data_holder}" | jq .
				printf "\\n\\n"

				PROMPT="Press 'Y' to continue. (Control-C to Cancel)"
				pluck_fig "__READY__" 11 false
			done
			unset __READY__
		else
			unset __REVIEW__
		fi
	fi
}

commit() {
	# USAGE:
	# commit    		      ::    VALIDATION ONLY - JUST CHECKS FOR CONFIG CONTENT
	# commit  COMMIT_NAME         ::    NEED TO USE THE NAME OF THE VAR, NOT THE ACTUAL VAR
	# commit  COMMIT_NAME SILENT  ::
	#			          THIS WILL COMMIT THE CHANGE (FIRST VERIFYING IT IS NOT 0 LENGTH)
	#			          THEN IT WILL VALIDATE THAT THE CHANGE TOOK SUCCESSFULLY.

	local _commit ; local _silent
	[[ -n "$1" ]] && _commit="$(eval echo \${$1})"
	[[ -n "$2" ]] && _silent="1"

	if [ -n "$1" ] && [ -z "$_commit" ] ;
	then
		printf "\\n\\e[91m\\e[4mNothing to commmit!\\e[0m\\n\\n"

	elif [ -z "$CONFIG" ] ;
	then
		printf "\\n\\e[91m\\e[4mNo config defined!\\e[0m\\n\\n"

	elif [ -z "$1" ] ;
	then
		check_configuration QUIETLY
                if [ -n "$__INVALID_CONFIG__" ] ;
                then
                        color red - bold
                        printf "\\nCONFIG CONTENT VALIDATION FAILED!\\n"
                        color - - clearAll
                elif [ -n "$__CONFIG__" ] ;
                then
			color green - bold
			printf "\\nCONFIG CONTENT VALIDATION SUCCEEDED!\\n"
			color - - clearAll
                fi
	elif [ -n "$1" ] && [ -n "$_commit" ] && [ -n "$CONFIG" ] ;
	then
		# OKAY TO ASSUME:
		# 1) A COMMIT ATTEMPT IS BEING MADE
		# 2) THE COMMIT IS NOT ZERO LENGTH
		# 3) THERE IS A CONFIG FILE DEFINED

		check_configuration QUIETLY
                if [ -n "$__INVALID_CONFIG__" ] ;
                then
			# OKAY TO ASSUME:
                        # 4) CONFIG AT DEFINED LOCATION IS CURRENTLY INVALID
                        local __NEW__ ; __NEW__="1"
			# current config is invalid
			# starting from scratch

                elif [ -n "$__CONFIG__" ] ;
                then
			# OKAY TO ASSUME:
			# 4) CONFIG AT DEFINED LOCATION IS VALID

                        [[ -z "$__QUIET_MODE__" ]] && [[ -z "$_silent" ]] && echo -e "\\n" \
			  && color red - bold && echo "$__CONFIG__" && color - - clearAll

			# CACHE THE CURRENT CONFIG
			unset _cached_config ;
			can_config "_cached_config" ;

			# IF THE CURRENT CONFIG DIDNT CACHE (IT SHOULD, BUT OKAY) THEN CALL IT OUT
			if [ -z "$_cached_config" ] ;
			then
				echo -e "\\nCaching of current config has failed..."
				echo -e "If we continue, there will be no reverting a failed commit.\\n"
				unset __CURRENT__
				PROMPT="Are you sure you still want to continue?"
				unset __CONTINUE__
				pluck_fig "__CONTINUE__" 11 false
				if [ -n "$__CONTINUE__" ] ;
				then
					echo -e "\\n\\t\\e[91m\\e[4mOkay, you've been warned.\\e[0m\\n"
					unset __CONTINUE__
				else
					echo -e "\\n\\e[91mConfiguration cancelled by user... exiting!\\e[0m\\n"
					exit 1
				fi
			fi
                fi

		can_config "_content"    # READ IN THE REVISED CONFIG CONTENTS
		while true ;
		do
			#echo "Committing contents..." #@3
			[[ -z "${_silent}" ]] && color yellow - bold
			[[ -z "${_silent}" ]] && printf "\\n      Writing config to:\\n"
			[[ -z "${_silent}" ]] && color yellow - dim
			[[ -z "${_silent}" ]] && echo -e -n "      ${CONFIG:?}\\n\\n"
			[[ -z "${_silent}" ]] && color - - clearAll

			echo "${_commit:?}" > "${CONFIG:?}"   				  # WRITE THE CONFIG
			unset _content	;

			can_config "_refreshed_content"
			if [ -n "${_refreshed_content:?}" ] ;
			then
				#echo "Found content..."
				if [ "${_commit:?}" == "${_refreshed_content:?}" ] ;
				then
					# SUCCESS!
		                        color green - bold
		                        [[ -z "${_silent}" ]] && printf "\\nCONFIGURATION SAVED SUCCESSFULLY!\\n"
		                        color - - clearAll
					ask_to_review "_content" "green" "committed"
		                        unset _refrehsed_content
					break ;

				elif [ "${_cached_config:?}" == "${_refreshed_content:?}" ] ;
		                then
					# NO CHANGES? WEIRD, BUT OKAY- LET ME KNOW.
					color yellow - bold
					echo "CONFIGURATION APPEARS UNALTERED..."
					color - - clearAll
					ask_to_review "_cached_config" "gray" "original"
					ask_to_review "_commit" "red" "revised"
					ask_to_review "_content" "green" "committed"

				elif [ -n "${_cached_config:?}" ] ;
				then
					# FAILED, BUT WE CAN GO BACK!
			                color red - bold
		        	        printf "\\nFAILED TO SAVE CONFIGURATION!\\n"
		                        color - - clearAll

					color white - bold
					echo "Attempting to revert configuration from cache..."
					color - - clearAll

					rebottle "_cached_config"  # WRITES THE CONTENTS TO $CONFIG

					unset _refreshed_content ;
					can_config "_restored_content" ;

					[[ -z "$_restored_content" ]] \
					  && echo "well, I tried to commit... but I got my privates stuck in a ceiling fan" \
					  && echo "...I've failed.  I'm very sorry!" && exit 1
					[[ -n "$_restored_content" ]] && [[ "$_restored_content" == "$_cached_config" ]] \
					  && echo "Successfully reverted the configuration back to its original state."
					unset _restored_content
				elif [ -z "$_cached_config" ] ;
        	                then
					# FAILED, NO RETURN!
					echo "well, I tried to commit... but I got my privates stuck in the ceiling fan"
					echo "If you are seeing this... I'm sorry."
					echo -e "\\nWe could try again, but I don't have much hope...\\n"
				else
					# I HAVE NO IDEA WHY THIS WOULD EVER TRIGGER
					color yellow red bold
					echo "Configuration to commit configuration.  FAILED!"  # this is very tired error code writing.  I'm leaving it!
					color - - clearAll
					exit 1
				fi
				printf "\\n\\n"
				PROMPT="Try again?" && unset __CONTINUE__
				pluck_fig "__CONTINUE__" 10 false
				[[ -z "$__CONTINUE__" ]] && break ;  ## worst code ever hahahaha
				unset __CONTINUE__
			fi
			unset _refreshed_content
		done
		unset _content
	fi
}

plant_fig() {
	# WHERES THE WORK?
	local _crop ; _crop="$1"

	# WHAT TO PLANT?
	local _fig ; _fig="$2"

	# auto determined... but it must be defined under jq_CURRENTVARNAME
	local _path ; _path="$(eval echo \$jq_${_fig})"

	[[ -z "$__RUNTIME__" ]] && identify_branches

	_fruit="${!_fig}"
	_yield=$(eval echo \${$_crop} | jq -r $_path=\""$_fruit"\")

	[[ -n "$_yield" ]] && printf -v "$_crop" '%s' "$_yield" \
	  || echo -e "\\n\\e[97merror planting fig!\\e[0m"
}

personalize() {

        #####################################################################
        ############ THIS SHOULD BE AT THE END STAGES #######################
        #####################################################################
        #
        # INJECT PERSONAL CREDENTIALS INTO THE CONFIGURATION FILE
        ##

        if [ ! -f "${GAME:?}/server.cfg" ] ;
	then
        	echo "Server configuration not found! Woopsie... FAILED!"
        	exit 1
        fi
	local _server_cfg ; local _server_cfg_name
	_server_cfg_name="${GAME:?}/server.cfg"
	_server_cfg=$(cat "${_server_cfg_name:?}" 2>/dev/null)
	[[ -z "$_server_cfg" ]] && "\\e91mServer.cfg is empty! Build config failed.  Exiting.\\e[0m" && exit 1

	# first, lets wipe down this table...  It looks like it could be dirty.
	# Better safe than sorry.
	rm -f "${GAME:?}/server.cfg.orig" 2>/dev/null || true
	rm -f "${GAME:?}/server.cfg.srvnm" 2>/dev/null || true
	rm -f "${GAME:?}/server.cfg.dbCfg" 2>/dev/null || true
	rm -f "${GAME:?}/server.cfg.rconCfg" 2>/dev/null || true
	rm -f "${GAME:?}/server.cfg.steamCfg" 2>/dev/null || true

	_server_cfg_previous_name="${_server_cfg_name:?}"
	_server_cfg_name="${GAME:?}/server.cfg.orig"
        mv "${_server_cfg_previous_name:?}" "${_server_cfg_name:?}" #--> Renaming file to be processed

        #-Server Name Injection
        servername_placeholder="sv_hostname \"Beyond Earth RolePlay (BERP)\""
        servername_actual="sv_hostname \"${SERVER_NAME:?}\""
        echo "Accepting original configuration; Injecting server name configuration..."
	_server_cfg_previous_name="${_server_cfg_name:?}"
	_server_cfg_name="${GAME:?}/server.cfg.srvnm"
        sed "s/${servername_placeholder:?}/${servername_actual:?}/" "${_server_cfg_previous_name:?}" > "${_server_cfg_name:?}"
	_server_cfg=$(cat "${_server_cfg_name:?}" 2>/dev/null)
	[[ -z "$_server_cfg" ]] && "\\e91m${_server_cfg_name:?} is empty! Failed. Exiting.\\e[0m" && exit 1
	unset _server_cfg ; local _server_cfg
        rm -f "${_server_cfg_previous_name:?}"  #--> cleaning up; handing off a .rconCfg

	if [ "${RCON_ENABLE:?}" == "true" ] ;
	then
        	#-RCON Password Creation
	        #echo "Generating RCON Password."
		salt_rcon

	        rcon_placeholder="#rcon_password changeme"
	        rcon_actual="rcon_password \"${RCON_PASSWORD:?}\""
	        echo "Accepting server name configuration; Injecting RCON configuration..."
		_server_cfg_previous_name="${_server_cfg_name:?}"
		_server_cfg_name="${GAME:?}/server.cfg.rconCfg"
	        sed "s/${rcon_placeholder:?}/${rcon_actual:?}/" "${_server_cfg_previous_name:?}" > "${_server_cfg_name:?}"
		_server_cfg=$(cat "${_server_cfg_name:?}" 2>/dev/null)
		[[ -z "$_server_cfg" ]] && "\\e91m${_server_cfg_name:?} is empty! Failed. Exiting.\\e[0m" && exit 1
		unset _server_cfg ; local _server_cfg
	        rm -f "${_server_cfg_previous_name:?}"  #--> cleaning up; handing off a .rconCfg
	else
		#-Skip RCON
		mv -f "${GAME:?}/server.cfg.srvnm" "${GAME:?}/server.cfg.rconCfg"
		echo "RCON is disabled... skipping."
	fi

        #-mySql Configuration
        echo "Accepting RCON config handoff; Injecting MySQL Connection String..."
        db_conn_placeholder="set mysql_connection_string \"server=localhost;database=essentialmode;userid=username;password=YourPassword\""
        db_conn_actual="set mysql_connection_string \"server=${MYSQL_SERVER};database=essentialmode;userid=${MYSQL_USER:?};password=${MYSQL_PASSWORD:?}\""
	_server_cfg_previous_name="${_server_cfg_name:?}"
	_server_cfg_name="${GAME:?}/server.cfg.dbCfg"
        sed "s/${db_conn_placeholder:?}/${db_conn_actual:?}/" "${_server_cfg_previous_name:?}" > "${_server_cfg_name:?}"
	_server_cfg=$(cat "${_server_cfg_name:?}" 2>/dev/null)
	[[ -z "$_server_cfg" ]] && "\\e91m${_server_cfg_name:?} is empty! Failed. Exiting.\\e[0m" && exit 1
	unset _server_cfg ; local _server_cfg
        rm -f "${_server_cfg_previous_name:?}" #--> cleaning up; handing off a .dbCfg

	#-Steam Key Injection into Config
	echo "Accepting MySql config handoff; Injecting Steam Key into config..."
	steamKey_placeholder="set steam_webApiKey \"SteamKeyGoesHere\""
	steamKey_actual="steam_webApiKey  \"${STEAM_WEBAPIKEY:?}\""
        _server_cfg_previous_name="${_server_cfg_name:?}"
        _server_cfg_name="${GAME:?}/server.cfg.steamCfg"
	sed "s/${steamKey_placeholder:?}/${steamKey_actual:?}/" "${_server_cfg_previous_name:?}" > "${_server_cfg_name:?}"
	_server_cfg=$(cat "${_server_cfg_name:?}" 2>/dev/null)
	[[ -z "$_server_cfg" ]] && "\\e91m${_server_cfg_name:?} is empty! Failed. Exiting.\\e[0m" && exit 1
	unset _server_cfg ; local _server_cfg
        rm -f "${_server_cfg_previous_name:?}" #--> cleaning up; handing off a .steamCfg



	#-FiveM License Key Injection into Config
	echo "Accepting Steam config handoff; Injecting FiveM License into config..."
	sv_licenseKey_placeholder="sv_licenseKey LicenseKeyGoesHere"
	sv_licenseKey_actual="sv_licenseKey ${SV_LICENSEKEY:?}"
        _server_cfg_previous_name="${_server_cfg_name:?}"
        _server_cfg_name="${GAME:?}/server.cfg"
	sed "s/${sv_licenseKey_placeholder:?}/${sv_licenseKey_actual:?}/" "${_server_cfg_previous_name:?}" > "${_server_cfg_name:?}"
	_server_cfg=$(cat "${_server_cfg_name:?}" 2>/dev/null)
	[[ -z "$_server_cfg" ]] && "\\e91m${_server_cfg_name:?} is empty! Failed. Exiting.\\e[0m" && exit 1
	unset _server_cfg ; local _server_cfg
        rm -f "${_server_cfg_previous_name:?}" #--> cleaning up; handing off a (now personalized) server.cfg


	if [ -f "${_server_cfg_name:?}" ];
	then
		color green - bold
		echo -e "\\nServer configuration file found.\\e[0m\\n"
	else
		color red - bold
		echo -e "\\nERROR: Something went wrong during the configuration personalization...\\e[0m\\n"
	fi

}


#-----[ CONFIGURES ]-----######################################################################
###############################################################################################

###############################################################################################
#-----[ RCON TINGS ]-----######################################################################

salt_rcon() {
	if [ "$RCON_ENABLE" == "true" ] ; then
		local _today ; _today=$(date +%Y-%m-%d)

		unset _content ;
		can_config "_content" ;

		if [ -n "$_content" ] ;
		then
			# reads in the timestamp or disregards if there is an error (i use that for condition set)
			local _last_set ; _last_set=$(echo "$_content" | jq -r '.sys.rcon.timestamp' 2>/dev/null)
		fi
		if [ -n "$_last_set" ] && [ "$_last_set" != "null" ] ;
		then
			local _d1 ; _d1=$(date -d "$_today" '+%s')
			local _d2 ; _d2=$(date -d "$_last_set" '+%s')
			local _since_set ; _since_set=$(( (_d1 - _d2)/(60*60*24) )) # in days
			unset _d1 ; unset _d2 ;
		else
			unset _last_set
		fi

		if [ "$RCON_PASSWORD_GEN" == "true" ] ;
		then
			if [ "$RCON_ASK_TO_CONFIRM" == "true" ] ;
			then
				unset RCON_PASSWORD

				while [ -z "$RCON_PASSWORD" ] ;
				do
					color lightYellow - bold
					echo ""
					echo "You may enter a custom RCON password, but it's recommended that you accept the randomly generated one."
					echo ""
					PROMPT="Enter RCON password"
					pluck_fig "RCON_PASSWORD" "s:n/y" true 25 128 "$RCON_PASSWORD_LENGTH"

					color white - bold
					echo "Writing new RCON password to config..."
					color - - clearAll
				done
			else
				color white - bold
				echo "Writing new RCON password to config..."
				color - - clearAll

				RCON_PASSWORD="$(add_salt $RCON_PASSWORD_LENGTH 1 date)"
			fi

			# WRITE THE CURRENT PASSWORD TO THE CONFIG
			commit_rcon_password

			if [ -n "$RCON_PASSWORD" ] ;
			then
				echo "The RCON Password has been regenerated..."
			else
				echo "RCON Password regeneration has failed..."
				exit 1
			fi

		elif [ -z "$RCON_PASSWORD" ] || [ "$_since_set" -ge 30 ] || [ -z "$_last_set" ] ;
		then

			# YOUR PASSWORD IS MORE THAN 30 DAYS OLD
			[[ -n "$_last_set" ]] && color red - bold
			[[ -n "$_last_set" ]] && [[ "$_since_set" -ge 30 ]] \
			  && echo -e "\\nYou last changed your RCON password on: $_last_set" \
			  && echo -e "It has been $_since_set days since you last changed your RCON password.\\n"

			echo -e "You should make sure and change this password often\\n"
			[[ -n "$_last_set" ]] && color - - clearAll

			_RCON_PASSWORD="$RCON_PASSWORD"
			if [ -n "$_RCON_PASSWORD" ] && [ -n "$_last_set" ] ;
			then
				echo -e "Current password:\\n${_RCON_PASSWORD}\\n"
				PROMPT="Keep using $_since_set day-old password? (not recommended)"
				pluck_fig "__KEEP__" 11 false
			fi

			if [ -z "$__KEEP__" ] ;
			then
				unset RCON_PASSWORD
				until [ -n "$RCON_PASSWORD" ] ;
				do
					PROMPT="Enter RCON password"
					pluck_fig "RCON_PASSWORD" "s:n/y" true 25 128 "$RCON_PASSWORD_LENGTH"
				done
				commit_rcon_password
			else
				printf "\\n"
				color yellow red bold
				echo -e "This is not smart... but okay.\\e[0m\\n"

				unset "__KEEP__"
                                PROMPT="Do you want to silence this reminder for another 30 days? (really not recoomented)?"
                                pluck_fig "__KEEP__" 11 false

				if [ "$__KEEP__" == "true" ] ;
				then
					 printf "\\n"
					color yellow red bold
					echo -e -n "If you get hacked, don't cry to me. I hope it is a long password!\\e[0m\\n"
					commit_rcon_password "timestamp"
				fi
			fi
		fi
	fi
}

commit_rcon_password() {
	# IT IS ASSUMED THAT YOU MUST HAVE CONTENT IN THE FILE TO EVEN GET THIS FAR
	# SO IF THIS VALIDATION FAILED, WE JUST SKIP THE ADDITION.  IT SHOULD GET ADDED
	# WHEN THE QUICK CONFIG COMMITS ITS DATA.
	[[ -z "$CONFIG" ]] && echo "No config defined. failed." && exit 1

        unset _contents ;
	can_config "_contents" ;

	local _today ; _today="$(date +%Y-%m-%d)"

	if [ -n "$_contents" ] ;
	then  # if there is no content in the file... we probably shouldn't be this far.  My assumption here atleast.

		local _rev1

		# I USE TIMESTAMP (ABOVE) AS A VAR HERE- BUT ANTYHING BEING PASSED CAUSES IT NOT TO WRITE.
		# SO I DO IT WITH TIMESTAMP ABOVE BECAUSE I DON'T WANT THIS PART.
		[[ -z "$1" ]] && _rev1=$( echo "${_contents:?}" | jq --arg pass "${RCON_PASSWORD:?}" '.sys.rcon.password=$pass')

		# IF $1 IS PASSED, ASSUME THIS IS ONLY A PASSWORD TIMESTAMP UPDATE
		if [ -n "$_rev1" ] || [ -n "$1" ] ;
              	then
			[[ -n "$_rev1" ]] && _contents="$_rev1"
			_revision=$(echo "${_contents:?}" | jq --arg today "${_today:?}" '.sys.rcon.timestamp=$today')
		else
                      	echo "failed while processing RCON password revision.  exiting."
                	exit 1
                fi
        	[[ -n "$_revision" ]] && commit "_revision" "SILENT"
		unset _revision ; unset _rev1

        fi # OTHERWISE, SKIP THIS.  IT IS NOT NEEDED YET.
	unset _contents
}

#-----[ RCON TINGS ]-----######################################################################
###############################################################################################

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#--[ WORKER FUNCTIONS ]--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#> THESE ARE MINE <3 Jay @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#

loading() {
        color white - -
	_1="$1"
        [[ -z "$2" ]] && echo -e -n "Loading"
        COUNTER="${_1:=1}"
        until [ "$COUNTER" -lt 0 ] ;
        do
                echo -e -n "."
                ping -c 1 127.0.0.1 > /dev/null || true
                (( COUNTER-- ))

        done
        [[ -n "$2" ]] && [[ "$2" == "END" ]] \
	  && color gray - bold \
	  && echo -e -n " Ready!\\n\\n" \
	  && color clear - unBold
        [[ -n "$2" ]] && [[ "$2" == "CONFIG" ]] \
	  && color lightYellow - bold \
	  && echo -e -n " More configuration is needed!\\n\\n" \
	  && color clear - unBold
	color - - clearAll
}

display_array_title() {
	printf "\\e[0m\\n"
	local _color ; local _title
	[[ -n "$2" ]] && _color="$1" || _color="none"
	[[ -n "$2" ]] && _title="$2" || _title="$1"
	[[ -z "$_title" ]] && echo "no title definition.  can't be right..." && exit 1

        case "$_color" in
  	      "red" ) printf "\\e[31m" ;;
            "green" ) printf "\\e[32m" ;;
           "yellow" ) printf "\\e[33m" ;;
	    "white" ) printf "\\e[97m" ;;
		  * ) printf "\\e[37m" ;; # Gray
	esac
	echo -e -n "\\t\\e[4m${_title}:\\e[0m\\n\\n" # Underlined / places colon & clears all format at end
}

display_array() {
	local _color_ ;	local _x_holder ; local _detail ; local _item
	_color_="\\e[0m\\e[37m" # gray is default
        for _item in "$@" ;
        do
		_detail="" ; _x_holder="" ;
		_x_holder=$(eval echo "_x_${_item:?}") ;

		if [ -n "$__X__" ] ;
		then
			_detail="\\t\\e[91m\\xC3\\x97 ${_color_:?}${_item:?}" ;

		elif [ -n "$__O__" ] ;
		then
			_detail="\\t\\e[92m\\xC2\\x95 ${_color_:?}${_item:?}" ;

		elif [ -n "${!_x_holder}" ] && [ -n "${!_item}" ] ;
		then
			if [ ! "${!_x_holder:?}" == "${!_item:?}" ] ;
			then
				_detail="\\t${_color_:?}\\xE2\\x80\\xA2 \\e[1m${_item:?} \\xE2\\x94\\x80 \\n" ;
				_detail+="\\t\\e[31m    - \\e[0m\\e[90m\\e[2m${!_x_holder:?}\\n" ;
				_detail+="\\t\\e[92m    + \\e[0m\\e[27m\\e[1m${!_item:?}\\n" ;
			fi

		elif [ -z "${!_item}" ] && [ -z "${!_x_holder}" ] ;
		then
			_detail="\\t${_color_:?}\\xE2\\x80\\xA2 ${_color_}$_item" ;

		elif [ -n "${!_x_holder}" ] && [ -z "${!_item}" ] ;
		then
			_detail="\\t${_color_:?}\\xE2\\x80\\xA2 ${_item:?}  \\e[91m\\xE2\\x9C\\x97 ${!_x_holder:?}" ;

		elif [ -z "${!_x_holder}" ] && [ -n "${!_item}" ] ;
		then
			_detail="\\t${_color_:?}\\xE2\\x80\\xA2 ${_item:?} \\xe2\\x86\\x92 ${!_item:?}" ;
		else
			_detail="\\t{_color_:?}\\xE2\\x80\\xA2 ${_item:?}" ;
		fi

		case "${_item:?}" in
		    red ) _color_="\\e[0m\\e[31m" ;;
		  green ) _color_="\\e[0m\\e[32m" ;;
		 yellow ) _color_="\\e[0m\\e[33m" ;;
		  white ) _color_="\\e[0m\\e[97m" ;;
		      * ) [[ -n "$_detail" ]] && echo -n -e "${_detail:?}\\e[0m\\n" ;;
		esac
        done
        printf "\\e[0m\\n" ;
	unset __X__ ; unset __O__ ; unset _color_ ; unset _detail ;
}

color(){    # COLOR FOR ALL THE TERMS!
  [[ ! "$2" ]] || [[ "$2" == "0" ]] && __back="clear"
  [[ ! "$1" ]] || [[ "$1" == "0" ]] && __fore="clear"
  local __fore ; __fore="$1"
  local __back ; __back="$2"
  local __dcor ; __dcor="$3"

  if [ "$__fore" != "-" ] ;
  then
    case "$__fore" in
       "clear") printf "\\e[39m";;
       "black") printf "\\e[30m";;
         "red") printf "\\e[31m";;
       "green") printf "\\e[32m";;
      "yellow") printf "\\e[33m";;
        "blue") printf "\\e[34m";;
     "magenta") printf "\\e[35m";;
        "cyan") printf "\\e[36m";;
   "lightGray") printf "\\e[37m";;
    "darkGray") printf "\\e[90m";;
    "lightRed") printf "\\e[91m";;
  "lightGreen") printf "\\e[92m";;
 "lightYellow") printf "\\e[93m";;
   "lightBlue") printf "\\e[94m";;
"lightMagenta") printf "\\e[95m";;
   "lightCyan") printf "\\e[96m";;
       "white") printf "\\e[97m";;
             *) printf "\\e[39m";;
    esac
  fi

  if [ "$__back" != "-" ] ;
  then
    case "$__back" in
       "clear") printf "\\e[49m";;
       "black") printf "\\e[40m";;
         "red") printf "\\e[41m";;
       "green") printf "\\e[42m";;
      "yellow") printf "\\e[43m";;
        "blue") printf "\\e[44m";;
     "magenta") printf "\\e[45m";;
        "cyan") printf "\\e[46m";;
   "lightGray") printf "\\e[47m";;
    "darkGray") printf "\\e[100m";;
    "lightRed") printf "\\e[101m";;
  "lightGreen") printf "\\e[102m";;
 "lightYellow") printf "\\e[103m";;
   "lightBlue") printf "\\e[104m";;
"lightMagenta") printf "\\e[105m";;
   "lightCyan") printf "\\e[106m";;
       "white") printf "\\e[107m";;
             *) printf "\\e[49m";;
    esac
  fi

  if [ "$__dcor" != "-" ] ;
  then
    case "$__dcor" in
        "bold") printf "\\e[1m";;
         "dim") printf "\\e[2m";;
   "underline") printf "\\e[4m";;
       "blink") printf "\\e[5m";;
      "invert") printf "\\e[7m";;
      "hidden") printf "\\e[8m";;
      "noBold") printf "\\e[21m";;
       "noDim") printf "\\e[22m";;
 "noUnderline") printf "\\e[24m";;
     "noBlink") printf "\\e[25m";;
    "noInvert") printf "\\e[27m";;
    "noHidden") printf "\\e[28m";;
    "clearAll") printf "\\e[0m";;
    esac
  fi
}

add_salt() {

	# default
	local _default_length_ ; _default_length_="64"

	# some vars
	local __salt ; local __stamp ; local __len ; local _shakerStamp ; local _salt ; local __shaker
	[[ -n "$1" ]] && __len="$1" || __len="$_default_length_"
	[[ -n "$2" ]] && __salt="$2" || __salt="default"
	[[ -n "$3" ]] && __stamp="$3"

	if ! [ "$1" -eq "$1" ] 2> /dev/null
	then
        	# using default
		__len="$_default_length_"
	else
		declare -i __len
		__len="$1"
	fi

	#random delim char
	_d=$(cat /dev/urandom | tr -dc "!#/:.~@+" | fold -w 1 | head -n 1)

	#make stamp
	if [ -n "$__stamp" ] ;
	then
		case "$__stamp" in
		  "date" ) _shakerStamp="${_d}$(date +%B${_d}%Y)" ;;
		       * ) _shakerStamp="${_d}$__stamp" ;;
		esac ;
		local __len="$(( $__len - ${#_shakerStamp} ))"
		[ "$__len" -lt 0 ] && __len=3 && _shakerStamp="${_shakerStamp:3}"
	fi

	# make salt
	case "$__salt" in
	  0 ) _salt="$(date +%s | sha256sum | base64 | head -c ${__len}; echo)" ;;
	  1 ) _salt=$(cat /dev/urandom | tr -dc "a-zA-Z0-9!@#&+~." | fold -w "$__len" | head -n 1) ;;
	  * ) _salt="$(date +%s | sha256sum | base64 | head -c ${__len}; echo)" ;;
	esac ;

	# if __stamp is empty, then just add salt / otherwise, add salt and the shaker stamp
	[ ! "$__stamp" ] && __shaker="${_salt}" || __shaker="${_salt}${_shakerStamp}"

	# This is needed to return for variable assignment
	echo "$__shaker"

}

stop_screen() {    # THIS STOPS A SCREEN SESSION.

  SCREEN_SESSION_NAME="fivem"
  echo "Quiting screen session '$SCREEN_SESSION_NAME' for FiveM (if applicable)"
  su "$SERVICE_ACCOUNT" -c "screen -XS '$SCREEN_SESSION_NAME' quit"
}

sleep() {

# Hold up N seconds
# Default (no args) is 10 seconds-ish
#
# usage:
#   sleep 5
#   sleep
#
  if [ -z "$1" ]; then
    count="10"
  else
    count="$1"
  fi
  ping -c "$count" 127.0.0.1 > /dev/null
}

#--[ WORKER FUNCTIONS BY OTHER PEOPLE ]--######################################################
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#--[ FUNCTIONS TYAT I DID NOT WRITE OR MAJORLY ALTER ]----------------------------------------#

######
#### THE DATABASE STUFF BELOW CAME FROM BERT VAN VRECKEM... TY! VERY GOOD WORK!!
#### Author: Bert Van Vreckem <bert.vanvreckem@gmail.com>
#### A non-interactive replacement for mysql_secure_installation
####

# Predicate that returns exit status 0 if the database root password
# is set, a nonzero exit status otherwise.
is_mysql_root_password_set() {
  ! mysqladmin --user=root status > /dev/null 2>&1
}

####
# Predicate that returns exit status 0 if the mysql(1) command is available,
# nonzero exit status otherwise.
is_mysql_command_available() {
  which mysql > /dev/null 2>&1
}

####
# CHECK FOR MYSQL
check_for_mysql() {
  if [ ! is_mysql_command_available ]; then
    echo "The MySQL/MariaDB client mysql(1) is not installed."
    exit 1
  fi
}

