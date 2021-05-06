module pxtone.woice;
// '12/03/03 pxtnWoice.

import pxtone.pxtn;

import pxtone.descriptor;
import pxtone.error;
import pxtone.evelist;
import pxtone.mem;
import pxtone.pulse.noise;
import pxtone.pulse.noisebuilder;
import pxtone.pulse.oscillator;
import pxtone.pulse.pcm;
import pxtone.pulse.oggv;
import pxtone.woiceptv;

enum pxtnMAX_TUNEWOICENAME = 16; // fixture.

enum pxtnMAX_UNITCONTROLVOICE = 2; // max-woice per unit

enum pxtnBUFSIZE_TIMEPAN = 0x40;
enum pxtnBITPERSAMPLE = 16;

enum PTV_VOICEFLAG_WAVELOOP = 0x00000001;
enum PTV_VOICEFLAG_SMOOTH = 0x00000002;
enum PTV_VOICEFLAG_BEATFIT = 0x00000004;
enum PTV_VOICEFLAG_UNCOVERED = 0xfffffff8;

enum PTV_DATAFLAG_WAVE = 0x00000001;
enum PTV_DATAFLAG_ENVELOPE = 0x00000002;
enum PTV_DATAFLAG_UNCOVERED = 0xfffffffc;

immutable _code = "PTVOICE-";

enum pxtnWOICETYPE {
	None = 0,
	PCM,
	PTV,
	PTN,
	OGGV,
}

enum pxtnVOICETYPE {
	Coodinate = 0,
	Overtone,
	Noise,
	Sampling,
	OggVorbis,
}

struct pxtnVOICEINSTANCE {
	int smp_head_w;
	int smp_body_w;
	int smp_tail_w;
	ubyte[] p_smp_w;

	ubyte[] p_env;
	int env_size;
	int env_release;
}

struct pxtnVOICEENVELOPE {
	int fps;
	int head_num;
	int body_num;
	int tail_num;
	pxtnPOINT[] points;
}

struct pxtnVOICEWAVE {
	int num;
	int reso; // COODINATERESOLUTION
	pxtnPOINT[] points;
}

struct pxtnVOICEUNIT {
	int basic_key;
	int volume;
	int pan;
	float tuning;
	uint voice_flags;
	uint data_flags;

	pxtnVOICETYPE type;
	pxtnPulse_PCM* p_pcm;
	pxtnPulse_Noise* p_ptn;
	version (pxINCLUDE_OGGVORBIS) {
		pxtnPulse_Oggv* p_oggv;
	}

	pxtnVOICEWAVE wave;
	pxtnVOICEENVELOPE envelope;
}

struct pxtnVOICETONE {
	double smp_pos;
	float offset_freq;
	int env_volume;
	int life_count;
	int on_count;

	int smp_count;
	int env_start;
	int env_pos;
	int env_release_clock;

	int smooth_volume;
}

private void _Voice_Release(pxtnVOICEUNIT* p_vc, pxtnVOICEINSTANCE* p_vi) nothrow @system {
	if (p_vc) {
		deallocate(p_vc.p_pcm);
		deallocate(p_vc.p_ptn);
		version (pxINCLUDE_OGGVORBIS) {
			deallocate(p_vc.p_oggv);
		}
		deallocate(p_vc.envelope.points);
		p_vc.envelope = pxtnVOICEENVELOPE.init;
		deallocate(p_vc.wave.points);
		p_vc.wave = pxtnVOICEWAVE.init;
	}
	if (p_vi) {
		deallocate(p_vi.p_env);
		deallocate(p_vi.p_smp_w);
		*p_vi = pxtnVOICEINSTANCE.init;
	}
}

void _UpdateWavePTV(pxtnVOICEUNIT* p_vc, pxtnVOICEINSTANCE* p_vi, int ch, int sps, int bps) nothrow @system {
	double work, osc;
	int long_;
	int[2] pan_volume = [64, 64];
	bool b_ovt;

	pxtnPulse_Oscillator osci;

	if (ch == 2) {
		if (p_vc.pan > 64) {
			pan_volume[0] = (128 - p_vc.pan);
		}
		if (p_vc.pan < 64) {
			pan_volume[1] = (p_vc.pan);
		}
	}

	osci.ReadyGetSample(p_vc.wave.points, p_vc.wave.num, p_vc.volume, p_vi.smp_body_w, p_vc.wave.reso);

	if (p_vc.type == pxtnVOICETYPE.Overtone) {
		b_ovt = true;
	} else {
		b_ovt = false;
	}

	//  8bit
	if (bps == 8) {
		ubyte* p = cast(ubyte*) p_vi.p_smp_w;
		for (int s = 0; s < p_vi.smp_body_w; s++) {
			if (b_ovt) {
				osc = osci.GetOneSample_Overtone(s);
			} else {
				osc = osci.GetOneSample_Coodinate(s);
			}
			for (int c = 0; c < ch; c++) {
				work = osc * pan_volume[c] / 64;
				if (work > 1.0) {
					work = 1.0;
				}
				if (work < -1.0) {
					work = -1.0;
				}
				long_ = cast(int)(work * 127);
				p[s * ch + c] = cast(ubyte)(long_ + 128);
			}
		}

		// 16bit
	} else {
		short* p = cast(short*) p_vi.p_smp_w;
		for (int s = 0; s < p_vi.smp_body_w; s++) {
			if (b_ovt) {
				osc = osci.GetOneSample_Overtone(s);
			} else {
				osc = osci.GetOneSample_Coodinate(s);
			}
			for (int c = 0; c < ch; c++) {
				work = osc * pan_volume[c] / 64;
				if (work > 1.0) {
					work = 1.0;
				}
				if (work < -1.0) {
					work = -1.0;
				}
				long_ = cast(int)(work * 32767);
				p[s * ch + c] = cast(short) long_;
			}
		}
	}
}

