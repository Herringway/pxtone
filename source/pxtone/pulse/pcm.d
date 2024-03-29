﻿module pxtone.pulse.pcm;

import pxtone.pxtn;

import pxtone.error;
import pxtone.descriptor;

struct WAVEFORMATCHUNK {
	ushort formatID; // PCM:0x0001
	ushort ch; //
	uint sps; //
	uint byte_per_sec; // byte per sec.
	ushort block_size; //
	ushort bps; // bit per sample.
	ushort ext; // no use for pcm.
}

struct pxtnPulse_PCM {
private:
	int _ch;
	int _sps;
	int _bps;
	int _smp_head; // no use. 0
	int _smp_body;
	int _smp_tail; // no use. 0
	ubyte[] _p_smp;

	// stereo / mono
	bool _Convert_ChannelNum(int new_ch) nothrow @system {
		ubyte[] p_work = null;
		int sample_size;
		int work_size;
		int a, b;
		int temp1;
		int temp2;

		sample_size = (_smp_head + _smp_body + _smp_tail) * _ch * _bps / 8;

		if (_p_smp == null) {
			return false;
		}
		if (_ch == new_ch) {
			return true;
		}

		// mono to stereo --------
		if (new_ch == 2) {
			work_size = sample_size * 2;
			p_work = new ubyte[](work_size);
			if (!p_work) {
				return false;
			}

			switch (_bps) {
			case 8:
				b = 0;
				for (a = 0; a < sample_size; a++) {
					p_work[b] = _p_smp[a];
					p_work[b + 1] = _p_smp[a];
					b += 2;
				}
				break;
			case 16:
				b = 0;
				for (a = 0; a < sample_size; a += 2) {
					p_work[b] = _p_smp[a];
					p_work[b + 1] = _p_smp[a + 1];
					p_work[b + 2] = _p_smp[a];
					p_work[b + 3] = _p_smp[a + 1];
					b += 4;
				}
				break;
			default:
				break;
			}

		}  // stereo to mono --------
		else {
			work_size = sample_size / 2;
			p_work = new ubyte[](work_size);
			if (!p_work) {
				return false;
			}

			switch (_bps) {
			case 8:
				b = 0;
				for (a = 0; a < sample_size; a += 2) {
					temp1 = cast(int) _p_smp[a] + cast(int) _p_smp[a + 1];
					p_work[b] = cast(ubyte)(temp1 / 2);
					b++;
				}
				break;
			case 16:
				b = 0;
				for (a = 0; a < sample_size; a += 4) {
					temp1 = *(cast(short*)(&_p_smp[a]));
					temp2 = *(cast(short*)(&_p_smp[a + 2]));
					*cast(short*)(&p_work[b]) = cast(short)((temp1 + temp2) / 2);
					b += 2;
				}
				break;
			default:
				break;
			}
		}

		// release once.
		_p_smp = null;

		_p_smp = new ubyte[](work_size);
		if (!(_p_smp)) {
			return false;
		}
		_p_smp[0 .. work_size] = p_work[0 .. work_size];

		// update param.
		_ch = new_ch;

		return true;
	}

