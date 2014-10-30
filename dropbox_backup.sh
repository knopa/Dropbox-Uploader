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
		
		echo -n " # Mysql databases: "
        read MYSQL_DATABASES
		
        echo -ne "\n > Dropbox uploader is $UPLOADER, Mysql user is $MYSQL_USER, Mysql password is $MYSQL_PASSWORD and Mysql databases are $MYSQL_DATABASES. Looks ok? [y/n]: "
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
	
    exit 0
fi

BACKUP=/tmp/dropboxbackup/db
mkdir -p "$BACKUP"

MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
ZIP="$(which zip)"
MYSQL_DATABASES=${MYSQL_DATABASES//;/$'\n'}

for db in $MYSQL_DATABASES
do
 FILE=$BACKUP/$db.zip
 $MYSQLDUMP --opt -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $db | $ZIP -9 > $FILE
done

$UPLOADER upload "$BACKUP" /

rm -rf "$BACKUP"

exit 0