if [ -z $5 ]; then
  echo "Usage : sh runclients <java-applet-file> <swf-file> <executable-flash-player-path> <hostname(same-as-swf)> <number-of-tests>"
  exit 0
fi
MMCFG_FILE=~/mm.cfg
if [ ! -e $MMCFG_FILE ]; then
  echo "ErrorReportingEnable=1\nTraceOutputFileEnable=1" > $MMCFG_FILE
fi
applet=$1
swf=$2
curdir=$(pwd)
flashplayer=$3
hostname=$4
testnum=$5
APPLET_RESULTS=appletresults.txt
FLASH_RESULTS=flashresults.txt
for (( i=1; i<=$testnum; i++ ))
do
  echo "Start Java test $i (time $(date -u))" >> $APPLET_RESULTS
  java -jar $applet $hostname >> $APPLET_RESULTS &
  javapid=$!
  sleep 90
  kill $javapid
  echo "Start Flash test $i (time $(date -u))" >> $FLASH_RESULTS
  cd $flashplayer
  ./flashplayerdebugger $curdir/$swf &
  flashpid=$!
  sleep 90
  kill $flashpid
  cd $curdir
  cat ~/.macromedia/Flash_Player/Logs/flashlog.txt >> $FLASH_RESULTS
done
echo "Completed"
