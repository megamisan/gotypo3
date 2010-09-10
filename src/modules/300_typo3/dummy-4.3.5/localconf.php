<?php
$TYPO3_CONF_VARS['SYS']['sitename'] = '${sitename}';

// Default password is "joh316" :
$TYPO3_CONF_VARS['BE']['installToolPassword'] = 'bacb98acf97e0b6112b1d1b650b84971';
$TYPO3_CONF_VARS['EXT']['extList'] = 'opendocs,feedit,cshmanual,about,scheduler,recycler,version,tsconfig_help,context_help,extra_page_cm_options,impexp,sys_note,tstemplate,tstemplate_ceditor,tstemplate_info,tstemplate_objbrowser,tstemplate_analyzer,func_wizards,wizard_crpages,wizard_sortpages,lowlevel,install,belog,beuser,aboutmodules,setup,taskcenter,info_pagetsconfig,viewpage,rtehtmlarea,css_styled_content,t3skin,t3editor,reports';

$typo_db_extTableDef_script = 'extTables.php';
$typo_db = '${typo3_db}';
$typo_db_username = '${typo3_dbusr}';
$typo_db_password = '${typo3_dbpwd}';
$typo_db_host = '${typo3_dbhost}';

$TYPO3_CONF_VARS['SYS']['encryptionKey'] = '${typo3_key}';
$TYPO3_CONF_VARS['SYS']['setDBinit'] = 'SET NAMES utf8;' . chr(10) . 'SET SESSION character_set_server=utf8;';
$TYPO3_CONF_VARS['BE']['forceCharset'] = 'utf-8';
$TYPO3_CONF_VARS['GFX']['im_combine_filename'] = 'composite';
$TYPO3_CONF_VARS['GFX']["im_path"] = '/usr/bin/';
$TYPO3_CONF_VARS['GFX']['im_version_5'] = 'im6';
$TYPO3_CONF_VARS["SYS"]["compat_version"] = '4.3';
$TYPO3_CONF_VARS['GFX']['TTFdpi'] = '96';
$TYPO3_CONF_VARS['GFX']['noIconProc'] = '0';
$TYPO3_CONF_VARS['SYS']['enable_DLOG'] = '/tmp/dlog';
$TYPO3_CONF_VARS['SYS']['t3lib_cs_convMethod'] = 'iconv';
$TYPO3_CONF_VARS['SYS']['t3lib_cs_utils'] = 'iconv';
$TYPO3_CONF_VARS['EXT']['noEdit'] = '0';
$TYPO3_CONF_VARS['BE']['unzip_path'] = 'unzip';
$TYPO3_CONF_VARS['BE']['fileCreateMask'] = '0664';
$TYPO3_CONF_VARS['BE']['folderCreateMask'] = '06775';
$TYPO3_CONF_VARS['BE']['createGroup'] = 'www-data';
$TYPO3_CONF_VARS['BE']['interfaces'] = 'backend,backend_old';
$TYPO3_CONF_VARS['BE']['accessListRenderMode'] = 'checkbox';
$TYPO3_CONF_VARS['FE']['tidy_option'] = 'all';
$TYPO3_CONF_VARS['FE']['tidy_path'] = 'tidy -i --quiet true --tidy-mark true -wrap 0 -raw --output-xhtml true';
$TYPO3_CONF_VARS['FE']['disableNoCacheParameter'] = '0';
$TYPO3_CONF_VARS['GFX']['jpg_quality'] = '100';

## INSTALL SCRIPT EDIT POINT TOKEN - all lines after this points may be changed by the install script!
?>