CREATE TABLE IF NOT EXISTS `offenders` (
  `time_of_offense` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ip_address` varchar(16) NOT NULL,
  `pcap_file_path` varchar(300) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