// 24byte =================
struct _MATERIALSTRUCT_PCM {
	ushort x3x_unit_no;
	ushort basic_key;
	uint voice_flags;
	ushort ch;
	ushort bps;
	uint sps;
	float tuning = 0.0;
	uint data_size;
}

/////////////
// matePTN
/////////////

// 16byte =================
struct _MATERIALSTRUCT_PTN {
	ushort x3x_unit_no;
	ushort basic_key;
	uint voice_flags;
	float tuning = 0.0;
	int rrr; // 0: -v.0.9.2.3
	// 1:  v.0.9.2.4-
}

/////////////////
// matePTV
/////////////////

// 24byte =================
struct _MATERIALSTRUCT_PTV {
	ushort x3x_unit_no;
	ushort rrr;
	float x3x_tuning = 0.0;
	int size;
}

//////////////////////
// mateOGGV
//////////////////////

// 16byte =================
struct _MATERIALSTRUCT_OGGV {
	ushort xxx; //ch;
	ushort basic_key;
	uint voice_flags;
	float tuning = 0.0;
}

////////////////////////
// publics..
////////////////////////

struct pxtnWoice {
private:
	int _voice_num;

	char[pxtnMAX_TUNEWOICENAME + 1] _name_buf;
	uint _name_size;

	pxtnWOICETYPE _type = pxtnWOICETYPE.None;
	pxtnVOICEUNIT[] _voices;
	pxtnVOICEINSTANCE[] _voinsts;

	float _x3x_tuning;
	int _x3x_basic_key; // tuning old-fmt when key-event

public:

	 ~this() nothrow @system {
		Voice_Release();
	}

	int get_voice_num() const nothrow @safe {
		return _voice_num;
	}

	float get_x3x_tuning() const nothrow @safe {
		return _x3x_tuning;
	}

	int get_x3x_basic_key() const nothrow @safe {
		return _x3x_basic_key;
	}

	pxtnWOICETYPE get_type() const nothrow @safe {
		return _type;
	}

	inout(pxtnVOICEUNIT)* get_voice(int idx) inout nothrow @safe {
		if (idx < 0 || idx >= _voice_num) {
			return null;
		}
		return &_voices[idx];
	}

	const(pxtnVOICEINSTANCE)* get_instance(int idx) const nothrow @safe {
		if (idx < 0 || idx >= _voice_num) {
			return null;
		}
		return &_voinsts[idx];
	}

	bool set_name_buf(const(char)[] name) nothrow @safe {
		if (!name || name.length < 0 || name.length > pxtnMAX_TUNEWOICENAME) {
			return false;
		}
		_name_buf[] = 0;
		_name_size = cast(uint)name.length;
		if (name.length) {
			_name_buf[0 .. name.length] = name;
		}
		return true;
	}

	const(char)[] get_name_buf() const return nothrow @safe {
		return _name_buf[0 .. _name_size];
	}

	bool is_name_buf() const nothrow @safe {
		if (_name_size > 0) {
			return true;
		}
		return false;
	}

	bool Voice_Allocate(int voice_num) nothrow @system {
		bool b_ret = false;

		Voice_Release();

		_voices = allocate!pxtnVOICEUNIT(voice_num);
		if (!_voices) {
			goto End;
		}
		_voinsts = allocate!pxtnVOICEINSTANCE(voice_num);
		if (!_voinsts) {
			goto End;
		}
		_voice_num = voice_num;

		for (int i = 0; i < voice_num; i++) {
			pxtnVOICEUNIT* p_vc = &_voices[i];
			p_vc.basic_key = EVENTDEFAULT_BASICKEY;
			p_vc.volume = 128;
			p_vc.pan = 64;
			p_vc.tuning = 1.0f;
			p_vc.voice_flags = PTV_VOICEFLAG_SMOOTH;
			p_vc.data_flags = PTV_DATAFLAG_WAVE;
			p_vc.p_pcm = allocate!pxtnPulse_PCM();
			p_vc.p_ptn = allocate!pxtnPulse_Noise();
			version (pxINCLUDE_OGGVORBIS) {
				p_vc.p_oggv = allocate!pxtnPulse_Oggv();
			}
			p_vc.envelope = pxtnVOICEENVELOPE.init;
		}

		b_ret = true;
	End:

		if (!b_ret) {
			Voice_Release();
		}

		return b_ret;
	}

