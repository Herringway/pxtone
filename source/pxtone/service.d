module pxtone.service;

import pxtone.pxtn;

import pxtone.descriptor;
import pxtone.pulse.noisebuilder;

import pxtone.error;
import pxtone.max;
import pxtone.text;
import pxtone.delay;
import pxtone.overdrive;
import pxtone.master;
import pxtone.woice;
import pxtone.pulse.frequency;
import pxtone.unit;
import pxtone.evelist;

import std.algorithm.comparison;
import std.exception;
import std.format;
import std.math;
import std.stdio;
import std.typecons;

enum PXTONEERRORSIZE = 64;

enum pxtnFlags {
	loop = 1 << 0,
	unitMute = 1 << 1
}

enum _VERSIONSIZE = 16;
enum _CODESIZE = 8;

//                                       0123456789012345
immutable _code_tune_x2x = "PTTUNE--20050608";
immutable _code_tune_x3x = "PTTUNE--20060115";
immutable _code_tune_x4x = "PTTUNE--20060930";
immutable _code_tune_v5 = "PTTUNE--20071119";

immutable _code_proj_x1x = "PTCOLLAGE-050227";
immutable _code_proj_x2x = "PTCOLLAGE-050608";
immutable _code_proj_x3x = "PTCOLLAGE-060115";
immutable _code_proj_x4x = "PTCOLLAGE-060930";
immutable _code_proj_v5 = "PTCOLLAGE-071119";

immutable _code_x1x_PROJ = "PROJECT=";
immutable _code_x1x_EVEN = "EVENT===";
immutable _code_x1x_UNIT = "UNIT====";
immutable _code_x1x_END = "END=====";
immutable _code_x1x_PCM = "matePCM=";

immutable _code_x3x_pxtnUNIT = "pxtnUNIT";
immutable _code_x4x_evenMAST = "evenMAST";
immutable _code_x4x_evenUNIT = "evenUNIT";

immutable _code_antiOPER = "antiOPER"; // anti operation(edit)

immutable _code_num_UNIT = "num UNIT";
immutable _code_MasterV5 = "MasterV5";
immutable _code_Event_V5 = "Event V5";
immutable _code_matePCM = "matePCM ";
immutable _code_matePTV = "matePTV ";
immutable _code_matePTN = "matePTN ";
immutable _code_mateOGGV = "mateOGGV";
immutable _code_effeDELA = "effeDELA";
immutable _code_effeOVER = "effeOVER";
immutable _code_textNAME = "textNAME";
immutable _code_textCOMM = "textCOMM";
immutable _code_assiUNIT = "assiUNIT";
immutable _code_assiWOIC = "assiWOIC";
immutable _code_pxtoneND = "pxtoneND";

enum _enum_Tag {
	Unknown = 0,
	antiOPER,

	x1x_PROJ,
	x1x_UNIT,
	x1x_PCM,
	x1x_EVEN,
	x1x_END,
	x3x_pxtnUNIT,
	x4x_evenMAST,
	x4x_evenUNIT,

	num_UNIT,
	MasterV5,
	Event_V5,
	matePCM,
	matePTV,
	matePTN,
	mateOGGV,
	effeDELA,
	effeOVER,
	textNAME,
	textCOMM,
	assiUNIT,
	assiWOIC,
	pxtoneND

}

private _enum_Tag _CheckTagCode(const char[] p_code) nothrow @safe {
	switch(p_code[0 .. _CODESIZE]) {
		case _code_antiOPER: return _enum_Tag.antiOPER;
		case _code_x1x_PROJ: return _enum_Tag.x1x_PROJ;
		case _code_x1x_UNIT: return _enum_Tag.x1x_UNIT;
		case _code_x1x_PCM: return _enum_Tag.x1x_PCM;
		case _code_x1x_EVEN: return _enum_Tag.x1x_EVEN;
		case _code_x1x_END: return _enum_Tag.x1x_END;
		case _code_x3x_pxtnUNIT: return _enum_Tag.x3x_pxtnUNIT;
		case _code_x4x_evenMAST: return _enum_Tag.x4x_evenMAST;
		case _code_x4x_evenUNIT: return _enum_Tag.x4x_evenUNIT;
		case _code_num_UNIT: return _enum_Tag.num_UNIT;
		case _code_Event_V5: return _enum_Tag.Event_V5;
		case _code_MasterV5: return _enum_Tag.MasterV5;
		case _code_matePCM: return _enum_Tag.matePCM;
		case _code_matePTV: return _enum_Tag.matePTV;
		case _code_matePTN: return _enum_Tag.matePTN;
		case _code_mateOGGV: return _enum_Tag.mateOGGV;
		case _code_effeDELA: return _enum_Tag.effeDELA;
		case _code_effeOVER: return _enum_Tag.effeOVER;
		case _code_textNAME: return _enum_Tag.textNAME;
		case _code_textCOMM: return _enum_Tag.textCOMM;
		case _code_assiUNIT: return _enum_Tag.assiUNIT;
		case _code_assiWOIC: return _enum_Tag.assiWOIC;
		case _code_pxtoneND: return _enum_Tag.pxtoneND;
		default: return _enum_Tag.Unknown;
	}
}

struct _ASSIST_WOICE {
	ushort woice_index;
	ushort rrr;
	char[pxtnMAX_TUNEWOICENAME] name = 0;
}

struct _ASSIST_UNIT {
	ushort unit_index;
	ushort rrr;
	char[pxtnMAX_TUNEUNITNAME] name = 0;
}

struct _NUM_UNIT {
	short num;
	short rrr;
}

enum _MAX_FMTVER_x1x_EVENTNUM = 10000;

// x1x project..------------------

enum _MAX_PROJECTNAME_x1x = 16;

// project (36byte) ================
struct _x1x_PROJECT {
	char[_MAX_PROJECTNAME_x1x] x1x_name = 0;

	float x1x_beat_tempo = 0.0;
	ushort x1x_beat_clock;
	ushort x1x_beat_num;
	ushort x1x_beat_note;
	ushort x1x_meas_num;
	ushort x1x_channel_num;
	ushort x1x_bps;
	uint x1x_sps;
}

struct pxtnVOMITPREPARATION {
	int start_pos_meas = 0;
	int start_pos_sample = 0;
	float start_pos_float = 0.0;

	int meas_end = 0;
	int meas_repeat = 0;
	float fadein_sec = 0.0;

	BitFlags!pxtnFlags flags;
	float master_volume = 1.0;
	invariant {
		import std.math : isNaN;
		assert(!master_volume.isNaN, "Master volume should never be NaN!");
		assert(!fadein_sec.isNaN, "fadein_sec should never be NaN!");
		assert(!start_pos_float.isNaN, "start_pos_float should never be NaN!");
	}
}

alias pxtnSampledCallback = bool function(void* user, const(pxtnService)* pxtn) nothrow;

struct pxtnService {
private:
	enum _enum_FMTVER {
		_enum_FMTVER_unknown = 0,
		_enum_FMTVER_x1x, // fix event num = 10000
		_enum_FMTVER_x2x, // no version of exe
		_enum_FMTVER_x3x, // unit has voice / basic-key for only view
		_enum_FMTVER_x4x, // unit has event
		_enum_FMTVER_v5,
	}

	bool _b_init;
	bool _b_edit;
	bool _b_fix_evels_num;

	int _dst_ch_num, _dst_sps, _dst_byte_per_smp;

	pxtnPulse_NoiseBuilder _ptn_bldr;

	int _delay_max;
	int _delay_num;
	pxtnDelay[] _delays;
	int _ovdrv_max;
	int _ovdrv_num;
	pxtnOverDrive*[] _ovdrvs;
	int _woice_max;
	int _woice_num;
	pxtnWoice*[] _woices;
	int _unit_max;
	int _unit_num;
	pxtnUnit[] _units;

	int _group_num;

