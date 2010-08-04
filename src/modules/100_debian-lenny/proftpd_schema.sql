CREATE TABLE `groups_virt` (
  `groupname` varchar(30) NOT NULL,
  `member` varchar(30) default NULL,
  UNIQUE (`groupname`, `member`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='virtual groups';

CREATE TABLE `groups_sys` (
  `groupname` varchar(30) NOT NULL,
  `gid` int(11) NOT NULL,
  PRIMARY KEY  (`groupname`),
  UNIQUE (`gid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='used system groups';

CREATE TABLE `users_plain` (
  `userid` varchar(30) NOT NULL,
  `password` varchar(50) character set ascii NULL,
  `uid` int(11) default NULL,
  `gid` int(11) default NULL,
  `homedir` varchar(255) default NULL,
  `active` tinyint(1) NOT NULL default '1',
  PRIMARY KEY  (`userid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='ftp users (pwd plain)';

CREATE VIEW `users` AS 
SELECT `users_plain`.`userid` AS `userid`, IF(`users_plain`.`password` IS NULL, '', password(`users_plain`.`password`)) AS `passwd`, `users_plain`.`uid` AS `uid`, `users_plain`.`gid` AS `gid`, `users_plain`.`homedir` AS `homedir`, _utf8'/bin/bash' AS `shell` 
FROM `users_plain` where (`users_plain`.`active` = 1);

CREATE VIEW `groups` AS
SELECT `groups_sys`.`groupname` AS `groupname`, `groups_sys`.`gid` AS `gid`, `users_plain`.`userid` AS `members`
FROM `groups_sys`
INNER JOIN `users_plain` ON `groups_sys`.`gid` = `users_plain`.`gid`
WHERE `users_plain`.`active` = 1
UNION
SELECT `groups_virt`.`groupname` AS `groupname`, 65534 AS `gid`, `groups_virt`.`member` AS `members`
FROM `groups_virt`;
