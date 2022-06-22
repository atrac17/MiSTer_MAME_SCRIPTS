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
#A update_hbmame-getter.ini file may be used to set custom location for your MAME files and MRA files.
#Add the following line to the ini file to set a directory for MRA files: MRADIR=/top/path/to/mra/files
#Add the following line to the ini file to set a directory for MAME files: ROMHBMAME=/path/to/hbmame
###################################################################################
#set -x

######INFO#####
if [ -d "/media/fat/_Arcade/hbmame" ] ; then
   echo
   echo "INFO: As of 6/11/2020 the default directory has been changed to /media/fat/games/hbmame"
   echo "INFO: Please move all roms from /media/fat/_Arcade/hbmame/* to /media/fat/games/hbmame/"
   echo "INFO: You may still set a custom ROMHBMAME path in update_hbmame-getter.ini if needed"
   sleep 5
fi
######VARS#####

ROMHBMAME="/media/fat/games/hbmame"
MRADIR="/media/fat/_Arcade"
INSTALL="false"
INIFILE="$(pwd)/update_hbmame-getter.ini"

CURL_RETRY="${CURL_RETRY:---connect-timeout 15 --max-time 300 --retry 3 --retry-delay 5 --show-error}"
SSL_SECURITY_OPTION="${SSL_SECURITY_OPTION:---insecure}"

rm /tmp/hbmame_getter_errors 2> /dev/null || true

#####INI FILES VARS#######

INIFILE_FIXED=$(mktemp)
if [[ -f "${INIFILE}" ]] ; then
	dos2unix < "${INIFILE}" 2> /dev/null > ${INIFILE_FIXED}
fi


# Warning! ROMDIR is deprecated in favor of ROMHBMAME. Don't use it!
if [ `grep -c "ROMDIR=" "${INIFILE_FIXED}"` -gt 0 ]
   then
      echo "ROMDIR ini property has been renamed ROMHBMAME."
      ROMHBMAME=`grep "ROMDIR" "${INIFILE_FIXED}" | awk -F "=" '{print$2}' | sed -e 's/^ *//' -e 's/ *$//' -e 's/^ *"//' -e 's/" *$//'`
fi 2>/dev/null


if [ `grep -c "ROMHBMAME=" "${INIFILE_FIXED}"` -gt 0 ]
   then
      ROMHBMAME=`grep "ROMHBMAME" "${INIFILE_FIXED}" | awk -F "=" '{print$2}' | sed -e 's/^ *//' -e 's/ *$//' -e 's/^ *"//' -e 's/" *$//'`
fi 2>/dev/null 


if [ `grep -c "MRADIR=" "${INIFILE_FIXED}"` -gt 0 ]
   then
      MRADIR=`grep "MRADIR=" "${INIFILE_FIXED}" | awk -F "=" '{print$2}' | sed -e 's/^ *//' -e 's/ *$//' -e 's/^ *"//' -e 's/" *$//'`
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
            ROMHBMAME="${GAMESDIR}/${SYSTEM}"
            mkdir -p $ROMHBMAME
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

GETTER_DO hbmame

#####INFO TXT#####

if [ `egrep -c "MRADIR|ROMHBMAME|ROMDIR|INSTALL|CURL_RETRY" "${INIFILE_FIXED}"` -gt 0 ]
   then
      echo ""
      echo "Using "${INIFILE}"" 
      echo ""
fi 2>/dev/null 

rm ${INIFILE_FIXED}

###############################
HBMAME_GETTER_VERSION="1.0"
#########Auto Install##########
if [[ "${INSTALL^^}" == "TRUE" ]] && [ ! -e "/media/fat/Scripts/update_hbmame-getter.sh" ]
   then
      echo "Downloading update_hbmame-getter.sh to /media/fat/Scripts"
      echo ""
      curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --location -o "/media/fat/Scripts/update_hbmame-getter.sh" https://raw.githubusercontent.com/MAME-GETTER/MiSTer_MAME_SCRIPTS/master/update_hbmame-getter.sh || true
      echo
fi

