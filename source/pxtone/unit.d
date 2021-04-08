module pxtone.unit;
// '12/03/03

import pxtone.pxtn;

import pxtone.descriptor;
import pxtone.error;
import pxtone.evelist;
import pxtone.max;
import pxtone.woice;

import core.stdc.string;

// v1x (20byte) =================
struct _x1x_UNIT {
	char[pxtnMAX_TUNEUNITNAME] name;
	ushort type;
	ushort group;
}

///////////////////
// pxtnUNIT x3x
///////////////////

struct _x3x_UNIT {
	ushort type;
	ushort group;
}

struct pxtnUnit {
private:
	bool _bOperated = true;
	bool _bPlayed = true;
	char[pxtnMAX_TUNEUNITNAME + 1] _name_buf = "no name";
	int _name_size = "no name".length;

	//	TUNEUNITTONESTRUCT
	int _key_now;
	int _key_start;
	int _key_margin;
	int _portament_sample_pos;
	int _portament_sample_num;
	int[pxtnMAX_CHANNEL] _pan_vols;
	int[pxtnMAX_CHANNEL] _pan_times;
	int[pxtnBUFSIZE_TIMEPAN][pxtnMAX_CHANNEL] _pan_time_bufs;
	int _v_VOLUME;
	int _v_VELOCITY;
	int _v_GROUPNO;
	float _v_TUNING = 0.0;

	const(pxtnWoice)* _p_woice;

	pxtnVOICETONE[pxtnMAX_UNITCONTROLVOICE] _vts;

public:

	void Tone_Init() nothrow @safe {
		_v_GROUPNO = EVENTDEFAULT_GROUPNO;
		_v_VELOCITY = EVENTDEFAULT_VELOCITY;
		_v_VOLUME = EVENTDEFAULT_VOLUME;
		_v_TUNING = EVENTDEFAULT_TUNING;
		_portament_sample_num = 0;
		_portament_sample_pos = 0;

		for (int i = 0; i < pxtnMAX_CHANNEL; i++) {
			_pan_vols[i] = 64;
			_pan_times[i] = 0;
		}
	}

	void Tone_Clear() nothrow @system {
		for (int i = 0; i < pxtnMAX_CHANNEL; i++) {
			_pan_time_bufs[i][0 .. pxtnBUFSIZE_TIMEPAN] = 0;
		}
	}

	void Tone_Reset_and_2prm(int voice_idx, int env_rls_clock, float offset_freq) nothrow @safe {
		pxtnVOICETONE* p_tone = &_vts[voice_idx];
		p_tone.life_count = 0;
		p_tone.on_count = 0;
		p_tone.smp_pos = 0;
		p_tone.smooth_volume = 0;
		p_tone.env_release_clock = env_rls_clock;
		p_tone.offset_freq = offset_freq;
	}

	void Tone_Envelope() nothrow @system {
		if (!_p_woice) {
			return;
		}

		for (int v = 0; v < _p_woice.get_voice_num(); v++) {
			const pxtnVOICEINSTANCE* p_vi = _p_woice.get_instance(v);
			pxtnVOICETONE* p_vt = &_vts[v];

			if (p_vt.life_count > 0 && p_vi.env_size) {
				if (p_vt.on_count > 0) {
					if (p_vt.env_pos < p_vi.env_size) {
						p_vt.env_volume = p_vi.p_env[p_vt.env_pos];
						p_vt.env_pos++;
					}
				}  // release.
				else {
					p_vt.env_volume = p_vt.env_start + (0 - p_vt.env_start) * p_vt.env_pos / p_vi.env_release;
					p_vt.env_pos++;
				}
			}
		}
	}

	void Tone_KeyOn() nothrow @safe {
		_key_now = _key_start + _key_margin;
		_key_start = _key_now;
		_key_margin = 0;
	}

	void Tone_ZeroLives() nothrow @safe {
		for (int i = 0; i < pxtnMAX_CHANNEL; i++) {
			_vts[i].life_count = 0;
		}
	}

	void Tone_Key(int key) nothrow @safe {
		_key_start = _key_now;
		_key_margin = key - _key_start;
		_portament_sample_pos = 0;
	}

