module pxtone.master;
// '12/03/03

import pxtone.pxtn;

import pxtone.descriptor;
import pxtone.error;
import pxtone.evelist;

/////////////////////////////////
// file io
/////////////////////////////////

// master info(8byte) ================
struct _x4x_MASTER {
	ushort data_num; // data-num is 3 ( clock / status / volume ）
	ushort rrr;
	uint event_num;
}

struct pxtnMaster {
private:
	int _beat_num = EVENTDEFAULT_BEATNUM;
	float _beat_tempo = EVENTDEFAULT_BEATTEMPO;
	int _beat_clock = EVENTDEFAULT_BEATCLOCK;
	int _meas_num = 1;
	int _repeat_meas;
	int _last_meas;
	int _volume_;

public:
	void Reset() nothrow @safe {
		_beat_num = EVENTDEFAULT_BEATNUM;
		_beat_tempo = EVENTDEFAULT_BEATTEMPO;
		_beat_clock = EVENTDEFAULT_BEATCLOCK;
		_meas_num = 1;
		_repeat_meas = 0;
		_last_meas = 0;
	}

	void Set(int beat_num, float beat_tempo, int beat_clock) nothrow @safe {
		_beat_num = beat_num;
		_beat_tempo = beat_tempo;
		_beat_clock = beat_clock;
	}

	void Get(int* p_beat_num, float* p_beat_tempo, int* p_beat_clock, int* p_meas_num) const nothrow @safe {
		if (p_beat_num) {
			*p_beat_num = _beat_num;
		}
		if (p_beat_tempo) {
			*p_beat_tempo = _beat_tempo;
		}
		if (p_beat_clock) {
			*p_beat_clock = _beat_clock;
		}
		if (p_meas_num) {
			*p_meas_num = _meas_num;
		}
	}

	int get_beat_num() const nothrow @safe {
		return _beat_num;
	}

	float get_beat_tempo() const nothrow @safe {
		return _beat_tempo;
	}

	int get_beat_clock() const nothrow @safe {
		return _beat_clock;
	}

	int get_meas_num() const nothrow @safe {
		return _meas_num;
	}

	int get_repeat_meas() const nothrow @safe {
		return _repeat_meas;
	}

	int get_last_meas() const nothrow @safe {
		return _last_meas;
	}

	int get_last_clock() const nothrow @safe {
		return _last_meas * _beat_clock * _beat_num;
	}

	int get_play_meas() const nothrow @safe {
		if (_last_meas) {
			return _last_meas;
		}
		return _meas_num;
	}

	void set_meas_num(int meas_num) nothrow @safe {
		if (meas_num < 1) {
			meas_num = 1;
		}
		if (meas_num <= _repeat_meas) {
			meas_num = _repeat_meas + 1;
		}
		if (meas_num < _last_meas) {
			meas_num = _last_meas;
		}
		_meas_num = meas_num;
	}

	void set_repeat_meas(int meas) nothrow @safe {
		if (meas < 0) {
			meas = 0;
		}
		_repeat_meas = meas;
	}

	void set_last_meas(int meas) nothrow @safe {
		if (meas < 0) {
			meas = 0;
		}
		_last_meas = meas;
	}

	void set_beat_clock(int beat_clock) nothrow @safe {
		if (beat_clock < 0) {
			beat_clock = 0;
		}
		_beat_clock = beat_clock;
	}

	void AdjustMeasNum(int clock) nothrow @safe {
		int m_num;
		int b_num;

		b_num = (clock + _beat_clock - 1) / _beat_clock;
		m_num = (b_num + _beat_num - 1) / _beat_num;
		if (_meas_num <= m_num) {
			_meas_num = m_num;
		}
		if (_repeat_meas >= _meas_num) {
			_repeat_meas = 0;
		}
		if (_last_meas > _meas_num) {
			_last_meas = _meas_num;
		}
	}

	int get_this_clock(int meas, int beat, int clock) const nothrow @safe {
		return _beat_num * _beat_clock * meas + _beat_clock * beat + clock;
	}

	bool io_w_v5(ref pxtnDescriptor p_doc, int rough) const nothrow @system {

		uint size = 15;
		short bclock = cast(short)(_beat_clock / rough);
		int clock_repeat = bclock * _beat_num * get_repeat_meas();
		int clock_last = bclock * _beat_num * get_last_meas();
		byte bnum = cast(byte) _beat_num;
		float btempo = _beat_tempo;
		if (!p_doc.w_asfile(size)) {
			return false;
		}
		if (!p_doc.w_asfile(bclock)) {
			return false;
		}
		if (!p_doc.w_asfile(bnum)) {
			return false;
		}
		if (!p_doc.w_asfile(btempo)) {
			return false;
		}
		if (!p_doc.w_asfile(clock_repeat)) {
			return false;
		}
		if (!p_doc.w_asfile(clock_last)) {
			return false;
		}

		return true;
	}

