#!/bin/bash
# cd to where we want to be so subdirs are where we expect.
cd "$(dirname ${BASH_SOURCE[0]})"

# Load up the config file
[ -f tornado.conf ] && . tornado.conf

# Check if ENABLED is true. x is placeholder for
# potential empty ENABLED variable.
[ "x$ENABLED" = "xtrue" ] || { echo Not ENABLED in conf.; exit 0; }

# Mount the cgroup temp fs
CG=/sys/fs/cgroup
if grep -q {$CG} /proc/mounts ; then
	echo $CG already mounted. Continuing...
else
	mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup $CG
fi
# Clear any cgroups
cgclear
# Setup the controllers. Desired controllers should be in the
# controllers dir with controller_name.conf and contain the
# defaults for that subsystem.
for f in controllers/*; do
	c="$(basename $f .conf)"
	mkdir -p $CG/$c
	mount -n -t cgroup -o $c $c $CG/$c
	# Make a "default" group to be used as cgrules.conf "catchall"
	mkdir $CG/$c/catchall
	# Push in defaults
	for LINE in `grep -v "#" $f`; do
		read NAME VALUE <<<$(echo $LINE|tr -s "=" " ")
		echo $VALUE > $CG/$c/catchall/$c.$NAME
	done
done

# Initialize the /etc/cgrules.conf
echo -n > /etc/cgrules.conf


# Get list of group confs
ls groups/* > /dev/null 2>&1 || { echo Empty groups dir. Exiting.; exit 0; }
for f in groups/*; do
	g="$(basename $f .conf)"
	u=$g
	# Create group dir in mounted subsystems that the conf file
	# has an entry for. Iterate over conf and make if subsys is mounted.
	for LINE in `grep -v "#" $f`; do
		echo -n $u >> /etc/cgrules.conf
		# Get the conf values for this group and subsys
		read SUBSYS_NAME VALUE <<<$(echo $LINE|tr -s "=" " ")
		# FIXME the following won't work with subsys with 2x .!
		read SUBSYS NAME <<<$(echo $SUBSYS_NAME|tr -s "." " ")
		# add to cgrules.con
		echo " "$SUBSYS $g/ >> /etc/cgrules.conf
		u="%"
		# Now check if SUBSYS is mounted
		if (lssubsys | grep -qw $SUBSYS); then
			# make the group in this subsystem
			SUBSYS_DIR=`lssubsys $SUBSYS -m|cut -d " " -f2`
			mkdir -p $SUBSYS_DIR/$g
			# set values
			echo $VALUE > $SUBSYS_DIR/$g/$SUBSYS.$NAME
		fi
	done
	echo >> /etc/cgrules.conf
done

# Add catchall to cgrules.conf
echo "*" "*" catchall/ >> /etc/cgrules.conf

# This is ugly...
killall cgrulesengd; cgrulesengd

