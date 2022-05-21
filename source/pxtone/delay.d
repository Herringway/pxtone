module pxtone.delay;

import pxtone.pxtn;

import pxtone.descriptor;
import pxtone.error;
import pxtone.max;
import pxtone.mem;

enum DELAYUNIT {
	Beat = 0,
	Meas,
	Second,
	num,
}

// (12byte) =================
struct _DELAYSTRUCT {
	ushort unit;
	ushort group;
	float rate = 0.0;
	float freq = 0.0;
}

struct pxtnDelay {
private:
	bool _b_played = true;
	DELAYUNIT _unit = DELAYUNIT.Beat;
	int _group = 0;
	float _rate = 33.0;
	float _freq = 3.0f;

	int _smp_num = 0;
	int _offset = 0;
	int[][pxtnMAX_CHANNEL] _bufs = null;
	int _rate_s32 = 0;

public:

	 ~this() nothrow @system {
		Tone_Release();
	}

	DELAYUNIT get_unit() const nothrow @safe {
		return _unit;
	}

	int get_group() const nothrow @safe {
		return _group;
	}

	float get_rate() const nothrow @safe {
		return _rate;
	}

	float get_freq() const nothrow @safe {
		return _freq;
	}

	void Set(DELAYUNIT unit, float freq, float rate, int group) nothrow @safe {
		_unit = unit;
		_group = group;
		_rate = rate;
		_freq = freq;
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

	void Tone_Release() nothrow @system {
		for (int i = 0; i < pxtnMAX_CHANNEL; i++) {
			deallocate(_bufs[i]);
		}
		_smp_num = 0;
	}

	void Tone_Ready(int beat_num, float beat_tempo, int sps) @system {
		Tone_Release();

		scope(failure) {
			Tone_Release();
		}
		if (_freq && _rate) {
			_offset = 0;
			_rate_s32 = cast(int) _rate; // /100;

			switch (_unit) {
			case DELAYUNIT.Beat:
				_smp_num = cast(int)(sps * 60 / beat_tempo / _freq);
				break;
			case DELAYUNIT.Meas:
				_smp_num = cast(int)(sps * 60 * beat_num / beat_tempo / _freq);
				break;
			case DELAYUNIT.Second:
				_smp_num = cast(int)(sps / _freq);
				break;
			default:
				break;
			}

			for (int c = 0; c < pxtnMAX_CHANNEL; c++) {
				_bufs[c] = allocate!int(_smp_num);
				if (!_bufs[c]) {
					throw new PxtoneException("Buffer allocation failed");
				}
			}
		}
	}

	void Tone_Supple(int ch, int[] group_smps) nothrow @safe {
		if (!_smp_num) {
			return;
		}
		int a = _bufs[ch][_offset] * _rate_s32 / 100;
		if (_b_played) {
			group_smps[_group] += a;
		}
		_bufs[ch][_offset] = group_smps[_group];
	}

	void Tone_Increment() nothrow @safe {
		if (!_smp_num) {
			return;
		}
		if (++_offset >= _smp_num) {
			_offset = 0;
		}
	}

	void Tone_Clear() nothrow @system {
		if (!_smp_num) {
			return;
		}
		int def = 0; // ..
		for (int i = 0; i < pxtnMAX_CHANNEL; i++) {
			_bufs[i][0 .. _smp_num] = def;
		}
	}

	void Write(ref pxtnDescriptor p_doc) const @system {
		_DELAYSTRUCT dela;
		int size;

		dela.unit = cast(ushort) _unit;
		dela.group = cast(ushort) _group;
		dela.rate = _rate;
		dela.freq = _freq;

		// dela ----------
		size = _DELAYSTRUCT.sizeof;
		p_doc.w_asfile(size);
		p_doc.w_asfile(dela);
	}

	void Read(ref pxtnDescriptor p_doc) @system {
		_DELAYSTRUCT dela;
		int size = 0;

		p_doc.r(size);
		p_doc.r(dela);
		if (dela.unit >= DELAYUNIT.num) {
			throw new PxtoneException("fmt unknown");
		}

		_unit = cast(DELAYUNIT) dela.unit;
		_freq = dela.freq;
		_rate = dela.rate;
		_group = dela.group;

		if (_group >= pxtnMAX_TUNEGROUPNUM) {
			_group = 0;
		}
	}
}
