module pxtone.service;

import pxtone.pxtn;

import pxtone.descriptor;
import pxtone.pulse.noisebuilder;

import pxtone.error;
import pxtone.max;
import pxtone.mem;
import pxtone.text;
import pxtone.delay;
import pxtone.overdrive;
import pxtone.master;
import pxtone.woice;
import pxtone.pulse.frequency;
import pxtone.unit;
import pxtone.evelist;

import core.stdc.stdint;
import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;

enum PXTONEERRORSIZE = 64;

enum pxtnVOMITPREPFLAG_loop = 0x01;
enum pxtnVOMITPREPFLAG_unit_mute = 0x02;

enum _VERSIONSIZE = 16;
enum _CODESIZE = 8;

//                                       0123456789012345
__gshared const(char)* _code_tune_x2x     = "PTTUNE--20050608";
__gshared const(char)* _code_tune_x3x     = "PTTUNE--20060115";
__gshared const(char)* _code_tune_x4x     = "PTTUNE--20060930";
__gshared const(char)* _code_tune_v5      = "PTTUNE--20071119";

__gshared const(char)* _code_proj_x1x     = "PTCOLLAGE-050227";
__gshared const(char)* _code_proj_x2x     = "PTCOLLAGE-050608";
__gshared const(char)* _code_proj_x3x     = "PTCOLLAGE-060115";
__gshared const(char)* _code_proj_x4x     = "PTCOLLAGE-060930";
__gshared const(char)* _code_proj_v5      = "PTCOLLAGE-071119";


__gshared const(char)* _code_x1x_PROJ     = "PROJECT=";
__gshared const(char)* _code_x1x_EVEN     = "EVENT===";
__gshared const(char)* _code_x1x_UNIT     = "UNIT====";
__gshared const(char)* _code_x1x_END      = "END=====";
__gshared const(char)* _code_x1x_PCM      = "matePCM=";

__gshared const(char)* _code_x3x_pxtnUNIT = "pxtnUNIT";
__gshared const(char)* _code_x4x_evenMAST = "evenMAST";
__gshared const(char)* _code_x4x_evenUNIT = "evenUNIT";

__gshared const(char)* _code_antiOPER     = "antiOPER"; // anti operation(edit)

__gshared const(char)* _code_num_UNIT     = "num UNIT";
__gshared const(char)* _code_MasterV5     = "MasterV5";
__gshared const(char)* _code_Event_V5     = "Event V5";
__gshared const(char)* _code_matePCM      = "matePCM ";
__gshared const(char)* _code_matePTV      = "matePTV ";
__gshared const(char)* _code_matePTN      = "matePTN ";
__gshared const(char)* _code_mateOGGV     = "mateOGGV";
__gshared const(char)* _code_effeDELA     = "effeDELA";
__gshared const(char)* _code_effeOVER     = "effeOVER";
__gshared const(char)* _code_textNAME     = "textNAME";
__gshared const(char)* _code_textCOMM     = "textCOMM";
__gshared const(char)* _code_assiUNIT     = "assiUNIT";
__gshared const(char)* _code_assiWOIC     = "assiWOIC";
__gshared const(char)* _code_pxtoneND     = "pxtoneND";

enum _enum_Tag
{
	_TAG_Unknown  = 0,
	_TAG_antiOPER    ,

	_TAG_x1x_PROJ    ,
	_TAG_x1x_UNIT    ,
	_TAG_x1x_PCM     ,
	_TAG_x1x_EVEN    ,
	_TAG_x1x_END     ,
	_TAG_x3x_pxtnUNIT,
	_TAG_x4x_evenMAST,
	_TAG_x4x_evenUNIT,

	_TAG_num_UNIT    ,
	_TAG_MasterV5    ,
	_TAG_Event_V5    ,
	_TAG_matePCM     ,
	_TAG_matePTV     ,
	_TAG_matePTN     ,
	_TAG_mateOGGV    ,
	_TAG_effeDELA    ,
	_TAG_effeOVER    ,
	_TAG_textNAME    ,
	_TAG_textCOMM    ,
	_TAG_assiUNIT    ,
	_TAG_assiWOIC    ,
	_TAG_pxtoneND

};

static _enum_Tag _CheckTagCode( const char *p_code )
{
	if(      !memcmp( p_code, _code_antiOPER    , _CODESIZE ) ) return _enum_Tag._TAG_antiOPER;
	else if( !memcmp( p_code, _code_x1x_PROJ    , _CODESIZE ) ) return _enum_Tag._TAG_x1x_PROJ;
	else if( !memcmp( p_code, _code_x1x_UNIT    , _CODESIZE ) ) return _enum_Tag._TAG_x1x_UNIT;
	else if( !memcmp( p_code, _code_x1x_PCM     , _CODESIZE ) ) return _enum_Tag._TAG_x1x_PCM;
	else if( !memcmp( p_code, _code_x1x_EVEN    , _CODESIZE ) ) return _enum_Tag._TAG_x1x_EVEN;
	else if( !memcmp( p_code, _code_x1x_END     , _CODESIZE ) ) return _enum_Tag._TAG_x1x_END;
	else if( !memcmp( p_code, _code_x3x_pxtnUNIT, _CODESIZE ) ) return _enum_Tag._TAG_x3x_pxtnUNIT;
	else if( !memcmp( p_code, _code_x4x_evenMAST, _CODESIZE ) ) return _enum_Tag._TAG_x4x_evenMAST;
	else if( !memcmp( p_code, _code_x4x_evenUNIT, _CODESIZE ) ) return _enum_Tag._TAG_x4x_evenUNIT;
	else if( !memcmp( p_code, _code_num_UNIT    , _CODESIZE ) ) return _enum_Tag._TAG_num_UNIT;
	else if( !memcmp( p_code, _code_Event_V5    , _CODESIZE ) ) return _enum_Tag._TAG_Event_V5;
	else if( !memcmp( p_code, _code_MasterV5    , _CODESIZE ) ) return _enum_Tag._TAG_MasterV5;
	else if( !memcmp( p_code, _code_matePCM     , _CODESIZE ) ) return _enum_Tag._TAG_matePCM ;
	else if( !memcmp( p_code, _code_matePTV     , _CODESIZE ) ) return _enum_Tag._TAG_matePTV ;
	else if( !memcmp( p_code, _code_matePTN     , _CODESIZE ) ) return _enum_Tag._TAG_matePTN ;
	else if( !memcmp( p_code, _code_mateOGGV    , _CODESIZE ) ) return _enum_Tag._TAG_mateOGGV;
	else if( !memcmp( p_code, _code_effeDELA    , _CODESIZE ) ) return _enum_Tag._TAG_effeDELA;
	else if( !memcmp( p_code, _code_effeOVER    , _CODESIZE ) ) return _enum_Tag._TAG_effeOVER;
	else if( !memcmp( p_code, _code_textNAME    , _CODESIZE ) ) return _enum_Tag._TAG_textNAME;
	else if( !memcmp( p_code, _code_textCOMM    , _CODESIZE ) ) return _enum_Tag._TAG_textCOMM;
	else if( !memcmp( p_code, _code_assiUNIT    , _CODESIZE ) ) return _enum_Tag._TAG_assiUNIT;
	else if( !memcmp( p_code, _code_assiWOIC    , _CODESIZE ) ) return _enum_Tag._TAG_assiWOIC;
	else if( !memcmp( p_code, _code_pxtoneND    , _CODESIZE ) ) return _enum_Tag._TAG_pxtoneND;
	return _enum_Tag._TAG_Unknown;
}



struct _ASSIST_WOICE
{
	uint16_t  woice_index;
	uint16_t  rrr;
	char[ pxtnMAX_TUNEWOICENAME ] name;
}


struct _ASSIST_UNIT
{
	uint16_t  unit_index;
	uint16_t  rrr;
	char[ pxtnMAX_TUNEUNITNAME ]      name;
}

struct _NUM_UNIT
{
	int16_t num;
	int16_t rrr;
}

enum _MAX_FMTVER_x1x_EVENTNUM = 10000;

// x1x project..------------------


enum _MAX_PROJECTNAME_x1x = 16;

// project (36byte) ================
struct _x1x_PROJECT
{
	char[_MAX_PROJECTNAME_x1x]  x1x_name;

	float x1x_beat_tempo;
	uint16_t   x1x_beat_clock;
	uint16_t   x1x_beat_num;
	uint16_t   x1x_beat_note;
	uint16_t   x1x_meas_num;
	uint16_t   x1x_channel_num;
	uint16_t   x1x_bps;
	uint32_t   x1x_sps;
}

struct pxtnVOMITPREPARATION
{
	int32_t   start_pos_meas  ;
	int32_t   start_pos_sample;
	float     start_pos_float ;

	int32_t   meas_end        ;
	int32_t   meas_repeat     ;
	float     fadein_sec      ;

	uint32_t  flags           ;
	float     master_volume   ;
}


alias pxtnSampledCallback = bool function( void* user, const(pxtnService)* pxtn );

struct pxtnService
{
private:
	enum _enum_FMTVER
	{
		_enum_FMTVER_unknown = 0,
		_enum_FMTVER_x1x, // fix event num = 10000
		_enum_FMTVER_x2x, // no version of exe
		_enum_FMTVER_x3x, // unit has voice / basic-key for only view
		_enum_FMTVER_x4x, // unit has event
		_enum_FMTVER_v5 ,
	};

	bool _b_init;
	bool _b_edit;
	bool _b_fix_evels_num;

	int32_t _dst_ch_num, _dst_sps, _dst_byte_per_smp;

	pxtnPulse_NoiseBuilder *_ptn_bldr;

