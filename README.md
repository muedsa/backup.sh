# backup.sh

备份由LNMP创建的网站与数据库，并上传备份文件到百度云。

Backup LNMP's websites and mysql databases, then upload backup files to BaiduPCS

## Before this

You need download and install [BaiduPCS-GO](https://github.com/iikira/BaiduPCS-Go/releases/latest).

Choose one right version for you ,and unzip to your dir.


Then login your baidu account.
```
# Maybe you need to give 'BaiduPCS-Go' run permission.
chmod -X BaiduPCS-Go 
# or
chmod 755 BaiduPCS-Go 

# Login
BaiduPCS-Go login
```

## Run
```
bash backup.sh
```