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

typedef struct {
	char cgroup_name[256];
} cgroup_cfg;

module AP_MODULE_DECLARE_DATA mod_tornadocgroup ;

const char *set_cgroup(cmd_parms *cmd, void *cfg, const char *arg)
{
	cgroup_cfg *conf = (cgroup_cfg *) cfg;
	if(conf) {
		strcpy(conf->cgroup_name,  arg);
	}
	return NULL;
}

static int tornadocgroup_handler(request_rec *r)
{
	cgroup *thegroup;
	int ret = 0;
	cgroup_cfg* cfg = (cgroup_cfg*) ap_get_module_config(r->per_dir_config, &mod_tornadocgroup);
	if ((thegroup = cgroup_new_cgroup(cfg->cgroup_name)) == NULL) {
		ap_log_rerror(APLOG_MARK, APLOG_ERR, 0, r, "Error creating libcgroup datastructure: %s", cfg->cgroup_name);
	}
	else {
		if ((ret = cgroup_attach_task(thegroup)) == 0) {
			ap_log_rerror(APLOG_MARK, APLOG_INFO, 0, r, "Sucess attaching task to cgroup: %s", cfg->cgroup_name);
		}
		else {
			ap_log_rerror(APLOG_MARK, APLOG_ERR, 0, r, "Failure %i attaching task to cgroup: %s", ret, cfg->cgroup_name);
		}
	}
	// Now return declined to allow apache to continue with request now that it's been moved into cgroup.
	return DECLINED;
}

static void* create_conf(apr_pool_t *pool, char* s) {
	cgroup_cfg* cfg = apr_pcalloc(pool, sizeof(cgroup_cfg));
	apr_cpystrn(cfg->cgroup_name, "default", 256);
	return cfg;
}

static const command_rec tornadocgroup_cmds[] =
{
	AP_INIT_TAKE1("tornadocgroup", set_cgroup, NULL, RSRC_CONF, "The cgroup to move task to."),
	{ NULL }
};

static void tornadocgroup_register_hooks(apr_pool_t *p)
{
	ap_hook_post_config(cgroup_init, NULL, NULL, APR_HOOK_LAST);
	ap_hook_handler(tornadocgroup_handler, NULL, NULL, APR_HOOK_FIRST);
}

/* Dispatch list for API hooks */
module AP_MODULE_DECLARE_DATA mod_tornadocgroup =
{
	//module AP_MODULE_DECLARE_DATA tornadocgroup_module = { // IMPORTANT! This line needed by apx2!!
	STANDARD20_MODULE_STUFF,
	create_conf,			/* create per-dir    config structures */
	NULL,				/* merge  per-dir    config structures */
	NULL,				/* create per-server config structures */
	NULL,				/* merge  per-server config structures */
	tornadocgroup_cmds,		/* table of config file commands       */
	tornadocgroup_register_hooks 	/* register hooks                      */
};