	void Voice_Release() nothrow @system {
		for (int v = 0; v < _voice_num; v++) {
			_Voice_Release(&_voices[v], &_voinsts[v]);
		}
		deallocate(_voices);
		deallocate(_voinsts);
		_voice_num = 0;
	}

	bool Copy(pxtnWoice* p_dst) const nothrow @system {
		bool b_ret = false;
		int v, num;
		size_t size;
		const(pxtnVOICEUNIT)* p_vc1 = null;
		pxtnVOICEUNIT* p_vc2 = null;

		if (!p_dst.Voice_Allocate(_voice_num)) {
			goto End;
		}

		p_dst._type = _type;

		p_dst._name_buf = _name_buf;

		for (v = 0; v < _voice_num; v++) {
			p_vc1 = &_voices[v];
			p_vc2 = &p_dst._voices[v];

			p_vc2.tuning = p_vc1.tuning;
			p_vc2.data_flags = p_vc1.data_flags;
			p_vc2.basic_key = p_vc1.basic_key;
			p_vc2.pan = p_vc1.pan;
			p_vc2.type = p_vc1.type;
			p_vc2.voice_flags = p_vc1.voice_flags;
			p_vc2.volume = p_vc1.volume;

			// envelope
			p_vc2.envelope.body_num = p_vc1.envelope.body_num;
			p_vc2.envelope.fps = p_vc1.envelope.fps;
			p_vc2.envelope.head_num = p_vc1.envelope.head_num;
			p_vc2.envelope.tail_num = p_vc1.envelope.tail_num;
			num = p_vc2.envelope.head_num + p_vc2.envelope.body_num + p_vc2.envelope.tail_num;
			size = pxtnPOINT.sizeof * num;
			p_vc2.envelope.points = allocate!pxtnPOINT(size / pxtnPOINT.sizeof);
			if (!p_vc2.envelope.points) {
				goto End;
			}
			p_vc2.envelope.points[0 .. size] = p_vc1.envelope.points[0 .. size];

			// wave
			p_vc2.wave.num = p_vc1.wave.num;
			p_vc2.wave.reso = p_vc1.wave.reso;
			size = pxtnPOINT.sizeof * p_vc2.wave.num;
			p_vc2.wave.points = allocate!pxtnPOINT(size / pxtnPOINT.sizeof);
			if (!p_vc2.wave.points) {
				goto End;
			}
			p_vc2.wave.points[0 .. size] = p_vc1.wave.points[0 .. size];

			if (p_vc1.p_pcm.Copy(p_vc2.p_pcm) != pxtnERR.OK) {
				goto End;
			}
			if (!p_vc1.p_ptn.Copy(p_vc2.p_ptn)) {
				goto End;
			}
			version (pxINCLUDE_OGGVORBIS) {
				if (!p_vc1.p_oggv.Copy(p_vc2.p_oggv)) {
					goto End;
				}
			}
		}

		b_ret = true;
	End:
		if (!b_ret) {
			p_dst.Voice_Release();
		}

		return b_ret;
	}

	void Slim() nothrow @system {
		for (int i = _voice_num - 1; i >= 0; i--) {
			bool b_remove = false;

			if (!_voices[i].volume) {
				b_remove = true;
			}

			if (_voices[i].type == pxtnVOICETYPE.Coodinate && _voices[i].wave.num <= 1) {
				b_remove = true;
			}

			if (b_remove) {
				_Voice_Release(&_voices[i], &_voinsts[i]);
				_voice_num--;
				for (int j = i; j < _voice_num; j++) {
					_voices[j] = _voices[j + 1];
				}
				_voices[_voice_num] = pxtnVOICEUNIT.init;
			}
		}
	}

