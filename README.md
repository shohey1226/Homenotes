# $HOME/notes

"$Home/notes" is a light wight knowledge base.

If you work as IT engineer, you may store notes/docs under home directory.
The purpose of this is to share the notes to everyone to make people productive :)

See - http://homenotes.iworlddesigner.com 

## Dependency 
* Perl
* MySQL 
* mroonga(http://mroonga.org) as fulltext search engine

## How to build $HOME/notes

### 0.Install prerequisite

 - install MySQL
 - install mroonga
 - Carton (Perl module)

### 1. git clone & carton install 

### 2. Create databse

DB: knowhow3
id: xx
pass: yyy

    $ mysql -uroot -p
    mysql> create database knowhow3;
    mysql> grant all on knowhow3.* to xx@localhost identified by "yyy";
    $ mysql -uxx -p -D knowhow3 < ./script/db_schema.sql
    $ vi ./etc/homenotes.conf
    
### 3. Start WebUI
    
    $ ./script/start_homenotes

## License

MIT License
