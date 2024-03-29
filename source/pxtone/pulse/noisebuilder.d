﻿module pxtone.pulse.noisebuilder;

import pxtone.pxtn;

import pxtone.error;
import pxtone.pulse.frequency;
import pxtone.pulse.oscillator;
import pxtone.pulse.pcm;
import pxtone.pulse.noise;

enum _BASIC_SPS = 44100.0;
enum _BASIC_FREQUENCY = 100.0; // 100 Hz
enum _SAMPLING_TOP = 32767; //  16 bit max
enum _KEY_TOP = 0x3200; //  40 key

enum _smp_num_rand = 44100;
enum _smp_num = cast(int)(_BASIC_SPS / _BASIC_FREQUENCY);

enum _RANDOMTYPE {
	None = 0,
	Saw,
	Rect,
}

struct _OSCILLATOR {
	double incriment;
	double offset;
	double volume;
	const(short)[] p_smp;
	bool bReverse;
	_RANDOMTYPE ran_type;
	int rdm_start;
	int rdm_margin;
	int rdm_index;
}

struct _POINT {
	int smp;
	double mag;
}

struct _UNIT {
	bool bEnable;
	double[2] pan;
	int enve_index;
	double enve_mag_start;
	double enve_mag_margin;
	int enve_count;
	int enve_num;
	_POINT[] enves;

	_OSCILLATOR main;
	_OSCILLATOR freq;
	_OSCILLATOR volu;
}

void _set_ocsillator(_OSCILLATOR* p_to, pxNOISEDESIGN_OSCILLATOR* p_from, int sps, const(short)[] p_tbl, const(short)[] p_tbl_rand) nothrow @safe {
	const(short)[] p;

	switch (p_from.type) {
	case pxWAVETYPE.Random:
		p_to.ran_type = _RANDOMTYPE.Saw;
		break;
	case pxWAVETYPE.Random2:
		p_to.ran_type = _RANDOMTYPE.Rect;
		break;
	default:
		p_to.ran_type = _RANDOMTYPE.None;
		break;
	}

	p_to.incriment = (_BASIC_SPS / sps) * (p_from.freq / _BASIC_FREQUENCY);

	// offset
	if (p_to.ran_type != _RANDOMTYPE.None) {
		p_to.offset = 0;
	} else {
		p_to.offset = cast(double) _smp_num * (p_from.offset / 100);
	}

	p_to.volume = p_from.volume / 100;
	p_to.p_smp = p_tbl;
	p_to.bReverse = p_from.b_rev;

	p_to.rdm_start = 0;
	p_to.rdm_index = cast(int)(cast(double)(_smp_num_rand) * (p_from.offset / 100));
	p = p_tbl_rand;
	p_to.rdm_margin = p[p_to.rdm_index];

}

void _incriment(_OSCILLATOR* p_osc, double incriment, const(short)[] p_tbl_rand) nothrow @safe {
	p_osc.offset += incriment;
	if (p_osc.offset > _smp_num) {
		p_osc.offset -= _smp_num;
		if (p_osc.offset >= _smp_num) {
			p_osc.offset = 0;
		}

		if (p_osc.ran_type != _RANDOMTYPE.None) {
			const(short)[] p = p_tbl_rand;
			p_osc.rdm_start = p[p_osc.rdm_index];
			p_osc.rdm_index++;
			if (p_osc.rdm_index >= _smp_num_rand) {
				p_osc.rdm_index = 0;
			}
			p_osc.rdm_margin = p[p_osc.rdm_index] - p_osc.rdm_start;
		}
	}
}

struct pxtnPulse_NoiseBuilder {
private:
	static immutable short[][pxWAVETYPE.num] _p_tables = genTables();

