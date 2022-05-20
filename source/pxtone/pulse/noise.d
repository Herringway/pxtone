module pxtone.pulse.noise;

import pxtone.pxtn;

import pxtone.error;
import pxtone.descriptor;
import pxtone.mem;
import pxtone.pulse.frequency;
import pxtone.pulse.oscillator;
import pxtone.pulse.pcm;

enum pxWAVETYPE {
	None = 0,
	Sine,
	Saw,
	Rect,
	Random,
	Saw2,
	Rect2,

	Tri,
	Random2,
	Rect3,
	Rect4,
	Rect8,
	Rect16,
	Saw3,
	Saw4,
	Saw6,
	Saw8,

	num,
}

struct pxNOISEDESIGN_OSCILLATOR {
	pxWAVETYPE type;
	float freq = 0.0;
	float volume = 0.0;
	float offset = 0.0;
	bool b_rev;
}

struct pxNOISEDESIGN_UNIT {
	bool bEnable;
	int enve_num;
	pxtnPOINT[] enves;
	int pan;
	pxNOISEDESIGN_OSCILLATOR main;
	pxNOISEDESIGN_OSCILLATOR freq;
	pxNOISEDESIGN_OSCILLATOR volu;
}

enum NOISEDESIGNLIMIT_SMPNUM = (48000 * 10);
enum NOISEDESIGNLIMIT_ENVE_X = (1000 * 10);
enum NOISEDESIGNLIMIT_ENVE_Y = (100);
enum NOISEDESIGNLIMIT_OSC_FREQUENCY = 44100.0f;
enum NOISEDESIGNLIMIT_OSC_VOLUME = 200.0f;
enum NOISEDESIGNLIMIT_OSC_OFFSET = 100.0f;

void _FixUnit(pxNOISEDESIGN_OSCILLATOR* p_osc) nothrow @safe {
	if (p_osc.type >= pxWAVETYPE.num) {
		p_osc.type = pxWAVETYPE.None;
	}
	if (p_osc.freq > NOISEDESIGNLIMIT_OSC_FREQUENCY) {
		p_osc.freq = NOISEDESIGNLIMIT_OSC_FREQUENCY;
	}
	if (p_osc.freq <= 0) {
		p_osc.freq = 0;
	}
	if (p_osc.volume > NOISEDESIGNLIMIT_OSC_VOLUME) {
		p_osc.volume = NOISEDESIGNLIMIT_OSC_VOLUME;
	}
	if (p_osc.volume <= 0) {
		p_osc.volume = 0;
	}
	if (p_osc.offset > NOISEDESIGNLIMIT_OSC_OFFSET) {
		p_osc.offset = NOISEDESIGNLIMIT_OSC_OFFSET;
	}
	if (p_osc.offset <= 0) {
		p_osc.offset = 0;
	}
}

enum MAX_NOISEEDITUNITNUM = 4;
enum MAX_NOISEEDITENVELOPENUM = 3;

enum NOISEEDITFLAG_XX1 = 0x0001;
enum NOISEEDITFLAG_XX2 = 0x0002;
enum NOISEEDITFLAG_ENVELOPE = 0x0004;
enum NOISEEDITFLAG_PAN = 0x0008;
enum NOISEEDITFLAG_OSC_MAIN = 0x0010;
enum NOISEEDITFLAG_OSC_FREQ = 0x0020;
enum NOISEEDITFLAG_OSC_VOLU = 0x0040;
enum NOISEEDITFLAG_OSC_PAN = 0x0080;

enum NOISEEDITFLAG_UNCOVERED = 0xffffff83;

immutable _code = "PTNOISE-";
//_ver =  20051028 ; -v.0.9.2.3
__gshared const uint _ver = 20120418; // 16 wave types.

bool _WriteOscillator(const(pxNOISEDESIGN_OSCILLATOR)* p_osc, ref pxtnDescriptor p_doc, ref int p_add) nothrow @system {
	int work;
	work = cast(int) p_osc.type;
	if (!p_doc.v_w_asfile(work, p_add)) {
		return false;
	}
	work = cast(int) p_osc.b_rev;
	if (!p_doc.v_w_asfile(work, p_add)) {
		return false;
	}
	work = cast(int)(p_osc.freq * 10);
	if (!p_doc.v_w_asfile(work, p_add)) {
		return false;
	}
	work = cast(int)(p_osc.volume * 10);
	if (!p_doc.v_w_asfile(work, p_add)) {
		return false;
	}
	work = cast(int)(p_osc.offset * 10);
	if (!p_doc.v_w_asfile(work, p_add)) {
		return false;
	}
	return true;
}