	void _ReadVersion(ref pxtnDescriptor p_doc, out _enum_FMTVER p_fmt_ver, out ushort p_exe_ver) @safe {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}

		char[_VERSIONSIZE] version_ = '\0';
		ushort dummy;

		p_doc.r(version_[]);

		// fmt version
		if (version_[0 .. _VERSIONSIZE] == _code_proj_x1x) {
			p_fmt_ver = _enum_FMTVER._enum_FMTVER_x1x;
			p_exe_ver = 0;
			return;
		} else if (version_[0 .. _VERSIONSIZE] == _code_proj_x2x) {
			p_fmt_ver = _enum_FMTVER._enum_FMTVER_x2x;
			p_exe_ver = 0;
			return;
		} else if (version_[0 .. _VERSIONSIZE] == _code_proj_x3x) {
			p_fmt_ver = _enum_FMTVER._enum_FMTVER_x3x;
		} else if (version_[0 .. _VERSIONSIZE] == _code_proj_x4x) {
			p_fmt_ver = _enum_FMTVER._enum_FMTVER_x4x;
		} else if (version_[0 .. _VERSIONSIZE] == _code_proj_v5) {
			p_fmt_ver = _enum_FMTVER._enum_FMTVER_v5;
		} else if (version_[0 .. _VERSIONSIZE] == _code_tune_x2x) {
			p_fmt_ver = _enum_FMTVER._enum_FMTVER_x2x;
			p_exe_ver = 0;
			return;
		} else if (version_[0 .. _VERSIONSIZE] == _code_tune_x3x) {
			p_fmt_ver = _enum_FMTVER._enum_FMTVER_x3x;
		} else if (version_[0 .. _VERSIONSIZE] == _code_tune_x4x) {
			p_fmt_ver = _enum_FMTVER._enum_FMTVER_x4x;
		} else if (version_[0 .. _VERSIONSIZE] == _code_tune_v5) {
			p_fmt_ver = _enum_FMTVER._enum_FMTVER_v5;
		} else {
			throw new PxtoneException("fmt unknown");
		}