	int32_t _delay_max;	int32_t _delay_num;	pxtnDelay     **_delays;
	int32_t _ovdrv_max;	int32_t _ovdrv_num;	pxtnOverDrive **_ovdrvs;
	int32_t _woice_max;	int32_t _woice_num;	pxtnWoice     **_woices;
	int32_t _unit_max ;	int32_t _unit_num ;	pxtnUnit      **_units ;

	int32_t _group_num;

	pxtnERR _ReadVersion( pxtnDescriptor *p_doc, _enum_FMTVER *p_fmt_ver, uint16_t *p_exe_ver )
	{
		if( !_b_init ) return pxtnERR.pxtnERR_INIT;

		char[ _VERSIONSIZE  ]     version_ = '\0';
		uint16_t dummy;

		if( !p_doc.r( version_.ptr, 1, _VERSIONSIZE ) )return pxtnERR.pxtnERR_desc_r;

		// fmt version
		if(      !memcmp( version_.ptr, _code_proj_x1x , _VERSIONSIZE ) ){ *p_fmt_ver = _enum_FMTVER._enum_FMTVER_x1x; *p_exe_ver = 0; return pxtnERR.pxtnOK; }
		else if( !memcmp( version_.ptr, _code_proj_x2x , _VERSIONSIZE ) ){ *p_fmt_ver = _enum_FMTVER._enum_FMTVER_x2x; *p_exe_ver = 0; return pxtnERR.pxtnOK; }
		else if( !memcmp( version_.ptr, _code_proj_x3x , _VERSIONSIZE ) ){ *p_fmt_ver = _enum_FMTVER._enum_FMTVER_x3x;                                }
		else if( !memcmp( version_.ptr, _code_proj_x4x , _VERSIONSIZE ) ){ *p_fmt_ver = _enum_FMTVER._enum_FMTVER_x4x;							    }
		else if( !memcmp( version_.ptr, _code_proj_v5  , _VERSIONSIZE ) ){ *p_fmt_ver = _enum_FMTVER._enum_FMTVER_v5 ;							    }
		else if( !memcmp( version_.ptr, _code_tune_x2x , _VERSIONSIZE ) ){ *p_fmt_ver = _enum_FMTVER._enum_FMTVER_x2x; *p_exe_ver = 0; return pxtnERR.pxtnOK; }
		else if( !memcmp( version_.ptr, _code_tune_x3x , _VERSIONSIZE ) ){ *p_fmt_ver = _enum_FMTVER._enum_FMTVER_x3x;							    }
		else if( !memcmp( version_.ptr, _code_tune_x4x , _VERSIONSIZE ) ){ *p_fmt_ver = _enum_FMTVER._enum_FMTVER_x4x;                                }
		else if( !memcmp( version_.ptr, _code_tune_v5  , _VERSIONSIZE ) ){ *p_fmt_ver = _enum_FMTVER._enum_FMTVER_v5 ;                                }
		else return pxtnERR.pxtnERR_fmt_unknown;

		// exe version
		if( !p_doc.r( p_exe_ver, uint16_t.sizeof, 1 ) ) return pxtnERR.pxtnERR_desc_r;
		if( !p_doc.r( &dummy   , uint16_t.sizeof, 1 ) ) return pxtnERR.pxtnERR_desc_r;

		return pxtnERR.pxtnOK;
	}
	////////////////////////////////////////
	// Read Project //////////////
	////////////////////////////////////////

	pxtnERR _ReadTuneItems( pxtnDescriptor *p_doc )
	{
		if( !_b_init ) return pxtnERR.pxtnERR_INIT;

		pxtnERR res   = pxtnERR.pxtnERR_VOID;
		bool    b_end = false;
		char[ _CODESIZE + 1 ]    code = '\0';


		/// must the unit before the voice.
		while( !b_end )
		{
			if( !p_doc.r( code.ptr, 1, _CODESIZE ) ){ res = pxtnERR.pxtnERR_desc_r; goto term; }

			_enum_Tag tag = _CheckTagCode( code.ptr );
			switch( tag )
			{
			case _enum_Tag._TAG_antiOPER    : res = pxtnERR.pxtnERR_anti_opreation; goto term;

			// new -------
			case _enum_Tag._TAG_num_UNIT    :
				{
					int32_t num = 0;
					res = _io_UNIT_num_r( p_doc, &num ); if( res != pxtnERR.pxtnOK ) goto term;
					for( int32_t i = 0; i < num; i++ ) _units[ i ] = allocate!pxtnUnit();
					_unit_num = num;
					break;
				}
			case _enum_Tag._TAG_MasterV5: res = master.io_r_v5( p_doc               ); if( res != pxtnERR.pxtnOK ) goto term; break;
			case _enum_Tag._TAG_Event_V5: res = evels.io_Read ( p_doc               ); if( res != pxtnERR.pxtnOK ) goto term; break;

			case _enum_Tag._TAG_matePCM : res = _io_Read_Woice( p_doc, pxtnWOICETYPE.pxtnWOICE_PCM ); if( res != pxtnERR.pxtnOK ) goto term; break;
			case _enum_Tag._TAG_matePTV : res = _io_Read_Woice( p_doc, pxtnWOICETYPE.pxtnWOICE_PTV ); if( res != pxtnERR.pxtnOK ) goto term; break;
			case _enum_Tag._TAG_matePTN : res = _io_Read_Woice( p_doc, pxtnWOICETYPE.pxtnWOICE_PTN ); if( res != pxtnERR.pxtnOK ) goto term; break;

			case _enum_Tag._TAG_mateOGGV:

	version(pxINCLUDE_OGGVORBIS) {
				res = _io_Read_Woice( p_doc, pxtnWOICE_OGGV );
				if( res != pxtnERR.pxtnOK ) goto term;
				break;
	} else {
				res = pxtnERR.pxtnERR_ogg_no_supported; goto term;
	}

			case _enum_Tag._TAG_effeDELA    : res = _io_Read_Delay               ( p_doc ); if( res != pxtnERR.pxtnOK ) goto term; break;
			case _enum_Tag._TAG_effeOVER    : res = _io_Read_OverDrive           ( p_doc ); if( res != pxtnERR.pxtnOK ) goto term; break;
			case _enum_Tag._TAG_textNAME    : if( !text.Name_r                  ( p_doc ) ){ res = pxtnERR.pxtnERR_desc_r; goto term; } break;
			case _enum_Tag._TAG_textCOMM    : if( !text.Comment_r               ( p_doc ) ){ res = pxtnERR.pxtnERR_desc_r; goto term; } break;
			case _enum_Tag._TAG_assiWOIC    : res = _io_assiWOIC_r               ( p_doc ); if( res != pxtnERR.pxtnOK ) goto term; break;
			case _enum_Tag._TAG_assiUNIT    : res = _io_assiUNIT_r               ( p_doc ); if( res != pxtnERR.pxtnOK ) goto term; break;
			case _enum_Tag._TAG_pxtoneND    : b_end = true; break;

			// old -------
			case _enum_Tag._TAG_x4x_evenMAST: res = master.io_r_x4x              ( p_doc                ); if( res != pxtnERR.pxtnOK ) goto term; break;
			case _enum_Tag._TAG_x4x_evenUNIT: res = evels .io_Unit_Read_x4x_EVENT( p_doc, false, true   ); if( res != pxtnERR.pxtnOK ) goto term; break;
			case _enum_Tag._TAG_x3x_pxtnUNIT: res = _io_Read_OldUnit              ( p_doc, 3             ); if( res != pxtnERR.pxtnOK ) goto term; break;
			case _enum_Tag._TAG_x1x_PROJ    : if( !_x1x_Project_Read              ( p_doc              ) ){ res = pxtnERR.pxtnERR_desc_r; goto term; } break;
			case _enum_Tag._TAG_x1x_UNIT    : res = _io_Read_OldUnit              ( p_doc, 1             ); if( res != pxtnERR.pxtnOK ) goto term; break;
			case _enum_Tag._TAG_x1x_PCM     : res = _io_Read_Woice                ( p_doc, pxtnWOICETYPE.pxtnWOICE_PCM ); if( res != pxtnERR.pxtnOK ) goto term; break;
			case _enum_Tag._TAG_x1x_EVEN    : res = evels .io_Unit_Read_x4x_EVENT( p_doc, true, false   ); if( res != pxtnERR.pxtnOK ) goto term; break;
			case _enum_Tag._TAG_x1x_END     : b_end = true; break;

			default: res = pxtnERR.pxtnERR_fmt_unknown; goto term;
			}
		}

		res = pxtnERR.pxtnOK;
	term:

		return res;

	}
	bool _x1x_Project_Read( pxtnDescriptor *p_doc )
	{
		if( !_b_init ) return false;

		_x1x_PROJECT prjc = {0};
		int32_t  beat_num, beat_clock;
		int32_t  size;
		float    beat_tempo;

		if( !p_doc.r( &size, 4,                      1 ) ) return false;
		if( !p_doc.r( &prjc,  _x1x_PROJECT.sizeof, 1 ) ) return false;

		beat_num   = prjc.x1x_beat_num  ;
		beat_tempo = prjc.x1x_beat_tempo;
		beat_clock = prjc.x1x_beat_clock;

		int32_t  ns = 0;
		for( /+ns+/; ns <  _MAX_PROJECTNAME_x1x; ns++ ){ if( !prjc.x1x_name[ ns ] ) break; }

		text.set_name_buf( prjc.x1x_name.ptr, ns );
		master.Set( beat_num, beat_tempo, beat_clock );

		return true;
	}