pxtnERR _ReadOscillator(pxNOISEDESIGN_OSCILLATOR* p_osc, ref pxtnDescriptor p_doc) nothrow @system {
	int work;
	if (!p_doc.v_r(work)) {
		return pxtnERR.desc_r;
	}
	p_osc.type = cast(pxWAVETYPE) work;
	if (p_osc.type >= pxWAVETYPE.num) {
		return pxtnERR.fmt_unknown;
	}
	if (!p_doc.v_r(work)) {
		return pxtnERR.desc_r;
	}
	p_osc.b_rev = work ? true : false;
	if (!p_doc.v_r(work)) {
		return pxtnERR.desc_r;
	}
	p_osc.freq = cast(float) work / 10;
	if (!p_doc.v_r(work)) {
		return pxtnERR.desc_r;
	}
	p_osc.volume = cast(float) work / 10;
	if (!p_doc.v_r(work)) {
		return pxtnERR.desc_r;
	}
	p_osc.offset = cast(float) work / 10;

	return pxtnERR.OK;
}

uint _MakeFlags(const(pxNOISEDESIGN_UNIT)* pU) nothrow @safe {
	uint flags = 0;
	flags |= NOISEEDITFLAG_ENVELOPE;
	if (pU.pan) {
		flags |= NOISEEDITFLAG_PAN;
	}
	if (pU.main.type != pxWAVETYPE.None) {
		flags |= NOISEEDITFLAG_OSC_MAIN;
	}
	if (pU.freq.type != pxWAVETYPE.None) {
		flags |= NOISEEDITFLAG_OSC_FREQ;
	}
	if (pU.volu.type != pxWAVETYPE.None) {
		flags |= NOISEEDITFLAG_OSC_VOLU;
	}
	return flags;
}

int _CompareOsci(const(pxNOISEDESIGN_OSCILLATOR)* p_osc1, const(pxNOISEDESIGN_OSCILLATOR)* p_osc2) nothrow @safe {
	if (p_osc1.type != p_osc2.type) {
		return 1;
	}
	if (p_osc1.freq != p_osc2.freq) {
		return 1;
	}
	if (p_osc1.volume != p_osc2.volume) {
		return 1;
	}
	if (p_osc1.offset != p_osc2.offset) {
		return 1;
	}
	if (p_osc1.b_rev != p_osc2.b_rev) {
		return 1;
	}
	return 0;
}

struct pxtnPulse_Noise {
private:
	int _smp_num_44k;
	int _unit_num;
	pxNOISEDESIGN_UNIT[] _units;

public:
	 ~this() nothrow @system {
		Release();
	}

	bool write(ref pxtnDescriptor p_doc, int* p_add) const nothrow @system {
		bool b_ret = false;
		int u, e, seek, num_seek, flags;
		char _byte;
		char unit_num = 0;
		const(pxNOISEDESIGN_UNIT)* pU;

		//	Fix();

		if (p_add) {
			seek = *p_add;
		} else {
			seek = 0;
		}

		if (!p_doc.w_asfile(_code)) {
			goto End;
		}
		if (!p_doc.w_asfile(_ver)) {
			goto End;
		}
		seek += 12;
		if (!p_doc.v_w_asfile(_smp_num_44k, seek)) {
			goto End;
		}

		if (!p_doc.w_asfile(unit_num)) {
			goto End;
		}
		num_seek = seek;
		seek += 1;

		for (u = 0; u < _unit_num; u++) {
			pU = &_units[u];
			if (pU.bEnable) {
				// フラグ
				flags = _MakeFlags(pU);
				if (!p_doc.v_w_asfile(flags, seek)) {
					goto End;
				}
				if (flags & NOISEEDITFLAG_ENVELOPE) {
					if (!p_doc.v_w_asfile(pU.enve_num, seek)) {
						goto End;
					}
					for (e = 0; e < pU.enve_num; e++) {
						if (!p_doc.v_w_asfile(pU.enves[e].x, seek)) {
							goto End;
						}
						if (!p_doc.v_w_asfile(pU.enves[e].y, seek)) {
							goto End;
						}
					}
				}
				if (flags & NOISEEDITFLAG_PAN) {
					_byte = cast(char) pU.pan;
					if (!p_doc.w_asfile(_byte)) {
						goto End;
					}
					seek++;
				}
				if (flags & NOISEEDITFLAG_OSC_MAIN) {
					if (!_WriteOscillator(&pU.main, p_doc, seek)) {
						goto End;
					}
				}
				if (flags & NOISEEDITFLAG_OSC_FREQ) {
					if (!_WriteOscillator(&pU.freq, p_doc, seek)) {
						goto End;
					}
				}
				if (flags & NOISEEDITFLAG_OSC_VOLU) {
					if (!_WriteOscillator(&pU.volu, p_doc, seek)) {
						goto End;
					}
				}
				unit_num++;
			}
		}

		// update unit_num.
		p_doc.seek(pxtnSEEK.cur, num_seek - seek);
		if (!p_doc.w_asfile(unit_num)) {
			goto End;
		}
		p_doc.seek(pxtnSEEK.cur, seek - num_seek - 1);
		if (p_add) {
			*p_add = seek;
		}

		b_ret = true;
	End:

		return b_ret;
	}