	pxtnERR read(ref pxtnDescriptor desc, pxtnWOICETYPE type) nothrow @system {
		pxtnERR res = pxtnERR.VOID;

		switch (type) {
			// PCM
		case pxtnWOICETYPE.PCM: {
				pxtnVOICEUNIT* p_vc;
				if (!Voice_Allocate(1)) {
					goto term;
				}
				p_vc = &_voices[0];
				p_vc.type = pxtnVOICETYPE.Sampling;
				res = p_vc.p_pcm.read(desc);
				if (res != pxtnERR.OK) {
					goto term;
				}
				// if under 0.005 sec, set LOOP.
				if (p_vc.p_pcm.get_sec() < 0.005f) {
					p_vc.voice_flags |= PTV_VOICEFLAG_WAVELOOP;
				} else {
					p_vc.voice_flags &= ~PTV_VOICEFLAG_WAVELOOP;
				}
				_type = pxtnWOICETYPE.PCM;
			}
			break;

			// PTV
		case pxtnWOICETYPE.PTV: {
				res = PTV_Read(desc);
				if (res != pxtnERR.OK) {
					goto term;
				}
			}
			break;

			// PTN
		case pxtnWOICETYPE.PTN:
			if (!Voice_Allocate(1)) {
				res = pxtnERR.memory;
				goto term;
			}
			{
				pxtnVOICEUNIT* p_vc = &_voices[0];
				p_vc.type = pxtnVOICETYPE.Noise;
				res = p_vc.p_ptn.read(desc);
				if (res != pxtnERR.OK) {
					goto term;
				}
				_type = pxtnWOICETYPE.PTN;
			}
			break;

			// OGGV
		case pxtnWOICETYPE.OGGV:
			version (pxINCLUDE_OGGVORBIS) {
				if (!Voice_Allocate(1)) {
					res = pxtnERR.memory;
					goto term;
				}
				{
					pxtnVOICEUNIT* p_vc;
					p_vc = &_voices[0];
					p_vc.type = pxtnVOICETYPE.OggVorbis;
					res = p_vc.p_oggv.ogg_read(desc);
					if (res != pxtnERR.OK) {
						goto term;
					}
					_type = pxtnWOICETYPE.OGGV;
				}
				break;
			} else {
				res = pxtnERR.ogg_no_supported;
				goto term;
			}

		default:
			goto term;
		}

		res = pxtnERR.OK;
	term:

		return res;
	}

	bool PTV_Write(ref pxtnDescriptor p_doc, int* p_total) const nothrow @system {
		bool b_ret = false;
		const(pxtnVOICEUNIT)* p_vc = null;
		uint work = 0;
		int v = 0;
		int total = 0;

		if (!p_doc.w_asfile(_code)) {
			goto End;
		}
		if (!p_doc.w_asfile(_version)) {
			goto End;
		}
		if (!p_doc.w_asfile(total)) {
			goto End;
		}

		work = 0;

		// p_ptv. (5)
		if (!p_doc.v_w_asfile(work, total)) {
			goto End; // basic_key (no use)
		}
		if (!p_doc.v_w_asfile(work, total)) {
			goto End;
		}
		if (!p_doc.v_w_asfile(work, total)) {
			goto End;
		}
		if (!p_doc.v_w_asfile(_voice_num, total)) {
			goto End;
		}

		for (v = 0; v < _voice_num; v++) {
			// p_ptvv. (9)
			p_vc = &_voices[v];
			if (!p_vc) {
				goto End;
			}

			if (!p_doc.v_w_asfile(p_vc.basic_key, total)) {
				goto End;
			}
			if (!p_doc.v_w_asfile(p_vc.volume, total)) {
				goto End;
			}
			if (!p_doc.v_w_asfile(p_vc.pan, total)) {
				goto End;
			}
			work = *(cast(uint*)&p_vc.tuning);
			if (!p_doc.v_w_asfile(work, total)) {
				goto End;
			}
			if (!p_doc.v_w_asfile(p_vc.voice_flags, total)) {
				goto End;
			}
			if (!p_doc.v_w_asfile(p_vc.data_flags, total)) {
				goto End;
			}

			if (p_vc.data_flags & PTV_DATAFLAG_WAVE && !_Write_Wave(p_doc, p_vc, total)) {
				goto End;
			}
			if (p_vc.data_flags & PTV_DATAFLAG_ENVELOPE && !_Write_Envelope(p_doc, p_vc, total)) {
				goto End;
			}
		}

		// total size
		if (!p_doc.seek(pxtnSEEK.cur, -(total + 4))) {
			goto End;
		}
		if (!p_doc.w_asfile(total)) {
			goto End;
		}
		if (!p_doc.seek(pxtnSEEK.cur, (total))) {
			goto End;
		}

		if (p_total) {
			*p_total = 16 + total;
		}
		b_ret = true;
	End:

		return b_ret;
	}

