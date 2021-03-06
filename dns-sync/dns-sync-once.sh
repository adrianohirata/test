#! /bin/bash
###
# Short-Description: Synchronizes /etc/resolv.conf in WLS with Windows DNS - RUNS ONCE
# Description: Updated to keep codepage so it won't change the console font
#              Original script by Matthias Brooks https://gist.github.com/matthiassb/9c8162d2564777a70e3ae3cbee7d2e95
### 

PATH=/sbin:/bin:/mnt/c/WINDOWS/system32
PS=/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe

. /lib/init/vars.sh
. /lib/lsb/init-functions


oemcp=$(reg.exe query "HKLM\\SYSTEM\\CurrentControlSet\\Control\\Nls\\CodePage" /v OEMCP | sed -n 3p | sed -e 's|\r||g' | grep -o '[[:digit:]]*')
chcp.com $oemcp > /dev/null

#Retrieve nameservers from via Powershell
TEMPFILE=$(mktemp)
$PS -Command "Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses" > $TEMPFILE
/usr/bin/awk '!x[$0]++' $TEMPFILE > $TEMPFILE.2
IFS=$'\r\n' GLOBIGNORE='*' command eval  'UNIQUE_NAMESERVERS=($(cat $TEMPFILE.2))'
rm -f $TEMPFILE $TEMPFILE.2

#Retrive search domains via powershell
IFS=$'\r\n' GLOBIGNORE='*' command eval  'SEARCH_DOMAIN=($($PS -Command "Get-DnsClientGlobalSetting | Select-Object -ExpandProperty SuffixSearchList"))'
UNIQUE_SEARCH_DOMAIN=($(/usr/bin/tr ' ' '\n' <<< "${SEARCH_DOMAIN[@]}" | /usr/bin/sort -u | /usr/bin/tr '\n' ' '))

chcp.com $oemcp > /dev/null
# 65001

#Modify /etc/resolv.conf
touch /etc/resolv.conf
sed -i '/nameserver/d' /etc/resolv.conf > /dev/null 2>&1 || true
sed -i '/search/d' /etc/resolv.conf > /dev/null 2>&1 || true

for i in "${UNIQUE_NAMESERVERS[@]}"
do
      echo "nameserver ${i}" >> /etc/resolv.conf
done
if [ ${#UNIQUE_SEARCH_DOMAIN[@]} -ne 0 ]; then
  echo "search ${UNIQUE_SEARCH_DOMAIN[@]}" >> /etc/resolv.conf
fi
          
