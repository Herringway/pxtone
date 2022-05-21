module pxtone.overdrive;
// '12/03/03

import pxtone.pxtn;
import pxtone.error;
import pxtone.descriptor;

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

	float get_cut() const nothrow @safe {
		return _cut_f;
	}

	float get_amp() const nothrow @safe {
		return _amp_f;
	}

	int get_group() const nothrow @safe {
		return _group;
	}

	void Set(float cut, float amp, int group) nothrow @safe {
		_cut_f = cut;
		_amp_f = amp;
		_group = group;
	}

	bool get_played() const nothrow @safe {
		return _b_played;
	}

	void set_played(bool b) nothrow @safe {
		_b_played = b;
	}

	bool switch_played() nothrow @safe {
		_b_played = _b_played ? false : true;
		return _b_played;
	}

	void Tone_Ready() nothrow @safe {
		_cut_16bit_top = cast(int)(32767 * (100 - _cut_f) / 100);
	}

	void Tone_Supple(int[] group_smps) const nothrow @safe {
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

	void Write(ref pxtnDescriptor p_doc) const @system {
		_OVERDRIVESTRUCT over;
		int size;

		over.cut = _cut_f;
		over.amp = _amp_f;
		over.group = cast(ushort) _group;

		// dela ----------
		size = _OVERDRIVESTRUCT.sizeof;
		p_doc.w_asfile(size);
		p_doc.w_asfile(over);
	}

	void Read(ref pxtnDescriptor p_doc) @system {
		_OVERDRIVESTRUCT over;
		int size = 0;

		p_doc.r(size);
		p_doc.r(over);

		if (over.xxx) {
			throw new PxtoneException("fmt unknown");
		}
		if (over.yyy) {
			throw new PxtoneException("fmt unknown");
		}
		if (over.cut > TUNEOVERDRIVE_CUT_MAX || over.cut < TUNEOVERDRIVE_CUT_MIN) {
			throw new PxtoneException("fmt unknown");
		}
		if (over.amp > TUNEOVERDRIVE_AMP_MAX || over.amp < TUNEOVERDRIVE_AMP_MIN) {
			throw new PxtoneException("fmt unknown");
		}

		_cut_f = over.cut;
		_amp_f = over.amp;
		_group = over.group;
	}
}

// (8byte) =================
struct _OVERDRIVESTRUCT {
	ushort xxx;
	ushort group;
	float cut = 0.0;
	float amp = 0.0;
	float yyy = 0.0;
}
