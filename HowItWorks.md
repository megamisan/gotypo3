# Introduction #

GoTYPO3 is a set of scripts designed to be stored on a web server and then downloaded and executed with the use of a single command.

GoTYPO3 is composed of a launcher, a main script and a set of modules that can be called by the main script.

See HowToInstall for installation instructions and HowToUse for usage instructions.


# File Structure #

The install.sh script generates the following file structure in the directory where GoTYPO3 is installed :

```
  |---/launcher.sh
  |
  |---/gotypo3.sh
  |
  |---/modules_list.txt
  |
  |---/modules/
          |
          |---/100_debian-lenny.sh
          |
          |---/200_vhost.sh
          |
          |---/250_ftp_users.sh
          |
          |---/300_typo3.sh
          |
          |---/...
```

  * `launcher.sh` and `gotypo3.sh` are the two main scripts of GoTYPO3.
  * `modules_list.txt` contains a list of all available modules.
  * `modules` directory contains the modules scripts and the resources they need.

# Execution #

The following command is used to execute GoTYPO3 from command line with root privileges :

```
wget -O - http://gotypo3.server.net/launcher.sh | bash
```

This way the content of `launcher.sh` is directly interpreted by bash. The presence of a configuration file is checked in /opt/ics/gotypo/conf.local and global configuration variables are set.

Then `gotypo3.sh` is downloaded and executed, the user selects a list of modules to execute and those modules are downloaded and executed one after another.

```
    -------------
   | launcher.sh |----> defines global configuration
    -------------   |-> downloads and executes gotypo3.sh
          |
          |
     ------------
    | gotypo3.sh |----> handles modules selection 
     ------------   |-> downloads and executes selected modules
          |      
          |       
      ---------
     | modules |------> handle various tasks
     |   ...   |
      ---------
```