	pxtnERR PTV_Read(ref pxtnDescriptor p_doc) nothrow @system {
		pxtnERR res = pxtnERR.VOID;
		pxtnVOICEUNIT* p_vc = null;
		ubyte[8] code = 0;
		int version_ = 0;
		int work1 = 0;
		int work2 = 0;
		int total = 0;
		int num = 0;

		if (!p_doc.r(code[])) {
			res = pxtnERR.desc_r;
			goto term;
		}
		if (!p_doc.r(version_)) {
			res = pxtnERR.desc_r;
			goto term;
		}
		if (code[0 .. 8] != _code) {
			res = pxtnERR.inv_code;
			goto term;
		}
		if (!p_doc.r(total)) {
			res = pxtnERR.desc_r;
			goto term;
		}
		if (version_ > _version) {
			res = pxtnERR.fmt_new;
			goto term;
		}

		// p_ptv. (5)
		if (!p_doc.v_r(&_x3x_basic_key)) {
			res = pxtnERR.desc_r;
			goto term;
		}
		if (!p_doc.v_r(&work1)) {
			res = pxtnERR.desc_r;
			goto term;
		}
		if (!p_doc.v_r(&work2)) {
			res = pxtnERR.desc_r;
			goto term;
		}
		if (work1 || work2) {
			res = pxtnERR.fmt_unknown;
			goto term;
		}
		if (!p_doc.v_r(&num)) {
			res = pxtnERR.desc_r;
			goto term;
		}
		if (!Voice_Allocate(num)) {
			res = pxtnERR.memory;
			goto term;
		}

		for (int v = 0; v < _voice_num; v++) {
			// p_ptvv. (8)
			p_vc = &_voices[v];
			if (!p_vc) {
				res = pxtnERR.FATAL;
				goto term;
			}
			if (!p_doc.v_r(&p_vc.basic_key)) {
				res = pxtnERR.desc_r;
				goto term;
			}
			if (!p_doc.v_r(&p_vc.volume)) {
				res = pxtnERR.desc_r;
				goto term;
			}
			if (!p_doc.v_r(&p_vc.pan)) {
				res = pxtnERR.desc_r;
				goto term;
			}
			if (!p_doc.v_r(&work1)) {
				res = pxtnERR.desc_r;
				goto term;
			}
			p_vc.tuning = *(cast(float*)&work1);
			if (!p_doc.v_r(cast(int*)&p_vc.voice_flags)) {
				res = pxtnERR.desc_r;
				goto term;
			}
			if (!p_doc.v_r(cast(int*)&p_vc.data_flags)) {
				res = pxtnERR.desc_r;
				goto term;
			}

			// no support.
			if (p_vc.voice_flags & PTV_VOICEFLAG_UNCOVERED) {
				res = pxtnERR.fmt_unknown;
				goto term;
			}
			if (p_vc.data_flags & PTV_DATAFLAG_UNCOVERED) {
				res = pxtnERR.fmt_unknown;
				goto term;
			}
			if (p_vc.data_flags & PTV_DATAFLAG_WAVE) {
				res = _Read_Wave(p_doc, p_vc);
				if (res != pxtnERR.OK) {
					goto term;
				}
			}
			if (p_vc.data_flags & PTV_DATAFLAG_ENVELOPE) {
				res = _Read_Envelope(p_doc, p_vc);
				if (res != pxtnERR.OK) {
					goto term;
				}
			}
		}
		_type = pxtnWOICETYPE.PTV;

		res = pxtnERR.OK;
	term:

		return res;
	}

	bool io_matePCM_w(ref pxtnDescriptor p_doc) const nothrow @system {
		const pxtnPulse_PCM* p_pcm = _voices[0].p_pcm;
		const(pxtnVOICEUNIT)* p_vc = &_voices[0];
		_MATERIALSTRUCT_PCM pcm;

		pcm.sps = cast(uint) p_pcm.get_sps();
		pcm.bps = cast(ushort) p_pcm.get_bps();
		pcm.ch = cast(ushort) p_pcm.get_ch();
		pcm.data_size = cast(uint) p_pcm.get_buf_size();
		pcm.x3x_unit_no = cast(ushort) 0;
		pcm.tuning = p_vc.tuning;
		pcm.voice_flags = p_vc.voice_flags;
		pcm.basic_key = cast(ushort) p_vc.basic_key;

		uint size = cast(uint)(_MATERIALSTRUCT_PCM.sizeof + pcm.data_size);
		if (!p_doc.w_asfile(size)) {
			return false;
		}
		if (!p_doc.w_asfile(pcm)) {
			return false;
		}
		if (!p_doc.w_asfile(p_pcm.get_p_buf())) {
			return false;
		}

		return true;
	}

	pxtnERR io_matePCM_r(ref pxtnDescriptor p_doc) nothrow @system {
		pxtnERR res = pxtnERR.VOID;
		_MATERIALSTRUCT_PCM pcm;
		int size = 0;

		if (!p_doc.r(size)) {
			return pxtnERR.desc_r;
		}
		if (!p_doc.r(pcm)) {
			return pxtnERR.desc_r;
		}

		if ((cast(int) pcm.voice_flags) & PTV_VOICEFLAG_UNCOVERED) {
			return pxtnERR.fmt_unknown;
		}

		if (!Voice_Allocate(1)) {
			res = pxtnERR.memory;
			goto term;
		}

		{
			pxtnVOICEUNIT* p_vc = &_voices[0];

			p_vc.type = pxtnVOICETYPE.Sampling;

			res = p_vc.p_pcm.Create(pcm.ch, pcm.sps, pcm.bps, pcm.data_size / (pcm.bps / 8 * pcm.ch));
			if (res != pxtnERR.OK) {
				goto term;
			}
			if (!p_doc.r(p_vc.p_pcm.get_p_buf()[0 .. pcm.data_size])) {
				res = pxtnERR.desc_r;
				goto term;
			}
			_type = pxtnWOICETYPE.PCM;

			p_vc.voice_flags = pcm.voice_flags;
			p_vc.basic_key = pcm.basic_key;
			p_vc.tuning = pcm.tuning;
			_x3x_basic_key = pcm.basic_key;
			_x3x_tuning = 0;
		}
		res = pxtnERR.OK;
	term:

		if (res != pxtnERR.OK) {
			Voice_Release();
		}
		return res;
	}