download_hbmame_roms_from_mra() {
   local MRA_FILE="${1}"
   echo "${MRA_FILE}" > /tmp/hbmame.getter.mra.file

   #find double quotes zip names
   grep ".zip=" "${MRA_FILE}" | sed 's/.*\(zip=".*\)\.zip.*/\1/' | awk -F '"' '{print$2".zip"}' | sed s/\|/\\n/g | sort -u | grep -v ^.zip | sed 's/\/hbmame\///g' > /tmp/hbmame.getter.zip.file

   #find single quotes zip names
   grep ".zip=" "${MRA_FILE}" | sed -n 's/^.*'\''\([^'\'']*\)'\''.*$/\1/p'| sed s/\|/\\n/g | sort -u | grep -v ^.zip | sed 's/\/hbmame\///g' > /tmp/hbmame.getter.zip.file2

   #put both files togther
   cat /tmp/hbmame.getter.zip.file >> /tmp/hbmame.getter.zip.file2

   sort -u /tmp/hbmame.getter.zip.file2 > /tmp/hbmame.getter.zip.file
   rm /tmp/hbmame.getter.zip.file2

   FIRST_ZIP="true"

   cat /tmp/hbmame.getter.zip.file | sed 's/\/hbmame\///g' | while read f
   do
      ZIP_PATH="${ROMHBMAME}/${f}"
      if [ ! -f "${ZIP_PATH}" ] && \
      [ $(grep -ic hbmame "${MRA_FILE}") -ge 1 ] && \
      [ `grep -c -Fx "${f}" /tmp/hbmame-merged-set-getter.sh` -gt 0 ] && \
      [ x"${f}" != x ]
      then
         if [[ "${FIRST_ZIP}" == "true" ]] ; then
            echo "MRA: ${MRA_FILE}"
            FIRST_ZIP="false"
         fi
         echo -n "ZIP: ${f} "

         if [ x$(grep "mameversion" "${MRA_FILE}" | sed 's/<mameversion>//' | sed 's/<\/mameversion>//'| sed 's/[[:blank:]]//g') != x ]
         then
            VER=$(grep "mameversion" "${MRA_FILE}" | sed 's/<mameversion>//' | sed 's/<\/mameversion>//'| sed 's/[[:blank:]]//g' | sed -e 's/\r//' | sed 's/[a-zA-Z]//')
            echo "(Ver ${VER})"
         else
            echo
            #echo "Ver: version not in MRA"
            VER=XXX
         fi

         #####DOWNLOAD#####

         case "$VER" in
            #--hopfully will see more souces in the future.
            '0217')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/hbmame0217/${f}"
                     ;;
            '0220')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/hbmame0220/${f}"
                     ;;
            '0221')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/hbmame0221aroms/${f}"
                     ;;
            '0222')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/hbmame0222roms${f}"
                     ;;
	    '0224')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/hbmame0224roms/${f}"
                     ;;	
	    '0226')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/HBmame0.226-romsmerged/${f}"
                     ;;
	    '0227')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/HBmame0.227-romsmerged/${f}"
                     ;;
	    '0228')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/HBmame0.228-romsmerged/${f}"
                     ;;	
	    '0229')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/HBmame0.229-romsmerged/${f}"
                     ;;
	    '0230')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/HBmame0.230-romsmerged/${f}"
                     ;;
            '0244')
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/hbmame_0244_roms/${f}"
                     ;;
	   	
            *)
                  echo "MAME version not listed in MRA or there is no download source for the version, downloading from 0.244 set"
                  curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${ZIP_PATH}" "https://archive.org/download/hbmame_0244_roms/${f}"
                     ;;
         esac

         #####CLEAN UP######

         CURL_RESULT=$?

         if [[ "${CURL_RESULT}" == "28" ]] ; then
            touch /tmp/hbmame_getter_errors
            echo ""
            echo "cURL error for "${f}"!"
            echo "Try increase the max time of CURL_RETRY if the error persists."
            rm -v "$ROMHBMAME"/"${f}" || true
         elif [ ! -s "$ROMHBMAME"/"${f}" ] ; then
            echo ""
            echo "0 byte file found for "${f}"!"
            echo "This happens when the file is missing or unavailable from the download source."
            rm -v "${ROMHBMAME}"/"${f}"
            touch /tmp/hbmame_getter_errors
         fi

         echo
      fi
   done
}