	pxtnERR _io_Read_Delay( pxtnDescriptor *p_doc )
	{
		if( !_b_init ) return pxtnERR.pxtnERR_INIT;
		if( !_delays ) return pxtnERR.pxtnERR_INIT;
		if( _delay_num >= _delay_max ) return pxtnERR.pxtnERR_fmt_unknown;

		pxtnERR    res   = pxtnERR.pxtnERR_VOID;
		pxtnDelay* delay = allocate!pxtnDelay();

		res = delay.Read( p_doc ); if( res != pxtnERR.pxtnOK ) goto term;
		res = pxtnERR.pxtnOK;
	term:
		if( res == pxtnERR.pxtnOK ){ _delays[ _delay_num ] = delay; _delay_num++; }
		else               { SAFE_DELETE( delay ); }
		return res;
	}

	pxtnERR _io_Read_OverDrive( pxtnDescriptor *p_doc )
	{
		if( !_b_init ) return pxtnERR.pxtnERR_INIT;
		if( !_ovdrvs ) return pxtnERR.pxtnERR_INIT;
		if( _ovdrv_num >= _ovdrv_max ) return pxtnERR.pxtnERR_fmt_unknown;

		pxtnERR    res   = pxtnERR.pxtnERR_VOID;
		pxtnOverDrive *ovdrv = allocate!pxtnOverDrive();
		res = ovdrv.Read( p_doc ); if( res != pxtnERR.pxtnOK ) goto term;
		res = pxtnERR.pxtnOK;
	term:
		if( res == pxtnERR.pxtnOK ){ _ovdrvs[ _ovdrv_num ] = ovdrv; _ovdrv_num++; }
		else               { SAFE_DELETE( ovdrv ); }

		return res;
	}

	pxtnERR _io_Read_Woice( pxtnDescriptor *p_doc, pxtnWOICETYPE type )
	{
		pxtnERR res = pxtnERR.pxtnERR_VOID;

		if( !_b_init ) return pxtnERR.pxtnERR_INIT;
		if( !_woices ) return pxtnERR.pxtnERR_INIT;
		if( _woice_num >= _woice_max ) return pxtnERR.pxtnERR_woice_full;

		pxtnWoice *woice = allocate!pxtnWoice();

		switch( type )
		{
		case pxtnWOICETYPE.pxtnWOICE_PCM : res = woice.io_matePCM_r( p_doc ); if( res != pxtnERR.pxtnOK ) goto term; break;
		case pxtnWOICETYPE.pxtnWOICE_PTV : res = woice.io_matePTV_r( p_doc ); if( res != pxtnERR.pxtnOK ) goto term; break;
		case pxtnWOICETYPE.pxtnWOICE_PTN : res = woice.io_matePTN_r( p_doc ); if( res != pxtnERR.pxtnOK ) goto term; break;
		case pxtnWOICETYPE.pxtnWOICE_OGGV:
	version(pxINCLUDE_OGGVORBIS) {
			res = woice.io_mateOGGV_r( p_doc );
			if( res != pxtnERR.pxtnOK ) goto term;
			break;
	} else {
			res = pxtnERR.pxtnERR_ogg_no_supported; goto term;
	}

		default: res = pxtnERR.pxtnERR_fmt_unknown; goto term;
		}
		_woices[ _woice_num ] = woice; _woice_num++;
		res = pxtnERR.pxtnOK;
	term:
		if( res != pxtnERR.pxtnOK ) SAFE_DELETE( woice );
		return res;
	}

	pxtnERR _io_Read_OldUnit( pxtnDescriptor *p_doc, int32_t ver        )
	{
		if( !_b_init               ) return pxtnERR.pxtnERR_INIT;
		if( !_units                ) return pxtnERR.pxtnERR_INIT;
		if( _unit_num >= _unit_max ) return pxtnERR.pxtnERR_fmt_unknown;

		pxtnERR   res   = pxtnERR.pxtnERR_VOID  ;
		pxtnUnit* unit  = allocate!pxtnUnit();
		int32_t   group =              0;

		switch( ver )
		{
		case  1: if( !unit.Read_v1x ( p_doc, &group )                    ) goto term; break;
		case  3: res = unit.Read_v3x( p_doc, &group ); if( res != pxtnERR.pxtnOK ) goto term; break;
		default: res = pxtnERR.pxtnERR_fmt_unknown; goto term;
		}

		if( group >= _group_num ) group = _group_num - 1;

		evels.x4x_Read_Add( 0, cast(uint8_t)_unit_num, EVENTKIND_GROUPNO, cast(int32_t)group     );
		evels.x4x_Read_NewKind();
		evels.x4x_Read_Add( 0, cast(uint8_t)_unit_num, EVENTKIND_VOICENO, cast(int32_t)_unit_num );
		evels.x4x_Read_NewKind();

		res = pxtnERR.pxtnOK;
	term:
		if( res == pxtnERR.pxtnOK ){ _units[ _unit_num ] = unit; _unit_num++; }
		else               { SAFE_DELETE( unit ); }

		return res;
	}

	/////////////
	// assi woice
	/////////////


	bool _io_assiWOIC_w( pxtnDescriptor *p_doc, int32_t idx ) const
	{
		if( !_b_init ) return false;

		_ASSIST_WOICE assi = {0};
		int32_t       size;
		int32_t       name_size = 0;
		const char*   p_name = _woices[ idx ].get_name_buf( &name_size );

		if( name_size > pxtnMAX_TUNEWOICENAME ) return false;

		memcpy( assi.name.ptr, p_name, name_size );
		assi.woice_index = cast(uint16_t)idx;

		size =  _ASSIST_WOICE.sizeof;
		if( !p_doc.w_asfile( &size, uint32_t.sizeof, 1 ) ) return false;
		if( !p_doc.w_asfile( &assi, size,             1 ) ) return false;

		return true;
	}

	pxtnERR _io_assiWOIC_r( pxtnDescriptor *p_doc )
	{
		if( !_b_init ) return pxtnERR.pxtnERR_INIT;

		_ASSIST_WOICE assi = {0};
		int32_t       size =  0 ;

		if( !p_doc.r( &size,    4, 1 )    ) return pxtnERR.pxtnERR_desc_r     ;
		if( size != assi.sizeof           ) return pxtnERR.pxtnERR_fmt_unknown;
		if( !p_doc.r( &assi, size, 1 )    ) return pxtnERR.pxtnERR_desc_r     ;
		if( assi.rrr                       ) return pxtnERR.pxtnERR_fmt_unknown;
		if( assi.woice_index >= _woice_num ) return pxtnERR.pxtnERR_fmt_unknown;

		if( !_woices[ assi.woice_index ].set_name_buf( assi.name.ptr, pxtnMAX_TUNEWOICENAME ) ) return pxtnERR.pxtnERR_FATAL;

		return pxtnERR.pxtnOK;
	}
	// -----
	// assi unit.
	// -----

	bool _io_assiUNIT_w( pxtnDescriptor *p_doc, int32_t idx ) const
	{
		if( !_b_init ) return false;

		_ASSIST_UNIT assi = {0};
		int32_t      size;
		int32_t      name_size;
		const char*  p_name = _units[ idx ].get_name_buf( &name_size );

		memcpy( assi.name.ptr, p_name, name_size );
		assi.unit_index = cast(uint16_t)idx;

		size = assi.sizeof;
		if( !p_doc.w_asfile( &size, uint32_t.sizeof, 1 ) ) return false;
		if( !p_doc.w_asfile( &assi, size            , 1 ) ) return false;

		return true;
	}

	pxtnERR _io_assiUNIT_r( pxtnDescriptor *p_doc )
	{
		if( !_b_init ) return pxtnERR.pxtnERR_INIT;

		_ASSIST_UNIT assi = {0};
		int32_t      size;

		if( !p_doc.r( &size, 4,            1 ) ) return pxtnERR.pxtnERR_desc_r     ;
		if( size != assi.sizeof                ) return pxtnERR.pxtnERR_fmt_unknown;
		if( !p_doc.r( &assi, assi.sizeof, 1 ) ) return pxtnERR.pxtnERR_desc_r     ;
		if( assi.rrr                            ) return pxtnERR.pxtnERR_fmt_unknown;
		if( assi.unit_index >= _unit_num        ) return pxtnERR.pxtnERR_fmt_unknown;

		if( !_units[ assi.unit_index ].set_name_buf( assi.name.ptr, pxtnMAX_TUNEUNITNAME ) ) return pxtnERR.pxtnERR_FATAL;

		return pxtnERR.pxtnOK;
	}
	// -----
	// unit num
	// -----

	bool _io_UNIT_num_w( pxtnDescriptor *p_doc ) const
	{
		if( !_b_init ) return false;

		_NUM_UNIT data;
		int32_t   size;

		memset( &data, 0,  _NUM_UNIT.sizeof );

		data.num = cast(int16_t)_unit_num;

		size = _NUM_UNIT.sizeof;
		if( !p_doc.w_asfile( &size, int32_t.sizeof, 1 ) ) return false;
		if( !p_doc.w_asfile( &data, size       , 1 ) ) return false;

		return true;
	}

	pxtnERR _io_UNIT_num_r    ( pxtnDescriptor *p_doc, int32_t* p_num )
	{
		if( !_b_init ) return pxtnERR.pxtnERR_INIT;

		_NUM_UNIT data = {0};
		int32_t   size =  0 ;

		if( !p_doc.r( &size, 4,                   1 ) ) return pxtnERR.pxtnERR_desc_r     ;
		if( size !=  _NUM_UNIT.sizeof                ) return pxtnERR.pxtnERR_fmt_unknown;
		if( !p_doc.r( &data,  _NUM_UNIT.sizeof, 1 ) ) return pxtnERR.pxtnERR_desc_r     ;
		if( data.rrr                                   ) return pxtnERR.pxtnERR_fmt_unknown;
		if( data.num > _unit_max                       ) return pxtnERR.pxtnERR_fmt_new    ;
		if( data.num <         0                       ) return pxtnERR.pxtnERR_fmt_unknown;
		*p_num = data.num;

		return pxtnERR.pxtnOK;
	}


