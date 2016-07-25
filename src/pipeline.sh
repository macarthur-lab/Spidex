# get command for initializing MySQL table
python src/generate_mysql_schema.py spidex_public_noncommercial_v1.0/spidex_public_noncommercial_v1_0.tab.gz -t spidex --enum -n 11290585

# create table
mysql
CREATE TABLE `spidex` (
 `chromosome` VARCHAR(5) DEFAULT NULL,
  `position` INT(9) DEFAULT NULL,
   `ref_allele` ENUM('A', 'C', 'T', 'G') DEFAULT NULL,
    `mut_allele` ENUM('A', 'C', 'T', 'G') DEFAULT NULL,
     `dpsi_max_tissue` FLOAT DEFAULT NULL,
      `dpsi_zscore` VARCHAR(6) DEFAULT NULL,
       `gene` VARCHAR(15) DEFAULT NULL,
        `strand` ENUM('+', '-') DEFAULT NULL,
	 `transcript` VARCHAR(14) DEFAULT NULL,
	  `exon_number` INT(3) DEFAULT NULL,
	   `location` ENUM('intronic', 'exonic') DEFAULT NULL,
	    `cds_type` ENUM('5pUTR', '3pUTR', 'CDS') DEFAULT NULL,
	     `ss_dist` INT(4) DEFAULT NULL,
	      `commonsnp_rsno` VARCHAR(11) DEFAULT NULL
	      ) ENGINE=MyISAM DEFAULT CHARSET=latin1;
exit

# populate table with data
zcat spidex_public_noncommercial_v1.0/spidex_public_noncommercial_v1_0.tab.gz | mysql --database loftee --local-infile=1 -e 'LOAD DATA LOCAL INFILE "/dev/stdin" INTO TABLE 'spidex';'