	bool io_matePTN_w(ref pxtnDescriptor p_doc) const nothrow @system {
		_MATERIALSTRUCT_PTN ptn;
		const(pxtnVOICEUNIT)* p_vc;
		int size = 0;

		// ptv -------------------------
		ptn.x3x_unit_no = cast(ushort) 0;

		p_vc = &_voices[0];
		ptn.tuning = p_vc.tuning;
		ptn.voice_flags = p_vc.voice_flags;
		ptn.basic_key = cast(ushort) p_vc.basic_key;
		ptn.rrr = 1;

		// pre
		if (!p_doc.w_asfile(size)) {
			return false;
		}
		if (!p_doc.w_asfile(ptn)) {
			return false;
		}
		size += _MATERIALSTRUCT_PTN.sizeof;
		if (!p_vc.p_ptn.write(p_doc, &size)) {
			return false;
		}
		if (!p_doc.seek(pxtnSEEK.cur, cast(int)(-size - int.sizeof))) {
			return false;
		}
		if (!p_doc.w_asfile(size)) {
			return false;
		}
		if (!p_doc.seek(pxtnSEEK.cur, size)) {
			return false;
		}

		return true;
	}

	pxtnERR io_matePTN_r(ref pxtnDescriptor p_doc) nothrow @system {
		pxtnERR res = pxtnERR.VOID;
		_MATERIALSTRUCT_PTN ptn;
		int size = 0;

		if (!p_doc.r(size)) {
			return pxtnERR.desc_r;
		}
		if (!p_doc.r(ptn)) {
			return pxtnERR.desc_r;
		}

		if (ptn.rrr > 1) {
			return pxtnERR.fmt_unknown;
		} else if (ptn.rrr < 0) {
			return pxtnERR.fmt_unknown;
		}

		if (!Voice_Allocate(1)) {
			return pxtnERR.memory;
		}

		{
			pxtnVOICEUNIT* p_vc = &_voices[0];

			p_vc.type = pxtnVOICETYPE.Noise;
			res = p_vc.p_ptn.read(p_doc);
			if (res != pxtnERR.OK) {
				goto term;
			}
			_type = pxtnWOICETYPE.PTN;
			p_vc.voice_flags = ptn.voice_flags;
			p_vc.basic_key = ptn.basic_key;
			p_vc.tuning = ptn.tuning;
		}

		_x3x_basic_key = ptn.basic_key;
		_x3x_tuning = 0;

		res = pxtnERR.OK;
	term:
		if (res != pxtnERR.OK) {
			Voice_Release();
		}
		return res;
	}

	bool io_matePTV_w(ref pxtnDescriptor p_doc) const nothrow @system {
		_MATERIALSTRUCT_PTV ptv;
		int head_size = _MATERIALSTRUCT_PTV.sizeof + int.sizeof;
		int size = 0;

		// ptv -------------------------
		ptv.x3x_unit_no = cast(ushort) 0;
		ptv.x3x_tuning = 0; //1.0f;//p_w.tuning;
		ptv.size = 0;

		// pre write
		if (!p_doc.w_asfile(size)) {
			return false;
		}
		if (!p_doc.w_asfile(ptv)) {
			return false;
		}
		if (!PTV_Write(p_doc, &ptv.size)) {
			return false;
		}

		if (!p_doc.seek(pxtnSEEK.cur, -(ptv.size + head_size))) {
			return false;
		}

		size = cast(int)(ptv.size + _MATERIALSTRUCT_PTV.sizeof);
		if (!p_doc.w_asfile(size)) {
			return false;
		}
		if (!p_doc.w_asfile(ptv)) {
			return false;
		}

		if (!p_doc.seek(pxtnSEEK.cur, ptv.size)) {
			return false;
		}

		return true;
	}

