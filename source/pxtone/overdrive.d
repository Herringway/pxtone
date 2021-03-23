﻿module pxtone.overdrive;
// '12/03/03

import pxtone.pxtn;
import pxtone.error;
import pxtone.descriptor;

import core.stdc.string;

enum TUNEOVERDRIVE_CUT_MAX = 99.9f;
enum TUNEOVERDRIVE_CUT_MIN = 50.0f;
enum TUNEOVERDRIVE_AMP_MAX = 8.0f;
enum TUNEOVERDRIVE_AMP_MIN = 0.1f;
enum TUNEOVERDRIVE_DEFAULT_CUT = 90.0f;
enum TUNEOVERDRIVE_DEFAULT_AMP = 2.0f;

struct pxtnOverDrive {
	bool _b_played = true;

	int _group;
	float _cut_f;
	float _amp_f;

	int _cut_16bit_top;

	float get_cut() const nothrow {
		return _cut_f;
	}

	float get_amp() const nothrow {
		return _amp_f;
	}

	int get_group() const nothrow {
		return _group;
	}

	void Set(float cut, float amp, int group) nothrow {
		_cut_f = cut;
		_amp_f = amp;
		_group = group;
	}

	bool get_played() const nothrow {
		return _b_played;
	}

	void set_played(bool b) nothrow {
		_b_played = b;
	}

	bool switch_played() nothrow {
		_b_played = _b_played ? false : true;
		return _b_played;
	}

	void Tone_Ready() nothrow {
		_cut_16bit_top = cast(int)(32767 * (100 - _cut_f) / 100);
	}

	void Tone_Supple(int* group_smps) const nothrow {
		if (!_b_played) {
			return;
		}
		int work = group_smps[_group];
		if (work > _cut_16bit_top) {
			work = _cut_16bit_top;
		} else if (work < -_cut_16bit_top) {
			work = -_cut_16bit_top;
		}
		group_smps[_group] = cast(int)(cast(float) work * _amp_f);
	}

	bool Write(pxtnDescriptor* p_doc) const nothrow {
		_OVERDRIVESTRUCT over;
		int size;

		memset(&over, 0, _OVERDRIVESTRUCT.sizeof);
		over.cut = _cut_f;
		over.amp = _amp_f;
		over.group = cast(ushort) _group;

		// dela ----------
		size = _OVERDRIVESTRUCT.sizeof;
		if (!p_doc.w_asfile(&size, uint.sizeof, 1)) {
			return false;
		}
		if (!p_doc.w_asfile(&over, size, 1)) {
			return false;
		}

		return true;
	}

	pxtnERR Read(pxtnDescriptor* p_doc) nothrow {
		_OVERDRIVESTRUCT over = {0};
		int size = 0;

		memset(&over, 0, _OVERDRIVESTRUCT.sizeof);
		if (!p_doc.r(&size, 4, 1)) {
			return pxtnERR.pxtnERR_desc_r;
		}
		if (!p_doc.r(&over, _OVERDRIVESTRUCT.sizeof, 1)) {
			return pxtnERR.pxtnERR_desc_r;
		}

		if (over.xxx) {
			return pxtnERR.pxtnERR_fmt_unknown;
		}
		if (over.yyy) {
			return pxtnERR.pxtnERR_fmt_unknown;
		}
		if (over.cut > TUNEOVERDRIVE_CUT_MAX || over.cut < TUNEOVERDRIVE_CUT_MIN) {
			return pxtnERR.pxtnERR_fmt_unknown;
		}
		if (over.amp > TUNEOVERDRIVE_AMP_MAX || over.amp < TUNEOVERDRIVE_AMP_MIN) {
			return pxtnERR.pxtnERR_fmt_unknown;
		}

		_cut_f = over.cut;
		_amp_f = over.amp;
		_group = over.group;

		return pxtnERR.pxtnOK;
	}
}

// (8byte) =================
struct _OVERDRIVESTRUCT {
	ushort xxx;
	ushort group;
	float cut;
	float amp;
	float yyy;
}
