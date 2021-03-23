module pxtone.error;
// '16/12/16 pxtnError.

enum pxtnERR {
	pxtnOK = 0,
	pxtnERR_VOID,
	pxtnERR_INIT,
	pxtnERR_FATAL,

	pxtnERR_anti_opreation,

	pxtnERR_deny_beatclock,

	pxtnERR_desc_w,
	pxtnERR_desc_r,
	pxtnERR_desc_broken,

	pxtnERR_fmt_new,
	pxtnERR_fmt_unknown,

	pxtnERR_inv_code,
	pxtnERR_inv_data,

	pxtnERR_memory,

	pxtnERR_moo_init,

	pxtnERR_ogg,
	pxtnERR_ogg_no_supported,

	pxtnERR_param,

	pxtnERR_pcm_convert,
	pxtnERR_pcm_unknown,

	pxtnERR_ptn_build,
	pxtnERR_ptn_init,

	pxtnERR_ptv_no_supported,

	pxtnERR_too_much_event,

	pxtnERR_woice_full,

	pxtnERR_x1x_ignore,

	pxtnERR_x3x_add_tuning,
	pxtnERR_x3x_key,

	pxtnERR_num,
};

__gshared const(char)*[pxtnERR.pxtnERR_num + 1] _err_msg_tbl = [
	"OK",
	"VOID",
	"INIT",
	"FATAL",
	"anti operation",
	"deny beatclock",
	"desc w",
	"desc r",
	"desc broken ",
	"fmt new",
	"fmt unknown ",
	"inv code",
	"inv data",
	"memory",
	"moo init",
	"ogg ",
	"ogg no supported",
	"param ",
	"pcm convert ",
	"pcm unknown ",
	"ptn build ",
	"ptn init",
	"ptv no supported",
	"woice full",
	"x1x ignore",
	"x3x add tuning",
	"x3x key ",
	"?"
];

const(char)* pxtnError_get_string(pxtnERR err_code) {
	if (err_code < 0 || err_code >= pxtnERR.pxtnERR_num) {
		return _err_msg_tbl[pxtnERR.pxtnERR_num];
	}
	return _err_msg_tbl[err_code];
}