	// fix old key event
	bool _x3x_TuningKeyEvent()
	{
		if( !_b_init ) return false;

		if( _unit_num > _woice_num ) return false;

		for( int32_t u = 0; u < _unit_num; u++ )
		{
			if( u >= _woice_num ) return false;

			int32_t change_value = _woices[ u ].get_x3x_basic_key() - EVENTDEFAULT_BASICKEY;

			if( !evels.get_Count( cast(uint8_t)u, cast(uint8_t)EVENTKIND_KEY ) )
			{
				evels.Record_Add_i( 0, cast(uint8_t)u, EVENTKIND_KEY, cast(int32_t)0x6000 );
			}
			evels.Record_Value_Change( 0, -1, cast(uint8_t)u, EVENTKIND_KEY, change_value );
		}
		return true;
	}

	// fix old tuning (1.0)
	bool _x3x_AddTuningEvent()
	{
		if( !_b_init ) return false;

		if( _unit_num > _woice_num ) return false;

		for( int32_t u = 0; u < _unit_num; u++ )
		{
			float tuning = _woices[ u ].get_x3x_tuning();
			if( tuning ) evels.Record_Add_f( 0, cast(uint8_t)u, EVENTKIND_TUNING, tuning );
		}

		return true;
	}

	bool _x3x_SetVoiceNames()
	{
		if( !_b_init ) return false;

		for( int32_t i = 0; i < _woice_num; i++ )
		{
			char[ pxtnMAX_TUNEWOICENAME + 1 ] name;
			sprintf( name.ptr, "voice_%02d", i );
			_woices[ i ].set_name_buf( name.ptr, 8 );
		}
		return true;
	}

	//////////////
	// vomit..
	//////////////
	bool     _moo_b_valid_data;
	bool     _moo_b_end_vomit = true;
	bool     _moo_b_init      ;

	bool     _moo_b_mute_by_unit;
	bool     _moo_b_loop = true;

	int32_t  _moo_smp_smooth  ;
	float    _moo_clock_rate  ; // as the sample
	int32_t  _moo_smp_count   ;
	int32_t  _moo_smp_start   ;
	int32_t  _moo_smp_end     ;
	int32_t  _moo_smp_repeat  ;

	int32_t  _moo_fade_count  ;
	int32_t  _moo_fade_max    ;
	int32_t  _moo_fade_fade   ;
	float    _moo_master_vol = 1.0f ;

	int32_t  _moo_top;
	float    _moo_smp_stride  ;
	int32_t  _moo_time_pan_index;

	float    _moo_bt_tempo    ;

	// for make now-meas
	int32_t  _moo_bt_clock    ;
	int32_t  _moo_bt_num      ;

	int32_t* _moo_group_smps  ;

	const(EVERECORD)*     _moo_p_eve;

	pxtnPulse_Frequency* _moo_freq ;


	pxtnERR _init( int32_t fix_evels_num, bool b_edit )
	{
		if( _b_init ) return pxtnERR.pxtnERR_INIT;

		pxtnERR res       = pxtnERR.pxtnERR_VOID;
		int32_t byte_size =            0;

		text      = allocate!pxtnText();
		if( !( text ) ){ res = pxtnERR.pxtnERR_INIT    ; goto End; }
		master    = allocate!pxtnMaster();
		if( !( master ) ){ res = pxtnERR.pxtnERR_INIT    ; goto End; }
		evels     = allocate!pxtnEvelist();
		if( !( evels ) ){ res = pxtnERR.pxtnERR_INIT    ; goto End; }
		_ptn_bldr = allocate!pxtnPulse_NoiseBuilder();
		if( !( _ptn_bldr ) ){ res = pxtnERR.pxtnERR_INIT    ; goto End; }
		if( !  _ptn_bldr.Init()                          ){ res = pxtnERR.pxtnERR_ptn_init; goto End; }

		if( fix_evels_num )
		{
			_b_fix_evels_num = true;
			if( !evels.Allocate( fix_evels_num )   ){ res = pxtnERR.pxtnERR_memory; goto End; }
		}
		else
		{
			_b_fix_evels_num = false;
		}

		// delay
		byte_size = (pxtnDelay*).sizeof * pxtnMAX_TUNEDELAYSTRUCT;
		_delays = cast(pxtnDelay**    )malloc( byte_size );
		if( !( _delays  ) ){ res = pxtnERR.pxtnERR_memory; goto End; }
		memset( _delays, 0,                        byte_size );
		_delay_max = pxtnMAX_TUNEDELAYSTRUCT;

		// over-drive
		byte_size = (pxtnOverDrive*).sizeof * pxtnMAX_TUNEOVERDRIVESTRUCT;
		_ovdrvs = cast(pxtnOverDrive**)malloc( byte_size );
		if( !( _ovdrvs  ) ){ res = pxtnERR.pxtnERR_memory; goto End; }
		memset( _ovdrvs, 0,                        byte_size );
		_ovdrv_max = pxtnMAX_TUNEOVERDRIVESTRUCT;

		// woice
		byte_size = (pxtnWoice*).sizeof * pxtnMAX_TUNEWOICESTRUCT;
		_woices = cast(pxtnWoice**    )malloc( byte_size );
		if( !( _woices  ) ){ res = pxtnERR.pxtnERR_memory; goto End; }
		memset( _woices, 0,                        byte_size );
		_woice_max = pxtnMAX_TUNEWOICESTRUCT;

		// unit
		byte_size = (pxtnUnit*).sizeof * pxtnMAX_TUNEUNITSTRUCT;
		_units = cast(pxtnUnit**      )malloc( byte_size );
		if( !( _units  ) ){ res = pxtnERR.pxtnERR_memory; goto End; }
		memset( _units, 0,                         byte_size );
		_unit_max = pxtnMAX_TUNEUNITSTRUCT;

		_group_num = pxtnMAX_TUNEGROUPNUM  ;

		if( !_moo_init() ){ res = pxtnERR.pxtnERR_moo_init; goto End; }


		if( fix_evels_num ) _moo_b_valid_data = true;

		_b_edit = b_edit;
		res     = pxtnERR.pxtnOK;
		_b_init = true  ;
	End:
		if( !_b_init ) _release();
		return res;
	}
	bool _release()
	{
		if( !_b_init ) return false;
		_b_init = false;

		_moo_destructer();

		SAFE_DELETE( text      );
		SAFE_DELETE( master    );
		SAFE_DELETE( evels     );
		SAFE_DELETE( _ptn_bldr );
		if( _delays ){ for( int32_t i = 0; i < _delay_num; i++ ) SAFE_DELETE( _delays[ i ] ); free( _delays ); _delays = null; }
		if( _ovdrvs ){ for( int32_t i = 0; i < _ovdrv_num; i++ ) SAFE_DELETE( _ovdrvs[ i ] ); free( _ovdrvs ); _ovdrvs = null; }
		if( _woices ){ for( int32_t i = 0; i < _woice_num; i++ ) SAFE_DELETE( _woices[ i ] ); free( _woices ); _woices = null; }
		if( _units  ){ for( int32_t i = 0; i < _unit_num ; i++ ) SAFE_DELETE( _units [ i ] ); free( _units  ); _units  = null; }
		return true;
	}

	pxtnERR _pre_count_event( pxtnDescriptor *p_doc, int32_t* p_count )
	{
		if( !_b_init ) return pxtnERR.pxtnERR_INIT ;
		if( !p_count ) return pxtnERR.pxtnERR_param;

		pxtnERR      res   = pxtnERR.pxtnERR_VOID;
		bool         b_end = false;

		int32_t      count = 0;
		int32_t      c     = 0;
		int32_t      size  = 0;
		char[ _CODESIZE + 1 ]         code = '\0';

		uint16_t     exe_ver = 0;
		_enum_FMTVER fmt_ver = _enum_FMTVER._enum_FMTVER_unknown;

		res = _ReadVersion( p_doc, &fmt_ver, &exe_ver ); if( res != pxtnERR.pxtnOK ) goto term;

		if( fmt_ver == _enum_FMTVER._enum_FMTVER_x1x )
		{
			count = _MAX_FMTVER_x1x_EVENTNUM;
			res = pxtnERR.pxtnOK;
			goto term;
		}

		while( !b_end )
		{
			if( !p_doc.r( code.ptr, 1, _CODESIZE ) ){ res = pxtnERR.pxtnERR_desc_r; goto term; }

			switch( _CheckTagCode( code.ptr ) )
			{
			case _enum_Tag._TAG_Event_V5    : count += evels .io_Read_EventNum ( p_doc ); break;
			case _enum_Tag._TAG_MasterV5    : count += master.io_r_v5_EventNum ( p_doc ); break;
			case _enum_Tag._TAG_x4x_evenMAST: count += master.io_r_x4x_EventNum( p_doc ); break;
			case _enum_Tag._TAG_x4x_evenUNIT: res = evels .io_Read_x4x_EventNum( p_doc, &c ); if( res != pxtnERR.pxtnOK ) goto term; count += c; break;
			case _enum_Tag._TAG_pxtoneND    : b_end = true; break;

			// skip
			case _enum_Tag._TAG_antiOPER    :
			case _enum_Tag._TAG_num_UNIT    :
			case _enum_Tag._TAG_x3x_pxtnUNIT:
			case _enum_Tag._TAG_matePCM     :
			case _enum_Tag._TAG_matePTV     :
			case _enum_Tag._TAG_matePTN     :
			case _enum_Tag._TAG_mateOGGV    :
			case _enum_Tag._TAG_effeDELA    :
			case _enum_Tag._TAG_effeOVER    :
			case _enum_Tag._TAG_textNAME    :
			case _enum_Tag._TAG_textCOMM    :
			case _enum_Tag._TAG_assiUNIT    :
			case _enum_Tag._TAG_assiWOIC    :

				if( !p_doc.r( &size, int32_t.sizeof, 1 ) ){ res = pxtnERR.pxtnERR_desc_r; goto term; }
				if( !p_doc.seek( pxtnSEEK.pxtnSEEK_cur, size )     ){ res = pxtnERR.pxtnERR_desc_r; goto term; }
				break;

			// ignore
			case _enum_Tag._TAG_x1x_PROJ    :
			case _enum_Tag._TAG_x1x_UNIT    :
			case _enum_Tag._TAG_x1x_PCM     :
			case _enum_Tag._TAG_x1x_EVEN    :
			case _enum_Tag._TAG_x1x_END     : res = pxtnERR.pxtnERR_x1x_ignore; goto term;
			default               : res = pxtnERR.pxtnERR_FATAL     ; goto term;
			}
		}

		if( fmt_ver <= _enum_FMTVER._enum_FMTVER_x3x ) count += pxtnMAX_TUNEUNITSTRUCT * 4; // voice_no, group_no, key tuning, key event x3x

		res = pxtnERR.pxtnOK;
	term:

		if( res != pxtnERR.pxtnOK ) *p_count =     0;
		else                *p_count = count;

		return res;
	}

