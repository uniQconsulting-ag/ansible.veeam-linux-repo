#!/bin/bash
# DESC: analysiert die aktuelle last und zieht die Daten für eine kSar auswertung
# WHO: cruettimann@uniqconsulting.ch
# DATE: 20190314

P=$$
logDir=/var/log/VeeamBackup
jobLog=$logDir/$HOSTNAME-veeamjobHistory.txt
sarLog=$logDir/$HOSTNAME-sarReport.txt
mailto="support@uniqconsulting.ch"
startP=' srv.*cleanup .* started'
stopP=' session has finished'

for p in mailx awk sort
do 
   which $p >/dev/null 2>&1 || (echo "ERROR: $p is not installed")
done

(
echo "JobCount,Date,Task,Job"
C=0 # start with zero jobs
cd $logDir || exit 1
# loop each job directory for logs
(ls -1d */ | while read line
do
   job="$(echo $line | cut -d'/' -f1)"
   f="$(ls -1tr $job/*.log | tail -1)"
   # examine start and stop patterns
   (egrep "$startP" $f | cut -d: -f-2 | cut -c2- | sed 's/ /:/' | sort -un | sed "s/$/,start,$job/g" 
   egrep "$stopP" $f | cut -d: -f-2 | cut -c2- | sed 's/ /:/' | sort -un | sed "s/$/,stop,$job/g")|\
   # remove restore jobs, sort by date, remove stop if it is first entry (we want to start with start job)
   grep -v restore | sort -t. -k3n -k2n -k1n -k4n -k5n | sed '0,/,stop,/ d'
done) | grep -v restore | sort -t. -k3n -k2n -k1n -k4n -k5n | while read line
do
   # count concurrent jobs
   echo $line | grep -q ,start, && C=$(($C + 1)) 
   echo $line | grep -q ,stop, && C=$(($C - 1)) 
   echo $C,$line
done) | tr ',' '\t' | column -t > $jobLog

> $sarLog
ls -1 /var/log/sa/sa?? | while read f; do LC_ALL=C sar -bBdqrRSuvwWy -I SUM -I XALL -u ALL -P ALL -r -f $f >> $sarLog; done

echo "
Dies ist eine performance Auswertunng

Host: $(uname -n)
vCPU: $(cat /proc/cpuinfo  | grep physical\ id | wc -l)
RAM: $(free -h | grep Mem: | awk '{print $2}')
NFS Shares:
$(df -hP | head -1 | sed 's/^/      /')
$(df -hP | grep nfs | sed 's/^/      /')

Datum: $(date '+%Y.%m.%d %H:%M')

Anhang:
    Eine History, welche Jobs wann und gleichzeitig gelaufen sind
  - $( basename $jobLog)
    kSar formatierte performance Daten: https://github.com/vlsi/ksar/releases
  - $( basename $sarLog)

" | mailx -s "Linux Veeam Backup Repository Agent Report" -a $sarLog -a $jobLog $mailto

sleep 5
mailq