		// exe version
		p_doc.r(p_exe_ver);
		p_doc.r(dummy);
	}
	////////////////////////////////////////
	// Read Project //////////////
	////////////////////////////////////////

	void _ReadTuneItems(ref pxtnDescriptor p_doc) @system {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}

		bool b_end = false;
		char[_CODESIZE + 1] code = '\0';

		/// must the unit before the voice.
		while (!b_end) {
			p_doc.r(code[0 .._CODESIZE]);

			_enum_Tag tag = _CheckTagCode(code);
			switch (tag) {
			case _enum_Tag.antiOPER:
				throw new PxtoneException("AntiOPER tag detected");

				// new -------
			case _enum_Tag.num_UNIT: {
					int num = 0;
					_io_UNIT_num_r(p_doc, num);
					for (int i = 0; i < num; i++) {
						_units[i] = pxtnUnit.init;
					}
					_unit_num = num;
					break;
				}
			case _enum_Tag.MasterV5:
				master.io_r_v5(p_doc);
				break;
			case _enum_Tag.Event_V5:
				evels.io_Read(p_doc);
				break;

			case _enum_Tag.matePCM:
				_io_Read_Woice(p_doc, pxtnWOICETYPE.PCM);
				break;
			case _enum_Tag.matePTV:
				_io_Read_Woice(p_doc, pxtnWOICETYPE.PTV);
				break;
			case _enum_Tag.matePTN:
				_io_Read_Woice(p_doc, pxtnWOICETYPE.PTN);
				break;

			case _enum_Tag.mateOGGV:

				version (pxINCLUDE_OGGVORBIS) {
					_io_Read_Woice(p_doc, pxtnWOICETYPE.OGGV);
					break;
				} else {
					throw new PxtoneException("Ogg Vorbis support is required");
				}

			case _enum_Tag.effeDELA:
				_io_Read_Delay(p_doc);
				break;
			case _enum_Tag.effeOVER:
				_io_Read_OverDrive(p_doc);
				break;
			case _enum_Tag.textNAME:
				text.Name_r(p_doc);
				break;
			case _enum_Tag.textCOMM:
				text.Comment_r(p_doc);
				break;
			case _enum_Tag.assiWOIC:
				_io_assiWOIC_r(p_doc);
				break;
			case _enum_Tag.assiUNIT:
				_io_assiUNIT_r(p_doc);
				break;
			case _enum_Tag.pxtoneND:
				b_end = true;
				break;

				// old -------
			case _enum_Tag.x4x_evenMAST:
				master.io_r_x4x(p_doc);
				break;
			case _enum_Tag.x4x_evenUNIT:
				evels.io_Unit_Read_x4x_EVENT(p_doc, false, true);
				break;
			case _enum_Tag.x3x_pxtnUNIT:
				_io_Read_OldUnit(p_doc, 3);
				break;
			case _enum_Tag.x1x_PROJ:
				_x1x_Project_Read(p_doc);
				break;
			case _enum_Tag.x1x_UNIT:
				_io_Read_OldUnit(p_doc, 1);
				break;
			case _enum_Tag.x1x_PCM:
				_io_Read_Woice(p_doc, pxtnWOICETYPE.PCM);
				break;
			case _enum_Tag.x1x_EVEN:
				evels.io_Unit_Read_x4x_EVENT(p_doc, true, false);
				break;
			case _enum_Tag.x1x_END:
				b_end = true;
				break;

			default:
				throw new PxtoneException("fmt unknown");
			}
		}

	}

	void _x1x_Project_Read(ref pxtnDescriptor p_doc) @system {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}

		_x1x_PROJECT prjc;
		int beat_num, beat_clock;
		int size;
		float beat_tempo;

		p_doc.r(size);
		p_doc.r(prjc);

		beat_num = prjc.x1x_beat_num;
		beat_tempo = prjc.x1x_beat_tempo;
		beat_clock = prjc.x1x_beat_clock;

		int ns = 0;
		for ( /+ns+/ ; ns < _MAX_PROJECTNAME_x1x; ns++) {
			if (!prjc.x1x_name[ns]) {
				break;
			}
		}

		text.set_name_buf(prjc.x1x_name.ptr, ns);
		master.Set(beat_num, beat_tempo, beat_clock);
	}

	void _io_Read_Delay(ref pxtnDescriptor p_doc) @system {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}
		if (!_delays) {
			throw new PxtoneException("pxtnService delays not initialized");
		}
		if (_delay_num >= _delay_max) {
			throw new PxtoneException("fmt unknown");
		}

		pxtnDelay delay;

		delay.Read(p_doc);
		_delays[_delay_num] = delay;
		_delay_num++;
	}

	void _io_Read_OverDrive(ref pxtnDescriptor p_doc) @system {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}
		if (!_ovdrvs) {
			throw new PxtoneException("pxtnService overdrives not initialized");
		}
		if (_ovdrv_num >= _ovdrv_max) {
			throw new PxtoneException("fmt unknown");
		}

		pxtnOverDrive* ovdrv = new pxtnOverDrive();
		ovdrv.Read(p_doc);
		_ovdrvs[_ovdrv_num] = ovdrv;
		_ovdrv_num++;
	}

	void _io_Read_Woice(ref pxtnDescriptor p_doc, pxtnWOICETYPE type) @system {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}
		if (!_woices) {
			throw new PxtoneException("pxtnService woices not initialized");
		}
		if (_woice_num >= _woice_max) {
			throw new PxtoneException("Too many woices");
		}

		pxtnWoice* woice = new pxtnWoice();

		switch (type) {
		case pxtnWOICETYPE.PCM:
			woice.io_matePCM_r(p_doc);
			break;
		case pxtnWOICETYPE.PTV:
			woice.io_matePTV_r(p_doc);
			break;
		case pxtnWOICETYPE.PTN:
			woice.io_matePTN_r(p_doc);
			break;
		case pxtnWOICETYPE.OGGV:
			version (pxINCLUDE_OGGVORBIS) {
				woice.io_mateOGGV_r(p_doc);
				break;
			} else {
				throw new PxtoneException("Ogg Vorbis support is required");
			}

		default:
			throw new PxtoneException("fmt unknown");
		}
		_woices[_woice_num] = woice;
		_woice_num++;
	}

	void _io_Read_OldUnit(ref pxtnDescriptor p_doc, int ver) @system {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}
		if (!_units) {
			throw new PxtoneException("pxtnService units not initialized");
		}
		if (_unit_num >= _unit_max) {
			throw new PxtoneException("fmt unknown");
		}

		pxtnUnit* unit = new pxtnUnit();
		int group = 0;
		switch (ver) {
		case 1:
			unit.Read_v1x(p_doc, &group);
			break;
		case 3:
			unit.Read_v3x(p_doc, &group);
			break;
		default:
			throw new PxtoneException("fmt unknown");
		}

		if (group >= _group_num) {
			group = _group_num - 1;
		}

		evels.x4x_Read_Add(0, cast(ubyte) _unit_num, EVENTKIND.GROUPNO, cast(int) group);
		evels.x4x_Read_NewKind();
		evels.x4x_Read_Add(0, cast(ubyte) _unit_num, EVENTKIND.VOICENO, cast(int) _unit_num);
		evels.x4x_Read_NewKind();

	term:
		_units[_unit_num] = *unit;
		_unit_num++;
	}

	/////////////
	// assi woice
	/////////////

	bool _io_assiWOIC_w(ref pxtnDescriptor p_doc, int idx) const @system {
		if (!_b_init) {
			return false;
		}

		_ASSIST_WOICE assi;
		int size;
		const char[] p_name = _woices[idx].get_name_buf();

		if (p_name.length > pxtnMAX_TUNEWOICENAME) {
			return false;
		}

		assi.name[0 .. p_name.length] = p_name;
		assi.woice_index = cast(ushort) idx;

		size = _ASSIST_WOICE.sizeof;
		p_doc.w_asfile(size);
		p_doc.w_asfile(assi);

		return true;
	}

	void _io_assiWOIC_r(ref pxtnDescriptor p_doc) @system {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}

		_ASSIST_WOICE assi;
		int size = 0;

		p_doc.r(size);
		if (size != assi.sizeof) {
			throw new PxtoneException("fmt unknown");
		}
		p_doc.r(assi);
		if (assi.rrr) {
			throw new PxtoneException("fmt unknown");
		}
		if (assi.woice_index >= _woice_num) {
			throw new PxtoneException("fmt unknown");
		}

		if (!_woices[assi.woice_index].set_name_buf(assi.name)) {
			throw new PxtoneException("FATAL");
		}
	}
	// -----
	// assi unit.
	// -----

	bool _io_assiUNIT_w(ref pxtnDescriptor p_doc, int idx) const @system {
		if (!_b_init) {
			return false;
		}

		_ASSIST_UNIT assi;
		int size;
		int name_size;
		const char* p_name = _units[idx].get_name_buf(&name_size);

		assi.name[0 .. name_size] = p_name[0 .. name_size];
		assi.unit_index = cast(ushort) idx;

		size = assi.sizeof;
		p_doc.w_asfile(size);
		p_doc.w_asfile(assi);

		return true;
	}

	void _io_assiUNIT_r(ref pxtnDescriptor p_doc) @safe {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}

		_ASSIST_UNIT assi;
		int size;

		p_doc.r(size);
		if (size != assi.sizeof) {
			throw new PxtoneException("fmt unknown");
		}
		p_doc.r(assi);
		if (assi.rrr) {
			throw new PxtoneException("fmt unknown");
		}
		if (assi.unit_index >= _unit_num) {
			throw new PxtoneException("fmt unknown");
		}

		if (!_units[assi.unit_index].setNameBuf(assi.name[])) {
			throw new PxtoneException("FATAL");
		}
	}
	// -----
	// unit num
	// -----

	void _io_UNIT_num_w(ref pxtnDescriptor p_doc) const @system {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}

		_NUM_UNIT data;
		int size;

		data.num = cast(short) _unit_num;

		size = _NUM_UNIT.sizeof;
		p_doc.w_asfile(size);
		p_doc.w_asfile(data);
	}

	void _io_UNIT_num_r(ref pxtnDescriptor p_doc, out int p_num) @system {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}

		_NUM_UNIT data;
		int size = 0;

		p_doc.r(size);
		if (size != _NUM_UNIT.sizeof) {
			throw new PxtoneException("fmt unknown");
		}
		p_doc.r(data);
		if (data.rrr) {
			throw new PxtoneException("fmt unknown");
		}
		if (data.num > _unit_max) {
			throw new PxtoneException("fmt new");
		}
		if (data.num < 0) {
			throw new PxtoneException("fmt unknown");
		}
		p_num = data.num;
	}

	// fix old key event
	bool _x3x_TuningKeyEvent() nothrow @system {
		if (!_b_init) {
			return false;
		}

		if (_unit_num > _woice_num) {
			return false;
		}

		for (int u = 0; u < _unit_num; u++) {
			if (u >= _woice_num) {
				return false;
			}

			int change_value = _woices[u].get_x3x_basic_key() - EVENTDEFAULT_BASICKEY;

			if (!evels.get_Count(cast(ubyte) u, cast(ubyte) EVENTKIND.KEY)) {
				evels.Record_Add_i(0, cast(ubyte) u, EVENTKIND.KEY, cast(int) 0x6000);
			}
			evels.Record_Value_Change(0, -1, cast(ubyte) u, EVENTKIND.KEY, change_value);
		}
		return true;
	}

	// fix old tuning (1.0)
	bool _x3x_AddTuningEvent() nothrow @system {
		if (!_b_init) {
			return false;
		}

		if (_unit_num > _woice_num) {
			return false;
		}

		for (int u = 0; u < _unit_num; u++) {
			float tuning = _woices[u].get_x3x_tuning();
			if (tuning) {
				evels.Record_Add_f(0, cast(ubyte) u, EVENTKIND.TUNING, tuning);
			}
		}

		return true;
	}

	bool _x3x_SetVoiceNames() nothrow @system {
		if (!_b_init) {
			return false;
		}

		for (int i = 0; i < _woice_num; i++) {
			char[pxtnMAX_TUNEWOICENAME + 1] name = 0;
			try {
				sformat(name[], "voice_%02d", i);
			} catch (Exception) { //This will never actually happen...
				return false;
			}
			_woices[i].set_name_buf(name);
		}
		return true;
	}

	//////////////
	// vomit..
	//////////////
	bool _moo_b_valid_data;
	bool _moo_b_end_vomit = true;
	bool _moo_b_init;

	bool _moo_b_mute_by_unit;
	bool _moo_b_loop = true;

	int _moo_smp_smooth;
	float _moo_clock_rate; // as the sample
	int _moo_smp_count;
	int _moo_smp_start;
	int _moo_smp_end;
	int _moo_smp_repeat;

	int _moo_fade_count;
	int _moo_fade_max;
	int _moo_fade_fade;
	float _moo_master_vol = 1.0f;

	int _moo_top;
	float _moo_smp_stride;
	int _moo_time_pan_index;

	float _moo_bt_tempo;

	// for make now-meas
	int _moo_bt_clock;
	int _moo_bt_num;

	int[] _moo_group_smps;

	const(EVERECORD)* _moo_p_eve;

	pxtnPulse_Frequency* _moo_freq;

	void _init(int fix_evels_num, bool b_edit) @system {
		if (_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}

		scope(failure) {
			_release();
		}

		int byte_size = 0;

		version (pxINCLUDE_OGGVORBIS) {
			import derelict.vorbis;

			try {
				DerelictVorbis.load();
				DerelictVorbisFile.load();
			} catch (Exception e) {
				throw new PxtoneException("Vorbis library failed to load");
			}
		}

		text = pxtnText.init;
		master = pxtnMaster.init;
		evels = pxtnEvelist.init;
		_ptn_bldr = pxtnPulse_NoiseBuilder.init;

		if (fix_evels_num) {
			_b_fix_evels_num = true;
			evels.Allocate(fix_evels_num);
		} else {
			_b_fix_evels_num = false;
		}

		// delay
		_delays = new pxtnDelay[](pxtnMAX_TUNEDELAYSTRUCT);
		_delay_max = pxtnMAX_TUNEDELAYSTRUCT;

		// over-drive
		_ovdrvs = new pxtnOverDrive*[](pxtnMAX_TUNEOVERDRIVESTRUCT);
		_ovdrv_max = pxtnMAX_TUNEOVERDRIVESTRUCT;

		// woice
		_woices = new pxtnWoice*[](pxtnMAX_TUNEWOICESTRUCT);
		_woice_max = pxtnMAX_TUNEWOICESTRUCT;

		// unit
		_units = new pxtnUnit[](pxtnMAX_TUNEUNITSTRUCT);
		_unit_max = pxtnMAX_TUNEUNITSTRUCT;

		_group_num = pxtnMAX_TUNEGROUPNUM;

		if (!_moo_init()) {
			throw new PxtoneException("_moo_init failed");
		}

		if (fix_evels_num) {
			_moo_b_valid_data = true;
		}

		_b_edit = b_edit;
		_b_init = true;

	}

	bool _release() nothrow @system {
		if (!_b_init) {
			return false;
		}
		_b_init = false;

		_moo_destructer();

		_delays = null;
		_ovdrvs = null;
		_woices = null;
		_units = null;
		return true;
	}

	void _pre_count_event(ref pxtnDescriptor p_doc, out int p_count) @system {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}

		bool b_end = false;

		int count = 0;
		int c = 0;
		int size = 0;
		char[_CODESIZE + 1] code = '\0';

		ushort exe_ver = 0;
		_enum_FMTVER fmt_ver = _enum_FMTVER._enum_FMTVER_unknown;

		scope(failure) {
			p_count = 0;
		}

		_ReadVersion(p_doc, fmt_ver, exe_ver);

		if (fmt_ver == _enum_FMTVER._enum_FMTVER_x1x) {
			count = _MAX_FMTVER_x1x_EVENTNUM;
			goto term;
		}

		while (!b_end) {
			p_doc.r(code[0 .. _CODESIZE]);

			switch (_CheckTagCode(code)) {
			case _enum_Tag.Event_V5:
				count += evels.io_Read_EventNum(p_doc);
				break;
			case _enum_Tag.MasterV5:
				count += master.io_r_v5_EventNum(p_doc);
				break;
			case _enum_Tag.x4x_evenMAST:
				count += master.io_r_x4x_EventNum(p_doc);
				break;
			case _enum_Tag.x4x_evenUNIT:
				evels.io_Read_x4x_EventNum(p_doc, &c);
				count += c;
				break;
			case _enum_Tag.pxtoneND:
				b_end = true;
				break;

				// skip
			case _enum_Tag.antiOPER:
			case _enum_Tag.num_UNIT:
			case _enum_Tag.x3x_pxtnUNIT:
			case _enum_Tag.matePCM:
			case _enum_Tag.matePTV:
			case _enum_Tag.matePTN:
			case _enum_Tag.mateOGGV:
			case _enum_Tag.effeDELA:
			case _enum_Tag.effeOVER:
			case _enum_Tag.textNAME:
			case _enum_Tag.textCOMM:
			case _enum_Tag.assiUNIT:
			case _enum_Tag.assiWOIC:

				p_doc.r(size);
				p_doc.seek(pxtnSEEK.cur, size);
				break;

				// ignore
			case _enum_Tag.x1x_PROJ:
			case _enum_Tag.x1x_UNIT:
			case _enum_Tag.x1x_PCM:
			case _enum_Tag.x1x_EVEN:
			case _enum_Tag.x1x_END:
				throw new PxtoneException("x1x ignore");
			default:
				throw new PxtoneException("FATAL");
			}
		}

		if (fmt_ver <= _enum_FMTVER._enum_FMTVER_x3x) {
			count += pxtnMAX_TUNEUNITSTRUCT * 4; // voice_no, group_no, key tuning, key event x3x
		}

	term:

		p_count = count;
	}

	void _moo_destructer() nothrow @system {

		_moo_release();
	}

	bool _moo_init() nothrow @system {
		bool b_ret = false;

		_moo_freq = new pxtnPulse_Frequency();
		if (!_moo_freq) {
			goto term;
		}
		_moo_group_smps = new int[](_group_num);
		if (!_moo_group_smps) {
			goto term;
		}

		_moo_b_init = true;
		b_ret = true;
	term:
		if (!b_ret) {
			_moo_release();
		}

		return b_ret;
	}

	bool _moo_release() nothrow @system {
		if (!_moo_b_init) {
			return false;
		}
		_moo_b_init = false;
		_moo_freq = null;
		_moo_group_smps = null;
		return true;
	}

	////////////////////////////////////////////////
	// Units   ////////////////////////////////////
	////////////////////////////////////////////////

	bool _moo_ResetVoiceOn(pxtnUnit* p_u, int w) const nothrow @safe {
		if (!_moo_b_init) {
			return false;
		}

		const(pxtnVOICEINSTANCE)* p_inst;
		const(pxtnVOICEUNIT)* p_vc;
		const(pxtnWoice)* p_wc = Woice_Get(w);

		if (!p_wc) {
			return false;
		}

		p_u.set_woice(p_wc);

		for (int v = 0; v < p_wc.get_voice_num(); v++) {
			p_inst = p_wc.get_instance(v);
			p_vc = p_wc.get_voice(v);

			float ofs_freq = 0;
			if (p_vc.voice_flags & PTV_VOICEFLAG_BEATFIT) {
				ofs_freq = (p_inst.smp_body_w * _moo_bt_tempo) / (44100 * 60 * p_vc.tuning);
			} else {
				ofs_freq = _moo_freq.Get(EVENTDEFAULT_BASICKEY - p_vc.basic_key) * p_vc.tuning;
			}
			p_u.Tone_Reset_and_2prm(v, cast(int)(p_inst.env_release / _moo_clock_rate), ofs_freq);
		}
		return true;
	}

	bool _moo_InitUnitTone() nothrow @safe {
		if (!_moo_b_init) {
			return false;
		}
		for (int u = 0; u < _unit_num; u++) {
			pxtnUnit* p_u = Unit_Get(u);
			p_u.Tone_Init();
			_moo_ResetVoiceOn(p_u, EVENTDEFAULT_VOICENO);
		}
		return true;
	}

	bool _moo_PXTONE_SAMPLE(ubyte[] p_data) nothrow @safe {
		if (!_moo_b_init) {
			return false;
		}

		// envelope..
		for (int u = 0; u < _unit_num; u++) {
			_units[u].Tone_Envelope();
		}

		int clock = cast(int)(_moo_smp_count / _moo_clock_rate);

		// events..
		for (; _moo_p_eve && _moo_p_eve.clock <= clock; _moo_p_eve = _moo_p_eve.next) {
			int u = _moo_p_eve.unit_no;
			pxtnUnit* p_u = &_units[u];
			pxtnVOICETONE* p_tone;
			const(pxtnWoice)* p_wc;
			const(pxtnVOICEINSTANCE)* p_vi;

			switch (_moo_p_eve.kind) {
			case EVENTKIND.ON: {
					int on_count = cast(int)((_moo_p_eve.clock + _moo_p_eve.value - clock) * _moo_clock_rate);
					if (on_count <= 0) {
						p_u.Tone_ZeroLives();
						break;
					}

					p_u.Tone_KeyOn();

					p_wc = p_u.get_woice();
					if (!(p_wc)) {
						break;
					}
					for (int v = 0; v < p_wc.get_voice_num(); v++) {
						p_tone = p_u.get_tone(v);
						p_vi = p_wc.get_instance(v);

						// release..
						if (p_vi.env_release) {
							int max_life_count1 = cast(int)((_moo_p_eve.value - (clock - _moo_p_eve.clock)) * _moo_clock_rate) + p_vi.env_release;
							int max_life_count2;
							int c = _moo_p_eve.clock + _moo_p_eve.value + p_tone.env_release_clock;
							const(EVERECORD)* next = null;
							for (const(EVERECORD)* p = _moo_p_eve.next; p; p = p.next) {
								if (p.clock > c) {
									break;
								}
								if (p.unit_no == u && p.kind == EVENTKIND.ON) {
									next = p;
									break;
								}
							}
							if (!next) {
								max_life_count2 = _moo_smp_end - cast(int)(clock * _moo_clock_rate);
							} else {
								max_life_count2 = cast(int)((next.clock - clock) * _moo_clock_rate);
							}
							if (max_life_count1 < max_life_count2) {
								p_tone.life_count = max_life_count1;
							} else {
								p_tone.life_count = max_life_count2;
							}
						}  // no-release..
						else {
							p_tone.life_count = cast(int)((_moo_p_eve.value - (clock - _moo_p_eve.clock)) * _moo_clock_rate);
						}

						if (p_tone.life_count > 0) {
							p_tone.on_count = on_count;
							p_tone.smp_pos = 0;
							p_tone.env_pos = 0;
							if (p_vi.env_size) {
								p_tone.env_volume = p_tone.env_start = 0; // envelope
							} else {
								p_tone.env_volume = p_tone.env_start = 128; // no-envelope
							}
						}
					}
					break;
				}

			case EVENTKIND.KEY:
				p_u.Tone_Key(_moo_p_eve.value);
				break;
			case EVENTKIND.PAN_VOLUME:
				p_u.Tone_Pan_Volume(_dst_ch_num, _moo_p_eve.value);
				break;
			case EVENTKIND.PAN_TIME:
				p_u.Tone_Pan_Time(_dst_ch_num, _moo_p_eve.value, _dst_sps);
				break;
			case EVENTKIND.VELOCITY:
				p_u.Tone_Velocity(_moo_p_eve.value);
				break;
			case EVENTKIND.VOLUME:
				p_u.Tone_Volume(_moo_p_eve.value);
				break;
			case EVENTKIND.PORTAMENT:
				p_u.Tone_Portament(cast(int)(_moo_p_eve.value * _moo_clock_rate));
				break;
			case EVENTKIND.BEATCLOCK:
				break;
			case EVENTKIND.BEATTEMPO:
				break;
			case EVENTKIND.BEATNUM:
				break;
			case EVENTKIND.REPEAT:
				break;
			case EVENTKIND.LAST:
				break;
			case EVENTKIND.VOICENO:
				_moo_ResetVoiceOn(p_u, _moo_p_eve.value);
				break;
			case EVENTKIND.GROUPNO:
				p_u.Tone_GroupNo(_moo_p_eve.value);
				break;
			case EVENTKIND.TUNING:
				p_u.Tone_Tuning(*(cast(const(float)*)(&_moo_p_eve.value)));
				break;
			default:
				break;
			}
		}

		// sampling..
		for (int u = 0; u < _unit_num; u++) {
			_units[u].Tone_Sample(_moo_b_mute_by_unit, _dst_ch_num, _moo_time_pan_index, _moo_smp_smooth);
		}

		for (int ch = 0; ch < _dst_ch_num; ch++) {
			for (int g = 0; g < _group_num; g++) {
				_moo_group_smps[g] = 0;
			}
			for (int u = 0; u < _unit_num; u++) {
				_units[u].Tone_Supple(_moo_group_smps, ch, _moo_time_pan_index);
			}
			for (int o = 0; o < _ovdrv_num; o++) {
				_ovdrvs[o].Tone_Supple(_moo_group_smps);
			}
			for (int d = 0; d < _delay_num; d++) {
				_delays[d].Tone_Supple(ch, _moo_group_smps);
			}

			// collect.
			int work = 0;
			for (int g = 0; g < _group_num; g++) {
				work += _moo_group_smps[g];
			}

			// fade..
			if (_moo_fade_fade) {
				work = work * (_moo_fade_count >> 8) / _moo_fade_max;
			}

			// master volume
			work = cast(int)(work * _moo_master_vol);

			// to buffer..
			if (work > _moo_top) {
				work = _moo_top;
			}
			if (work < -_moo_top) {
				work = -_moo_top;
			}
			(cast(short[])p_data)[ch] = cast(short)(work);
		}

		// --------------
		// increments..

		_moo_smp_count++;
		_moo_time_pan_index = (_moo_time_pan_index + 1) & (pxtnBUFSIZE_TIMEPAN - 1);

		for (int u = 0; u < _unit_num; u++) {
			int key_now = _units[u].Tone_Increment_Key();
			_units[u].Tone_Increment_Sample(_moo_freq.Get2(key_now) * _moo_smp_stride);
		}

		// delay
		for (int d = 0; d < _delay_num; d++) {
			_delays[d].Tone_Increment();
		}

		// fade out
		if (_moo_fade_fade < 0) {
			if (_moo_fade_count > 0) {
				_moo_fade_count--;
			} else {
				return false;
			}
		}  // fade in
		else if (_moo_fade_fade > 0) {
			if (_moo_fade_count < (_moo_fade_max << 8)) {
				_moo_fade_count++;
			} else {
				_moo_fade_fade = 0;
			}
		}

		if (_moo_smp_count >= _moo_smp_end) {
			if (!_moo_b_loop) {
				return false;
			}
			_moo_smp_count = _moo_smp_repeat;
			_moo_p_eve = evels.get_Records();
			_moo_InitUnitTone();
		}
		return true;
	}

	pxtnSampledCallback _sampled_proc;
	void* _sampled_user;