	void Tone_Pan_Volume(int ch, int pan) nothrow @safe {
		_pan_vols[0] = 64;
		_pan_vols[1] = 64;
		if (ch == 2) {
			if (pan >= 64) {
				_pan_vols[0] = 128 - pan;
			} else {
				_pan_vols[1] = pan;
			}
		}
	}

	void Tone_Pan_Time(int ch, int pan, int sps) nothrow @safe {
		_pan_times[0] = 0;
		_pan_times[1] = 0;

		if (ch == 2) {
			if (pan >= 64) {
				_pan_times[0] = pan - 64;
				if (_pan_times[0] > 63) {
					_pan_times[0] = 63;
				}
				_pan_times[0] = (_pan_times[0] * 44100) / sps;
			} else {
				_pan_times[1] = 64 - pan;
				if (_pan_times[1] > 63) {
					_pan_times[1] = 63;
				}
				_pan_times[1] = (_pan_times[1] * 44100) / sps;
			}
		}
	}

	void Tone_Velocity(int val) nothrow @safe {
		_v_VELOCITY = val;
	}

	void Tone_Volume(int val) nothrow @safe {
		_v_VOLUME = val;
	}

	void Tone_Portament(int val) nothrow @safe {
		_portament_sample_num = val;
	}

	void Tone_GroupNo(int val) nothrow @safe {
		_v_GROUPNO = val;
	}

	void Tone_Tuning(float val) nothrow @safe {
		_v_TUNING = val;
	}

	void Tone_Sample(bool b_mute_by_unit, int ch_num, int time_pan_index, int smooth_smp) nothrow @system {
		if (!_p_woice) {
			return;
		}

		if (b_mute_by_unit && !_bPlayed) {
			for (int ch = 0; ch < ch_num; ch++) {
				_pan_time_bufs[ch][time_pan_index] = 0;
			}
			return;
		}

		for (int ch = 0; ch < pxtnMAX_CHANNEL; ch++) {
			int time_pan_buf = 0;

			for (int v = 0; v < _p_woice.get_voice_num(); v++) {
				pxtnVOICETONE* p_vt = &_vts[v];
				const pxtnVOICEINSTANCE* p_vi = _p_woice.get_instance(v);

				int work = 0;

				if (p_vt.life_count > 0) {
					int pos = cast(int) p_vt.smp_pos * 4 + ch * 2;
					work += *(cast(short*)&p_vi.p_smp_w[pos]);

					if (ch_num == 1) {
						work += *(cast(short*)&p_vi.p_smp_w[pos + 2]);
						work = work / 2;
					}

					work = (work * _v_VELOCITY) / 128;
					work = (work * _v_VOLUME) / 128;
					work = work * _pan_vols[ch] / 64;

					if (p_vi.env_size) {
						work = work * p_vt.env_volume / 128;
					}

					// smooth tail
					if (_p_woice.get_voice(v).voice_flags & PTV_VOICEFLAG_SMOOTH && p_vt.life_count < smooth_smp) {
						work = work * p_vt.life_count / smooth_smp;
					}
				}
				time_pan_buf += work;
			}
			_pan_time_bufs[ch][time_pan_index] = time_pan_buf;
		}
	}

	void Tone_Supple(int* group_smps, int ch, int time_pan_index) const nothrow @system {
		int idx = (time_pan_index - _pan_times[ch]) & (pxtnBUFSIZE_TIMEPAN - 1);
		group_smps[_v_GROUPNO] += _pan_time_bufs[ch][idx];
	}

	int Tone_Increment_Key() nothrow @safe {
		// prtament..
		if (_portament_sample_num && _key_margin) {
			if (_portament_sample_pos < _portament_sample_num) {
				_portament_sample_pos++;
				_key_now = cast(int)(_key_start + cast(double) _key_margin * _portament_sample_pos / _portament_sample_num);
			} else {
				_key_now = _key_start + _key_margin;
				_key_start = _key_now;
				_key_margin = 0;
			}
		} else {
			_key_now = _key_start + _key_margin;
		}
		return _key_now;
	}