	// change bps
	bool _Convert_BitPerSample(int new_bps) nothrow @system {
		ubyte[] p_work;
		int sample_size;
		int work_size;
		int a, b;
		int temp1;

		if (!_p_smp) {
			return false;
		}
		if (_bps == new_bps) {
			return true;
		}

		sample_size = (_smp_head + _smp_body + _smp_tail) * _ch * _bps / 8;

		switch (new_bps) {
			// 16 to 8 --------
		case 8:
			work_size = sample_size / 2;
			p_work = new ubyte[](work_size);
			if (!p_work) {
				return false;
			}
			b = 0;
			for (a = 0; a < sample_size; a += 2) {
				temp1 = *(cast(short*)(&_p_smp[a]));
				temp1 = (temp1 / 0x100) + 128;
				p_work[b] = cast(ubyte) temp1;
				b++;
			}
			break;
			//  8 to 16 --------
		case 16:
			work_size = sample_size * 2;
			p_work = new ubyte[](work_size);
			if (!p_work) {
				return false;
			}
			b = 0;
			for (a = 0; a < sample_size; a++) {
				temp1 = _p_smp[a];
				temp1 = (temp1 - 128) * 0x100;
				*(cast(short*)(&p_work[b])) = cast(short) temp1;
				b += 2;
			}
			break;

		default:
			return false;
		}

		// release once.
		_p_smp = null;

		_p_smp = new ubyte[](work_size);
		if (!(_p_smp)) {
			return false;
		}
		_p_smp[0 .. work_size] = p_work[0 .. work_size];

		// update param.
		_bps = new_bps;

		return true;
	}
	// sps
	bool _Convert_SamplePerSecond(int new_sps) nothrow @system {
		bool b_ret = false;
		int sample_num;
		int work_size;

		int head_size, body_size, tail_size;

		ubyte[] p1byte_data;
		ushort[] p2byte_data;
		uint[] p4byte_data;

		ubyte[] p1byte_work = null;
		ushort[] p2byte_work = null;
		uint[] p4byte_work = null;

		int a, b;

		if (!_p_smp) {
			return false;
		}
		if (_sps == new_sps) {
			return true;
		}

		head_size = _smp_head * _ch * _bps / 8;
		body_size = _smp_body * _ch * _bps / 8;
		tail_size = _smp_tail * _ch * _bps / 8;

		head_size = cast(int)((cast(double) head_size * cast(double) new_sps + cast(double)(_sps) - 1) / _sps);
		body_size = cast(int)((cast(double) body_size * cast(double) new_sps + cast(double)(_sps) - 1) / _sps);
		tail_size = cast(int)((cast(double) tail_size * cast(double) new_sps + cast(double)(_sps) - 1) / _sps);

		work_size = head_size + body_size + tail_size;

		// stereo 16bit ========
		if (_ch == 2 && _bps == 16) {
			_smp_head = head_size / 4;
			_smp_body = body_size / 4;
			_smp_tail = tail_size / 4;
			sample_num = work_size / 4;
			work_size = sample_num * 4;
			p4byte_data = cast(uint[]) _p_smp;
			p4byte_work = new uint[](work_size / uint.sizeof);
			if (!p4byte_work) {
				goto End;
			}
			for (a = 0; a < sample_num; a++) {
				b = cast(int)(cast(double) a * cast(double)(_sps) / cast(double) new_sps);
				p4byte_work[a] = p4byte_data[b];
			}
		}  // mono 8bit ========
		else if (_ch == 1 && _bps == 8) {
			_smp_head = head_size / 1;
			_smp_body = body_size / 1;
			_smp_tail = tail_size / 1;
			sample_num = work_size / 1;
			work_size = sample_num * 1;
			p1byte_data = cast(ubyte[]) _p_smp;
			p1byte_work = new ubyte[](work_size);
			if (!p1byte_work) {
				goto End;
			}
			for (a = 0; a < sample_num; a++) {
				b = cast(int)(cast(double) a * cast(double)(_sps) / cast(double)(new_sps));
				p1byte_work[a] = p1byte_data[b];
			}
		} else // mono 16bit / stereo 8bit ========
		{
			_smp_head = head_size / 2;
			_smp_body = body_size / 2;
			_smp_tail = tail_size / 2;
			sample_num = work_size / 2;
			work_size = sample_num * 2;
			p2byte_data = cast(ushort[]) _p_smp;
			p2byte_work = new ushort[](work_size / ushort.sizeof);
			if (!p2byte_work) {
				goto End;
			}
			for (a = 0; a < sample_num; a++) {
				b = cast(int)(cast(double) a * cast(double)(_sps) / cast(double) new_sps);
				p2byte_work[a] = p2byte_data[b];
			}
		}

		// release once.
		_p_smp = new ubyte[](work_size);
		if (!_p_smp) {
			goto End;
		}

		if (p4byte_work) {
			_p_smp[0 .. work_size] = (cast(ubyte*)p4byte_work)[0 .. work_size];
		} else if (p2byte_work) {
			_p_smp[0 .. work_size] = (cast(ubyte*)p2byte_work)[0 .. work_size];
		} else if (p1byte_work) {
			_p_smp[0 .. work_size] = p1byte_work[0 .. work_size];
		} else {
			goto End;
		}

		// update.
		_sps = new_sps;

		b_ret = true;
	End:

		if (!b_ret) {
			_smp_head = 0;
			_smp_body = 0;
			_smp_tail = 0;
		}

		return b_ret;
	}

public:
	 ~this() nothrow @system {
		Release();
	}