hbmame_getter_optimized() {
   local CACHE_HBMAME_GETTER_PATH="/media/fat/Scripts/.cache/hbmame-getter"
   local CONFIG_HBMAME_GETTER_PATH="/media/fat/Scripts/.config/hbmame-getter"
   mkdir -p "/media/fat/Scripts/.config"
   [ -d "${CACHE_HBMAME_GETTER_PATH}" ] && mv "${CACHE_HBMAME_GETTER_PATH}" "${CONFIG_HBMAME_GETTER_PATH}"

   local WORK_PATH="/media/fat/Scripts/.config/hbmame-getter"
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
   if [ ! -d "${ROMHBMAME}/" ] || \
      (( $(du -s "${ROMHBMAME}/" | awk '{print $1}') < 512 ))
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
   FIND_ARGS+=("${MRADIR}" -iname \*HBMame.mra)
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
         echo "No new MRAs with HBMAME roms detected"
         echo
         echo "Skipping HBMAME Getter..."
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
   echo "Skipping HBMAME files that already exist"
   echo
   echo "Downloading ROMs to "${ROMHBMAME}" - Be Patient!!!"
   echo
   sleep 5

   IFS=$'\n'
   MRA_FROM_FILE=($(cat ${UPDATED_MRAS}))
   unset IFS

   rm "${UPDATED_MRAS}"

   for i in "${MRA_FROM_FILE[@]}" ; do
      download_hbmame_roms_from_mra "${i}"
   done

   if [ ! -f /tmp/hbmame_getter_errors ] ; then
      echo "${HBMAME_GETTER_VERSION}" > "${LAST_RUN_PATH}"
      echo "${INI_DATE}" >> "${LAST_RUN_PATH}"
      echo "${MRA_DATE}" >> "${LAST_RUN_PATH}"
   fi
}

