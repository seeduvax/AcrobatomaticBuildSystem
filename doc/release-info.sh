#!/bin/bash

outpfx=$PRJROOT/build/release
if [ "$JIRA_URL" == "" ]; then
	JIRA_URL=https://pforgerle.public.infrapub.fr.st.space.corp/jira
fi

mkdir -p $outpfx

echo "Enter subversion/jira password: "
read -s SVNPASS
SVN="svn --username $USER --password $SVNPASS --non-interactive --trust-server-cert"

if [ "$SVNROOT" == "" ]; then
	SVNROOT=`LANG=C $SVN info | fgrep "Repository Root" | cut -f 3 -d ' '`
fi
URLFROM=$SVNROOT/tags/$APP/$APP-$VPARENT
URLTO=$SVNROOT/tags/$APP/$APP-$VERSION


FROMLREV=`LANG=C $SVN info $URLFROM | fgrep "Last Changed Rev:" | cut -f 4 -d ' '`
FROMLREV=`expr $FROMLREV + 1`
echo "Getting from file list..."
$SVN ls -R --xml $URLFROM > $outpfx-ls-from.xml
echo "Getting to file list..."
$SVN ls -R --xml $URLTO > $outpfx-ls-to.xml
echo "Getting from/to diff list..."
$SVN diff --xml --summarize --notice-ancestry --old=$URLFROM --new=$URLTO | sed -e "s!$URLFROM/!!g" > $outpfx-diff.xml
echo "Getting commit log..."
$SVN log --xml $URLTO -v -r $FROMLREV:HEAD > $outpfx-log.xml
$SVN export $URLTO tmp$$
echo "Computing checksum..."
echo '<?xml version="1.0"?>
<checksum type="sha256">' > $outpfx-checksum.xml
find tmp$$ -type f | xargs -d '\n' sha256sum | sed -e "s!tmp$$/!!g" | while read crc path
do
     echo '<entry path="'$path'" checksum="'$crc'"/>' >> $outpfx-checksum.xml
done
echo '</checksum>' >> $outpfx-checksum.xml
rm -rf tmp$$/
echo "Getting issues..."
curl -D- -u "$USER:$SVNPASS" -k -X GET -H "Content-Type: application/json" $JIRA_URL/rest/api/2/search?jql=issue%20in%20linkedIssues%28%22$VISSUE%22%2C%22is%20parent%20task%20of%22%29 -o $outpfx-issues.json
echo '<?xml version="1.0" encoding="utf-8"?>
<issues parent="'$VISSUE'">' > $outpfx-issues.xml
(
 export IFS='!' 
 cat $outpfx-issues.json | jq '.issues[]| @html "\(.key)!\(.fields.resolution.name)!\(.fields.issuetype.name)!\(.fields.summary)"' | sed -e 's/^"//g' | sed -e 's/"$//g' | while read key completion type summary
 do
    echo '<issue key="'$key'" completion="'$completion'" type="'$type'">'"$summary"'</issue>' >> $outpfx-issues.xml
 done
 echo '</issues>' >> $outpfx-issues.xml
)

