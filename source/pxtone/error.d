module pxtone.error;
// '16/12/16 pxtnError.

enum pxtnERR {
	OK = 0,
	VOID,
	INIT,
	FATAL,

	anti_opreation,

	deny_beatclock,

	desc_w,
	desc_r,
	desc_broken,

	fmt_new,
	fmt_unknown,

	inv_code,
	inv_data,

	memory,

	moo_init,

	ogg,
	ogg_no_supported,

	param,

	pcm_convert,
	pcm_unknown,

	ptn_build,
	ptn_init,

	ptv_no_supported,

	too_much_event,

	woice_full,

	x1x_ignore,

	x3x_add_tuning,
	x3x_key,

	num,
}

__gshared const(char)*[pxtnERR.num + 1] _err_msg_tbl = [
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

const(char)* pxtnError_get_string(pxtnERR err_code) @system {
	if (err_code < 0 || err_code >= pxtnERR.num) {
		return _err_msg_tbl[pxtnERR.num];
	}
	return _err_msg_tbl[err_code];
}