	pxtnERR io_r_v5(ref pxtnDescriptor p_doc) nothrow @system {
		pxtnERR res = pxtnERR.VOID;
		short beat_clock = 0;
		byte beat_num = 0;
		float beat_tempo = 0;
		int clock_repeat = 0;
		int clock_last = 0;

		uint size = 0;

		if (!p_doc.r(size)) {
			return pxtnERR.desc_r;
		}
		if (size != 15) {
			return pxtnERR.fmt_unknown;
		}

		if (!p_doc.r(beat_clock)) {
			return pxtnERR.desc_r;
		}
		if (!p_doc.r(beat_num)) {
			return pxtnERR.desc_r;
		}
		if (!p_doc.r(beat_tempo)) {
			return pxtnERR.desc_r;
		}
		if (!p_doc.r(clock_repeat)) {
			return pxtnERR.desc_r;
		}
		if (!p_doc.r(clock_last)) {
			return pxtnERR.desc_r;
		}

		_beat_clock = beat_clock;
		_beat_num = beat_num;
		_beat_tempo = beat_tempo;

		set_repeat_meas(clock_repeat / (beat_num * beat_clock));
		set_last_meas(clock_last / (beat_num * beat_clock));

		return pxtnERR.OK;
	}

	int io_r_v5_EventNum(ref pxtnDescriptor p_doc) nothrow @system {
		uint size;
		if (!p_doc.r(size)) {
			return 0;
		}
		if (size != 15) {
			return 0;
		}
		byte[15] buf;
		if (!p_doc.r(buf[])) {
			return 0;
		}
		return 5;
	}

	pxtnERR io_r_x4x(ref pxtnDescriptor p_doc) nothrow @system {
		_x4x_MASTER mast;
		int size = 0;
		int e = 0;
		int status = 0;
		int clock = 0;
		int volume = 0;
		int absolute = 0;

		int beat_clock, beat_num, repeat_clock, last_clock;
		float beat_tempo = 0;

		if (!p_doc.r(size)) {
			return pxtnERR.desc_r;
		}
		if (!p_doc.r(mast)) {
			return pxtnERR.desc_r;
		}

		// unknown format
		if (mast.data_num != 3) {
			return pxtnERR.fmt_unknown;
		}
		if (mast.rrr) {
			return pxtnERR.fmt_unknown;
		}

		beat_clock = EVENTDEFAULT_BEATCLOCK;
		beat_num = EVENTDEFAULT_BEATNUM;
		beat_tempo = EVENTDEFAULT_BEATTEMPO;
		repeat_clock = 0;
		last_clock = 0;

		absolute = 0;

		for (e = 0; e < cast(int) mast.event_num; e++) {
			if (!p_doc.v_r(&status)) {
				break;
			}
			if (!p_doc.v_r(&clock)) {
				break;
			}
			if (!p_doc.v_r(&volume)) {
				break;
			}
			absolute += clock;
			clock = absolute;

			switch (status) {
			case EVENTKIND.BEATCLOCK:
				beat_clock = volume;
				if (clock) {
					return pxtnERR.desc_broken;
				}
				break;
			case EVENTKIND.BEATTEMPO:
				beat_tempo = *(cast(float*)&volume);
				if (clock) {
					return pxtnERR.desc_broken;
				}
				break;
			case EVENTKIND.BEATNUM:
				beat_num = volume;
				if (clock) {
					return pxtnERR.desc_broken;
				}
				break;
			case EVENTKIND.REPEAT:
				repeat_clock = clock;
				if (volume) {
					return pxtnERR.desc_broken;
				}
				break;
			case EVENTKIND.LAST:
				last_clock = clock;
				if (volume) {
					return pxtnERR.desc_broken;
				}
				break;
			default:
				return pxtnERR.fmt_unknown;
			}
		}

		if (e != mast.event_num) {
			return pxtnERR.desc_broken;
		}

		_beat_num = beat_num;
		_beat_tempo = beat_tempo;
		_beat_clock = beat_clock;

		set_repeat_meas(repeat_clock / (beat_num * beat_clock));
		set_last_meas(last_clock / (beat_num * beat_clock));

		return pxtnERR.OK;
	}

	int io_r_x4x_EventNum(ref pxtnDescriptor p_doc) nothrow @system {
		_x4x_MASTER mast;
		int size;
		int work;
		int e;

		if (!p_doc.r(size)) {
			return 0;
		}
		if (!p_doc.r(mast)) {
			return 0;
		}

		if (mast.data_num != 3) {
			return 0;
		}

		for (e = 0; e < cast(int) mast.event_num; e++) {
			if (!p_doc.v_r(&work)) {
				return 0;
			}
			if (!p_doc.v_r(&work)) {
				return 0;
			}
			if (!p_doc.v_r(&work)) {
				return 0;
			}
		}

		return mast.event_num;
	}
}
