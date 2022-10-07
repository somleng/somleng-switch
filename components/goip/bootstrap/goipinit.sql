-- MySQL dump 10.9
--
-- Host: localhost    Database: goip
-- ------------------------------------------------------
-- Server version       4.1.20

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


--
-- Table structure for table `crowd`
--
GRANT all ON goip.* TO goip@localhost IDENTIFIED BY 'goip';
DROP database IF EXISTS `goip`;
create database goip;
use goip;

DROP TABLE IF EXISTS `crowd`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `crowd` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(20) NOT NULL default '',
  `info` varchar(100) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `crowd`
--

LOCK TABLES `crowd` WRITE;
/*!40000 ALTER TABLE `crowd` DISABLE KEYS */;
INSERT INTO `crowd` VALUES (1,'TEST','');
/*!40000 ALTER TABLE `crowd` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `goip`
--

DROP TABLE IF EXISTS `goip`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `goip` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(64) NOT NULL default '',
  `provider` int(11) NOT NULL,
  `host` varchar(50) NOT NULL default '',
  `port` int(11) NOT NULL default '0',
  `password` varchar(64) NOT NULL default '',
  `alive` tinyint(1) NOT NULL default '0',
  `num`  varchar(30) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `goip`
--

LOCK TABLES `goip` WRITE;
/*!40000 ALTER TABLE `goip` DISABLE KEYS */;
/*!40000 ALTER TABLE `goip` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `groups`
--

DROP TABLE IF EXISTS `groups`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `groups` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(20) NOT NULL default '',
  `info` varchar(100) default NULL,
  `crowdid` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `crowdid` (`crowdid`),
  CONSTRAINT `groups_ibfk_1` FOREIGN KEY (`crowdid`) REFERENCES `crowd` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `groups`
--

LOCK TABLES `groups` WRITE;
/*!40000 ALTER TABLE `groups` DISABLE KEYS */;
INSERT INTO `groups` VALUES (1,'TEST','',1);
/*!40000 ALTER TABLE `groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `message`
--

DROP TABLE IF EXISTS `message`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `message` (
  `id` int(11) NOT NULL auto_increment,
  `crontime` int(10) unsigned NOT NULL default '0',
  `time` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `userid` int(11) NOT NULL default '0',
  `cronid` int(11) NOT NULL default '0',
  `msg` text NOT NULL,
  `type` int(1) NOT NULL default '0',
  `receiverid` text,
  `receiverid1` text,
  `receiverid2` text,
  `groupid` text,
  `groupid1` text,
  `groupid2` text,
  `recv` tinyint(1) NOT NULL default '0',
  `recv1` tinyint(1) NOT NULL default '0',
  `recv2` tinyint(1) NOT NULL default '0',
  `over` int(1) NOT NULL default '0',
  `stoptime` INT(10) UNSIGNED NULL DEFAULT '0',
  `tel` VARCHAR( 30 ) NULL,
  `prov` VARCHAR( 30 ) NULL,
  `goipid` int(11) default '0', 
  `uid` VARCHAR( 64 ) NULL,
  `msgid` INT(10) UNSIGNED NULL DEFAULT '0',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `message`
--

LOCK TABLES `message` WRITE;
/*!40000 ALTER TABLE `message` DISABLE KEYS */;
/*!40000 ALTER TABLE `message` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `prov`
--

DROP TABLE IF EXISTS `prov`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `prov` (
  `id` int(11) NOT NULL auto_increment,
  `prov` varchar(30) default NULL,
  `inter` varchar(10) character set ascii default NULL,
  `local` varchar(10) character set ascii default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `prov`
--

LOCK TABLES `prov` WRITE;
/*!40000 ALTER TABLE `prov` DISABLE KEYS */;
INSERT INTO `prov` VALUES (1,'','',''),(2,'','',''),(3,'','',''),(4,'','',''),(5,'','',''),(6,'','',''),(7,'','',''),(8,'','',''),(9,'','',''),(10,'','','');
/*!40000 ALTER TABLE `prov` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `receiver`
--

DROP TABLE IF EXISTS `receiver`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `receiver` (
  `id` int(11) NOT NULL auto_increment,
  `no` varchar(20) NOT NULL default '',
  `name` varchar(20) NOT NULL default '',
  `name_l` varchar(20) NOT NULL,
  `ename_f` varchar(30) NOT NULL,
  `ename_l` varchar(30) NOT NULL,
  `gender` varchar(1) NOT NULL,
  `info` varchar(100) NOT NULL default '',
  `tel` varchar(20) default NULL,
  `hometel` varchar(20) NOT NULL,
  `officetel` varchar(20) NOT NULL,
  `provider` varchar(20) NOT NULL default '',
  `dead` int(1) NOT NULL,
  `reject` int(1) NOT NULL,
  `name1` varchar(20) NOT NULL default '',
  `tel1` varchar(20) default NULL,
  `provider1` varchar(20) NOT NULL default '',
  `name2` varchar(20) NOT NULL default '',
  `tel2` varchar(20) default NULL,
  `provider2` varchar(20) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `receiver`
--

LOCK TABLES `receiver` WRITE;
/*!40000 ALTER TABLE `receiver` DISABLE KEYS */;
/*!40000 ALTER TABLE `receiver` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `recvgroup`
--

DROP TABLE IF EXISTS `recvgroup`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `recvgroup` (
  `id` int(11) NOT NULL auto_increment,
  `groupsid` int(11) NOT NULL default '0',
  `recvid` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `groupsid` (`groupsid`),
  KEY `recvid` (`recvid`),
  CONSTRAINT `recvgroup_ibfk_1` FOREIGN KEY (`groupsid`) REFERENCES `groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `recvgroup_ibfk_2` FOREIGN KEY (`recvid`) REFERENCES `receiver` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `recvgroup`
--

LOCK TABLES `recvgroup` WRITE;
/*!40000 ALTER TABLE `recvgroup` DISABLE KEYS */;
/*!40000 ALTER TABLE `recvgroup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `refcrowd`
--

DROP TABLE IF EXISTS `refcrowd`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `refcrowd` (
  `id` int(11) NOT NULL auto_increment,
  `userid` int(11) NOT NULL default '0',
  `crowdid` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `userid` (`userid`),
  KEY `crowdid` (`crowdid`),
  CONSTRAINT `refcrowd_ibfk_1` FOREIGN KEY (`userid`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `refcrowd_ibfk_2` FOREIGN KEY (`crowdid`) REFERENCES `crowd` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `refcrowd`
--

LOCK TABLES `refcrowd` WRITE;
/*!40000 ALTER TABLE `refcrowd` DISABLE KEYS */;
/*!40000 ALTER TABLE `refcrowd` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `refgroup`
--

DROP TABLE IF EXISTS `refgroup`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `refgroup` (
  `id` int(11) NOT NULL auto_increment,
  `groupsid` int(11) NOT NULL default '0',
  `userid` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `groupsid` (`groupsid`),
  KEY `userid` (`userid`),
  CONSTRAINT `refgroup_ibfk_1` FOREIGN KEY (`groupsid`) REFERENCES `groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `refgroup_ibfk_2` FOREIGN KEY (`userid`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `refgroup`
--

LOCK TABLES `refgroup` WRITE;
/*!40000 ALTER TABLE `refgroup` DISABLE KEYS */;
/*!40000 ALTER TABLE `refgroup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sends`
--

DROP TABLE IF EXISTS `sends`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `sends` (
  `id` int(11) NOT NULL auto_increment,
  `time` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `userid` int(11) NOT NULL default '0',
  `messageid` int(11) NOT NULL default '0',
  `goipid` int(11) NOT NULL default '0',
  `provider` varchar(20) NOT NULL default '',
  `telnum` varchar(20) NOT NULL default '',
  `recvlev` int(1) NOT NULL default '0',
  `recvid` int(11) NOT NULL default '0',
  `over` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `messageid` (`messageid`),
  CONSTRAINT `sends_ibfk_1` FOREIGN KEY (`messageid`) REFERENCES `message` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `sends`
--

LOCK TABLES `sends` WRITE;
/*!40000 ALTER TABLE `sends` DISABLE KEYS */;
/*!40000 ALTER TABLE `sends` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `system`
--

DROP TABLE IF EXISTS `system`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system` (
  `maxword` int(11) NOT NULL default '0',
  `sysname` varchar(20) NOT NULL default '',
  `lan` int(1) NOT NULL default '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `system`
--

LOCK TABLES `system` WRITE;
/*!40000 ALTER TABLE `system` DISABLE KEYS */;
INSERT INTO `system` VALUES (70,'goipsms',3);
/*!40000 ALTER TABLE `system` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `user` (
  `id` int(11) NOT NULL auto_increment,
  `username` varchar(20) character set utf8 NOT NULL default '',
  `password` varchar(50) NOT NULL default '',
  `permissions` int(1) NOT NULL default '0',
  `info` text character set utf8,
  `msg1` varchar(20) character set utf8 NOT NULL default '',
  `msg2` varchar(20) character set utf8 NOT NULL default '',
  `msg3` varchar(20) character set utf8 NOT NULL default '',
  `msg4` varchar(20) character set utf8 NOT NULL default '',
  `msg5` varchar(20) character set utf8 NOT NULL default '',
  `msg6` varchar(20) character set utf8 NOT NULL default '',
  `msg7` varchar(20) character set utf8 NOT NULL default '',
  `msg8` varchar(20) character set utf8 NOT NULL default '',
  `msg9` varchar(20) character set utf8 NOT NULL default '',
  `msg10` varchar(20) character set utf8 NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `user`
--

LOCK TABLES `user` WRITE;
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` VALUES (1,'root','63a9f0ea7bb98050796b649e85481845',0,'Super Adminstrator','','','','','','','','','','');
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- 表的结构 `receive`
--

DROP TABLE IF EXISTS `receive`;
CREATE TABLE IF NOT EXISTS `receive` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `srcnum` varchar(30) NOT NULL default '',
  `provid` int(10) unsigned NOT NULL default '0',
  `msg` text NOT NULL,
  `time` datetime NOT NULL default '0000-00-00 00:00:00',
  `goipid` int(11) NOT NULL default '0',
  `goipname` varchar(30) NOT NULL default '',
  `srcid` int(11) NOT NULL default '0',
  `srcname` varchar(30) NOT NULL default '',
  `srclevel` int(1) NOT NULL default '0',
  `status` int(1) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

DROP TABLE IF EXISTS `record`;
CREATE TABLE IF NOT EXISTS `record` (
  `id` int(10) unsigned NOT NULL auto_increment,                                                                  
  `goipid` int(10) unsigned NOT NULL default '0',
  `dir` int(1) NOT NULL default '0',
  `num` varchar(64) NOT NULL default '',
  `time` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `expiry` int(11) default '-1',
  PRIMARY KEY  (`id`),
  KEY `goipid` (`goipid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;


DROP TABLE IF EXISTS `USSD`;
CREATE TABLE IF NOT EXISTS `USSD` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `TERMID` varchar(64) NOT NULL default '',
  `USSD_MSG` varchar(255) NOT NULL default '',
  `USSD_RETURN` varchar(255) NOT NULL default '',
  `ERROR_MSG` varchar(64) NOT NULL default '',
  `INSERTTIME` timestamp NOT NULL default '0000-00-00 00:00:00' on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2009-07-08  3:41:46
