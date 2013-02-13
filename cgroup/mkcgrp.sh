#!/bin/bash
# cd to where we want to be so subdirs are where we expect.
cd "$(dirname ${BASH_SOURCE[0]})"

# Load up the config file
[ -f tornado.conf ] && . tornado.conf

# Check if ENABLED is true. x is placeholder for
# potential empty ENABLED variable.
[ "x$ENABLED" = "xtrue" ] || { echo Not ENABLED in conf.; exit 0; }

CG=/sys/fs/cgroup
# umount cgroups
#cgroups-umount

# Mount the cgroup temp fs
if grep -q "^cgroup $CG" /proc/mounts ; then
	echo $CG already mounted. Continuing...
else
	mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup $CG
fi
# Setup the controllers. Desired controllers should be in the
# controllers dir with controller_name.conf and contain the
# defaults for that subsystem.
for f in controllers/*.conf; do
	c="$(basename $f .conf)"
	# See if this controller is already mounted
	if [ `lssubsys -m $c | wc -l` -lt 1 ]; then
		mkdir -p $CG/$c
		mount -n -t cgroup -o $c $c $CG/$c
	fi
	# Make a "default" group to be used as cgrules.conf "catchall"
	mkdir -p $CG/$c/catchall
	# Push in defaults
	for LINE in `grep -v "#" $f`; do
		read NAME VALUE <<<$(echo $LINE|tr -s "=" " ")
		echo $VALUE > $CG/$c/catchall/$c.$NAME
	done
done

# Initialize the /etc/cgrules.conf
echo -n > /etc/cgrules.conf


# Get list of group confs
#ls groups/* > /dev/null 2>&1 || { echo Empty groups dir. Exiting.; exit 0; }
for f in groups/*.conf; do
	g="$(basename $f .conf)"
	u=$g
	PROCESSED_SUBSYSTEM=""
	# Create group dir in mounted subsystems that the conf file
	# has an entry for. Iterate over conf and make if subsys is mounted.
	for LINE in `grep -v "#" $f`; do
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
				echo -n $u >> /etc/cgrules.conf
				# and % for subsequent.
				u="%" # Needed because of silly cgrules.conf limitations
				echo " "$SUBSYS $g/ >> /etc/cgrules.conf
			fi
		fi
		PROCESSED_SUBSYS=$SUBSYS
	done
	echo >> /etc/cgrules.conf
done

# Add our cgrules.footer
[ -f /etc/cgrules.conf.footer ] && cat /etc/cgrules.conf.footer >> /etc/cgrules.conf

# Add catchall to cgrules.conf
echo "*" "*" catchall/ >> /etc/cgrules.conf

# This is ugly... but we don't have to deal with PID and SIGUSR2.
killall cgrulesengd; cgrulesengd

