#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#USE AT YOUR OWN RISK - THIS COMES WITHOUT WARRANTE AND MAY KILL BABY SEALS.
#A update_mame-getter.ini file may be used to set custom location for your MAME files and MRA files.
#Add the following line to the ini file to set a directory for MRA files: MRADIR=/top/path/to/mra/files
#Add the following line to the ini file to set a directory for MAME files: ROMMAME=/path/to/mame
#####################################################################################
#set -x
######INFO#####
if [ -d "/media/fat/_Arcade/mame" ] ; then
   echo
   echo "INFO: As of 6/11/2020 the default directory has been changed to /media/fat/games/mame"
   echo "INFO: Please move all roms from /media/fat/_Arcade/mame/* to /media/fat/games/mame/"
   echo "INFO: You may still set a custom ROMMAME path in update_mame-getter.ini if needed"
   sleep 5
fi
######VARS#####

ROMMAME="/media/fat/games/mame"
MRADIR="/media/fat/_Arcade"
INSTALL="false"
INIFILE="$(pwd)/update_mame-getter.ini"

CURL_RETRY="${CURL_RETRY:---connect-timeout 15 --max-time 300 --retry 3 --retry-delay 5 --show-error}"
SSL_SECURITY_OPTION="${SSL_SECURITY_OPTION:---insecure}"

rm /tmp/mame_getter_errors 2> /dev/null || true
#####INI FILES VARS######

INIFILE_FIXED=$(mktemp)
if [[ -f "${INIFILE}" ]] ; then
	dos2unix < "${INIFILE}" 2> /dev/null > ${INIFILE_FIXED}
fi

# Warning! ROMDIR is deprecated in favor of ROMMAME. Don't use it!
if [ `grep -c "ROMDIR=" "${INIFILE_FIXED}"` -gt 0 ]
   then
      echo "ROMDIR ini property has been renamed ROMMAME."
      ROMMAME=`grep "ROMDIR" "${INIFILE_FIXED}" | awk -F "=" '{print$2}' | sed -e 's/^ *//' -e 's/ *$//' -e 's/^"//' -e 's/"$//'`
fi 2>/dev/null


if [ `grep -c "ROMMAME=" "${INIFILE_FIXED}"` -gt 0 ]
   then
      ROMMAME=`grep "ROMMAME" "${INIFILE_FIXED}" | awk -F "=" '{print$2}' | sed -e 's/^ *//' -e 's/ *$//' -e 's/^"//' -e 's/"$//'`
fi 2>/dev/null 


if [ `grep -c "MRADIR=" "${INIFILE_FIXED}"` -gt 0 ]
   then
      MRADIR=`grep "MRADIR=" "${INIFILE_FIXED}" | awk -F "=" '{print$2}' | sed -e 's/^ *//' -e 's/ *$//' -e 's/^"//' -e 's/"$//'`
fi 2>/dev/null

if [ `grep -c "INSTALL=" "${INIFILE_FIXED}"` -gt 0 ]
   then
      INSTALL=`grep "INSTALL=" "${INIFILE_FIXED}" | awk -F "=" '{print$2}' | sed -e 's/^ *//' -e 's/ *$//' -e 's/^ *"//' -e 's/" *$//'`
fi 2>/dev/null

if [ `grep -c "CURL_RETRY=" "${INIFILE_FIXED}"` -gt 0 ]
   then
      CURL_RETRY=`grep "CURL_RETRY=" "${INIFILE_FIXED}" | awk -F "=" '{print$2}' | sed -e 's/^ *//' -e 's/ *$//' -e 's/^"//' -e 's/"$//'`
fi 2>/dev/null

GAMESDIR_FOLDERS=( \
    /media/usb0/games \
    /media/usb1/games \
    /media/usb2/games \
    /media/usb3/games \
    /media/usb4/games \
    /media/usb5/games \
    /media/fat/cifs/games \
    /media/fat/games \
)

GETTER_DO()
{
    local SYSTEM="${1}"

    shift

    GET_SYSTEM_FOLDER "${SYSTEM}"
    local SYSTEM_FOLDER="${GET_SYSTEM_FOLDER_RESULT}"
    local GAMESDIR="${GET_SYSTEM_FOLDER_GAMESDIR}"

    if [[ "${SYSTEM_FOLDER}" != "" ]]
        then
            ROMMAME="${GAMESDIR}/${SYSTEM}"
            mkdir -p $ROMMAME
    fi	
}