	void Create(int ch, int sps, int bps, int sample_num) @system {
		Release();

		if (bps != 8 && bps != 16) {
			throw new PxtoneException("pcm unknown");
		}

		int size = 0;

		_p_smp = null;
		_ch = ch;
		_sps = sps;
		_bps = bps;
		_smp_head = 0;
		_smp_body = sample_num;
		_smp_tail = 0;

		// bit / sample is 8 or 16
		size = _smp_body * _bps * _ch / 8;

		_p_smp = new ubyte[](size);

		if (_bps == 8) {
			_p_smp[0 .. size] = 128;
		} else {
			_p_smp[0 .. size] = 0;
		}
	}

	void Release() nothrow @system {
		_p_smp = null;
		_ch = 0;
		_sps = 0;
		_bps = 0;
		_smp_head = 0;
		_smp_body = 0;
		_smp_tail = 0;
	}

	void read(ref pxtnDescriptor doc) @system {
		char[16] buf = 0;
		uint size = 0;
		WAVEFORMATCHUNK format;

		_p_smp = null;
		scope(failure) {
			_p_smp = null;
		}

		// 'RIFFxxxxWAVEfmt '
		doc.r(buf[]);

		if (buf[0] != 'R' || buf[1] != 'I' || buf[2] != 'F' || buf[3] != 'F' || buf[8] != 'W' || buf[9] != 'A' || buf[10] != 'V' || buf[11] != 'E' || buf[12] != 'f' || buf[13] != 'm' || buf[14] != 't' || buf[15] != ' ') {
			throw new PxtoneException("pcm unknown");
		}

		// read format.
		doc.r(size);
		doc.r(format);

		if (format.formatID != 0x0001) {
			throw new PxtoneException("pcm unknown");
		}
		if (format.ch != 1 && format.ch != 2) {
			throw new PxtoneException("pcm unknown");
		}
		if (format.bps != 8 && format.bps != 16) {
			throw new PxtoneException("pcm unknown");
		}

		// find 'data'
		doc.seek(pxtnSEEK.set, 12);
	 	// skip 'RIFFxxxxWAVE'

		while (1) {
			doc.r(buf[0 .. 4]);
			doc.r(size);
			if (buf[0] == 'd' && buf[1] == 'a' && buf[2] == 't' && buf[3] == 'a') {
				break;
			}
			doc.seek(pxtnSEEK.cur, size);
		}

		Create(format.ch, format.sps, format.bps, size * 8 / format.bps / format.ch);

		doc.r(_p_smp[0 .. size]);
	}

	void write(ref pxtnDescriptor doc, const char[] pstrLIST) const @system {
		if (!_p_smp) {
			throw new PxtoneException("_p_smp");
		}

		WAVEFORMATCHUNK format;
		uint riff_size;
		uint fact_size; // num sample.
		uint list_size; // num list text.
		uint isft_size;
		uint sample_size;

		bool bText;

		char[4] tag_RIFF = ['R', 'I', 'F', 'F'];
		char[4] tag_WAVE = ['W', 'A', 'V', 'E'];
		char[8] tag_fmt_ = ['f', 'm', 't', ' ', 0x12, 0, 0, 0];
		char[8] tag_fact = ['f', 'a', 'c', 't', 0x04, 0, 0, 0];
		char[4] tag_data = ['d', 'a', 't', 'a'];
		char[4] tag_LIST = ['L', 'I', 'S', 'T'];
		char[8] tag_INFO = ['I', 'N', 'F', 'O', 'I', 'S', 'F', 'T'];

		if (pstrLIST && pstrLIST.length) {
			bText = true;
		} else {
			bText = false;
		}

		sample_size = (_smp_head + _smp_body + _smp_tail) * _ch * _bps / 8;

		format.formatID = 0x0001; // PCM
		format.ch = cast(ushort) _ch;
		format.sps = cast(uint) _sps;
		format.bps = cast(ushort) _bps;
		format.byte_per_sec = cast(uint)(_sps * _bps * _ch / 8);
		format.block_size = cast(ushort)(_bps * _ch / 8);
		format.ext = 0;

		fact_size = (_smp_head + _smp_body + _smp_tail);
		riff_size = sample_size;
		riff_size += 4; // 'WAVE'
		riff_size += 26; // 'fmt '
		riff_size += 12; // 'fact'
		riff_size += 8; // 'data'

		if (bText) {
			isft_size = cast(uint) pstrLIST.length;
			list_size = 4 + 4 + 4 + isft_size; // "INFO" + "ISFT" + size + ver_Text;
			riff_size += 8 + list_size; // 'LIST'
		} else {
			isft_size = 0;
			list_size = 0;
		}

		// open file..

		doc.w_asfile(tag_RIFF);
		doc.w_asfile(riff_size);
		doc.w_asfile(tag_WAVE);
		doc.w_asfile(tag_fmt_);
		doc.w_asfile(format);

		if (bText) {
			doc.w_asfile(tag_LIST);
			doc.w_asfile(list_size);
			doc.w_asfile(tag_INFO);
			doc.w_asfile(isft_size);
			doc.w_asfile(pstrLIST);
		}

		doc.w_asfile(tag_fact);
		doc.w_asfile(fact_size);
		doc.w_asfile(tag_data);
		doc.w_asfile(sample_size);
		doc.w_asfile(_p_smp);
	}