	void _moo_destructer()
	{

		_moo_release();
	}

	bool _moo_init()
	{
		bool b_ret = false;

		_moo_freq = allocate!pxtnPulse_Frequency();
		if( !( _moo_freq ) ||  !_moo_freq.Init() ) goto term;
		if( !pxtnMem_zero_alloc( cast(void **)&_moo_group_smps, int32_t.sizeof * _group_num ) ) goto term;

		_moo_b_init = true;
		b_ret       = true;
	term:
		if( !b_ret ) _moo_release();

		return b_ret;
	}
	bool _moo_release()
	{
		if( !_moo_b_init ) return false;
		_moo_b_init = false;
		SAFE_DELETE( _moo_freq );
		if( _moo_group_smps ) free( _moo_group_smps ); _moo_group_smps = null;
		return true;
	}


	////////////////////////////////////////////////
	// Units   ////////////////////////////////////
	////////////////////////////////////////////////

	bool _moo_ResetVoiceOn( pxtnUnit *p_u, int32_t  w ) const
	{
		if( !_moo_b_init ) return false;

		const(pxtnVOICEINSTANCE)* p_inst;
		const(pxtnVOICEUNIT)*     p_vc  ;
		const(pxtnWoice)*         p_wc = Woice_Get( w );

		if( !p_wc ) return false;

		p_u.set_woice( p_wc );

		for( int32_t v = 0; v < p_wc.get_voice_num(); v++ )
		{
			p_inst = p_wc.get_instance( v );
			p_vc   = p_wc.get_voice   ( v );

			float ofs_freq = 0;
			if( p_vc.voice_flags & PTV_VOICEFLAG_BEATFIT )
			{
				ofs_freq = ( p_inst.smp_body_w * _moo_bt_tempo ) / ( 44100 * 60 * p_vc.tuning );
			}
			else
			{
				ofs_freq = _moo_freq.Get( EVENTDEFAULT_BASICKEY - p_vc.basic_key ) * p_vc.tuning;
			}
			p_u.Tone_Reset_and_2prm( v, cast(int32_t)( p_inst.env_release / _moo_clock_rate ), ofs_freq );
		}
		return true;
	}


	bool _moo_InitUnitTone()
	{
		if( !_moo_b_init ) return false;
		for( int32_t u = 0; u < _unit_num; u++ )
		{
			pxtnUnit *p_u = Unit_Get_variable( u );
			p_u.Tone_Init();
			_moo_ResetVoiceOn( p_u, EVENTDEFAULT_VOICENO );
		}
		return true;
	}


	bool _moo_PXTONE_SAMPLE( void *p_data )
	{
		if( !_moo_b_init ) return false;

		// envelope..
		for( int32_t u = 0; u < _unit_num;  u++ ) _units[ u ].Tone_Envelope();

		int32_t  clock = cast(int32_t)( _moo_smp_count / _moo_clock_rate );

		// events..
		for( ; _moo_p_eve && _moo_p_eve.clock <= clock; _moo_p_eve = _moo_p_eve.next )
		{
			int32_t                  u   = _moo_p_eve.unit_no;
			pxtnUnit*                p_u = _units[ u ];
			pxtnVOICETONE*           p_tone;
			const(pxtnWoice)*         p_wc  ;
			const(pxtnVOICEINSTANCE)* p_vi  ;

			switch( _moo_p_eve.kind )
			{
			case EVENTKIND_ON       :
				{
					int32_t on_count = cast(int32_t)( (_moo_p_eve.clock + _moo_p_eve.value - clock) * _moo_clock_rate );
					if( on_count <= 0 ){ p_u.Tone_ZeroLives(); break; }

					p_u.Tone_KeyOn();

					p_wc = p_u.get_woice();
					if( !( p_wc ) ) break;
					for( int32_t v = 0; v < p_wc.get_voice_num(); v++ )
					{
						p_tone = p_u .get_tone    ( v );
						p_vi   = p_wc.get_instance( v );

						// release..
						if( p_vi.env_release )
						{
							int32_t        max_life_count1 = cast(int32_t)( ( _moo_p_eve.value - ( clock - _moo_p_eve.clock ) ) * _moo_clock_rate ) + p_vi.env_release;
							int32_t        max_life_count2;
							int32_t        c    = _moo_p_eve.clock + _moo_p_eve.value + p_tone.env_release_clock;
							const(EVERECORD)* next = null;
							for( const(EVERECORD)* p = _moo_p_eve.next; p; p = p.next )
							{
								if( p.clock > c ) break;
								if( p.unit_no == u && p.kind == EVENTKIND_ON ){ next = p; break; }
							}
							if( !next ) max_life_count2 = _moo_smp_end - cast(int32_t)( clock   * _moo_clock_rate );
							else        max_life_count2 = cast(int32_t)( ( next.clock -      clock ) * _moo_clock_rate );
							if( max_life_count1 < max_life_count2 ) p_tone.life_count = max_life_count1;
							else                                    p_tone.life_count = max_life_count2;
						}
						// no-release..
						else
						{
							p_tone.life_count = cast(int32_t)( ( _moo_p_eve.value - ( clock - _moo_p_eve.clock ) ) * _moo_clock_rate );
						}

						if( p_tone.life_count > 0 )
						{
							p_tone.on_count  = on_count;
							p_tone.smp_pos   = 0;
							p_tone.env_pos   = 0;
							if( p_vi.env_size ) p_tone.env_volume = p_tone.env_start  =   0; // envelope
							else                 p_tone.env_volume = p_tone.env_start  = 128; // no-envelope
						}
					}
					break;
				}

			case EVENTKIND_KEY       : p_u.Tone_Key       (              _moo_p_eve.value ); break;
			case EVENTKIND_PAN_VOLUME: p_u.Tone_Pan_Volume( _dst_ch_num, _moo_p_eve.value ); break;
			case EVENTKIND_PAN_TIME  : p_u.Tone_Pan_Time  ( _dst_ch_num, _moo_p_eve.value, _dst_sps ); break;
			case EVENTKIND_VELOCITY  : p_u.Tone_Velocity  (              _moo_p_eve.value ); break;
			case EVENTKIND_VOLUME    : p_u.Tone_Volume    (              _moo_p_eve.value ); break;
			case EVENTKIND_PORTAMENT : p_u.Tone_Portament ( cast(int32_t)(   _moo_p_eve.value * _moo_clock_rate ) ); break;
			case EVENTKIND_BEATCLOCK : break;
			case EVENTKIND_BEATTEMPO : break;
			case EVENTKIND_BEATNUM   : break;
			case EVENTKIND_REPEAT    : break;
			case EVENTKIND_LAST      : break;
			case EVENTKIND_VOICENO   : _moo_ResetVoiceOn   ( p_u, _moo_p_eve.value            ); break;
			case EVENTKIND_GROUPNO   : p_u.Tone_GroupNo   (              _moo_p_eve.value    ); break;
			case EVENTKIND_TUNING    : p_u.Tone_Tuning    ( *( cast(float*)(&_moo_p_eve.value) ) ); break;
			default: break;
			}
		}

		// sampling..
		for( int32_t u = 0; u < _unit_num; u++ )
		{
			_units[ u ].Tone_Sample( _moo_b_mute_by_unit, _dst_ch_num, _moo_time_pan_index, _moo_smp_smooth );
		}

		for( int32_t ch = 0; ch < _dst_ch_num; ch++ )
		{
			for( int32_t g = 0; g < _group_num; g++ ) _moo_group_smps[ g ] = 0;
			for( int32_t u = 0; u < _unit_num ; u++ ) _units [ u ].Tone_Supple(     _moo_group_smps, ch, _moo_time_pan_index );
			for( int32_t o = 0; o < _ovdrv_num; o++ ) _ovdrvs[ o ].Tone_Supple(     _moo_group_smps );
			for( int32_t d = 0; d < _delay_num; d++ ) _delays[ d ].Tone_Supple( ch, _moo_group_smps );

			// collect.
			int32_t  work = 0;
			for( int32_t g = 0; g < _group_num; g++ ) work += _moo_group_smps[ g ];

			// fade..
			if( _moo_fade_fade ) work = work * ( _moo_fade_count >> 8 ) / _moo_fade_max;

			// master volume
			work = cast(int32_t)( work * _moo_master_vol );

			// to buffer..
			if( work >  _moo_top ) work =  _moo_top;
			if( work < -_moo_top ) work = -_moo_top;
			*( cast(int16_t*)p_data + ch ) = cast(int16_t)( work );
		}

		// --------------
		// increments..

		_moo_smp_count++;
		_moo_time_pan_index = ( _moo_time_pan_index + 1 ) & ( pxtnBUFSIZE_TIMEPAN - 1 );

		for( int32_t u = 0; u < _unit_num;  u++ )
		{
			int32_t  key_now = _units[ u ].Tone_Increment_Key();
			_units[ u ].Tone_Increment_Sample( _moo_freq.Get2( key_now ) *_moo_smp_stride );
		}

		// delay
		for( int32_t d = 0; d < _delay_num; d++ ) _delays[ d ].Tone_Increment();

		// fade out
		if( _moo_fade_fade < 0 )
		{
			if( _moo_fade_count > 0  ) _moo_fade_count--;
			else return false;
		}
		// fade in
		else if( _moo_fade_fade > 0 )
		{
			if( _moo_fade_count < (_moo_fade_max << 8) ) _moo_fade_count++;
			else                                         _moo_fade_fade = 0;
		}

		if( _moo_smp_count >= _moo_smp_end )
		{
			if( !_moo_b_loop ) return false;
			_moo_smp_count = _moo_smp_repeat;
			_moo_p_eve     = evels.get_Records();
			_moo_InitUnitTone();
		}
		return true;
	}