	pxtnPulse_Frequency _freq;

public:
	pxtnPulse_PCM BuildNoise(ref pxtnPulse_Noise p_noise, int ch, int sps, int bps) const @system {
		int offset = 0;
		double work = 0;
		double vol = 0;
		double fre = 0;
		double store = 0;
		int byte4 = 0;
		int unit_num = 0;
		ubyte* p = null;
		int smp_num = 0;

		_UNIT[] units = null;
		pxtnPulse_PCM p_pcm;

		p_noise.Fix();

		unit_num = p_noise.get_unit_num();

		units = new _UNIT[](unit_num);
		scope(exit) {
			units = null;
		}

		for (int u = 0; u < unit_num; u++) {
			_UNIT* pU = &units[u];

			pxNOISEDESIGN_UNIT* p_du = p_noise.get_unit(u);

			pU.bEnable = p_du.bEnable;
			pU.enve_num = p_du.enve_num;
			if (p_du.pan == 0) {
				pU.pan[0] = 1;
				pU.pan[1] = 1;
			} else if (p_du.pan < 0) {
				pU.pan[0] = 1;
				pU.pan[1] = cast(double)(100.0f + p_du.pan) / 100;
			} else {
				pU.pan[1] = 1;
				pU.pan[0] = cast(double)(100.0f - p_du.pan) / 100;
			}

			pU.enves = new _POINT[](pU.enve_num);

			// envelope
			for (int e = 0; e < p_du.enve_num; e++) {
				pU.enves[e].smp = sps * p_du.enves[e].x / 1000;
				pU.enves[e].mag = cast(double) p_du.enves[e].y / 100;
			}
			pU.enve_index = 0;
			pU.enve_mag_start = 0;
			pU.enve_mag_margin = 0;
			pU.enve_count = 0;
			while (pU.enve_index < pU.enve_num) {
				pU.enve_mag_margin = pU.enves[pU.enve_index].mag - pU.enve_mag_start;
				if (pU.enves[pU.enve_index].smp) {
					break;
				}
				pU.enve_mag_start = pU.enves[pU.enve_index].mag;
				pU.enve_index++;
			}

			_set_ocsillator(&pU.main, &p_du.main, sps, _p_tables[p_du.main.type], _p_tables[pxWAVETYPE.Random]);
			_set_ocsillator(&pU.freq, &p_du.freq, sps, _p_tables[p_du.freq.type], _p_tables[pxWAVETYPE.Random]);
			_set_ocsillator(&pU.volu, &p_du.volu, sps, _p_tables[p_du.volu.type], _p_tables[pxWAVETYPE.Random]);
		}

		smp_num = cast(int)(cast(double) p_noise.get_smp_num_44k() / (44100.0 / sps));

		p_pcm = pxtnPulse_PCM.init;
		p_pcm.Create(ch, sps, bps, smp_num);
		p = p_pcm.get_p_buf().ptr;

		for (int s = 0; s < smp_num; s++) {
			for (int c = 0; c < ch; c++) {
				store = 0;
				for (int u = 0; u < unit_num; u++) {
					_UNIT* pU = &units[u];

					if (pU.bEnable) {
						_OSCILLATOR* po;

						// main
						po = &pU.main;
						switch (po.ran_type) {
						case _RANDOMTYPE.None:
							offset = cast(int) po.offset;
							if (offset >= 0) {
								work = po.p_smp[offset];
							} else {
								work = 0;
							}
							break;
						case _RANDOMTYPE.Saw:
							if (po.offset >= 0) {
								work = po.rdm_start + po.rdm_margin * cast(int) po.offset / _smp_num;
							} else {
								work = 0;
							}
							break;
						case _RANDOMTYPE.Rect:
							if (po.offset >= 0) {
								work = po.rdm_start;
							} else {
								work = 0;
							}
							break;
						default:
							break;
						}
						if (po.bReverse) {
							work *= -1;
						}
						work *= po.volume;

						// volu
						po = &pU.volu;
						switch (po.ran_type) {
						case _RANDOMTYPE.None:
							offset = cast(int) po.offset;
							vol = cast(double) po.p_smp[offset];
							break;
						case _RANDOMTYPE.Saw:
							vol = po.rdm_start + po.rdm_margin * cast(int) po.offset / _smp_num;
							break;
						case _RANDOMTYPE.Rect:
							vol = po.rdm_start;
							break;
						default:
							break;
						}
						if (po.bReverse) {
							vol *= -1;
						}
						vol *= po.volume;

						work = work * (vol + _SAMPLING_TOP) / (_SAMPLING_TOP * 2);
						work = work * pU.pan[c];

						// envelope
						if (pU.enve_index < pU.enve_num) {
							work *= pU.enve_mag_start + (pU.enve_mag_margin * pU.enve_count / pU.enves[pU.enve_index].smp);
						} else {
							work *= pU.enve_mag_start;
						}
						store += work;
					}
				}

				byte4 = cast(int) store;
				if (byte4 > _SAMPLING_TOP) {
					byte4 = _SAMPLING_TOP;
				}
				if (byte4 < -_SAMPLING_TOP) {
					byte4 = -_SAMPLING_TOP;
				}
				if (bps == 8) {
					*p = cast(ubyte)((byte4 >> 8) + 128);
					p += 1;
				}  //  8bit
				else {
					*(cast(short*) p) = cast(short) byte4;
					p += 2;
				} // 16bit
			}

			// incriment
			for (int u = 0; u < unit_num; u++) {
				_UNIT* pU = &units[u];

				if (pU.bEnable) {
					_OSCILLATOR* po = &pU.freq;

					switch (po.ran_type) {
					case _RANDOMTYPE.None:
						offset = cast(int) po.offset;
						fre = _KEY_TOP * po.p_smp[offset] / _SAMPLING_TOP;
						break;
					case _RANDOMTYPE.Saw:
						fre = po.rdm_start + po.rdm_margin * cast(int) po.offset / _smp_num;
						break;
					case _RANDOMTYPE.Rect:
						fre = po.rdm_start;
						break;
					default:
						break;
					}

					if (po.bReverse) {
						fre *= -1;
					}
					fre *= po.volume;

					_incriment(&pU.main, pU.main.incriment * _freq.Get(cast(int) fre), _p_tables[pxWAVETYPE.Random]);
					_incriment(&pU.freq, pU.freq.incriment, _p_tables[pxWAVETYPE.Random]);
					_incriment(&pU.volu, pU.volu.incriment, _p_tables[pxWAVETYPE.Random]);

					// envelope
					if (pU.enve_index < pU.enve_num) {
						pU.enve_count++;
						if (pU.enve_count >= pU.enves[pU.enve_index].smp) {
							pU.enve_count = 0;
							pU.enve_mag_start = pU.enves[pU.enve_index].mag;
							pU.enve_mag_margin = 0;
							pU.enve_index++;
							while (pU.enve_index < pU.enve_num) {
								pU.enve_mag_margin = pU.enves[pU.enve_index].mag - pU.enve_mag_start;
								if (pU.enves[pU.enve_index].smp) {
									break;
								}
								pU.enve_mag_start = pU.enves[pU.enve_index].mag;
								pU.enve_index++;
							}
						}
					}
				}
			}
		}

		return p_pcm;
	}
}