	void Tone_Increment_Sample(float freq) nothrow @system {
		if (!_p_woice) {
			return;
		}

		for (int v = 0; v < _p_woice.get_voice_num(); v++) {
			const pxtnVOICEINSTANCE* p_vi = _p_woice.get_instance(v);
			pxtnVOICETONE* p_vt = &_vts[v];

			if (p_vt.life_count > 0) {
				p_vt.life_count--;
			}
			if (p_vt.life_count > 0) {
				p_vt.on_count--;

				p_vt.smp_pos += p_vt.offset_freq * _v_TUNING * freq;

				if (p_vt.smp_pos >= p_vi.smp_body_w) {
					if (_p_woice.get_voice(v).voice_flags & PTV_VOICEFLAG_WAVELOOP) {
						if (p_vt.smp_pos >= p_vi.smp_body_w) {
							p_vt.smp_pos -= p_vi.smp_body_w;
						}
						if (p_vt.smp_pos >= p_vi.smp_body_w) {
							p_vt.smp_pos = 0;
						}
					} else {
						p_vt.life_count = 0;
					}
				}

				// OFF
				if (p_vt.on_count == 0 && p_vi.env_size) {
					p_vt.env_start = p_vt.env_volume;
					p_vt.env_pos = 0;
				}
			}
		}
	}

	bool set_woice(const(pxtnWoice)* p_woice) nothrow @safe {
		if (!p_woice) {
			return false;
		}
		_p_woice = p_woice;
		_key_now = EVENTDEFAULT_KEY;
		_key_margin = 0;
		_key_start = EVENTDEFAULT_KEY;
		return true;
	}

	const(pxtnWoice)* get_woice() const nothrow @safe {
		return _p_woice;
	}

	bool set_name_buf(const(char)* name, int buf_size) nothrow @system {
		if (!name || buf_size < 0 || buf_size > pxtnMAX_TUNEUNITNAME) {
			return false;
		}
		_name_buf[0 .. $] = 0;
		if (buf_size) {
			memcpy(_name_buf.ptr, name, buf_size);
		}
		_name_size = buf_size;
		return true;
	}

	const(char)* get_name_buf(int* p_buf_size) const return nothrow @system {
		if (p_buf_size) {
			*p_buf_size = _name_size;
		}
		return _name_buf.ptr;
	}

	bool is_name_buf() const nothrow @safe {
		if (_name_size > 0) {
			return true;
		}
		return false;
	}

	pxtnVOICETONE* get_tone(int voice_idx) return nothrow @safe {
		return &_vts[voice_idx];
	}

	void set_operated(bool b) nothrow @safe {
		_bOperated = b;
	}

	void set_played(bool b) nothrow @safe {
		_bPlayed = b;
	}

	bool get_operated() const nothrow @safe {
		return _bOperated;
	}

	bool get_played() const nothrow @safe {
		return _bPlayed;
	}

	pxtnERR Read_v3x(pxtnDescriptor* p_doc, int* p_group) nothrow @system {
		_x3x_UNIT unit = {0};
		int size = 0;

		if (!p_doc.r(&size, 4, 1)) {
			return pxtnERR.pxtnERR_desc_r;
		}
		if (!p_doc.r(&unit, _x3x_UNIT.sizeof, 1)) {
			return pxtnERR.pxtnERR_desc_r;
		}
		if (cast(pxtnWOICETYPE) unit.type != pxtnWOICETYPE.pxtnWOICE_PCM && cast(pxtnWOICETYPE) unit.type != pxtnWOICETYPE.pxtnWOICE_PTV && cast(pxtnWOICETYPE) unit.type != pxtnWOICETYPE.pxtnWOICE_PTN) {
			return pxtnERR.pxtnERR_fmt_unknown;
		}
		*p_group = unit.group;

		return pxtnERR.pxtnOK;
	}

	bool Read_v1x(pxtnDescriptor* p_doc, int* p_group) nothrow @system {
		_x1x_UNIT unit;
		int size;

		if (!p_doc.r(&size, 4, 1)) {
			return false;
		}
		if (!p_doc.r(&unit, _x1x_UNIT.sizeof, 1)) {
			return false;
		}
		if (cast(pxtnWOICETYPE) unit.type != pxtnWOICETYPE.pxtnWOICE_PCM) {
			return false;
		}

		memcpy(_name_buf.ptr, unit.name.ptr, pxtnMAX_TUNEUNITNAME);
		_name_buf[pxtnMAX_TUNEUNITNAME] = '\0';
		*p_group = unit.group;
		return true;
	}
};
