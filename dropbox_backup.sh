#!/usr/bin/env bash

#Default configuration file
CONFIG_FILE=~/.dropbox_backup

if [[ -e $CONFIG_FILE ]]; then

    #Loading data... and change old format config if necesary.
    source "$CONFIG_FILE" 2>/dev/null || {
        sed -i'' 's/:/=/' "$CONFIG_FILE" && source "$CONFIG_FILE" 2>/dev/null
    }

    #Checking the loaded data
    if [[ $MYSQL_USER == "" || $MYSQL_PASSWORD == "" || $MYSQL_HOST == "" || $MYSQL_DATABASES == "" ]]; then
        echo -ne "Error loading data from $CONFIG_FILE...\n"
        echo -ne "It is recommended to fix .dropbox_backup\n"
        exit 1
    fi

#NEW SETUP...
else
    echo -ne "\n This is the first time you run this script.\n\n"

    #Getting the app key and secret from the user
    while (true); do
		echo -n " # Dropbox uploader path: "
        read UPLOADER
		
        echo -n " # Mysql user: "
        read MYSQL_USER

        echo -n " # Mysql password: "
        read MYSQL_PASSWORD

		echo -n " # Mysql host: "
        read MYSQL_HOST
		
		echo -n " # Mysql databases with ; as semicolon: "
        read MYSQL_DATABASES
		
		echo -n " # Web pathes with ; as semicolon: "
        read WEB_PATH
		
        echo -ne "\n > Dropbox uploader is $UPLOADER\n Mysql user is $MYSQL_USER\n Mysql password is $MYSQL_PASSWORD\n Mysql databases are $MYSQL_DATABASES  \n Web pathes are $WEB_PATH.\n Looks ok? [y/n]: "
        read answer
        if [[ $answer == "y" ]]; then
            break;
        fi

    done
	#Saving data in new format, compatible with source command.
	echo "UPLOADER=$UPLOADER" > "$CONFIG_FILE"
	echo "MYSQL_USER=$MYSQL_USER" >> "$CONFIG_FILE"
	echo "MYSQL_PASSWORD=$MYSQL_PASSWORD" >> "$CONFIG_FILE"
	echo "MYSQL_HOST=$MYSQL_HOST" >> "$CONFIG_FILE"
	echo "MYSQL_DATABASES=$MYSQL_DATABASES" >> "$CONFIG_FILE"
	echo "WEB_PATH=$WEB_PATH" >> "$CONFIG_FILE"
	
    exit 0
fi

BACKUP=/tmp/dropboxbackup/db
BACKUPFILE=/tmp/dropboxbackup/www
mkdir -p "$BACKUP"
mkdir -p "$BACKUPFILE"

MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
ZIP="$(which zip)"
MYSQL_DATABASES=${MYSQL_DATABASES//;/$'\n'}

if [[ $MYSQL_DATABASES ]]; then
for db in $MYSQL_DATABASES
do
 FILE=$BACKUP/$db.zip
 $MYSQLDUMP --opt -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $db | $ZIP -9 > $FILE
done
fi
$UPLOADER upload "$BACKUP" /

WEB_PATH=${WEB_PATH//;/$'\n'}
if [[ $WEB_PATH ]]; then
for web in $WEB_PATH
do
  FILENAME=$(basename $web)
  $ZIP -r "$BACKUPFILE/$FILENAME.zip" $web 
done

$UPLOADER upload "$BACKUPFILE" /
fi

rm -rf "$BACKUP"
rm -rf "$BACKUPFILE"

exit 0