short[][pxWAVETYPE.num] genTables() {
	pxtnPOINT[1] overtones_sine = [{1, 128}];
	pxtnPOINT[16] overtones_saw2 = [{1, 128}, {2, 128}, {3, 128}, {4, 128}, {5, 128}, {6, 128}, {7, 128}, {8, 128}, {9, 128}, {10, 128}, {11, 128}, {12, 128}, {13, 128}, {14, 128}, {15, 128}, {16, 128},];
	pxtnPOINT[8] overtones_rect2 = [{1, 128}, {3, 128}, {5, 128}, {7, 128}, {9, 128}, {11, 128}, {13, 128}, {15, 128},];

	pxtnPOINT[4] coodi_tri = [{0, 0}, {_smp_num / 4, 128}, {_smp_num * 3 / 4, -128}, {_smp_num, 0}];
	int s;
	short[] p;
	double work;

	int a;
	short v;
	pxtnPulse_Oscillator osci;
	int[2] _rand_buf;

	void _random_reset() nothrow @safe {
		_rand_buf[0] = 0x4444;
		_rand_buf[1] = 0x8888;
	}

	short _random_get() nothrow @system {
		ubyte[2] w1, w2;

        short tmp = cast(short)(_rand_buf[0] + _rand_buf[1]);
		w2[1] = (tmp & 0xFF);
		w2[0] = (tmp & 0xFF00) >> 8;
		_rand_buf[1] = cast(short) _rand_buf[0];
		_rand_buf[0] = cast(short) (w2[0] + (w2[1] << 8));

		return cast(short) (w2[0] + (w2[1] << 8));
	}

	short[][pxWAVETYPE.num] _p_tables;
	_p_tables[pxWAVETYPE.None] = new short[_smp_num];
	_p_tables[pxWAVETYPE.Sine] = new short[_smp_num];
	_p_tables[pxWAVETYPE.Saw] = new short[_smp_num];
	_p_tables[pxWAVETYPE.Rect] = new short[_smp_num];
	_p_tables[pxWAVETYPE.Random] = new short[_smp_num_rand];
	_p_tables[pxWAVETYPE.Saw2] = new short[_smp_num];
	_p_tables[pxWAVETYPE.Rect2] = new short[_smp_num];
	_p_tables[pxWAVETYPE.Tri] = new short[_smp_num];
	//_p_tables[pxWAVETYPE.Random2] = new short[_smp_num_rand];
	_p_tables[pxWAVETYPE.Rect3] = new short[_smp_num];
	_p_tables[pxWAVETYPE.Rect4] = new short[_smp_num];
	_p_tables[pxWAVETYPE.Rect8] = new short[_smp_num];
	_p_tables[pxWAVETYPE.Rect16] = new short[_smp_num];
	_p_tables[pxWAVETYPE.Saw3] = new short[_smp_num];
	_p_tables[pxWAVETYPE.Saw4] = new short[_smp_num];
	_p_tables[pxWAVETYPE.Saw6] = new short[_smp_num];
	_p_tables[pxWAVETYPE.Saw8] = new short[_smp_num];

	// none --

	// sine --
	osci.ReadyGetSample(overtones_sine[], 1, 128, _smp_num, 0);
	p = _p_tables[pxWAVETYPE.Sine];
	for (s = 0; s < _smp_num; s++) {
		work = osci.GetOneSample_Overtone(s);
		if (work > 1.0) {
			work = 1.0;
		}
		if (work < -1.0) {
			work = -1.0;
		}
		p[0] = cast(short)(work * _SAMPLING_TOP);
		p = p[1 .. $];
	}

	// saw down --
	p = _p_tables[pxWAVETYPE.Saw];
	work = _SAMPLING_TOP + _SAMPLING_TOP;
	for (s = 0; s < _smp_num; s++) {
		p[0] = cast(short)(_SAMPLING_TOP - work * s / _smp_num);
		p = p[1 .. $];
	}

	// rect --
	p = _p_tables[pxWAVETYPE.Rect];
	for (s = 0; s < _smp_num / 2; s++) {
		p[0] = cast(short)(_SAMPLING_TOP);
		p = p[1 ..$];
	}
	for ( /+s+/ ; s < _smp_num; s++) {
		p[0] = cast(short)(-_SAMPLING_TOP);
		p = p[1 .. $];
	}

	// random --
	p = _p_tables[pxWAVETYPE.Random];
	_random_reset();
	for (s = 0; s < _smp_num_rand; s++) {
		p[0] = _random_get();
		p = p[1 .. $];
	}

	// saw2 --
	osci.ReadyGetSample(overtones_saw2[], 16, 128, _smp_num, 0);
	p = _p_tables[pxWAVETYPE.Saw2];
	for (s = 0; s < _smp_num; s++) {
		work = osci.GetOneSample_Overtone(s);
		if (work > 1.0) {
			work = 1.0;
		}
		if (work < -1.0) {
			work = -1.0;
		}
		p[0] = cast(short)(work * _SAMPLING_TOP);
		p = p[1 .. $];
	}

	// rect2 --
	osci.ReadyGetSample(overtones_rect2[], 8, 128, _smp_num, 0);
	p = _p_tables[pxWAVETYPE.Rect2];
	for (s = 0; s < _smp_num; s++) {
		work = osci.GetOneSample_Overtone(s);
		if (work > 1.0) {
			work = 1.0;
		}
		if (work < -1.0) {
			work = -1.0;
		}
		p[0] = cast(short)(work * _SAMPLING_TOP);
		p = p[1 .. $];
	}

	// Triangle --
	osci.ReadyGetSample(coodi_tri[], 4, 128, _smp_num, _smp_num);
	p = _p_tables[pxWAVETYPE.Tri];
	for (s = 0; s < _smp_num; s++) {
		work = osci.GetOneSample_Coodinate(s);
		if (work > 1.0) {
			work = 1.0;
		}
		if (work < -1.0) {
			work = -1.0;
		}
		p[0] = cast(short)(work * _SAMPLING_TOP);
		p = p[1 .. $];
	}

	// Random2  -- x

	// Rect-3  --
	p = _p_tables[pxWAVETYPE.Rect3];
	for (s = 0; s < _smp_num / 3; s++) {
		p[0] = cast(short)(_SAMPLING_TOP);
		p = p[1 .. $];
	}
	for ( /+s+/ ; s < _smp_num; s++) {
		p[0] = cast(short)(-_SAMPLING_TOP);
		p = p[1 .. $];
	}
	// Rect-4   --
	p = _p_tables[pxWAVETYPE.Rect4];
	for (s = 0; s < _smp_num / 4; s++) {
		p[0] = cast(short)(_SAMPLING_TOP);
		p = p[1 .. $];
	}
	for ( /+s+/ ; s < _smp_num; s++) {
		p[0] = cast(short)(-_SAMPLING_TOP);
		p = p[1 .. $];
	}
	// Rect-8   --
	p = _p_tables[pxWAVETYPE.Rect8];
	for (s = 0; s < _smp_num / 8; s++) {
		p[0] = cast(short)(_SAMPLING_TOP);
		p = p[1 .. $];
	}
	for ( /+s+/ ; s < _smp_num; s++) {
		p[0] = cast(short)(-_SAMPLING_TOP);
		p = p[1 .. $];
	}
	// Rect-16  --
	p = _p_tables[pxWAVETYPE.Rect16];
	for (s = 0; s < _smp_num / 16; s++) {
		p[0] = cast(short)(_SAMPLING_TOP);
		p = p[1 .. $];
	}
	for ( /+s+/ ; s < _smp_num; s++) {
		p[0] = cast(short)(-_SAMPLING_TOP);
		p = p[1 .. $];
	}

	// Saw-3    --
	p = _p_tables[pxWAVETYPE.Saw3];
	for (s = 0; s < _smp_num / 3; s++) {
		p[0] = cast(short)(_SAMPLING_TOP);
		p = p[1 .. $];
	}
	for ( /+s+/ ; s < _smp_num * 2 / 3; s++) {
		p[0] = cast(short)(0);
		p = p[1 .. $];
	}
	for ( /+s+/ ; s < _smp_num; s++) {
		p[0] = cast(short)(-_SAMPLING_TOP);
		p = p[1 .. $];
	}

	// Saw-4    --
	p = _p_tables[pxWAVETYPE.Saw4];
	for (s = 0; s < _smp_num / 4; s++) {
		p[0] = cast(short)(_SAMPLING_TOP);
		p = p[1 .. $];
	}
	for ( /+s+/ ; s < _smp_num * 2 / 4; s++) {
		p[0] = cast(short)(_SAMPLING_TOP / 3);
		p = p[1 .. $];
	}
	for ( /+s+/ ; s < _smp_num * 3 / 4; s++) {
		p[0] = cast(short)(-_SAMPLING_TOP / 3);
		p = p[1 .. $];
	}
	for ( /+s+/ ; s < _smp_num; s++) {
		p[0] = cast(short)(-_SAMPLING_TOP);
		p = p[1 .. $];
	}

	// Saw-6    --
	p = _p_tables[pxWAVETYPE.Saw6];
	a = _smp_num * 1 / 6;
	v = _SAMPLING_TOP;
	for (s = 0; s < a; s++) {
		p[0] = v;
		p = p[1 .. $];
	}
	a = _smp_num * 2 / 6;
	v = _SAMPLING_TOP - _SAMPLING_TOP * 2 / 5;
	for ( /+s+/ ; s < a; s++) {
		p[0] = v;
		p = p[1 .. $];
	}
	a = _smp_num * 3 / 6;
	v = _SAMPLING_TOP / 5;
	for ( /+s+/ ; s < a; s++) {
		p[0] = v;
		p = p[1 .. $];
	}
	a = _smp_num * 4 / 6;
	v = -_SAMPLING_TOP / 5;
	for ( /+s+/ ; s < a; s++) {
		p[0] = v;
		p = p[1 .. $];
	}
	a = _smp_num * 5 / 6;
	v = -_SAMPLING_TOP + _SAMPLING_TOP * 2 / 5;
	for ( /+s+/ ; s < a; s++) {
		p[0] = v;
		p = p[1 .. $];
	}
	a = _smp_num;
	v = -_SAMPLING_TOP;
	for ( /+s+/ ; s < a; s++) {
		p[0] = v;
		p = p[1 .. $];
	}

	// Saw-8    --
	p = _p_tables[pxWAVETYPE.Saw8];
	a = _smp_num * 1 / 8;
	v = _SAMPLING_TOP;
	for (s = 0; s < a; s++) {
		p[0] = v;
		p = p[1 .. $];
	}
	a = _smp_num * 2 / 8;
	v = _SAMPLING_TOP - _SAMPLING_TOP * 2 / 7;
	for ( /+s+/ ; s < a; s++) {
		p[0] = v;
		p = p[1 .. $];
	}
	a = _smp_num * 3 / 8;
	v = _SAMPLING_TOP - _SAMPLING_TOP * 4 / 7;
	for ( /+s+/ ; s < a; s++) {
		p[0] = v;
		p = p[1 .. $];
	}
	a = _smp_num * 4 / 8;
	v = _SAMPLING_TOP / 7;
	for ( /+s+/ ; s < a; s++) {
		p[0] = v;
		p = p[1 .. $];
	}
	a = _smp_num * 5 / 8;
	v = -_SAMPLING_TOP / 7;
	for ( /+s+/ ; s < a; s++) {
		p[0] = v;
		p = p[1 .. $];
	}
	a = _smp_num * 6 / 8;
	v = -_SAMPLING_TOP + _SAMPLING_TOP * 4 / 7;
	for ( /+s+/ ; s < a; s++) {
		p[0] = v;
		p = p[1 .. $];
	}
	a = _smp_num * 7 / 8;
	v = -_SAMPLING_TOP + _SAMPLING_TOP * 2 / 7;
	for ( /+s+/ ; s < a; s++) {
		p[0] = v;
		p = p[1 .. $];
	}
	a = _smp_num;
	v = -_SAMPLING_TOP;
	for ( /+s+/ ; s < a; s++) {
		p[0] = v;
		p = p[1 .. $];
	}
	return _p_tables;
}
