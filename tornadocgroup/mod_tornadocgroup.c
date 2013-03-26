/* 
* Apache2 module to move the vhost serving process to a specified kernel cgroup.
* In a VirtualHost block, the directive Tornadocgroup follwed by a cgroup name
* will make this module do it's magic. 2013-03-25 Joseph Santaniello <js@syse.no>
*/ 

#include "httpd.h"
#include "http_log.h"
#include "http_config.h"
#include "http_protocol.h"
#include "ap_config.h"
#include "apr_strings.h"

#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include <libcgroup.h>


typedef struct cgroup cgroup;

static char cgroup_name[256];

static const char* set_cgroup(cmd_parms *cmd, void *cfg, const char *arg) {
	apr_cpystrn(cgroup_name, arg, 256);
	return NULL;
}


static void tornadocgroup_child_init(apr_pool_t *pool, server_rec *r)
{
	cgroup *thegroup;
	int ret = 0;
	// Initialize libcgroup
	if ((ret = cgroup_init()) > 0) {
		ap_log_error(APLOG_MARK, APLOG_ERR, 0, r, "Error %i initializing libcgroup.", ret );
	}
	// Create cgroup datastructure
	else if ((thegroup = cgroup_new_cgroup(cgroup_name)) == NULL) {
		ap_log_error(APLOG_MARK, APLOG_ERR, 0, r, "Error creating libcgroup datastructure: %s", &cgroup_name);
	}
	// Load the kernel cgroup in the datastructure
	else if ((ret = cgroup_get_cgroup(thegroup)) == ECGROUPNOTEXIST) {	
		ap_log_error(APLOG_MARK, APLOG_ERR, 0, r, "libcgroup error %i getting nonexistant cgroup: %s", ret, &cgroup_name);
	// All that stuff worked, lets move our PID to the group
	} else {
		if ((ret = cgroup_attach_task(thegroup)) == 0) {
			ap_log_error(APLOG_MARK, APLOG_NOTICE, 0, r, "Sucess attaching task to cgroup: %s", &cgroup_name);
		} else {
			ap_log_error(APLOG_MARK, APLOG_ERR, 0, r, "Failure %i attaching task to cgroup: %s", ret, &cgroup_name);
		}
	}
	// Now return declined to allow apache to continue with request now that it's been moved into cgroup.
	return DECLINED;
}

static const command_rec tornadocgroup_cmds[] = {
	AP_INIT_TAKE1("tornadocgroup", set_cgroup, NULL, RSRC_CONF, "The cgroup to move task to."),
	{ NULL }
};

static void tornadocgroup_register_hooks(apr_pool_t *p)
{
	ap_hook_child_init(tornadocgroup_child_init, NULL, NULL, APR_HOOK_LAST);
}

/* Dispatch list for API hooks */
module AP_MODULE_DECLARE_DATA mod_tornadocgroup = {
//module AP_MODULE_DECLARE_DATA tornadocgroup_module = { // IMPORTANT! This line needed by apx2!!
    STANDARD20_MODULE_STUFF, 
    NULL,                  		/* create per-dir    config structures */
    NULL,                  		/* merge  per-dir    config structures */
    NULL,                  		/* create per-server config structures */
    NULL,                  		/* merge  per-server config structures */
    tornadocgroup_cmds,    		/* table of config file commands       */
    tornadocgroup_register_hooks  	/* register hooks                      */
};

