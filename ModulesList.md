# Introduction #

Here is a list of all GoTYPO3 modules, each module is described by the following elements :

  * **ID** : The unique identifier of the module. Determine in which order modules should be executed.
  * **Name** : The name of the module.
  * **Description** : A description of the module and what it does.
  * **Files** : A list of files associated with the module


# Modules #

## 100\_debian-lenny.sh ##
  * **ID** : 100
  * **Name** : Debian Lenny
  * **Description** : This module should be executed after Debian Lenny installation, and before executing any other module. It installs Debian packages needed by other modules, sets up a database for Proftpd, sets up awstats and sets up logs rotation.
  * **Files** : N/A

## 200\_vhost.sh ##
  * **ID** : 200
  * **Name** : Vhost
  * **Description** : This module configures Apache virtual hosts in /var/www/vhosts and creates the associated file structures and system users. A report is added in /opt/ics/gotypo/ for each virtual host.
  * **Files** :
    * vhost\_skeleton.tgz : Virtual host file structure, ready to be configured.

## 225\_awstats.sh ##
  * **ID** : 225
  * **Name** : Awstats
  * **Description** : This module configures Awstats for the selected virtual hosts and updates their reports.
  * **Files** :
    * awstats.conf : Awstats configuration template.
    * awstats\_daily.cron : Daily stats update script.
    * awstats\_index.php : Index for the awstats static pages access.
    * awstats\_menu.php : Menu for the awstats static pages access.
    * awstats\_update.sh : Awstats statistics update script.

## 250\_ftp\_users.sh ##
  * **ID** : 250
  * **Name** : FTP users
  * **Description** : This module creates virtual proftpd users with rights mapped on system users.
  * **Files** : N/A

## 300\_typo3.sh ##
  * **ID** : 300
  * **Name** : TYPO3
  * **Description** : This module install TYPO3 on virtual hosts configured by the Vhost module. It checks if TYPO3 sources are installed on the server, creates a database and database user, and configures a TYPO3 dummy package. At the end of the installation the corresponding virtual host report is updated.
  * **Files** :
    * localconf.php : a custom localconf.php.
    * htaccess : a custom htaccess file.