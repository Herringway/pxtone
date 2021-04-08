module pxtone.pulse.oscillator;

import pxtone.pxtn;

import core.stdc.math;

struct pxtnPulse_Oscillator {
private:
	pxtnPOINT[] _p_point = null;
	int _point_num = 0;
	int _point_reso = 0;
	int _volume = 0;
	int _sample_num = 0;

public:
	void ReadyGetSample(pxtnPOINT[] p_point, int point_num, int volume, int sample_num, int point_reso) nothrow @safe {
		_volume = volume;
		_p_point = p_point;
		_sample_num = sample_num;
		_point_num = point_num;
		_point_reso = point_reso;
	}

	double GetOneSample_Overtone(int index) nothrow @safe {
		int o;
		double work_double;
		double pi = 3.1415926535897932;
		double sss;

		work_double = 0;
		for (o = 0; o < _point_num; o++) {
			sss = 2 * pi * (_p_point[o].x) * index / _sample_num;
			work_double += (sin(sss) * cast(double) _p_point[o].y / (_p_point[o].x) / 128);
		}
		work_double = work_double * _volume / 128;

		return work_double;
	}

	double GetOneSample_Coodinate(int index) nothrow @safe {
		int i;
		int c;
		int x1, y1, x2, y2;
		int w, h;
		double work;

		i = _point_reso * index / _sample_num;

		// find target 2 ponits
		c = 0;
		while (c < _point_num) {
			if (_p_point[c].x > i) {
				break;
			}
			c++;
		}

		//末端
		if (c == _point_num) {
			x1 = _p_point[c - 1].x;
			y1 = _p_point[c - 1].y;
			x2 = _point_reso;
			y2 = _p_point[0].y;
		} else {
			if (c) {
				x1 = _p_point[c - 1].x;
				y1 = _p_point[c - 1].y;
				x2 = _p_point[c].x;
				y2 = _p_point[c].y;
			} else {
				x1 = _p_point[0].x;
				y1 = _p_point[0].y;
				x2 = _p_point[0].x;
				y2 = _p_point[0].y;
			}
		}

		w = x2 - x1;
		i = i - x1;
		h = y2 - y1;

		if (i) {
			work = cast(double) y1 + cast(double) h * cast(double) i / cast(double) w;
		} else {
			work = y1;
		}

		return work * _volume / 128 / 128;

	}
}