GET_SYSTEM_FOLDER_GAMESDIR=
GET_SYSTEM_FOLDER_RESULT=
GET_SYSTEM_FOLDER()
{
    GET_SYSTEM_FOLDER_GAMESDIR="/media/fat/games"
    GET_SYSTEM_FOLDER_RESULT=
    local SYSTEM="${1}"
    for folder in ${GAMESDIR_FOLDERS[@]}
    do
        local RESULT=$(find "${folder}" -maxdepth 1 -type d -iname "${SYSTEM}" -printf "%P\n" -quit 2> /dev/null)
        if [[ "${RESULT}" != "" ]] ; then
            GET_SYSTEM_FOLDER_GAMESDIR="${folder}"
            GET_SYSTEM_FOLDER_RESULT="${RESULT}"
            break
        fi
    done
}

GETTER_DO mame

#####INFO TXT#####

if [ `egrep -c "MRADIR|ROMMAME|ROMDIR|INSTALL|CURL_RETRY" "${INIFILE_FIXED}"` -gt 0 ]
   then
      echo ""
      echo "Using "${INIFILE}"" 
      echo ""
fi 2>/dev/null 

rm ${INIFILE_FIXED}

###############################
MAME_GETTER_VERSION="1.0"
#########Auto Install##########
if [[ "${INSTALL^^}" == "TRUE" ]] && [ ! -e "/media/fat/Scripts/update_mame-getter.sh" ]
   then
      echo "Downloading update_mame-getter.sh to /media/fat/Scripts"
      echo ""
      curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --location -o "/media/fat/Scripts/update_mame-getter.sh" https://raw.githubusercontent.com/MAME-GETTER/MiSTer_MAME_SCRIPTS/master/update_mame-getter.sh || true
      echo
fi



download_mame_roms_from_mra() {
   local MRA_FILE="${1}"
   echo "${MRA_FILE}" > /tmp/mame.getter.mra.file

   #find double quotes zip names
   grep ".zip=" "${MRA_FILE}" | sed 's/.*\(zip=".*\)\.zip.*/\1/' | awk -F '"' '{print$2".zip"}' | sed s/\|/\\n/g | sort -u | grep -v ^.zip > /tmp/mame.getter.zip.file

   #find sigle quotes zip names
   grep ".zip=" "${MRA_FILE}" | sed -n 's/^.*'\''\([^'\'']*\)'\''.*$/\1/p'| sed s/\|/\\n/g | sort -u | grep -v ^.zip > /tmp/mame.getter.zip.file2

   #put both files togther
   cat /tmp/mame.getter.zip.file >> /tmp/mame.getter.zip.file2

   sort -u /tmp/mame.getter.zip.file2 > /tmp/mame.getter.zip.file
   rm /tmp/mame.getter.zip.file2

   FIRST_ZIP="true"

   cat /tmp/mame.getter.zip.file | while read f
   do
      ZIP_PATH="${ROMMAME}/${f}"
      if [ ! -f "${ZIP_PATH}" ] && \
      [ $(grep -ic hbmame "${MRA_FILE}") -eq 0 ] && \
      [ `grep -c -Fx "${f}" /tmp/mame-merged-set-getter.sh` -gt 0 ] && \
      [ x"${f}" != x ]
      then
         if [[ "${FIRST_ZIP}" == "true" ]] ; then
            echo "MRA: ${MRA_FILE}"
            FIRST_ZIP="false"
         fi
         echo -n "ZIP: ${f} "

         if [ x$(grep "mameversion" "${MRA_FILE}" | sed 's/<mameversion>//' | sed 's/<\/mameversion>//'| sed 's/[[:blank:]]//g'| head -1) != x ]
         then
            VER=$(grep "mameversion" "${MRA_FILE}" | sed 's/<mameversion>//' | sed 's/<\/mameversion>//'| sed 's/[[:blank:]]//g' | sed -e 's/\r//' | head -1)
            echo "(Ver ${VER})"
         else
            echo
            #echo "Ver: version not in MRA"
            VER=XXX
         fi

         #####DOWNLOAD#####

         case "$VER" in

            '0229')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/mame.0229/${f}"
                     ;;	  
            '0230')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/mame.0230.revival/${f}"
                     ;;	  
            '0231')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/mame.0231/${f}"
                     ;;	  
            '0232')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/mame.0232/${f}"
                     ;;	  
            '0233')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/mame.0233/${f}"
                     ;;	  
            '0234')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/mame.0234/${f}"
                     ;;	  
            '0235')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/mame.0235/${f}"
                     ;;	  
            '0236')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/mame.0236/${f}"
                     ;;	  
            '0237')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/mame.0237/${f}"
                     ;;	  
            '0238')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/mame.0238/${f}"
                     ;;	  
            '0239')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/mame.0239/${f}"
                     ;;	  
            '0240')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/mame.0240/${f}"
                     ;;	  
            'darksoft_neogeo')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/mister_neogeo/${f}"
                     ;;	  
            *)
                  echo "MAME version not listed in MRA or there is no download source for the version, downloading from .240 set"
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/mame.0240/${f}"
                     ;;
         esac

         #####CLEAN UP######

         CURL_RESULT=$?

         if [[ "${CURL_RESULT}" == "28" ]] ; then
            touch /tmp/mame_getter_errors
            echo ""
            echo "cURL error for "${f}"!"
            echo "Try increase the max time of CURL_RETRY if the error persists."
            rm -v "$ROMMAME"/"${f}" || true
         elif [ ! -s "$ROMMAME"/"${f}" ] ; then
            ouch /tmp/mame_getter_errors
            echo ""
            echo "0 byte file found for "${f}"!"
            echo "This happens when the file is missing or unavailable from the download source."
            rm -v "${ROMMAME}"/"${f}"
         fi

         echo
      fi
   done
}