	pxtnERR io_matePTV_r(ref pxtnDescriptor p_doc) nothrow @system {
		pxtnERR res = pxtnERR.VOID;
		_MATERIALSTRUCT_PTV ptv;
		int size = 0;

		if (!p_doc.r(size)) {
			return pxtnERR.desc_r;
		}
		if (!p_doc.r(ptv)) {
			return pxtnERR.desc_r;
		}
		if (ptv.rrr) {
			return pxtnERR.fmt_unknown;
		}
		res = PTV_Read(p_doc);
		if (res != pxtnERR.OK) {
			goto term;
		}

		if (ptv.x3x_tuning != 1.0) {
			_x3x_tuning = ptv.x3x_tuning;
		} else {
			_x3x_tuning = 0;
		}

		res = pxtnERR.OK;
	term:

		return res;
	}

	version (pxINCLUDE_OGGVORBIS) {
		bool io_mateOGGV_w(ref pxtnDescriptor p_doc) const nothrow @system {
			if (!_voices) {
				return false;
			}

			_MATERIALSTRUCT_OGGV mate;
			const(pxtnVOICEUNIT)* p_vc = &_voices[0];

			if (!p_vc.p_oggv) {
				return false;
			}

			int oggv_size = p_vc.p_oggv.GetSize();

			mate.tuning = p_vc.tuning;
			mate.voice_flags = p_vc.voice_flags;
			mate.basic_key = cast(ushort) p_vc.basic_key;

			uint size = cast(uint)(_MATERIALSTRUCT_OGGV.sizeof + oggv_size);
			if (!p_doc.w_asfile(size)) {
				return false;
			}
			if (!p_doc.w_asfile(mate)) {
				return false;
			}
			if (!p_vc.p_oggv.pxtn_write(p_doc)) {
				return false;
			}

			return true;
		}

		pxtnERR io_mateOGGV_r(ref pxtnDescriptor p_doc) nothrow @system {
			pxtnERR res = pxtnERR.VOID;
			_MATERIALSTRUCT_OGGV mate;
			int size = 0;

			if (!p_doc.r(size)) {
				return pxtnERR.desc_r;
			}
			if (!p_doc.r(mate)) {
				return pxtnERR.desc_r;
			}

			if ((cast(int) mate.voice_flags) & PTV_VOICEFLAG_UNCOVERED) {
				return pxtnERR.fmt_unknown;
			}

			if (!Voice_Allocate(1)) {
				goto End;
			}

			{
				pxtnVOICEUNIT* p_vc = &_voices[0];
				p_vc.type = pxtnVOICETYPE.OggVorbis;

				if (!p_vc.p_oggv.pxtn_read(p_doc)) {
					goto End;
				}

				p_vc.voice_flags = mate.voice_flags;
				p_vc.basic_key = mate.basic_key;
				p_vc.tuning = mate.tuning;
			}

			_x3x_basic_key = mate.basic_key;
			_x3x_tuning = 0;
			_type = pxtnWOICETYPE.OGGV;

			res = pxtnERR.OK;
		End:
			if (res != pxtnERR.OK) {
				Voice_Release();
			}
			return res;
		}
	}

	pxtnERR Tone_Ready_sample(const pxtnPulse_NoiseBuilder* ptn_bldr) nothrow @system {
		pxtnERR res = pxtnERR.VOID;
		pxtnVOICEINSTANCE* p_vi = null;
		pxtnVOICEUNIT* p_vc = null;
		pxtnPulse_PCM pcm_work;

		int ch = 2;
		int sps = 44100;
		int bps = 16;

		for (int v = 0; v < _voice_num; v++) {
			p_vi = &_voinsts[v];
			deallocate(p_vi.p_smp_w);
			p_vi.smp_head_w = 0;
			p_vi.smp_body_w = 0;
			p_vi.smp_tail_w = 0;
		}

		for (int v = 0; v < _voice_num; v++) {
			p_vi = &_voinsts[v];
			p_vc = &_voices[v];

			switch (p_vc.type) {
			case pxtnVOICETYPE.OggVorbis:

				version (pxINCLUDE_OGGVORBIS) {
					res = p_vc.p_oggv.Decode(&pcm_work);
					if (res != pxtnERR.OK) {
						goto term;
					}
					if (!pcm_work.Convert(ch, sps, bps)) {
						goto term;
					}
					p_vi.smp_head_w = pcm_work.get_smp_head();
					p_vi.smp_body_w = pcm_work.get_smp_body();
					p_vi.smp_tail_w = pcm_work.get_smp_tail();
					p_vi.p_smp_w = cast(ubyte[]) pcm_work.Devolve_SamplingBuffer();
					break;
				} else {
					res = pxtnERR.ogg_no_supported;
					goto term;
				}

			case pxtnVOICETYPE.Sampling:

				res = p_vc.p_pcm.Copy(&pcm_work);
				if (res != pxtnERR.OK) {
					goto term;
				}
				if (!pcm_work.Convert(ch, sps, bps)) {
					res = pxtnERR.pcm_convert;
					goto term;
				}
				p_vi.smp_head_w = pcm_work.get_smp_head();
				p_vi.smp_body_w = pcm_work.get_smp_body();
				p_vi.smp_tail_w = pcm_work.get_smp_tail();
				p_vi.p_smp_w = cast(ubyte[]) pcm_work.Devolve_SamplingBuffer();
				break;

			case pxtnVOICETYPE.Overtone:
			case pxtnVOICETYPE.Coodinate: {
					p_vi.smp_body_w = 400;
					int size = p_vi.smp_body_w * ch * bps / 8;
					p_vi.p_smp_w = allocate!ubyte(size);
					if (!(p_vi.p_smp_w)) {
						res = pxtnERR.memory;
						goto term;
					}
					p_vi.p_smp_w[0 .. size] = 0x00;
					_UpdateWavePTV(p_vc, p_vi, ch, sps, bps);
					break;
				}

			case pxtnVOICETYPE.Noise: {
					pxtnPulse_PCM* p_pcm = null;
					if (!ptn_bldr) {
						res = pxtnERR.ptn_init;
						goto term;
					}
					p_pcm = ptn_bldr.BuildNoise(p_vc.p_ptn, ch, sps, bps);
					if (!(p_pcm)) {
						res = pxtnERR.ptn_build;
						goto term;
					}
					p_vi.p_smp_w = cast(ubyte[]) p_pcm.Devolve_SamplingBuffer();
					p_vi.smp_body_w = p_vc.p_ptn.get_smp_num_44k();
					break;
				}
			default:
				break;
			}
		}

		res = pxtnERR.OK;
	term:
		if (res != pxtnERR.OK) {
			for (int v = 0; v < _voice_num; v++) {
				p_vi = &_voinsts[v];
				deallocate(p_vi.p_smp_w);
				p_vi.smp_head_w = 0;
				p_vi.smp_body_w = 0;
				p_vi.smp_tail_w = 0;
			}
		}

		return res;
	}

