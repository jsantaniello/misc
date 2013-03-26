mod_tornadocgroup.la: mod_tornadocgroup.slo
	$(SH_LINK) -rpath $(libexecdir) -module -avoid-version  mod_tornadocgroup.lo -lcgroup
DISTCLEAN_TARGETS = modules.mk
shared =  mod_tornadocgroup.la
