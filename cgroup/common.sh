#!/bin/bash
function create {
	g="$(basename $1 .conf)"
	# Initialize the cgrules.conf for this group
	echo -n > cgrules/$g
	u=$g
	PROCESSED_SUBSYSTEM=""
	# Create group dir in mounted subsystems that the conf file
	# has an entry for. Iterate over conf and make if subsys is mounted.
	for LINE in `cat $1 | sort | grep -v "#"`; do
		# Get the conf values for this group and subsys
		read SUBSYS_NAME VALUE <<<$(echo $LINE|tr -s "=" " ")
		read SUBSYS NAME <<<$(echo $SUBSYS_NAME|tr -s "." " ")
		# Now check if SUBSYS is mounted
		if (lssubsys -m | grep -qw $SUBSYS); then
			# make the group in this subsystem
			SUBSYS_DIR=`lssubsys $SUBSYS -m|cut -d " " -f2`
			mkdir -p $SUBSYS_DIR/$g
			# set values
			echo $VALUE > $SUBSYS_DIR/$g/$SUBSYS.$NAME
			# add to cgrules.conf if we don't already have a
			# line for this controller. Some controllers have
			# multiple subsystem values and we could be here
			# several times in the enclosing loop.
			# use groupname for first line
			if [ "$PROCESSED_SUBSYS" != $SUBSYS ]; then
				echo -n $u >> cgrules/$g
				# and % for subsequent.
				u="%" # Needed because of silly cgrules.conf limitations
				echo " "$SUBSYS $g/ >> cgrules/$g
			fi
		else
			echo $SUBSYS not mounted. Skipping...
		fi
		PROCESSED_SUBSYS=$SUBSYS
	done

}


# Check that there is at least one mounted subsystem
function chk_subsys {
	if [ `lssubsys -m $c | wc -l` -lt 1 ]; then
		echo "No mounted cgroup subsystems found!" | logger -s -t CGROUP
		return 1
	fi
}

function delete {
	g="$(basename $1 .conf)"
	rm cgrules/$g > /dev/null 2>&1
	for LINE in `lscgroup | grep :/$g$`; do
		cgdelete $LINE
	done
}

function construct_cgrules {
	echo -n > /etc/cgrules.conf
	cat cgrules/* >> /etc/cgrules.conf

	# Add our cgrules.footer
	[ -f /etc/cgrules.conf.footer ] && cat /etc/cgrules.conf.footer >> /etc/cgrules.conf

	# Add catchall to cgrules.conf
	echo "*" "*" catchall/ >> /etc/cgrules.conf
}
