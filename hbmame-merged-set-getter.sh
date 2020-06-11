#!/bin/bash
#USE AT YOUR OWN RISK - THIS COMES WITHOUT WARRANTE AND MAY KILL BABY SEALS.
#A /media/fat/Scripts/update_hbmame-getter.ini file may be used to set custom location for your MAME files and MRA files.
#Add the following line to the ini file to set a directory for MRA files: MRADIR=/top/path/to/mra/files
#Add the following line to the ini file to set a directory for MAME files: HBMAMEDIR=/path/to/hbmame
###############################################################################
#set -x

######VARS#####

HBMAMEDIR="/media/fat/_Arcade/hbmame"
MRADIR="/media/fat/_Arcade"
INIFILE="/media/fat/Scripts/update_hbmame-getter.ini"

#####INI FILES VARS######

INIFILE_FIXED=$(mktemp)
if [[ -f "${INIFILE}" ]] ; then
	dos2unix < "${INIFILE}" 2> /dev/null > ${INIFILE_FIXED}
fi


# Warning! ROMDIR is deprecated in favor of HBMAMEDIR. Don't use it!
if [ `grep -c "ROMDIR=" "${INIFILE_FIXED}"` -gt 0 ]
   then
      echo "ROMDIR ini property has been renamed HBMAMEDIR."
      HBMAMEDIR=`grep "ROMDIR" "${INIFILE_FIXED}" | awk -F "=" '{print$2}' | sed -e 's/^"//' -e 's/"$//'`
fi 2>/dev/null


if [ `grep -c "HBMAMEDIR=" "${INIFILE_FIXED}"` -gt 0 ]
   then
      HBMAMEDIR=`grep "HBMAMEDIR" "${INIFILE_FIXED}" | awk -F "=" '{print$2}' | sed -e 's/^"//' -e 's/"$//'`
fi 2>/dev/null 


if [ `grep -c "MRADIR=" "${INIFILE_FIXED}"` -gt 0 ]
   then
      MRADIR=`grep "MRADIR=" "${INIFILE_FIXED}" | awk -F "=" '{print$2}' | sed -e 's/^"//' -e 's/"$//'`
fi 2>/dev/null 

mkdir -p ${HBMAMEDIR}

#####INFO TXT#####

if [ `egrep -c "MRADIR|HBMAMEDIR|ROMDIR" "${INIFILE_FIXED}"` -gt 0 ]
   then
      echo ""
      echo "Using "${INIFILE}"" 
      echo ""
fi 2>/dev/null 

rm ${INIFILE_FIXED}

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
      
  cat /tmp/hbmame.getter.zip.file | sed 's/\/hbmame\///g' | while read f
  do

   if [ $(grep -ic hbmame "`head -1 /tmp/hbmame.getter.mra.file`") -ge 1 ]
      then
  
    if [ ! -f "${HBMAMEDIR}/${f}" ]
       then
 
          if [ `grep -c -Fx "${f}" /tmp/hbmame-merged-set-getter.sh` -gt 0 ]
             then

                if [ x"${f}" != x ]
                   then
                      echo ""
                      echo "MRA: `head -1 /tmp/hbmame.getter.mra.file`" 
                      MRA=`head -1 /tmp/hbmame.getter.mra.file`
                      echo "ZIP: "${f}"" 
          
                      if [ x$(grep "mameversion" "`head -1 /tmp/hbmame.getter.mra.file`" | sed 's/<mameversion>//' | sed 's/<\/mameversion>//'| sed 's/[[:blank:]]//g') != x ]
                         then
                            VER=$(grep "mameversion" "`head -1 /tmp/hbmame.getter.mra.file`" | sed 's/<mameversion>//' | sed 's/<\/mameversion>//'| sed 's/[[:blank:]]//g' | sed -e 's/\r//' | sed 's/[a-zA-Z]//')
                            echo $VER
                      else
                         #echo "Ver: version not in MRA"
                         VER=XXX
                      fi 

#####DOWNLOAD#####

                case "$VER" in
                    #--hopfully will see more souces in the future. 
                  0217)
                           wget -q -nc -t 3 --output-file=/tmp/wget-log --no-check-certificate --show-progress -O  "${HBMAMEDIR}"/"${f}" "https://archive.org/download/hbmame0217"/"${f}"
                            ;;
                  0220)
                           echo "MAME version not listed in MRA or there is no download source for the version, downloading from .220 set"
                           wget -q -nc -t 3 --output-file=/tmp/wget-log --no-check-certificate --show-progress -O  "${HBMAMEDIR}"/"${f}" "https://archive.org/download/hbmame0220"/"${f}"
                            ;;
                  0221)
                           wget -q -nc -t 3 --output-file=/tmp/wget-log --no-check-certificate --show-progress -O  "${HBMAMEDIR}"/"${f}" ""https://archive.org/download/hbmame0221aroms/"${f}"
                            ;;
                     *)
                           echo "MAME version not listed in MRA or there is no download source for the version, downloading from .220 set"
                           wget -q -nc -t 3 --output-file=/tmp/wget-log --no-check-certificate --show-progress -O  "${HBMAMEDIR}"/"${f}" "https://archive.org/download/hbmame0220"/"${f}"
                            ;;
                 esac               
 
#####CLEAN UP######

                      if [ ! -s "$HBMAMEDIR"/"${f}" ]
                         then
                            echo ""
                            echo "0 byte file found for "${f}"!"
                            echo "This happens when the file is missing or unavalible from the download source."
                            rm -v "${HBMAMEDIR}"/"${f}"
                            echo ""
           fi

        fi
     fi  

 fi 

fi
  done
}

if [ ${#} -ge 1 ] ; then
   echo ""
   echo "${#} arguments provided, this script expect them to be valid .mra files."
   echo ""
   echo "Skipping HBMAME files that already exist"
   echo ""
   echo "Downloading ROMs to "${HBMAMEDIR}" - Be Patient!!!"
   echo ""
   sleep 5
   printf '%s\n' "$@" | grep -o ".*\.[mM][rR][aA]" | sort | while read i
   do
      download_hbmame_roms_from_mra "${i}"
   done
else
   echo ""
   echo "Finding all .mra files in "${MRADIR}" and in recursive directores."
   echo ""
   echo "`find "${MRADIR}" -name \*.mra | grep -v _Organized | wc -l` .mra files found."
   echo ""
   echo "Skipping HBMAME files that already exist"
   echo ""
   echo "Downloading ROMs to "${HBMAMEDIR}" - Be Patient!!!"
   echo ""
   sleep 5

   ####FIND NEEDED ROMS FROM MRA FILES####

   find "${MRADIR}" -name \*.mra | grep -v _Organized | sort | while read i
   do
      download_hbmame_roms_from_mra "${i}"
   done
fi

rm /tmp/hbmame.getter.zip.file
rm /tmp/hbmame.getter.mra.file

echo ""
echo "Finished Downloading!" 
exit

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
