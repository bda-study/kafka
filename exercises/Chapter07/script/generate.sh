#/bin/sh

# Author: chancethecoder
#
# get random picked 10 lines from log file in weblogs directory
# tested on OSX

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
DATADIR=$SCRIPTPATH/../data

mkdir -p $DATADIR/weblogs

RANDOM_PICK="$(ls $DATADIR/weblogs | sort -R | head -n1)"

sort -R $DATADIR/weblogs/$RANDOM_PICK | head -n 10 >> $DATADIR/weblogs.log

echo "data generated..."