if [ ${#} -eq 2 ] && [ ${1} == "--input-file" ] ; then

   MRA_INPUT="${2:-}"
   if [ ! -f ${MRA_INPUT} ] ; then
      echo "Option --input-file selected, but file '${MRA_INPUT}' does not exist."
      echo "Usage: ./${0} --input-file file"
      exit 1
   fi

   echo ""
   echo "$(wc -l ${MRA_INPUT} | awk '{print $1}') arguments provided, this script expects them to be valid .mra files."
   echo ""
   echo "Skipping HBMAME files that already exist"
   echo ""
   echo "Downloading ROMs to "${ROMHBMAME}" - Be Patient!!!"
   echo ""
   sleep 5
   IFS=$'\n'
   MRA_FROM_FILE=($(cat ${MRA_INPUT}))
   unset IFS
   printf '%s\n' "${MRA_FROM_FILE[@]}" | while read i
   do
      download_hbmame_roms_from_mra "${i}"
   done
elif [ ${#} -eq 1 ] && [ ${1} == "--optimized" ] ; then
   hbmame_getter_optimized
elif [ ${#} -eq 1 ] && [ ${1} == "--print-ini-options" ] ; then
   echo MRADIR=\""${MRADIR}\""
   echo ROMHBMAME=\""${ROMHBMAME}\""
   echo INSTALL=\""${INSTALL}\""
   exit 0
elif [ ${#} -ge 1 ] ; then
   echo "Invalid arguments."
   echo "Usage: ./${0} --input-file file"
   exit 1
else
   hbmame_getter_optimized
fi

rm /tmp/hbmame.getter.zip.file
rm /tmp/hbmame.getter.mra.file

if [ ! -f /tmp/hbmame_getter_errors ] ; then
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

#####MERGED .220 LIST######
##HBMAME .220 LIST
1942.zip
1943.zip
1943kai.zip
1944.zip
19xx.zip
2020bb.zip
3countb.zip
3wonders.zip
aa.zip
absurd.zip
airwolf.zip
akiradmo.zip
aliencha.zip
alienres.zip
alpaca8.zip
alpha1v.zip
alpham2.zip
alpine.zip
altbeast.zip
amidar.zip
androdun.zip
aof.zip
aof2.zip
aof3.zip
aoh.zip
arabianm.zip
arkanoid.zip
armwar.zip
asteroid.zip
astrob.zip
astrof.zip
asuka.zip
asurabld.zip
asurabus.zip
atarisy1.zip
avsp.zip
b2b.zip
bace.zip
badapple.zip
baddudes.zip
bagman.zip
bakatono.zip
bangbead.zip
batcir.zip
batsugun.zip
bbugtest.zip
beast.zip
bgaregga.zip
bjourney.zip
blandia.zip
blazstar.zip
blktiger.zip
bloodbro.zip
bloodwar.zip
bombjack.zip
bonzeadv.zip
breakers.zip
breakrev.zip
brival.zip
brubber.zip
bsmt2000.zip
bstars.zip
btime.zip
bublbob2.zip
bublbobl.zip
burningf.zip
c2frog.zip
cabal.zip
cameltry.zip
captcomm.zip
caravan.zip
cawing.zip
cball.zip
cchip.zip
cclimber.zip
centiped.zip
ckong.zip
cleopatr.zip
cnbe.zip
cndi.zip
coh1000c.zip
coh1002m.zip
coh3002c.zip
columnsn.zip
commando.zip
contra.zip
cphd.zip
cps1demo.zip
cps1frog.zip
crashh.zip
crswd2bl.zip
crsword.zip
csclub.zip
cthd2k3b.zip
ctomaday.zip
cyberlip.zip
cybots.zip
dankuga.zip
daraku.zip
dariusg.zip
dbz.zip
dbz2.zip
dderby.zip
ddonpach.zip
ddragon2.zip
ddsom.zip
ddsprdmo.zip
ddtod.zip
deadconx.zip
deathsml.zip
decocass.zip
decomult.zip
defender.zip
deroon.zip
didemo.zip
dimahoo.zip
dino.zip
dinorex.zip
dkong.zip
doapp.zip
dondokod.zip
dorunrun.zip
dotrikun.zip
doubledr.zip
dragons1.zip
dragoona.zip
drmario.zip
drtoppel.zip
dstlk.zip
dti.zip
dwi.zip
ecofghtr.zip
eightman.zip
elvactr.zip
evilston.zip
exerion.zip
eyes.zip
f2demo.zip
f3demo.zip
fatfursp.zip
fatfury1.zip
fatfury2.zip
fatfury3.zip
fbfrenzy.zip
ffeast.zip
ffight.zip
fghthist.zip
fightfev.zip
fireshrk.zip
flipshot.zip
flstory.zip
fourplay.zip
fr2.zip
frogger.zip
frontlin.zip
fstarfrc.zip
ga2.zip
gaia.zip
galaga.zip
galaxyfg.zip
galnamco.zip
ganryu.zip
garou.zip
garoupy.zip
gaunt2.zip
gaxeduel.zip
gbi.zip
gekiridn.zip
gemini.zip
gground.zip
ghostlop.zip
ghouls.zip
gigawing.zip
ginganin.zip
gnw_bride.zip
gnw_squeeze.zip
goalx3.zip
gowcaizr.zip
gpilots.zip
gradius3.zip
grdians.zip
groovef.zip
growl.zip
gseeker.zip
gunbird2.zip
gunfront.zip
hbmame0220_archive.torrent
hbmame0220_files.xml
hbmame0220_meta.sqlite
hbmame0220_meta.xml
hook.zip
hsf2.zip
igla.zip
indytemp.zip
insectx.zip
invaders.zip
invmulti.zip
iocero.zip
ironclad.zip
itecdemo.zip
jockeygp.zip
jojobanc.zip
jojonc.zip
joyjoy.zip
jrpacman.zip
jumpbugx.zip
kabukikl.zip
kaiserkn.zip
kangaroh.zip
karatblz.zip
karnovr.zip
ket.zip
kf2k3pcb.zip
kicker.zip
kikikai.zip
killbld.zip
killbldp.zip
kingdmgp.zip
kizuna.zip
knacki.zip
knckhead.zip
knights.zip
kod.zip
kof2000.zip
kof2001.zip
kof2002.zip
kof2003.zip
kof2k4se.zip
kof94.zip
kof95.zip
kof96.zip
kof97.zip
kof98.zip
kof99.zip
kof99hp.zip
konamigx.zip
kotm.zip
kotm2.zip
kov.zip
kov2.zip
kov2p.zip
kovplus.zip
kovsh.zip
kovshp.zip
kurikint.zip
landmakr.zip
lastblad.zip
lastbld2.zip
lasthope.zip
lazybug.zip
lbowling.zip
lernit.zip
lhb2.zip
lightbr.zip
liquidk.zip
lkage.zip
lnc.zip
lresort.zip
ltorb.zip
m68705p3.zip
m68705p5.zip
m68705r3.zip
m68705u3.zip
madpac.zip
magdrop3.zip
maglord.zip
mappy.zip
mario.zip
martmast.zip
matrim.zip
mbombrd.zip
megablst.zip
megaman.zip
megaman2.zip
mercs.zip
metamrph.zip
metmqstr.zip
mhavoc.zip
midcsd.zip
midssio.zip
miexchng.zip
milliped.zip
minasan.zip
mineswp.zip
missile.zip
mitcdemo.zip
mjdchuka.zip
mjelctrn.zip
mjmyster.zip
mjreach1.zip
mk.zip
mk2.zip
mmatrix.zip
mmaulers.zip
model1io.zip
monaco.zip
monstrz.zip
mooncrst.zip
mosyougi.zip
mpang.zip
mpatrol.zip
mrdo.zip
mrdonm.zip
ms5pcb.zip
msgundam.zip
msh.zip
mshvsf.zip
mslug.zip
mslug2.zip
mslug3.zip
mslug4.zip
mslug5.zip
mslugx.zip
mspacman.zip
mspacmnx.zip
mtlchamp.zip
mtturbo.zip
multi15.zip
mutantf.zip
mutnat.zip
mvsc.zip
nam1975.zip
namco50.zip
namco51.zip
namco52.zip
namco53.zip
namco54.zip
namcoc65.zip
namcoc68.zip
namcoc69.zip
namcoc70.zip
namcoc74.zip
namcoc75.zip
namcoc76.zip
nbajamte.zip
nbbatman.zip
ncombat.zip
ncommand.zip
neo2500.zip
neo3d.zip
neobombe.zip
neobubble.zip
neocstlv.zip
neocup98.zip
neodemo.zip
neodrift.zip
neofight.zip
neogal1.zip
neogeo.zip
neonopon.zip
neopong.zip
neoromjb.zip
neothund.zip
neotrisd1.zip
ngem2k.zip
ngftdemo.zip
ngmontst.zip
ngtd2.zip
ngtetris.zip
ngym2610.zip
ninjamas.zip
nitd.zip
nmk004.zip
nwarr.zip
nyan.zip
olds.zip
oldsplus.zip
orlegend.zip
outrun.zip
overtop.zip
pachello.zip
pacland.zip
pacmatri.zip
pactest.zip
pang.zip
pbobble.zip
pbobble2.zip
pbobblen.zip
pc_ark.zip
pc_bb2.zip
pc_cch.zip
pc_ctfrc.zip
pc_digdg.zip
pc_dk.zip
pc_dk3.zip
pc_galag.zip
pc_gyrus.zip
pc_krsty.zip
pc_mman5.zip
pc_pacm.zip
pc_parsl.zip
pc_skykd.zip
pcktgal.zip
pcmademo.zip
pcmbdemo.zip
pengo.zip
pgemeni.zip
pgm.zip
pgmdemo.zip
pgmfrog.zip
phelios.zip
phoenix.zip
pickin.zip
pipibibs.zip
pisces.zip
playch10.zip
plegends.zip
plotting.zip
pnickj.zip
pnyaa.zip
poknight.zip
polepos.zip
pooyan.zip
powerins.zip
ppong.zip
pr8210.zip
preisle2.zip
progear.zip
pspikes2.zip
puckman.zip
puckmanx.zip
pulstar.zip
punisher.zip
puzzledp.zip
pwrinst2.zip
px320a.zip
pzloop2.zip
qbert.zip
qsound_hle.zip
rabbit.zip
ragnagrd.zip
rainboh.zip
rallyx.zip
raroggame.zip
rastan.zip
rbff1.zip
rbff2.zip
rbffspec.zip
rci.zip
redeartn.zip
renju.zip
retofinv.zip
rezon.zip
ridhero.zip
ringdest.zip
roboarmy.zip
robocop.zip
robotron.zip
roishtar.zip
rotd.zip
rygar.zip
s1945ii.zip
s1945iii.zip
s1945p.zip
sagaiav2.zip
sailormn.zip
salamand.zip
samantha.zip
samsh5sp.zip
samsho.zip
samsho2.zip
samsho3.zip
samsho4.zip
samsho5.zip
santabll.zip
sarge.zip
savagere.zip
sblast2b.zip
schasrcv.zip
schmeisr.zip
scramble.zip
sdodgeb.zip
seafight.zip
segabill.zip
sengoku.zip
sengoku2.zip
sengoku3.zip
seq1.zip
sf.zip
sf2.zip
sf2ce.zip
sfa.zip
sfa2.zip
sfa3.zip
sfex.zip
sfex2.zip
sfex2p.zip
sfexp.zip
sfiii2nc.zip
sfiii3nc.zip
sfiiinc.zip
sfz2al.zip
sfzch.zip
sgemf.zip
shadfrce.zip
shaman16.zip
shocktr2.zip
shocktro.zip
shogwarr.zip
shollow.zip
sidepckt.zip
silkroad.zip
silkworm.zip
simutrek.zip
skimaxx.zip
slammast.zip
smi.zip
snddemo.zip
snowbro2.zip
snowbros.zip
socbrawl.zip
sokoban.zip
soldivid.zip
solomon.zip
sonicwi2.zip
sonicwi3.zip
spacmissx.zip
spacwarp.zip
spcinv95.zip
speccies.zip
spf2t.zip
spicegirls.zip
spinmast.zip
splat.zip
spriteex.zip
sqij.zip
srallyc.zip
ssf2.zip
ssf2t.zip
ssideki.zip
ssideki4.zip
ssriders.zip
sstriker.zip
stakwindev.zip
stinger.zip
strhoop.zip
strider.zip
stvbios.zip
suicide.zip
suikoenb.zip
superabc.zip
superpac.zip
superspy.zip
suprmrio.zip
survarts.zip
svc.zip
sys16dem.zip
syscheck.zip
taotaido.zip
tapper.zip
targ.zip
tdragon.zip
tdragon2.zip
teetert.zip
tehkanwc.zip
tempest.zip
tengai.zip
tenkai.zip
terracre.zip
test01.zip
theglad.zip
theroes.zip
thundfox.zip
timelimt.zip
timeplt.zip
timesupd.zip
tinyworld.zip
tkdensho.zip
tldemo.zip
tldemo2.zip
tmnt2.zip
tmnti.zip
tms32030.zip
tms32031.zip
tms32032.zip
tophuntr.zip
totc.zip
tpgolf.zip
trackfld.zip
trally.zip
tron.zip
tst_gor1.zip
tst_gorf.zip
tst_pacm.zip
tst_wow2.zip
tst_wow3.zip
turfmast.zip
twcup90.zip
twincobr.zip
twinspri.zip
twister.zip
tws96.zip
uccops.zip
umk3.zip
vantris.zip
varth.zip
vhunt2.zip
videight.zip
viewpoin.zip
viostorm.zip
vlad2000.zip
volfied.zip
votrax.zip
vsav.zip
vsav2.zip
wakuwak7.zip
warrior.zip
wbeast.zip
wbml.zip
wh1.zip
wh2.zip
wh2j.zip
whp.zip
willow.zip
wjammers.zip
wmg.zip
wof.zip
wofch.zip
ww2demo.zip
xevious.zip
xmas2017.zip
xmcota.zip
xmvsf.zip
xymg.zip
yiear.zip
ym2608.zip
zap.zip
zeroteam.zip
zintrckb.zip
zupapa.zip