	pxtnSampledCallback _sampled_proc;
	void*               _sampled_user;

public :

	~this()
	{
		_release();
	}

	pxtnText    *text  ;
	pxtnMaster  *master;
	pxtnEvelist *evels ;

	pxtnERR init_        (){ return _init( 0, false ); }
	pxtnERR init_collage( int32_t fix_evels_num ){ return _init( fix_evels_num, true ); }
	bool clear()
	{
		if( !_b_init ) return false;

		if( !_b_edit ) _moo_b_valid_data = false;

		if( !text.set_name_buf   ( "", 0 ) ) return false;
		if( !text.set_comment_buf( "", 0 ) ) return false;

		evels.Clear();

		for( int32_t i = 0; i < _delay_num; i++ ) SAFE_DELETE( _delays[ i ] ); _delay_num = 0;
		for( int32_t i = 0; i < _delay_num; i++ ) SAFE_DELETE( _ovdrvs[ i ] ); _ovdrv_num = 0;
		for( int32_t i = 0; i < _woice_num; i++ ) SAFE_DELETE( _woices[ i ] ); _woice_num = 0;
		for( int32_t i = 0; i < _unit_num ; i++ ) SAFE_DELETE( _units [ i ] ); _unit_num  = 0;

		master.Reset();

		if( !_b_edit ) evels.Release();
		else           evels.Clear  ();
		return true;
	}

	////////////////////////////////////////
	// save               //////////////////
	////////////////////////////////////////