mame_getter_optimized() {
   local CACHE_MAME_GETTER_PATH="/media/fat/Scripts/.cache/mame-getter"
   local CONFIG_MAME_GETTER_PATH="/media/fat/Scripts/.config/mame-getter"
   mkdir -p "/media/fat/Scripts/.config"
   [ -d "${CACHE_MAME_GETTER_PATH}" ] && mv "${CACHE_MAME_GETTER_PATH}" "${CONFIG_MAME_GETTER_PATH}"

   local WORK_PATH="/media/fat/Scripts/.config/mame-getter"
   mkdir -p "${WORK_PATH}"

   local INI_DATE=
   if [ -f "${INIFILE}" ] ; then
      INI_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ" -d "$(stat -c %y "${INIFILE}" 2> /dev/null)")
   fi

   local LAST_RUN_PATH="${WORK_PATH}/last_run"

   local LAST_INI_DATE=
   local LAST_MRA_DATE=
   if [ -f "${LAST_RUN_PATH}" ] ; then
      LAST_INI_DATE=$(cat "${LAST_RUN_PATH}" | sed '2q;d')
      LAST_MRA_DATE=$(cat "${LAST_RUN_PATH}" | sed '3q;d')
   fi

   echo
   local FROM_SCRATCH="false"
   if [ ! -d "${ROMMAME}/" ] || \
      (( $(du -s "${ROMMAME}/" | awk '{print $1}') < 10000 ))
   then
      FROM_SCRATCH="true"
      echo "Inexistent or small rom folder detected."
      echo
   fi

   if [[ "${LAST_MRA_DATE}" =~ ^[[:space:]]*$ ]] || \
      ! date -d "${LAST_MRA_DATE}" > /dev/null 2>&1
   then
      FROM_SCRATCH="true"
      echo "No previous runs detected."
      echo
   fi

   if [[ "${INI_DATE}" != "${LAST_INI_DATE}" ]] ; then
      FROM_SCRATCH="true"
      echo "INI file has been modified."
      echo
   fi

   local ORGDIR_FOLDERS="${WORK_PATH}/../arcade-organizer/orgdir-folders"

   FIND_ARGS=()
   FIND_ARGS+=("${MRADIR}" \( ! -iname \*HBMame.mra \) -iname \*.mra)
   if [ -s "${ORGDIR_FOLDERS}" ] ; then
      while IFS="" read -r p || [ -n "${p}" ] ; do
         FIND_ARGS+=(-not -ipath "${p}/*")
      done < "${ORGDIR_FOLDERS}"
   else
      FIND_ARGS+=(-not -ipath "${MRADIR}/_Organized/*")
   fi

   if [[ "${FROM_SCRATCH}" == "false" ]] ; then
      FIND_ARGS+=(-newerct ${LAST_MRA_DATE})
   fi

   local UPDATED_MRAS=$(mktemp)
   local MRA_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

   find "${FIND_ARGS[@]}" | sort > ${UPDATED_MRAS}

   local TOTAL_MRAS="$(wc -l ${UPDATED_MRAS} | awk '{print $1}')"
   if [[ "${FROM_SCRATCH}" == "true" ]] ; then
      echo "Performing a full update."
      echo
      echo "Finding all .mra files in "${MRADIR}" and in recursive directores."
      echo ""
      echo "${TOTAL_MRAS} .mra files found in total."
   else
      if [ ${TOTAL_MRAS} -eq 0 ] ; then
         echo "No new MRAs with MAME roms detected"
         echo
         echo "Skipping MAME Getter..."
         echo
         exit 0
      fi
      echo "Performing an incremental update."
      echo "NOTE: Remove following file if you wish to force a full update."
      echo " - ${LAST_RUN_PATH}"
      echo
      echo "Found ${TOTAL_MRAS} new MRAs that may require new roms."
   fi
   echo
   echo "Skipping MAME files that already exist"
   echo
   echo "Downloading ROMs to "${ROMMAME}" - Be Patient!!!"
   echo
   sleep 5

   IFS=$'\n'
   MRA_FROM_FILE=($(cat ${UPDATED_MRAS}))
   unset IFS

   rm "${UPDATED_MRAS}"

   for i in "${MRA_FROM_FILE[@]}" ; do
      download_mame_roms_from_mra "${i}"
   done

   if [ ! -f /tmp/mame_getter_errors ] ; then
      echo "${MAME_GETTER_VERSION}" > "${LAST_RUN_PATH}"
      echo "${INI_DATE}" >> "${LAST_RUN_PATH}"
      echo "${MRA_DATE}" >> "${LAST_RUN_PATH}"
   fi
}