	// convert..
	void Convert(int new_ch, int new_sps, int new_bps) @system {
		if (!_Convert_ChannelNum(new_ch)) {
			throw new PxtoneException("_Convert_ChannelNum");
		}
		if (!_Convert_BitPerSample(new_bps)) {
			throw new PxtoneException("_Convert_BitPerSample");
		}
		if (!_Convert_SamplePerSecond(new_sps)) {
			throw new PxtoneException("_Convert_SamplePerSecond");
		}
	}

	bool Convert_Volume(float v) nothrow @safe {
		if (!_p_smp) {
			return false;
		}

		int sample_num = (_smp_head + _smp_body + _smp_tail) * _ch;

		switch (_bps) {
		case 8: {
				ubyte[] p8 = _p_smp;
				for (int i = 0; i < sample_num; i++) {
					p8[0] = cast(ubyte)(((cast(float)(p8[0]) - 128) * v) + 128);
					p8 = p8[1 .. $];
				}
				break;
			}
		case 16: {
				short[] p16 = cast(short[]) _p_smp;
				for (int i = 0; i < sample_num; i++) {
					p16[0] = cast(short)(cast(float)p16[0] * v);
					p16 = p16[1 .. $];
				}
				break;
			}
		default:
			return false;
		}
		return true;
	}

	void Copy(ref pxtnPulse_PCM p_dst) const @system {
		if (!_p_smp) {
			p_dst.Release();
			return;
		}
		p_dst.Create(_ch, _sps, _bps, _smp_body);
		const size = (_smp_head + _smp_body + _smp_tail) * _ch * _bps / 8;
		p_dst._p_smp[0 .. size] =_p_smp[0 .. size];
	}

	bool Copy_(ref pxtnPulse_PCM p_dst, int start, int end) const @system {
		int size, offset;

		if (_smp_head || _smp_tail) {
			return false;
		}
		if (!_p_smp) {
			p_dst.Release();
			return true;
		}

		size = (end - start) * _ch * _bps / 8;
		offset = start * _ch * _bps / 8;

		p_dst.Create(_ch, _sps, _bps, end - start);

		p_dst._p_smp[0 .. size] = _p_smp[offset .. offset + size];

		return true;
	}

	void[] Devolve_SamplingBuffer() nothrow @safe {
		void[] p = _p_smp;
		_p_smp = null;
		return p;
	}

	float get_sec() const nothrow @safe {
		return cast(float)(_smp_body + _smp_head + _smp_tail) / cast(float) _sps;
	}

	int get_ch() const nothrow @safe {
		return _ch;
	}

	int get_bps() const nothrow @safe {
		return _bps;
	}

	int get_sps() const nothrow @safe {
		return _sps;
	}

	int get_smp_body() const nothrow @safe {
		return _smp_body;
	}

	int get_smp_head() const nothrow @safe {
		return _smp_head;
	}

	int get_smp_tail() const nothrow @safe {
		return _smp_tail;
	}

	int get_buf_size() const nothrow @safe {
		return (_smp_head + _smp_body + _smp_tail) * _ch * _bps / 8;
	}

	inout(ubyte)[] get_p_buf() inout nothrow @safe {
		return _p_smp;
	}
}
