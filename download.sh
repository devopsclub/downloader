#!/ffp/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/config.ini

while read -r SHOWNAME SHOWLINK WHATTODO; do
	cp $FILEDIR/$SHOWNAME".files" $FILEDIR/$SHOWNAME."old"
	sleep 5
	wget "$SHOWLINK" -O $FILEDIR/$SHOWNAME".files"
	dos2unix -u $FILEDIR/$SHOWNAME".files"
	cat $FILEDIR/$SHOWNAME".files" | awk -F '/' '{print $7}' > $FILEDIR"/tmp.files"
	cat $FILEDIR/$SHOWNAME".old" | awk -F '/' '{print $7}' > $FILEDIR"/tmp.old"
	comm -23 $FILEDIR/"tmp.files" $FILEDIR/"tmp.old" >> $FILEDIR/"tmp.email"
	wget -t 3 -c -i $FILEDIR/$SHOWNAME".files" -P $DOWNLOADDIR/$SHOWNAME
	chmod a+rw $DOWNLOADDIR/$SHOWNAME
done < $SCRIPTDIR/list.txt

sleep 5

if [ -e $FILEDIR/"tmp.email" ]; then
	EMAILLINES=$(wc -l $FILEDIR/"tmp.email" | awk '{print $1}')
	if [ $EMAILLINES -gt 0 ]; then
		cat $FILEDIR/"tmp.email" | tr '\n' '!' | sed 's:!:\\n:g' > $FILEDIR/"tmp.email2"
		sleep 10
		curl --retry 3 -X POST --data-urlencode 'payload={"text": "New files are here!\n'$(cat $FILEDIR/"tmp.email2")'", "channel": "#general", "username": "DNS-320 downloader", "icon_emoji": ":space_invader:"}' $SLACK_HOOK -k
		sleep 10
	fi
fi

sleep 5

rm -f $FILEDIR"/tmp.files" 
rm -f $FILEDIR"/tmp.old" 
rm -f $FILEDIR/*.old
rm -f $FILEDIR/"tmp.email"
rm -f $FILEDIR/"tmp.email2"

cp $SCRIPTDIR/list.txt $SCRIPTDIR/list.tmp.txt

while read -r SHOWNAME SHOWLINK WHATTODO; do
	if [ "$WHATTODO" = "check" ]; then
		printf "$SHOWNAME $SHOWLINK $WHATTODO\n"
	fi
done < $SCRIPTDIR/list.tmp.txt > $SCRIPTDIR/list.txt

rm -f $SCRIPTDIR/list.tmp.txt