public:

	void load(ubyte[] buffer) @system {
		pxtnDescriptor desc;
		desc.set_memory_r(buffer);
		read(desc);
		tones_ready();
	}

	void load(File fd) @system {
		pxtnDescriptor desc;
		desc.set_file_r(fd);
		read(desc);
		tones_ready();
	}

	 ~this() nothrow @system {
		_release();
	}

	pxtnText text;
	pxtnMaster master;
	pxtnEvelist evels;

	void initialize() @system {
		_init(0, false);
	}

	void init_collage(int fix_evels_num) @system {
		return _init(fix_evels_num, true);
	}

	bool clear() nothrow @system {
		if (!_b_init) {
			return false;
		}

		if (!_b_edit) {
			_moo_b_valid_data = false;
		}

		if (!text.set_name_buf("", 0)) {
			return false;
		}
		if (!text.set_comment_buf("", 0)) {
			return false;
		}

		evels.Clear();

		_delay_num = 0;
		_ovdrvs[0 .. _ovdrv_num] = null;
		_ovdrv_num = 0;
		_woices[0 .. _woice_num] = null;
		_woice_num = 0;
		_unit_num = 0;

		master.Reset();

		if (!_b_edit) {
			evels.Release();
		} else {
			evels.Clear();
		}
		return true;
	}

	////////////////////////////////////////
	// save               //////////////////
	////////////////////////////////////////

	void write(ref pxtnDescriptor p_doc, bool b_tune, ushort exe_ver) @system {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}

		bool b_ret = false;
		int rough = b_tune ? 10 : 1;
		ushort rrr = 0;

		// format version
		if (b_tune) {
			p_doc.w_asfile(_code_tune_v5);
		} else {
			p_doc.w_asfile(_code_proj_v5);
		}

		// exe version
		p_doc.w_asfile(exe_ver);
		p_doc.w_asfile(rrr);

		// master
		p_doc.w_asfile(_code_MasterV5);
		master.io_w_v5(p_doc, rough);

		// event
		p_doc.w_asfile(_code_Event_V5);
		evels.io_Write(p_doc, rough);

		// name
		if (text.is_name_buf()) {
			p_doc.w_asfile(_code_textNAME);
			if (!text.Name_w(p_doc)) {
				throw new PxtoneException("desc w");
			}
		}

		// comment
		if (text.is_comment_buf()) {
			p_doc.w_asfile(_code_textCOMM);
			if (!text.Comment_w(p_doc)) {
				throw new PxtoneException("desc w");
			}
		}

		// delay
		for (int d = 0; d < _delay_num; d++) {
			p_doc.w_asfile(_code_effeDELA);
			_delays[d].Write(p_doc);
		}

		// overdrive
		for (int o = 0; o < _ovdrv_num; o++) {
			p_doc.w_asfile(_code_effeOVER);
			_ovdrvs[o].Write(p_doc);
		}

		// woice
		for (int w = 0; w < _woice_num; w++) {
			pxtnWoice* p_w = _woices[w];

			switch (p_w.get_type()) {
			case pxtnWOICETYPE.PCM:
				p_doc.w_asfile(_code_matePCM);
				p_w.io_matePCM_w(p_doc);
				break;
			case pxtnWOICETYPE.PTV:
				p_doc.w_asfile(_code_matePTV);
				if (!p_w.io_matePTV_w(p_doc)) {
					throw new PxtoneException("desc w");
				}
				break;
			case pxtnWOICETYPE.PTN:
				p_doc.w_asfile(_code_matePTN);
				p_w.io_matePTN_w(p_doc);
				break;
			case pxtnWOICETYPE.OGGV:

				version (pxINCLUDE_OGGVORBIS) {
					p_doc.w_asfile(_code_mateOGGV);
					if (!p_w.io_mateOGGV_w(p_doc)) {
						throw new PxtoneException("desc w");
					}
					break;
				} else {
					throw new PxtoneException("Ogg vorbis support is required");
				}
			default:
				throw new PxtoneException("inv data");
			}

			if (!b_tune && p_w.is_name_buf()) {
				p_doc.w_asfile(_code_assiWOIC);
				if (!_io_assiWOIC_w(p_doc, w)) {
					throw new PxtoneException("desc w");
				}
			}
		}

		// unit
		p_doc.w_asfile(_code_num_UNIT);
		_io_UNIT_num_w(p_doc);

		for (int u = 0; u < _unit_num; u++) {
			if (!b_tune && _units[u].is_name_buf()) {
				p_doc.w_asfile(_code_assiUNIT);
				if (!_io_assiUNIT_w(p_doc, u)) {
					throw new PxtoneException("desc w");
				}
			}
		}

		{
			int end_size = 0;
			p_doc.w_asfile(_code_pxtoneND);
			p_doc.w_asfile(end_size);
		}
	}

	void read(ref pxtnDescriptor p_doc) @system {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}

		ushort exe_ver = 0;
		_enum_FMTVER fmt_ver = _enum_FMTVER._enum_FMTVER_unknown;
		int event_num = 0;

		clear();

		scope(failure) {
			clear();
		}

		_pre_count_event(p_doc, event_num);
		p_doc.seek(pxtnSEEK.set, 0);

		if (_b_fix_evels_num) {
			if (event_num > evels.get_Num_Max()) {
				throw new PxtoneException("Too many events");
			}
		} else {
			evels.Allocate(event_num);
		}

		_ReadVersion(p_doc, fmt_ver, exe_ver);

		if (fmt_ver >= _enum_FMTVER._enum_FMTVER_v5) {
			evels.Linear_Start();
		} else {
			evels.x4x_Read_Start();
		}

		_ReadTuneItems(p_doc);

		if (fmt_ver >= _enum_FMTVER._enum_FMTVER_v5) {
			evels.Linear_End(true);
		}

		if (fmt_ver <= _enum_FMTVER._enum_FMTVER_x3x) {
			if (!_x3x_TuningKeyEvent()) {
				throw new PxtoneException("x3x key");
			}
			if (!_x3x_AddTuningEvent()) {
				throw new PxtoneException("x3x add tuning");
			}
			_x3x_SetVoiceNames();
		}

		if (_b_edit && master.get_beat_clock() != EVENTDEFAULT_BEATCLOCK) {
			throw new PxtoneException("deny beatclock");
		}

		{
			int clock1 = evels.get_Max_Clock();
			int clock2 = master.get_last_clock();

			if (clock1 > clock2) {
				master.AdjustMeasNum(clock1);
			} else {
				master.AdjustMeasNum(clock2);
			}
		}

		_moo_b_valid_data = true;
	}

	bool AdjustMeasNum() nothrow @safe {
		if (!_b_init) {
			return false;
		}
		master.AdjustMeasNum(evels.get_Max_Clock());
		return true;
	}

	void tones_ready() @system {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}

		int beat_num = master.get_beat_num();
		float beat_tempo = master.get_beat_tempo();

		for (int i = 0; i < _delay_num; i++) {
			_delays[i].Tone_Ready(beat_num, beat_tempo, _dst_sps);
		}
		for (int i = 0; i < _ovdrv_num; i++) {
			_ovdrvs[i].Tone_Ready();
		}
		for (int i = 0; i < _woice_num; i++) {
			_woices[i].Tone_Ready(_ptn_bldr, _dst_sps);
		}
	}

	bool tones_clear() nothrow @system {
		if (!_b_init) {
			return false;
		}
		for (int i = 0; i < _delay_num; i++) {
			_delays[i].Tone_Clear();
		}
		for (int i = 0; i < _unit_num; i++) {
			_units[i].Tone_Clear();
		}
		return true;
	}

	int Group_Num() const nothrow @safe {
		return _b_init ? _group_num : 0;
	}

	// ---------------------------
	// Delay..
	// ---------------------------

	int Delay_Num() const nothrow @safe {
		return _b_init ? _delay_num : 0;
	}

	int Delay_Max() const nothrow @safe {
		return _b_init ? _delay_max : 0;
	}

	bool Delay_Set(int idx, DELAYUNIT unit, float freq, float rate, int group) nothrow @system {
		if (!_b_init) {
			return false;
		}
		if (idx >= _delay_num) {
			return false;
		}
		_delays[idx].Set(unit, freq, rate, group);
		return true;
	}

	bool Delay_Add(DELAYUNIT unit, float freq, float rate, int group) nothrow @system {
		if (!_b_init) {
			return false;
		}
		if (_delay_num >= _delay_max) {
			return false;
		}
		_delays[_delay_num] = pxtnDelay.init;
		_delays[_delay_num].Set(unit, freq, rate, group);
		_delay_num++;
		return true;
	}

	bool Delay_Remove(int idx) nothrow @system {
		if (!_b_init) {
			return false;
		}
		if (idx >= _delay_num) {
			return false;
		}

		_delay_num--;
		for (int i = idx; i < _delay_num; i++) {
			_delays[i] = _delays[i + 1];
		}
		_delays[_delay_num] = pxtnDelay.init;
		return true;
	}

	void Delay_ReadyTone(int idx) @system {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}
		if (idx < 0 || idx >= _delay_num) {
			throw new PxtoneException("param");
		}
		_delays[idx].Tone_Ready(master.get_beat_num(), master.get_beat_tempo(), _dst_sps);
	}

	pxtnDelay* Delay_Get(int idx) nothrow @system {
		if (!_b_init) {
			return null;
		}
		if (idx < 0 || idx >= _delay_num) {
			return null;
		}
		return &_delays[idx];
	}

	// ---------------------------
	// Over Drive..
	// ---------------------------

	int OverDrive_Num() const nothrow @safe {
		return _b_init ? _ovdrv_num : 0;
	}

	int OverDrive_Max() const nothrow @safe {
		return _b_init ? _ovdrv_max : 0;
	}

	bool OverDrive_Set(int idx, float cut, float amp, int group) nothrow @system {
		if (!_b_init) {
			return false;
		}
		if (idx >= _ovdrv_num) {
			return false;
		}
		_ovdrvs[idx].Set(cut, amp, group);
		return true;
	}

	bool OverDrive_Add(float cut, float amp, int group) nothrow @system {
		if (!_b_init) {
			return false;
		}
		if (_ovdrv_num >= _ovdrv_max) {
			return false;
		}
		_ovdrvs[_ovdrv_num] = new pxtnOverDrive();
		_ovdrvs[_ovdrv_num].Set(cut, amp, group);
		_ovdrv_num++;
		return true;
	}

	bool OverDrive_Remove(int idx) nothrow @system {
		if (!_b_init) {
			return false;
		}
		if (idx >= _ovdrv_num) {
			return false;
		}

		_ovdrvs[idx] = null;
		_ovdrv_num--;
		for (int i = idx; i < _ovdrv_num; i++) {
			_ovdrvs[i] = _ovdrvs[i + 1];
		}
		_ovdrvs[_ovdrv_num] = null;
		return true;
	}

	bool OverDrive_ReadyTone(int idx) nothrow @system {
		if (!_b_init) {
			return false;
		}
		if (idx < 0 || idx >= _ovdrv_num) {
			return false;
		}
		_ovdrvs[idx].Tone_Ready();
		return true;
	}

	pxtnOverDrive* OverDrive_Get(int idx) nothrow @system {
		if (!_b_init) {
			return null;
		}
		if (idx < 0 || idx >= _ovdrv_num) {
			return null;
		}
		return _ovdrvs[idx];
	}

	// ---------------------------
	// Woice..
	// ---------------------------

	int Woice_Num() const nothrow @safe {
		return _b_init ? _woice_num : 0;
	}

	int Woice_Max() const nothrow @safe {
		return _b_init ? _woice_max : 0;
	}

	inout(pxtnWoice)* Woice_Get(int idx) inout nothrow @safe {
		if (!_b_init) {
			return null;
		}
		if (idx < 0 || idx >= _woice_num) {
			return null;
		}
		return _woices[idx];
	}

	void Woice_read(int idx, ref pxtnDescriptor desc, pxtnWOICETYPE type) @system {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}
		if (idx < 0 || idx >= _woice_max) {
			throw new PxtoneException("param");
		}
		if (idx > _woice_num) {
			throw new PxtoneException("param");
		}
		if (idx == _woice_num) {
			_woices[idx] = new pxtnWoice();
			_woice_num++;
		}

		scope(failure) {
			Woice_Remove(idx);
		}
		_woices[idx].read(desc, type);
	}

	void Woice_ReadyTone(int idx) @system {
		if (!_b_init) {
			throw new PxtoneException("pxtnService not initialized");
		}
		if (idx < 0 || idx >= _woice_num) {
			throw new PxtoneException("param");
		}
		_woices[idx].Tone_Ready(_ptn_bldr, _dst_sps);
	}

	bool Woice_Remove(int idx) nothrow @system {
		if (!_b_init) {
			return false;
		}
		if (idx < 0 || idx >= _woice_num) {
			return false;
		}
		_woices[idx] = null;
		_woice_num--;
		for (int i = idx; i < _woice_num; i++) {
			_woices[i] = _woices[i + 1];
		}
		_woices[_woice_num] = null;
		return true;
	}

	bool Woice_Replace(int old_place, int new_place) nothrow @system {
		if (!_b_init) {
			return false;
		}

		pxtnWoice* p_w = _woices[old_place];
		int max_place = _woice_num - 1;

		if (new_place > max_place) {
			new_place = max_place;
		}
		if (new_place == old_place) {
			return true;
		}

		if (old_place < new_place) {
			for (int w = old_place; w < new_place; w++) {
				if (_woices[w]) {
					_woices[w] = _woices[w + 1];
				}
			}
		} else {
			for (int w = old_place; w > new_place; w--) {
				if (_woices[w]) {
					_woices[w] = _woices[w - 1];
				}
			}
		}

		_woices[new_place] = p_w;
		return true;
	}

	// ---------------------------
	// Unit..
	// ---------------------------

	int Unit_Num() const nothrow @safe {
		return _b_init ? _unit_num : 0;
	}

	int Unit_Max() const nothrow @safe {
		return _b_init ? _unit_max : 0;
	}

	inout(pxtnUnit)* Unit_Get(int idx) inout nothrow @safe {
		if (!_b_init) {
			return null;
		}
		if (idx < 0 || idx >= _unit_num) {
			return null;
		}
		return &_units[idx];
	}

	bool Unit_Remove(int idx) nothrow @system {
		if (!_b_init) {
			return false;
		}
		if (idx < 0 || idx >= _unit_num) {
			return false;
		}
		_unit_num--;
		for (int i = idx; i < _unit_num; i++) {
			_units[i] = _units[i + 1];
		}
		_units[_unit_num] = pxtnUnit.init;
		return true;
	}

	bool Unit_Replace(int old_place, int new_place) nothrow @system {
		if (!_b_init) {
			return false;
		}

		pxtnUnit p_w = _units[old_place];
		int max_place = _unit_num - 1;

		if (new_place > max_place) {
			new_place = max_place;
		}
		if (new_place == old_place) {
			return true;
		}

		if (old_place < new_place) {
			for (int w = old_place; w < new_place; w++) {
				_units[w] = _units[w + 1];
			}
		} else {
			for (int w = old_place; w > new_place; w--) {
				_units[w] = _units[w - 1];
			}
		}
		_units[new_place] = p_w;
		return true;
	}

	bool Unit_AddNew() nothrow @system {
		if (_unit_num >= _unit_max) {
			return false;
		}
		_units[_unit_num] = pxtnUnit.init;
		_unit_num++;
		return true;
	}

	bool Unit_SetOpratedAll(bool b) nothrow @system {
		if (!_b_init) {
			return false;
		}
		for (int u = 0; u < _unit_num; u++) {
			_units[u].set_operated(b);
			if (b) {
				_units[u].set_played(true);
			}
		}
		return true;
	}

	bool Unit_Solo(int idx) nothrow @system {
		if (!_b_init) {
			return false;
		}
		for (int u = 0; u < _unit_num; u++) {
			if (u == idx) {
				_units[u].set_played(true);
			} else {
				_units[u].set_played(false);
			}
		}
		return false;
	}

	// ---------------------------
	// Quality..
	// ---------------------------

	void set_destination_quality(int ch_num, int sps) @safe {
		enforce(_b_init, new PxtoneException("pxtnService not initialized"));
		switch (ch_num) {
		case 1:
			break;
		case 2:
			break;
		default:
			throw new PxtoneException("Unsupported sample rate");
		}

		_dst_ch_num = ch_num;
		_dst_sps = sps;
		_dst_byte_per_smp = pxtnBITPERSAMPLE / 8 * ch_num;
	}

	void get_destination_quality(int* p_ch_num, int* p_sps) const @safe {
		enforce(_b_init, new PxtoneException("pxtnService not initialized"));
		if (p_ch_num) {
			*p_ch_num = _dst_ch_num;
		}
		if (p_sps) {
			*p_sps = _dst_sps;
		}
	}

	void set_sampled_callback(pxtnSampledCallback proc, void* user) @safe {
		enforce(_b_init, new PxtoneException("pxtnService not initialized"));
		_sampled_proc = proc;
		_sampled_user = user;
	}

	//////////////
	// Moo..
	//////////////

	///////////////////////
	// get / set
	///////////////////////

	bool moo_is_valid_data() const @safe {
		enforce(_moo_b_init, new PxtoneException("pxtnService not initialized"));
		return _moo_b_valid_data;
	}

	bool moo_is_end_vomit() const @safe {
		enforce(_moo_b_init, new PxtoneException("pxtnService not initialized"));
		return _moo_b_end_vomit;
	}

	void moo_set_mute_by_unit(bool b) @safe {
		enforce(_moo_b_init, new PxtoneException("pxtnService not initialized"));
		_moo_b_mute_by_unit = b;
	}

	void moo_set_loop(bool b) @safe {
		enforce(_moo_b_init, new PxtoneException("pxtnService not initialized"));
		_moo_b_loop = b;
	}

	void moo_set_fade(int fade, float sec) @safe {
		enforce(_moo_b_init, new PxtoneException("pxtnService not initialized"));
		_moo_fade_max = cast(int)(cast(float) _dst_sps * sec) >> 8;
		if (fade < 0) {
			_moo_fade_fade = -1;
			_moo_fade_count = _moo_fade_max << 8;
		}  // out
		else if (fade > 0) {
			_moo_fade_fade = 1;
			_moo_fade_count = 0;
		}  // in
		else {
			_moo_fade_fade = 0;
			_moo_fade_count = 0;
		} // off
	}

	void moo_set_master_volume(float v) @safe {
		enforce(_moo_b_init, new PxtoneException("pxtnService not initialized"));
		if (v < 0) {
			v = 0;
		}
		if (v > 1) {
			v = 1;
		}
		_moo_master_vol = v;
	}

	int moo_get_total_sample() const @system {
		enforce(_moo_b_init, new PxtoneException("pxtnService not initialized"));
		enforce(_moo_b_valid_data, new PxtoneException("no valid data loaded"));

		int meas_num;
		int beat_num;
		float beat_tempo;
		master.Get(&beat_num, &beat_tempo, null, &meas_num);
		return pxtnService_moo_CalcSampleNum(meas_num, beat_num, _dst_sps, master.get_beat_tempo());
	}

	int moo_get_now_clock() const @safe {
		enforce(_moo_b_init, new PxtoneException("pxtnService not initialized"));
		enforce(_moo_clock_rate, new PxtoneException("No clock rate set"));
		return cast(int)(_moo_smp_count / _moo_clock_rate);
	}

	int moo_get_end_clock() const @safe {
		enforce(_moo_b_init, new PxtoneException("pxtnService not initialized"));
		enforce(_moo_clock_rate, new PxtoneException("No clock rate set"));
		return cast(int)(_moo_smp_end / _moo_clock_rate);
	}

	int moo_get_sampling_offset() const @safe {
		enforce(_moo_b_init, new PxtoneException("pxtnService not initialized"));
		enforce(!_moo_b_end_vomit, new PxtoneException("playback has ended"));
		return _moo_smp_count;
	}

	int moo_get_sampling_end() const @safe {
		enforce(_moo_b_init, new PxtoneException("pxtnService not initialized"));
		enforce(!_moo_b_end_vomit, new PxtoneException("playback has ended"));
		return _moo_smp_end;
	}

	// preparation
	void moo_preparation() @system {
		return moo_preparation(pxtnVOMITPREPARATION.init);
	}
	void moo_preparation(in pxtnVOMITPREPARATION p_prep) @system {
		scope(failure) {
			_moo_b_end_vomit = true;
		}
		enforce(_moo_b_init, new PxtoneException("pxtnService not initialized"));
		enforce(_moo_b_valid_data, new PxtoneException("no valid data loaded"));
		enforce(_dst_ch_num, new PxtoneException("invalid channel number specified"));
		enforce(_dst_sps, new PxtoneException("invalid sample rate specified"));
		enforce(_dst_byte_per_smp, new PxtoneException("invalid sample size"));

		int meas_end = master.get_play_meas();
		int meas_repeat = master.get_repeat_meas();

		if (p_prep.meas_end) {
			meas_end = p_prep.meas_end;
		}
		if (p_prep.meas_repeat) {
			meas_repeat = p_prep.meas_repeat;
		}

		_moo_b_mute_by_unit = p_prep.flags.unitMute;
		_moo_b_loop = p_prep.flags.loop;

		setVolume(p_prep.master_volume);

		_moo_bt_clock = master.get_beat_clock();
		_moo_bt_num = master.get_beat_num();
		_moo_bt_tempo = master.get_beat_tempo();
		_moo_clock_rate = cast(float)(60.0f * cast(double) _dst_sps / (cast(double) _moo_bt_tempo * cast(double) _moo_bt_clock));
		_moo_smp_stride = (44100.0f / _dst_sps);
		_moo_top = 0x7fff;

		_moo_time_pan_index = 0;

		_moo_smp_end = cast(int)(cast(double) meas_end * cast(double) _moo_bt_num * cast(double) _moo_bt_clock * _moo_clock_rate);
		_moo_smp_repeat = cast(int)(cast(double) meas_repeat * cast(double) _moo_bt_num * cast(double) _moo_bt_clock * _moo_clock_rate);

		if (p_prep.start_pos_float) {
			_moo_smp_start = cast(int)(cast(float) moo_get_total_sample() * p_prep.start_pos_float);
		} else if (p_prep.start_pos_sample) {
			_moo_smp_start = p_prep.start_pos_sample;
		} else {
			_moo_smp_start = cast(int)(cast(double) p_prep.start_pos_meas * cast(double) _moo_bt_num * cast(double) _moo_bt_clock * _moo_clock_rate);
		}

		_moo_smp_count = _moo_smp_start;
		_moo_smp_smooth = _dst_sps / 250; // (0.004sec) // (0.010sec)

		if (p_prep.fadein_sec > 0) {
			moo_set_fade(1, p_prep.fadein_sec);
		} else {
			moo_set_fade(0, 0);
		}
		start();
	}

	void setVolume(float volume) @system {
		enforce(!volume.isNaN, "Volume must be a number");
		_moo_master_vol = clamp(volume, 0.0, 1.0);
	}

	void start() @system {
		tones_clear();

		_moo_p_eve = evels.get_Records();

		_moo_InitUnitTone();

		_moo_b_end_vomit = false;
	}

	////////////////////
	//
	////////////////////

	bool Moo(ubyte[] p_buf) nothrow @system {
		if (!_moo_b_init) {
			return false;
		}
		if (!_moo_b_valid_data) {
			return false;
		}
		if (_moo_b_end_vomit) {
			return false;
		}

		bool b_ret = false;

		int smp_w = 0;

		if (p_buf.length % _dst_byte_per_smp) {
			return false;
		}

		int smp_num = cast(int)(p_buf.length / _dst_byte_per_smp);

		{
			short[] p16 = cast(short[]) p_buf;
			short[2] sample;

			for (smp_w = 0; smp_w < smp_num; smp_w++) {
				if (!_moo_PXTONE_SAMPLE(cast(ubyte[])(sample[]))) {
					_moo_b_end_vomit = true;
					break;
				}
				for (int ch = 0; ch < _dst_ch_num; ch++, p16 = p16[1 .. $]) {
					p16[0] = sample[ch];
				}
			}
			for (; smp_w < smp_num; smp_w++) {
				for (int ch = 0; ch < _dst_ch_num; ch++, p16 = p16[1 .. $]) {
					p16[0] = 0;
				}
			}
		}

		if (_sampled_proc) {
			int clock = cast(int)(_moo_smp_count / _moo_clock_rate);
			if (!_sampled_proc(_sampled_user, &this)) {
				_moo_b_end_vomit = true;
				goto term;
			}
		}

		b_ret = true;
	term:
		return b_ret;
	}
}

int pxtnService_moo_CalcSampleNum(int meas_num, int beat_num, int sps, float beat_tempo) nothrow @safe {
	uint total_beat_num;
	uint sample_num;
	if (!beat_tempo) {
		return 0;
	}
	total_beat_num = meas_num * beat_num;
	sample_num = cast(uint)(cast(double) sps * 60 * cast(double) total_beat_num / cast(double) beat_tempo);
	return sample_num;
}
