#!/bin/sh

docker exec paperless-webserver-1 document_exporter ../export

TIMESTAMP=`date "+%Y-%m-%dT%H-%M-%S"`
SOURCEDIR=~/paperless/export/
TARGETDIR=~/syncthing/sync/paperless-backup

# Create new backup using rsync and output to log
rsync -avP --delete --link-dest=$TARGETDIR/current/ $SOURCEDIR $TARGETDIR/$TIMESTAMP > ~/log/rsync/$TIMESTAMP.log 2>&1

# check exit status to see if backup failed
if [ "$?" = 0 ]; then
    # Remove link to current backup
    rm -rf $TARGETDIR/current
    # Create link to the newest backup
    ln -s $TARGETDIR/$TIMESTAMP $TARGETDIR/current
elif [ -d "$TARGETDIR/$TIMESTAMP" ]; then
    # Rename directory if failed
    mv $TARGETDIR/$TIMESTAMP $TARGETDIR/failed-$USER-$TIMESTAMP
else
    echo "Something went wrong, please consult the docs"
fi

# This prevents rsync from doing incremental backups, therefore it's not active for now
# rm -r --interactive=never $SOURCEDIR*
