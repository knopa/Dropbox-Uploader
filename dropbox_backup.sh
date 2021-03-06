#!/usr/bin/env bash

#Default configuration file
CONFIG_FILE=/etc/dropbox_backup.conf

if [[ -e $CONFIG_FILE ]]; then

    #Loading data... and change old format config if necesary.
    source "$CONFIG_FILE"

    #Checking the loaded data
    if [[ $MYSQL_USER == "" || $MYSQL_PASSWORD == "" || $MYSQL_HOST == "" ]]; then
        echo -ne "Error loading data from $CONFIG_FILE...\n"
        echo -ne "It is recommended to fix dropbox_backup.conf\n"
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
		
		echo -n " # Mysql databases with , as semicolon (if empty will use show databases): "
        read MYSQL_DATABASES
		
		echo -n " # Web pathes with , as semicolon: "
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
	if [[ $MYSQL_DATABASES ]]; then
		echo "MYSQL_DATABASES=$MYSQL_DATABASES" >> "$CONFIG_FILE"
	else
		echo "#MYSQL_DATABASES=" >> "$CONFIG_FILE"
	fi
	if [[ $WEB_PATH ]]; then
		echo "WEB_PATH=$WEB_PATH" >> "$CONFIG_FILE"
	else
		echo "#WEB_PATH=" >> "$CONFIG_FILE"
	fi
	
    exit 0
fi

BACKUP=/tmp/dropboxbackup/db
BACKUPFILE=/tmp/dropboxbackup/www
mkdir -p "$BACKUP"
mkdir -p "$BACKUPFILE"

MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
ZIP="$(which zip)"

if [[ -z $MYSQL_DATABASES ]]; then
MYSQL_DATABASES="$($MYSQL -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD -Bse 'show databases')"
fi

if [[ $MYSQL_DATABASES ]]; then
MYSQL_DATABASES=$(echo $MYSQL_DATABASES | tr "," "\n")
for db in $MYSQL_DATABASES
do
	if [[ $db != "mysql" && $db != "information_schema" ]]; then
	    FILE="$BACKUP/$db.sql.zip"
	    FILEDB="$BACKUP/$db.sql"
		$MYSQLDUMP --opt -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $db > "$FILEDB"
		$ZIP -j "$FILE" "$FILEDB"
		rm -f "$FILEDB"
	fi
done

$UPLOADER upload "$BACKUP" /
fi

if [[ $WEB_PATH ]]; then
WEB_PATH=$(echo $WEB_PATH | tr "," "\n")
for web in $WEB_PATH
do
  FILENAME=$(basename $web)
  $ZIP -r "$BACKUPFILE/$FILENAME.zip" $web 
done

$UPLOADER upload "$BACKUPFILE" /
fi
IFS=$OIFS
rm -rf "$BACKUP"
rm -rf "$BACKUPFILE"

exit 0