	pxtnERR write( pxtnDescriptor *p_doc, bool b_tune, uint16_t exe_ver )
	{
		if( !_b_init ) return pxtnERR.pxtnERR_INIT;

		bool     b_ret = false;
		int32_t  rough = b_tune ? 10 : 1;
		uint16_t rrr   =            0;
		pxtnERR  res   = pxtnERR.pxtnERR_VOID;

		// format version
		if( b_tune ){ if( !p_doc.w_asfile( _code_tune_v5, 1, _VERSIONSIZE ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; } }
		else        { if( !p_doc.w_asfile( _code_proj_v5, 1, _VERSIONSIZE ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; } }

		// exe version
		if( !p_doc.w_asfile( &exe_ver, uint16_t.sizeof, 1 )                ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
		if( !p_doc.w_asfile( &rrr    , uint16_t.sizeof, 1 )                ){ res = pxtnERR.pxtnERR_desc_w; goto End; }

		// master
		if( !p_doc.w_asfile( _code_MasterV5    , 1, _CODESIZE ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
		if( !master.io_w_v5(   p_doc, rough  )                  ){ res = pxtnERR.pxtnERR_desc_w; goto End; }

		// event
		if( !p_doc.w_asfile( _code_Event_V5,     1, _CODESIZE ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
		if( !evels.io_Write(   p_doc, rough  )                  ){ res = pxtnERR.pxtnERR_desc_w; goto End; }

		// name
		if( text.is_name_buf() )
		{
			if( !p_doc.w_asfile( _code_textNAME, 1, _CODESIZE ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
			if( !text.Name_w( p_doc  )                          ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
		}

		// comment
		if( text.is_comment_buf() )
		{
			if( !p_doc.w_asfile( _code_textCOMM, 1, _CODESIZE ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
			if( !text.Comment_w( p_doc                        ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
		}

		// delay
		for( int32_t d = 0; d < _delay_num; d++ )
		{
			if( !p_doc.w_asfile( _code_effeDELA, 1, _CODESIZE ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
			if( !_delays[ d ].Write( p_doc )                    ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
		}

		// overdrive
		for( int32_t o = 0; o < _ovdrv_num; o++ )
		{
			if( !p_doc.w_asfile( _code_effeOVER, 1, _CODESIZE ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
			if( !_ovdrvs[ o ].Write( p_doc )                    ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
		}

		// woice
		for( int32_t w = 0; w < _woice_num; w++ )
		{
			pxtnWoice * p_w = _woices[ w ];

			switch( p_w.get_type() )
			{
			case pxtnWOICETYPE.pxtnWOICE_PCM:
				if( !p_doc.w_asfile( _code_matePCM , 1, _CODESIZE ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
				if( !p_w.io_matePCM_w ( p_doc )                     ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
				break;
			case pxtnWOICETYPE.pxtnWOICE_PTV:
				if( !p_doc.w_asfile( _code_matePTV , 1, _CODESIZE ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
				if( !p_w.io_matePTV_w ( p_doc                     ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
				break;
			case pxtnWOICETYPE.pxtnWOICE_PTN:
				if( !p_doc.w_asfile( _code_matePTN , 1, _CODESIZE ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
				if( !p_w.io_matePTN_w ( p_doc                     ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
				break;
			case pxtnWOICETYPE.pxtnWOICE_OGGV:

	version(pxINCLUDE_OGGVORBIS) {
				if( !p_doc.w_asfile( _code_mateOGGV, 1, _CODESIZE ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
				if( !p_w.io_mateOGGV_w( p_doc                     ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
				break;
	} else {
				res = pxtnERR.pxtnERR_ogg_no_supported; goto End;
	}
	        default:
	            res = pxtnERR.pxtnERR_inv_data; goto End;
			}

	        if( !b_tune && p_w.is_name_buf() )
			{
				if( !p_doc.w_asfile( _code_assiWOIC, 1, _CODESIZE ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
				if( !_io_assiWOIC_w( p_doc, w )                      ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
			}
		}

		// unit
		if( !p_doc.w_asfile( _code_num_UNIT, 1, _CODESIZE ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
		if( !_io_UNIT_num_w( p_doc )                         ){ res = pxtnERR.pxtnERR_desc_w; goto End; }

		for( int32_t u = 0; u < _unit_num; u++ )
		{
			if( !b_tune && _units[ u ].is_name_buf() )
			{
				if( !p_doc.w_asfile( _code_assiUNIT, 1, _CODESIZE) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
				if( !_io_assiUNIT_w( p_doc, u )                     ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
			}
		}

		{
			int32_t end_size = 0;
			if( !p_doc.w_asfile( _code_pxtoneND, 1, _CODESIZE ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
			if( !p_doc.w_asfile( &end_size     , 4,         1 ) ){ res = pxtnERR.pxtnERR_desc_w; goto End; }
		}

		res = pxtnERR.pxtnOK;
	End:

		return res;
	}
	pxtnERR read( pxtnDescriptor *p_doc )
	{
		if( !_b_init ) return pxtnERR.pxtnERR_INIT;

		pxtnERR      res       = pxtnERR.pxtnERR_VOID;
		uint16_t     exe_ver   =            0;
		_enum_FMTVER fmt_ver   = _enum_FMTVER._enum_FMTVER_unknown;
		int32_t      event_num =            0;

		clear();

		res = _pre_count_event( p_doc, &event_num );
		if( res != pxtnERR.pxtnOK ) goto term;
		p_doc.seek( pxtnSEEK.pxtnSEEK_set, 0 );

		if( _b_fix_evels_num )
		{
			if( event_num > evels.get_Num_Max() ){ res = pxtnERR.pxtnERR_too_much_event; goto term; }
		}
		else
		{
			if( !evels.Allocate( event_num )    ){ res = pxtnERR.pxtnERR_memory        ; goto term; }
		}

		res = _ReadVersion(   p_doc, &fmt_ver, &exe_ver ); if( res != pxtnERR.pxtnOK ) goto term;

		if( fmt_ver >= _enum_FMTVER._enum_FMTVER_v5 ) evels.Linear_Start  ();
		else                             evels.x4x_Read_Start();

		res = _ReadTuneItems( p_doc ); if( res != pxtnERR.pxtnOK ) goto term;

		if( fmt_ver >= _enum_FMTVER._enum_FMTVER_v5  ) evels.Linear_End( true );

		if( fmt_ver <= _enum_FMTVER._enum_FMTVER_x3x )
		{
			if( !_x3x_TuningKeyEvent() ){ res = pxtnERR.pxtnERR_x3x_key       ; goto term; }
			if( !_x3x_AddTuningEvent() ){ res = pxtnERR.pxtnERR_x3x_add_tuning; goto term; }
			_x3x_SetVoiceNames();
		}

		if( _b_edit && master.get_beat_clock() != EVENTDEFAULT_BEATCLOCK ){ res = pxtnERR.pxtnERR_deny_beatclock; goto term; }

		{
			int32_t clock1 = evels .get_Max_Clock ();
			int32_t clock2 = master.get_last_clock();

			if( clock1 > clock2 ) master.AdjustMeasNum( clock1 );
			else                  master.AdjustMeasNum( clock2 );
		}

		_moo_b_valid_data = true;
		res = pxtnERR.pxtnOK;
	term:

		if( res != pxtnERR.pxtnOK ) clear();

		return res;
	}

	bool AdjustMeasNum()
	{
		if( !_b_init ) return false;
		master.AdjustMeasNum( evels.get_Max_Clock() );
		return true;
	}

	int32_t get_last_error_id() const;

	pxtnERR tones_ready()
	{
		if( !_b_init ) return pxtnERR.pxtnERR_INIT;

		pxtnERR res        = pxtnERR.pxtnERR_VOID;
		int32_t beat_num   = master.get_beat_num  ();
		float   beat_tempo = master.get_beat_tempo();

		for( int32_t i = 0; i < _delay_num; i++ )
		{
			res = _delays[ i ].Tone_Ready( beat_num, beat_tempo, _dst_sps );
			if( res != pxtnERR.pxtnOK ) return res;
		}
		for( int32_t i = 0; i < _ovdrv_num; i++ )
		{
			_ovdrvs[ i ].Tone_Ready();
		}
		for( int32_t i = 0; i < _woice_num; i++ )
		{
			res = _woices[ i ].Tone_Ready( _ptn_bldr, _dst_sps );
			if( res != pxtnERR.pxtnOK ) return res;
		}
		return pxtnERR.pxtnOK;
	}
	bool tones_clear()
	{
		if( !_b_init ) return false;
		for( int32_t i = 0; i < _delay_num; i++ ) _delays[ i ].Tone_Clear();
		for( int32_t i = 0; i < _unit_num;  i++ ) _units [ i ].Tone_Clear();
		return true;
	}

	int32_t  Group_Num() const{ return _b_init ? _group_num : 0; }

	// ---------------------------
	// Delay..
	// ---------------------------

	int32_t  Delay_Num() const{ return _b_init ? _delay_num : 0; }
	int32_t  Delay_Max() const{ return _b_init ? _delay_max : 0; }
	bool Delay_Set( int32_t idx, DELAYUNIT unit, float freq, float rate, int32_t group )
	{
		if( !_b_init ) return false;
		if( idx >= _delay_num ) return false;
		_delays[ idx ].Set( unit, freq, rate, group );
		return true;
	}
	bool Delay_Add( DELAYUNIT unit, float freq, float rate, int32_t group )
	{
		if( !_b_init ) return false;
		if( _delay_num >= _delay_max ) return false;
		_delays[ _delay_num ] = allocate!pxtnDelay();
		_delays[ _delay_num ].Set( unit, freq, rate, group );
		_delay_num++;
		return true;
	}
	bool Delay_Remove( int32_t idx )
	{
		if( !_b_init ) return false;
		if( idx >= _delay_num ) return false;

		SAFE_DELETE( _delays[ idx ] );
		_delay_num--;
		for( int32_t i = idx; i < _delay_num; i++ ) _delays[ i ] = _delays[ i + 1 ];
		_delays[ _delay_num ] = null;
		return true;
	}
	pxtnERR Delay_ReadyTone( int32_t idx )
	{
		if( !_b_init ) return pxtnERR.pxtnERR_INIT;
		if( idx < 0 || idx >= _delay_num ) return pxtnERR.pxtnERR_param;
		return _delays[ idx ].Tone_Ready( master.get_beat_num(), master.get_beat_tempo(), _dst_sps );
	}
	pxtnDelay *Delay_Get( int32_t idx )
	{
		if( !_b_init ) return null;
		if( idx < 0 || idx >= _delay_num ) return null;
		return _delays[ idx ];
	}

	// ---------------------------
	// Over Drive..
	// ---------------------------

	int32_t  OverDrive_Num() const{ return _b_init ? _ovdrv_num : 0; }
	int32_t  OverDrive_Max() const{ return _b_init ? _ovdrv_max : 0; }

	bool OverDrive_Set( int32_t idx, float cut, float amp, int32_t group )
	{
		if( !_b_init ) return false;
		if( idx >= _ovdrv_num ) return false;
		_ovdrvs[ idx ].Set( cut, amp, group );
		return true;
	}

	bool OverDrive_Add( float cut, float amp, int32_t group )
	{
		if( !_b_init ) return false;
		if( _ovdrv_num >= _ovdrv_max ) return false;
		_ovdrvs[ _ovdrv_num ] = allocate!pxtnOverDrive();
		_ovdrvs[ _ovdrv_num ].Set( cut, amp, group );
		_ovdrv_num++;
		return true;
	}

	bool OverDrive_Remove( int32_t idx )
	{
		if( !_b_init ) return false;
		if( idx >= _ovdrv_num ) return false;

		SAFE_DELETE( _ovdrvs[ idx ] );
		_ovdrv_num--;
		for( int32_t i = idx; i < _ovdrv_num; i++ ) _ovdrvs[ i ] = _ovdrvs[ i + 1 ];
		_ovdrvs[ _ovdrv_num ] = null;
		return true;
	}

	bool OverDrive_ReadyTone( int32_t idx )
	{
		if( !_b_init ) return false;
		if( idx < 0 || idx >= _ovdrv_num ) return false;
		_ovdrvs[ idx ].Tone_Ready();
		return true;
	}

	pxtnOverDrive *OverDrive_Get( int32_t idx )
	{
		if( !_b_init ) return null;
		if( idx < 0 || idx >= _ovdrv_num ) return null;
		return _ovdrvs[ idx ];
	}

	// ---------------------------
	// Woice..
	// ---------------------------

	int32_t  Woice_Num() const{ return _b_init ? _woice_num : 0; }
	int32_t  Woice_Max() const{ return _b_init ? _woice_max : 0; }

	const(pxtnWoice) *Woice_Get( int32_t idx ) const
	{
		if( !_b_init ) return null;
		if( idx < 0 || idx >= _woice_num ) return null;
		return _woices[ idx ];
	}
	pxtnWoice* Woice_Get_variable( int32_t idx )
	{
		if( !_b_init ) return null;
		if( idx < 0 || idx >= _woice_num ) return null;
		return _woices[ idx ];
	}


	pxtnERR Woice_read( int32_t idx, pxtnDescriptor* desc, pxtnWOICETYPE type )
	{
		if( !_b_init ) return pxtnERR.pxtnERR_INIT;
		if( idx < 0 || idx >= _woice_max ) return pxtnERR.pxtnERR_param;
		if( idx > _woice_num             ) return pxtnERR.pxtnERR_param;
		if( idx == _woice_num ){ _woices[ idx ] = allocate!pxtnWoice(); _woice_num++; }

		pxtnERR res = pxtnERR.pxtnERR_VOID;
		res = _woices[ idx ].read( desc, type ); if( res != pxtnERR.pxtnOK ){ Woice_Remove( idx ); return res; }
		return res;
	}

	pxtnERR Woice_ReadyTone( int32_t idx )
	{
		if( !_b_init ) return pxtnERR.pxtnERR_INIT;
		if( idx < 0 || idx >= _woice_num ) return pxtnERR.pxtnERR_param;
		return _woices[ idx ].Tone_Ready( _ptn_bldr, _dst_sps );
	}

	bool Woice_Remove( int32_t idx )
	{
		if( !_b_init ) return false;
		if( idx < 0 || idx >= _woice_num ) return false;
		SAFE_DELETE( _woices[ idx ] );
		_woice_num--;
		for( int32_t i = idx; i < _woice_num; i++ ) _woices[ i ] = _woices[ i + 1 ];
		_woices[ _woice_num ] = null;
		return true;
	}

	bool Woice_Replace( int32_t old_place, int32_t new_place )
	{
		if( !_b_init ) return false;

		pxtnWoice* p_w       = _woices[ old_place ];
		int32_t    max_place = _woice_num - 1;

		if( new_place >  max_place ) new_place = max_place;
		if( new_place == old_place ) return true;

		if( old_place < new_place )
		{
			for( int32_t w = old_place; w < new_place; w++ ){ if( _woices[ w ] ) _woices[ w ] = _woices[ w + 1 ]; }
		}
		else
		{
			for( int32_t w = old_place; w > new_place; w-- ){ if( _woices[ w ] ) _woices[ w ] = _woices[ w - 1 ]; }
		}

		_woices[ new_place ] = p_w;
		return true;
	}

	// ---------------------------
	// Unit..
	// ---------------------------

	int32_t  Unit_Num() const{ return _b_init ? _unit_num : 0; }
	int32_t  Unit_Max() const{ return _b_init ? _unit_max : 0; }

	const(pxtnUnit) *Unit_Get( int32_t idx ) const
	{
		if( !_b_init ) return null;
		if( idx < 0 || idx >= _unit_num ) return null;
		return _units[ idx ];
	}
	pxtnUnit       *Unit_Get_variable( int32_t idx )
	{
		if( !_b_init ) return null;
		if( idx < 0 || idx >= _unit_num ) return null;
		return _units[ idx ];
	}

	bool Unit_Remove( int32_t idx )
	{
		if( !_b_init ) return false;
		if( idx < 0 || idx >= _unit_num ) return false;
		SAFE_DELETE( _units[ idx ] );
		_unit_num--;
		for( int32_t i = idx; i < _unit_num; i++ ) _units[ i ] = _units[ i + 1 ];
		_units[ _unit_num ] = null;
		return true;
	}

	bool Unit_Replace( int32_t old_place, int32_t new_place )
	{
		if( !_b_init ) return false;

		pxtnUnit* p_w        = _units[ old_place ];
		int32_t   max_place  = _unit_num - 1;

		if( new_place >  max_place ) new_place = max_place;
		if( new_place == old_place ) return true;

		if( old_place < new_place )
		{
			for( int32_t w = old_place; w < new_place; w++ ){ if( _units[ w ] ) _units[ w ] = _units[ w + 1 ]; }
		}
		else
		{
			for( int32_t w = old_place; w > new_place; w-- ){ if( _units[ w ] ) _units[ w ] = _units[ w - 1 ]; }
		}
		_units[ new_place ] = p_w;
		return true;
	}

	bool Unit_AddNew()
	{
		if( _unit_num >= _unit_max ) return false;
		_units[ _unit_num ] = allocate!pxtnUnit();
		_unit_num++;
		return true;
	}

	bool Unit_SetOpratedAll( bool b )
	{
		if( !_b_init ) return false;
		for( int32_t u = 0; u < _unit_num; u++ )
		{
			_units[ u ].set_operated( b );
			if( b ) _units[ u ].set_played( true );
		}
		return true;
	}

	bool Unit_Solo( int idx )
	{
		if( !_b_init ) return false;
		for( int32_t u = 0; u < _unit_num; u++ )
		{
			if( u == idx ) _units[ u ].set_played( true  );
			else           _units[ u ].set_played( false );
		}
		return false;
	}


	// ---------------------------
	// Quality..
	// ---------------------------

	bool set_destination_quality( int32_t ch_num, int32_t sps )
	{
		if( !_b_init ) return false;
		switch( ch_num )
		{
		case  1: break;
		case  2: break;
		default: return false;
		}

		_dst_ch_num = ch_num;
		_dst_sps    = sps   ;
		_dst_byte_per_smp = pxtnBITPERSAMPLE / 8 * ch_num;
		return true;
	}

	bool get_destination_quality( int32_t *p_ch_num, int32_t *p_sps ) const
	{
		if( !_b_init ) return false;
		if( p_ch_num ) *p_ch_num = _dst_ch_num;
		if( p_sps    ) *p_sps    = _dst_sps   ;
		return true;
	}

	bool set_sampled_callback   ( pxtnSampledCallback proc, void* user )
	{
		if( !_b_init ) return false;
		_sampled_proc = proc;
		_sampled_user = user;
		return true;
	}

	//////////////
	// Moo..
	//////////////

	///////////////////////
	// get / set
	///////////////////////

	bool moo_is_valid_data() const
	{
		if( !_moo_b_init ) return false;
		return _moo_b_valid_data;
	}
	bool moo_is_end_vomit() const
	{
		if( !_moo_b_init ) return true;
		return _moo_b_end_vomit ;
	}

	bool moo_set_mute_by_unit( bool b ){ if( !_moo_b_init ) return false; _moo_b_mute_by_unit = b; return true; }
	bool moo_set_loop        ( bool b ){ if( !_moo_b_init ) return false; _moo_b_loop         = b; return true; }
	bool moo_set_fade( int32_t  fade, float sec )
	{
		if( !_moo_b_init ) return false;
		_moo_fade_max = cast(int32_t)( cast(float)_dst_sps * sec ) >> 8;
		if(      fade < 0 ){ _moo_fade_fade  = -1; _moo_fade_count = _moo_fade_max << 8; } // out
		else if( fade > 0 ){ _moo_fade_fade  =  1; _moo_fade_count =  0;                 } // in
		else               { _moo_fade_fade =   0; _moo_fade_count =  0;                 } // off
		return true;
	}
	bool moo_set_master_volume( float v )
	{
		if( !_moo_b_init ) return false;
		if( v < 0 ) v = 0;
		if( v > 1 ) v = 1;
		_moo_master_vol = v;
		return true;
	}
	int32_t moo_get_total_sample   () const
	{
		if( !_b_init           ) return 0;
		if( !_moo_b_valid_data ) return 0;

		int32_t meas_num  ;
		int32_t beat_num  ;
		float   beat_tempo;
		master.Get( &beat_num, &beat_tempo, null, &meas_num );
		return pxtnService_moo_CalcSampleNum( meas_num, beat_num, _dst_sps, master.get_beat_tempo() );
	}

	int32_t moo_get_now_clock() const
	{
		if( !_moo_b_init ) return 0;
		if( _moo_clock_rate ) return cast(int32_t)( _moo_smp_count / _moo_clock_rate );
		return 0;
	}
	int32_t moo_get_end_clock() const
	{
		if( !_moo_b_init ) return 0;
		if( _moo_clock_rate ) return cast(int32_t)( _moo_smp_end / _moo_clock_rate );
		return 0;
	}

	int32_t moo_get_sampling_offset() const
	{
		if( !_moo_b_init     ) return 0;
		if( _moo_b_end_vomit ) return 0;
		return _moo_smp_count;
	}

	int32_t moo_get_sampling_end() const
	{
		if( !_moo_b_init     ) return 0;
		if( _moo_b_end_vomit ) return 0;
		return _moo_smp_end;
	}



	// preparation
	bool moo_preparation( const(pxtnVOMITPREPARATION) *p_prep )
	{
		if( !_moo_b_init || !_moo_b_valid_data || !_dst_ch_num || !_dst_sps || !_dst_byte_per_smp )
		{
			 _moo_b_end_vomit = true ;
			 return false;
		}

		bool    b_ret        = false;
		int32_t start_meas   =     0;
		int32_t start_sample =     0;
		float   start_float  =     0;

		int32_t meas_end     = master.get_play_meas  ();
		int32_t meas_repeat  = master.get_repeat_meas();
		float   fadein_sec   =     0;

		if( p_prep )
		{
			start_meas   = p_prep.start_pos_meas  ;
			start_sample = p_prep.start_pos_sample;
			start_float  = p_prep.start_pos_float ;

			if( p_prep.meas_end     ) meas_end    	= p_prep.meas_end    ;
			if( p_prep.meas_repeat  ) meas_repeat 	= p_prep.meas_repeat ;
			if( p_prep.fadein_sec   ) fadein_sec  	= p_prep.fadein_sec  ;

			if( p_prep.flags & pxtnVOMITPREPFLAG_unit_mute ) _moo_b_mute_by_unit = true ;
			else                                              _moo_b_mute_by_unit = false;
			if( p_prep.flags & pxtnVOMITPREPFLAG_loop      ) _moo_b_loop         = true ;
			else                                              _moo_b_loop         = false;

			_moo_master_vol = p_prep.master_volume;
		}

		_moo_bt_clock   = master.get_beat_clock();
		_moo_bt_num     = master.get_beat_num  ();
		_moo_bt_tempo   = master.get_beat_tempo();
		_moo_clock_rate = cast(float)( 60.0f * cast(double)_dst_sps / ( cast(double)_moo_bt_tempo * cast(double)_moo_bt_clock ) );
		_moo_smp_stride = ( 44100.0f / _dst_sps );
		_moo_top        = 0x7fff;

		_moo_time_pan_index = 0;

		_moo_smp_end    = cast(int32_t)( cast(double)meas_end    * cast(double)_moo_bt_num * cast(double)_moo_bt_clock * _moo_clock_rate );
		_moo_smp_repeat = cast(int32_t)( cast(double)meas_repeat * cast(double)_moo_bt_num * cast(double)_moo_bt_clock * _moo_clock_rate );

		if     ( start_float  ){ _moo_smp_start = cast(int32_t)( cast(float)moo_get_total_sample() * start_float ); }
		else if( start_sample ){ _moo_smp_start = start_sample; }
		else                   { _moo_smp_start = cast(int32_t)( cast(double)start_meas  * cast(double)_moo_bt_num * cast(double)_moo_bt_clock * _moo_clock_rate ); }

		_moo_smp_count  = _moo_smp_start;
		_moo_smp_smooth = _dst_sps / 250; // (0.004sec) // (0.010sec)

		if( fadein_sec > 0 ) moo_set_fade( 1, fadein_sec );
		else                 moo_set_fade( 0,          0 );

		tones_clear();

		_moo_p_eve = evels.get_Records();

		_moo_InitUnitTone();

		b_ret = true;
		if( b_ret ) _moo_b_end_vomit = false;
		else        _moo_b_end_vomit = true ;

		return b_ret;
	}

	////////////////////
	//
	////////////////////

	bool Moo( void* p_buf, int32_t  size )
	{
		if( !_moo_b_init       ) return false;
		if( !_moo_b_valid_data ) return false;
		if(  _moo_b_end_vomit  ) return false;

		bool b_ret = false;

		int32_t  smp_w = 0;

		if( size % _dst_byte_per_smp ) return false;

		int32_t  smp_num = size / _dst_byte_per_smp;

		{
			int16_t  *p16 = cast(int16_t*)p_buf;
			int16_t[ 2 ]  sample;

			for( smp_w = 0; smp_w < smp_num; smp_w++ )
			{
				if( !_moo_PXTONE_SAMPLE( sample.ptr ) ){ _moo_b_end_vomit = true; break; }
				for( int ch = 0; ch < _dst_ch_num; ch++, p16++ ) *p16 = sample[ ch ];
			}
			for( ;          smp_w < smp_num; smp_w++ )
			{
				for( int ch = 0; ch < _dst_ch_num; ch++, p16++ ) *p16 = 0;
			}
		}

		if( _sampled_proc )
		{
			int32_t clock = cast(int32_t)( _moo_smp_count / _moo_clock_rate );
			if( !_sampled_proc( _sampled_user, &this ) ){ _moo_b_end_vomit = true; goto term; }
		}

		b_ret = true;
	term:
		return b_ret;
	}
};


int32_t pxtnService_moo_CalcSampleNum( int32_t meas_num, int32_t beat_num, int32_t sps, float beat_tempo )
{
	uint32_t  total_beat_num;
	uint32_t  sample_num    ;
	if( !beat_tempo ) return 0;
	total_beat_num = meas_num * beat_num;
	sample_num     = cast(uint32_t )( cast(double)sps * 60 * cast(double)total_beat_num / cast(double)beat_tempo );
	return sample_num;
}