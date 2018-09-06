#!/bin/bash
# ----------------------------------------------------------------------
# name:         backup.sh
# version:      1.0
# createTime:   20168-09-06
# description:  backup LNMP's websites and mysql databases, then upload backup files to BaiduPCS(you need install BaiduPCS-GO from https://github.com/iikira/BaiduPCS-Go and login your baidu account)
# author:       muedsa
# website:      https://wwww.muedsa.com
# github:       https://github.com/muedsa/backup.sh
# lnmp website: https://lnmp.org/
# ----------------------------------------------------------------------

# Config (Before run this script, you need to modify these variables)

# dir for saving backup file
BACKUP_SAVE_PATH='/home/backup/'

# if is 0, script will auto backup all dirs in 'BACKUP_DIR_PATH'
IS_BACKUP_ALL_DIR=0
BACKUP_DIR_PATH='/home/wwwroot/'
#else , script will backup dirs in 'BACKUP_DIRS'
BACKUP_DIRS=('/home/wwwroot/default' '/home/wwwroot/yoursite1' '/home/wwwroot/yoursite2')

# mysql cmd path
CMD_MYSQL='/usr/local/mysql/bin/mysql'
# mysqldump cmd path
CMD_MYSQLJUMP='/usr/local/mysql/bin/mysqldump'

# mysql username and password
MYSQL_USERNAME='root'
MYSQL_PASSWORD='password'

# if is 0, script will auto backup all database in your mysql username
IS_BACKUP_ALL_DATABASE=0
# exclude these databases
# +--------------------+
# | Database           |
# +--------------------+
# | information_schema |
# | mysql              |
# | performance_schema |
# | test               |
# +--------------------+
# plase add no-backup databases, not delete these default databases
EXCLUDE_DATABASES=("Database" "mysql" "information_schema" "performance_schema" "test")
# else, script will backup databases  in 'BACKUP_DATABASES'
BACKUP_DATABASES=('yourdatabase1', 'yourdatabase2')

# if is 0, upload backup files to BaiduPCS
IS_UPLOAD_BAIDUPCS=0
CMD_BAIDUPCS_GO="/root/BaiduPCS-Go/BaiduPCS-Go" # BaiduPCS-Go cmd path
UPLOAD_PACH="/LNMP_BACKUP" # upload to the dir
# if is 0, delete old backup files from BaiduPCS
IS_DELETE_BAIDUPCS_OLD_FILE=1

NEW_BACKUP_FILE_WWW=www-*-$(date +"%Y%m%d").tar.gz
NEW_BACKUP_FILE_SQL=db-*-$(date +"%Y%m%d").sql
OLD_BACKUP_FILE_WWW=www-*-$(date -d -3day +"%Y%m%d").tar.gz
OLD_BACKUP_FILE_SQL=db-*-$(date -d -3day +"%Y%m%d").sql

Backup_Dir()
{
    Backup_Path=$1
    echo "BACKUP DIR: ${Backup_Path}"
    Dir_Name=`echo ${Backup_Path##*/}`
    Pre_Dir=`echo ${Backup_Path}|sed 's/'${Dir_Name}'//g'`
    tar zcf ${BACKUP_SAVE_PATH}www-${Dir_Name}-$(date +"%Y%m%d").tar.gz -C ${Pre_Dir} ${Dir_Name}
}

Get_DataBases(){
    TEMP_FILE=/tmp/temp_file_$RANDOM
    touch $TEMP_FILE
    $CMD_MYSQL -u$MYSQL_USERNAME -p$MYSQL_PASSWORD <<EOF >$TEMP_FILE
show databases;
EOF
    i=0
    BACKUP_DATABASES=()
    while read line; do
        if [[ "${EXCLUDE_DATABASES[@]}" != *$line* ]] ;then
            let "i++"
            BACKUP_DATABASES[$i]=$line
            echo "BACKUP DATABASE: ${BACKUP_DATABASES[$i]}"
        fi
    done < $TEMP_FILE
}

Backup_Sql()
{
    ${CMD_MYSQLJUMP} -u$MYSQL_USERNAME -p$MYSQL_PASSWORD $1 > ${BACKUP_SAVE_PATH}db-$1-$(date +"%Y%m%d").sql
}

# check something
if [ ! -f ${CMD_MYSQL} ]; then  
    echo "mysql not found, please modify config."
    exit 1
fi

if [ ! -f ${CMD_MYSQLJUMP} ]; then  
    echo "mysqljump not found, please modify config."
    exit 1
fi

if [ ! -f ${CMD_BAIDUPCS_GO} ]; then  
    echo "BaiduPCS-Go not found, please modify config."
    exit 1
fi

if [ ! -d ${BACKUP_SAVE_PATH} ]; then  
    mkdir -p ${BACKUP_SAVE_PATH}
fi

# backup website files
echo "Backup website files..."
if [ ${IS_BACKUP_ALL_DIR} = 0 ]; then
    for dd in $(ls -l ${BACKUP_DIR_PATH} |awk '/^d/ {print $NF}');do
        Backup_Dir ${BACKUP_DIR_PATH}${dd}
    done
else
    for dd in ${BACKUP_DIRS[@]}; do
        Backup_Dir ${dd}
    done
fi

# backup databases
echo "Backup database files..."
if [ ${IS_BACKUP_ALL_DATABASE} = 0 ]; then
    Get_DataBases
fi

for db in ${BACKUP_DATABASES[@]};do
    Backup_Sql ${db}
done

# delete old files
echo "Delete old backup files..."
rm -f ${BACKUP_SAVE_PATH}${OLD_BACKUP_FILE_WWW}
rm -f ${BACKUP_SAVE_PATH}${OLD_BACKUP_FILE_SQL}

# uploading backup files to BaiduPCS
if [ ${IS_UPLOAD_BAIDUPCS} = 0 ]; then
    echo "Uploading backup files to BaiduPCS..."
    if [ ${IS_DELETE_BAIDUPCS_OLD_FILE} = 0 ]; then
        ${CMD_BAIDUPCS_GO} rm ${UPLOAD_PACH}/${OLD_BACKUP_FILE_WWW}
        ${CMD_BAIDUPCS_GO} rm ${UPLOAD_PACH}/${OLD_BACKUP_FILE_SQL}
    fi
    ${CMD_BAIDUPCS_GO} u ${BACKUP_SAVE_PATH}${NEW_BACKUP_FILE_WWW} ${UPLOAD_PACH}
    ${CMD_BAIDUPCS_GO} u ${BACKUP_SAVE_PATH}${NEW_BACKUP_FILE_SQL} ${UPLOAD_PACH}
    echo "upload complete."
fi

echo "end."