if [ ${#} -eq 2 ] && [ "${1}" == "--input-file" ] ; then

   MRA_INPUT="${2:-}"
   if [ ! -f ${MRA_INPUT} ] ; then
      echo "Option --input-file selected, but file '${MRA_INPUT}' does not exist."
      echo "Usage: ./${0} --input-file file"
      exit 1
   fi

   echo ""
   echo "$(wc -l ${MRA_INPUT} | awk '{print $1}') arguments provided, this script expects them to be valid .mra files."
   echo ""
   echo "Skipping MAME files that already exist"
   echo ""
   echo "Downloading ROMs to "${ROMMAME}" - Be Patient!!!"
   echo ""
   sleep 5
   IFS=$'\n'
   MRA_FROM_FILE=($(cat ${MRA_INPUT}))
   unset IFS
   printf '%s\n' "${MRA_FROM_FILE[@]}" | while read i
   do
      download_mame_roms_from_mra "${i}"
   done
elif [ ${#} -eq 1 ] && [ ${1} == "--optimized" ] ; then
   mame_getter_optimized
elif [ ${#} -eq 1 ] && [ ${1} == "--print-ini-options" ] ; then
   echo MRADIR=\""${MRADIR}\""
   echo ROMMAME=\""${ROMMAME}\""
   echo INSTALL=\""${INSTALL}\""
   exit 0
elif [ ${#} -ge 1 ] ; then
   echo "Invalid arguments."
   echo "Usage: ./${0} --input-file file"
   exit 1
else
   mame_getter_optimized
fi

rm /tmp/mame.getter.zip.file
rm /tmp/mame.getter.mra.file

if [ ! -f /tmp/mame_getter_errors ] ; then
   echo
   echo "SUCCESS!"
   echo
   exit 0
else
   echo
   echo "Some error happened. Try again later!"
   echo
   exit 1
fi