	pxtnERR read(ref pxtnDescriptor p_doc) nothrow @system {
		pxtnERR res = pxtnERR.VOID;
		uint flags = 0;
		char unit_num = 0;
		char _byte = 0;
		uint ver = 0;

		pxNOISEDESIGN_UNIT* pU = null;

		char[8] code = 0;

		Release();

		if (!p_doc.r(code[])) {
			res = pxtnERR.desc_r;
			goto term;
		}
		if (code != _code[0 .. 8]) {
			res = pxtnERR.inv_code;
			goto term;
		}
		if (!p_doc.r(ver)) {
			res = pxtnERR.desc_r;
			goto term;
		}
		if (ver > _ver) {
			res = pxtnERR.fmt_new;
			goto term;
		}
		if (!p_doc.v_r(_smp_num_44k)) {
			res = pxtnERR.desc_r;
			goto term;
		}
		if (!p_doc.r(unit_num)) {
			res = pxtnERR.desc_r;
			goto term;
		}
		if (unit_num < 0) {
			res = pxtnERR.inv_data;
			goto term;
		}
		if (unit_num > MAX_NOISEEDITUNITNUM) {
			res = pxtnERR.fmt_unknown;
			goto term;
		}
		_unit_num = unit_num;

		_units = allocate!pxNOISEDESIGN_UNIT(_unit_num);
		if (!_units) {
			res = pxtnERR.memory;
			goto term;
		}

		for (int u = 0; u < _unit_num; u++) {
			pU = &_units[u];
			pU.bEnable = true;

			if (!p_doc.v_r(*cast(int*)&flags)) {
				res = pxtnERR.desc_r;
				goto term;
			}
			if (flags & NOISEEDITFLAG_UNCOVERED) {
				res = pxtnERR.fmt_unknown;
				goto term;
			}

			// envelope
			if (flags & NOISEEDITFLAG_ENVELOPE) {
				if (!p_doc.v_r(pU.enve_num)) {
					res = pxtnERR.desc_r;
					goto term;
				}
				if (pU.enve_num > MAX_NOISEEDITENVELOPENUM) {
					res = pxtnERR.fmt_unknown;
					goto term;
				}
				pU.enves = allocate!pxtnPOINT(pU.enve_num);
				if (!pU.enves) {
					res = pxtnERR.memory;
					goto term;
				}
				for (int e = 0; e < pU.enve_num; e++) {
					if (!p_doc.v_r(pU.enves[e].x)) {
						res = pxtnERR.desc_r;
						goto term;
					}
					if (!p_doc.v_r(pU.enves[e].y)) {
						res = pxtnERR.desc_r;
						goto term;
					}
				}
			}
			// pan
			if (flags & NOISEEDITFLAG_PAN) {
				if (!p_doc.r(_byte)) {
					res = pxtnERR.desc_r;
					goto term;
				}
				pU.pan = _byte;
			}

			if (flags & NOISEEDITFLAG_OSC_MAIN) {
				res = _ReadOscillator(&pU.main, p_doc);
				if (res != pxtnERR.OK) {
					goto term;
				}
			}
			if (flags & NOISEEDITFLAG_OSC_FREQ) {
				res = _ReadOscillator(&pU.freq, p_doc);
				if (res != pxtnERR.OK) {
					goto term;
				}
			}
			if (flags & NOISEEDITFLAG_OSC_VOLU) {
				res = _ReadOscillator(&pU.volu, p_doc);
				if (res != pxtnERR.OK) {
					goto term;
				}
			}
		}

		res = pxtnERR.OK;
	term:
		if (res != pxtnERR.OK) {
			Release();
		}

		return res;
	}

	void Release() nothrow @system {
		if (_units) {
			for (int u = 0; u < _unit_num; u++) {
				if (_units[u].enves) {
					deallocate(_units[u].enves);
				}
			}
			deallocate(_units);
			_unit_num = 0;
		}
	}

	bool Allocate(int unit_num, int envelope_num) nothrow @system {
		bool b_ret = false;

		Release();

		_unit_num = unit_num;
		_units = allocate!pxNOISEDESIGN_UNIT(unit_num);
		if (!_units) {
			goto End;
		}

		for (int u = 0; u < unit_num; u++) {
			pxNOISEDESIGN_UNIT* p_unit = &_units[u];
			p_unit.enve_num = envelope_num;
			p_unit.enves = allocate!pxtnPOINT(p_unit.enve_num);
			if (!p_unit.enves) {
				goto End;
			}
		}

		b_ret = true;
	End:
		if (!b_ret) {
			Release();
		}

		return b_ret;
	}