	pxtnERR Tone_Ready_envelope(int sps) nothrow @system {
		pxtnERR res = pxtnERR.VOID;
		int e = 0;
		pxtnPOINT[] p_point = null;

		for (int v = 0; v < _voice_num; v++) {
			pxtnVOICEINSTANCE* p_vi = &_voinsts[v];
			pxtnVOICEUNIT* p_vc = &_voices[v];
			pxtnVOICEENVELOPE* p_enve = &p_vc.envelope;
			int size = 0;

			deallocate(p_vi.p_env);

			if (p_enve.head_num) {
				for (e = 0; e < p_enve.head_num; e++) {
					size += p_enve.points[e].x;
				}
				p_vi.env_size = cast(int)(cast(double) size * sps / p_enve.fps);
				if (!p_vi.env_size) {
					p_vi.env_size = 1;
				}

				p_vi.p_env = allocate!ubyte(p_vi.env_size);
				if (!p_vi.p_env) {
					res = pxtnERR.memory;
					goto term;
				}
				p_point = allocate!pxtnPOINT(p_enve.head_num);
				if (!p_point) {
					res = pxtnERR.memory;
					goto term;
				}

				// convert points.
				int offset = 0;
				int head_num = 0;
				for (e = 0; e < p_enve.head_num; e++) {
					if (!e || p_enve.points[e].x || p_enve.points[e].y) {
						offset += cast(int)(cast(double) p_enve.points[e].x * sps / p_enve.fps);
						p_point[e].x = offset;
						p_point[e].y = p_enve.points[e].y;
						head_num++;
					}
				}

				pxtnPOINT start;
				e = start.x = start.y = 0;
				for (int s = 0; s < p_vi.env_size; s++) {
					while (e < head_num && s >= p_point[e].x) {
						start.x = p_point[e].x;
						start.y = p_point[e].y;
						e++;
					}

					if (e < head_num) {
						p_vi.p_env[s] = cast(ubyte)(start.y + (p_point[e].y - start.y) * (s - start.x) / (p_point[e].x - start.x));
					} else {
						p_vi.p_env[s] = cast(ubyte) start.y;
					}
				}

				deallocate(p_point);
			}

			if (p_enve.tail_num) {
				p_vi.env_release = cast(int)(cast(double) p_enve.points[p_enve.head_num].x * sps / p_enve.fps);
			} else {
				p_vi.env_release = 0;
			}
		}

		res = pxtnERR.OK;
	term:

		deallocate(p_point);

		if (res != pxtnERR.OK) {
			for (int v = 0; v < _voice_num; v++) {
				deallocate(_voinsts[v].p_env);
			}
		}

		return res;
	}

	pxtnERR Tone_Ready(const pxtnPulse_NoiseBuilder* ptn_bldr, int sps) nothrow @system {
		pxtnERR res = pxtnERR.VOID;
		res = Tone_Ready_sample(ptn_bldr);
		if (res != pxtnERR.OK) {
			return res;
		}
		res = Tone_Ready_envelope(sps);
		if (res != pxtnERR.OK) {
			return res;
		}
		return pxtnERR.OK;
	}
}
