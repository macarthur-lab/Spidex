fname=$1
db=$2
table=$3
ignore=$4
extension=${fname##*.}

terminate=\',\'
enclose=\'\"\'

if [ $fname = '-h' ];
then
	echo "load_data_infile filename database table [ignore_x_lines]"
else
	if [ $extension = 'gz' ];
	then
		if [ -n "$ignore" ];
		then
			zcat $fname | mysql --database $db --local-infile=1 -e 'LOAD DATA LOCAL INFILE "/dev/stdin" INTO TABLE '$table' IGNORE '$ignore' LINES;'
		else
			zcat $fname | mysql --database $db --local-infile=1 -e 'LOAD DATA LOCAL INFILE "/dev/stdin" INTO TABLE '$table';'
		fi	
	elif [ $extension = 'csv' ];
	then
		if [ -n "$ignore" ];
		then
			cat $fname | mysql --database $db --local-infile=1 -e 'LOAD DATA LOCAL INFILE "/dev/stdin" INTO TABLE '$table' FIELDS TERMINATED BY '$terminate' ENCLOSED BY '$enclose' IGNORE '$ignore' LINES;'
		else
			cat $fname | mysql --database $db --local-infile=1 -e 'LOAD DATA LOCAL INFILE "/dev/stdin" INTO TABLE '$table' FIELDS TERMINATED BY '$terminate' ENCLOSED BY '$enclose';'
		fi
	else
		if [ -n "$ignore" ];
		then
			cat $fname | mysql --database $db --local-infile=1 -e 'LOAD DATA LOCAL INFILE "/dev/stdin" INTO TABLE '$table' IGNORE '$ignore' LINES;'
		else
			cat $fname | mysql --database $db --local-infile=1 -e 'LOAD DATA LOCAL INFILE "/dev/stdin" INTO TABLE '$table';'
		fi
	fi
fi