	bool Copy(pxtnPulse_Noise* p_dst) const nothrow @system {
		if (!p_dst) {
			return false;
		}

		bool b_ret = false;

		p_dst.Release();
		p_dst._smp_num_44k = _smp_num_44k;

		if (_unit_num) {
			int enve_num = _units[0].enve_num;
			if (!p_dst.Allocate(_unit_num, enve_num)) {
				goto End;
			}
			for (int u = 0; u < _unit_num; u++) {
				p_dst._units[u].bEnable = _units[u].bEnable;
				p_dst._units[u].enve_num = _units[u].enve_num;
				p_dst._units[u].freq = _units[u].freq;
				p_dst._units[u].main = _units[u].main;
				p_dst._units[u].pan = _units[u].pan;
				p_dst._units[u].volu = _units[u].volu;
				p_dst._units[u].enves = allocate!pxtnPOINT(enve_num);
				if (!p_dst._units[u].enves) {
					goto End;
				}
				for (int e = 0; e < enve_num; e++) {
					p_dst._units[u].enves[e] = _units[u].enves[e];
				}
			}
		}

		b_ret = true;
	End:
		if (!b_ret) {
			p_dst.Release();
		}

		return b_ret;
	}

	int Compare(const(pxtnPulse_Noise)* p_src) const nothrow @safe {
		if (!p_src) {
			return -1;
		}

		if (p_src._smp_num_44k != _smp_num_44k) {
			return 1;
		}
		if (p_src._unit_num != _unit_num) {
			return 1;
		}

		for (int u = 0; u < _unit_num; u++) {
			if (p_src._units[u].bEnable != _units[u].bEnable) {
				return 1;
			}
			if (p_src._units[u].enve_num != _units[u].enve_num) {
				return 1;
			}
			if (p_src._units[u].pan != _units[u].pan) {
				return 1;
			}
			if (_CompareOsci(&p_src._units[u].main, &_units[u].main)) {
				return 1;
			}
			if (_CompareOsci(&p_src._units[u].freq, &_units[u].freq)) {
				return 1;
			}
			if (_CompareOsci(&p_src._units[u].volu, &_units[u].volu)) {
				return 1;
			}

			for (int e = 0; e < _units[u].enve_num; e++) {
				if (_units[u].enves[e].x != _units[u].enves[e].x) {
					return 1;
				}
				if (_units[u].enves[e].y != _units[u].enves[e].y) {
					return 1;
				}
			}
		}
		return 0;
	}

	void Fix() nothrow @safe {
		pxNOISEDESIGN_UNIT* p_unit;
		int i, e;

		if (_smp_num_44k > NOISEDESIGNLIMIT_SMPNUM) {
			_smp_num_44k = NOISEDESIGNLIMIT_SMPNUM;
		}

		for (i = 0; i < _unit_num; i++) {
			p_unit = &_units[i];
			if (p_unit.bEnable) {
				for (e = 0; e < p_unit.enve_num; e++) {
					if (p_unit.enves[e].x > NOISEDESIGNLIMIT_ENVE_X) {
						p_unit.enves[e].x = NOISEDESIGNLIMIT_ENVE_X;
					}
					if (p_unit.enves[e].x < 0) {
						p_unit.enves[e].x = 0;
					}
					if (p_unit.enves[e].y > NOISEDESIGNLIMIT_ENVE_Y) {
						p_unit.enves[e].y = NOISEDESIGNLIMIT_ENVE_Y;
					}
					if (p_unit.enves[e].y < 0) {
						p_unit.enves[e].y = 0;
					}
				}
				if (p_unit.pan < -100) {
					p_unit.pan = -100;
				}
				if (p_unit.pan > 100) {
					p_unit.pan = 100;
				}
				_FixUnit(&p_unit.main);
				_FixUnit(&p_unit.freq);
				_FixUnit(&p_unit.volu);
			}
		}
	}

	void set_smp_num_44k(int num) nothrow @safe {
		_smp_num_44k = num;
	}

	int get_unit_num() const nothrow @safe {
		return _unit_num;
	}

	int get_smp_num_44k() const nothrow @safe {
		return _smp_num_44k;
	}

	float get_sec() const nothrow @safe {
		return cast(float) _smp_num_44k / 44100;
	}

	pxNOISEDESIGN_UNIT* get_unit(int u) nothrow @safe {
		if (!_units || u < 0 || u >= _unit_num) {
			return null;
		}
		return &_units[u];
	}
}
