module pxtone.pulse.oggv;

version (pxINCLUDE_OGGVORBIS):
import derelict.vorbis.codec;
import derelict.vorbis.file;

import pxtone.descriptor;
import pxtone.error;
import pxtone.mem;
import pxtone.pulse.pcm;

import std.stdio;

struct OVMEM {
	const(ubyte)[] p_buf; // ogg vorbis-data on memory.s
	int size; //
	int pos; // reading position.
}

// 4 callbacks below:

extern (C) size_t _mread(void* p, size_t size, size_t nmemb, void* p_void) nothrow @system {
	OVMEM* pom = cast(OVMEM*) p_void;

	if (!pom) {
		return -1;
	}
	if (pom.pos >= pom.size) {
		return 0;
	}
	if (pom.pos == -1) {
		return 0;
	}

	int left = pom.size - pom.pos;

	if (cast(int)(size * nmemb) >= left) {
		p[0 .. pom.size - pom.pos] = cast(void[])pom.p_buf[pom.pos .. pom.size];
		pom.pos = pom.size;
		return left / size;
	}

	p[0 .. nmemb * size] = cast(void[])pom.p_buf[pom.pos .. pom.pos + nmemb * size];
	pom.pos += cast(int)(nmemb * size);

	return nmemb;
}

extern (C) int _mseek(void* p_void, long offset, int mode) nothrow @system {
	int newpos;
	OVMEM* pom = cast(OVMEM*) p_void;

	if (!pom || pom.pos < 0) {
		return -1;
	}
	if (offset < 0) {
		pom.pos = -1;
		return -1;
	}

	switch (mode) {
	case SEEK_SET:
		newpos = cast(int) offset;
		break;
	case SEEK_CUR:
		newpos = pom.pos + cast(int) offset;
		break;
	case SEEK_END:
		newpos = pom.size + cast(int) offset;
		break;
	default:
		return -1;
	}
	if (newpos < 0) {
		return -1;
	}

	pom.pos = newpos;

	return 0;
}

extern (C) int _mtell(void* p_void) nothrow @system {
	OVMEM* pom = cast(OVMEM*) p_void;
	if (!pom) {
		return -1;
	}
	return pom.pos;
}

extern (C) int _mclose_dummy(void* p_void) nothrow @system {
	OVMEM* pom = cast(OVMEM*) p_void;
	if (!pom) {
		return -1;
	}
	return 0;
}

/////////////////
// global
/////////////////

struct pxtnPulse_Oggv {
private:
	int _ch;
	int _sps2;
	int _smp_num;
	int _size;
	ubyte[] _p_data;

	bool _SetInformation() nothrow @system {
		bool b_ret = false;

		OVMEM ovmem;
		ovmem.p_buf = _p_data;
		ovmem.pos = 0;
		ovmem.size = _size;

		// set callback func.
		ov_callbacks oc;
		oc.read_func = &_mread;
		oc.seek_func = &_mseek;
		oc.close_func = &_mclose_dummy;
		oc.tell_func = &_mtell;

		OggVorbis_File vf;

		vorbis_info* vi;

		switch (ov_open_callbacks(&ovmem, &vf, null, 0, oc)) {
		case OV_EREAD:
			goto End; //{printf("A read from media returned an error.\n");exit(1);}
		case OV_ENOTVORBIS:
			goto End; //{printf("Bitstream is not Vorbis data. \n");exit(1);}
		case OV_EVERSION:
			goto End; //{printf("Vorbis version mismatch. \n");exit(1);}
		case OV_EBADHEADER:
			goto End; //{printf("Invalid Vorbis bitstream header. \n");exit(1);}
		case OV_EFAULT:
			goto End; //{printf("Internal logic fault; indicates a bug or heap/stack corruption. \n");exit(1);}
		default:
			break;
		}

		vi = ov_info(&vf, -1);

		_ch = vi.channels;
		_sps2 = vi.rate;
		_smp_num = cast(int) ov_pcm_total(&vf, -1);

		// end.
		ov_clear(&vf);

		b_ret = true;

	End:
		return b_ret;

	}

public:
	 ~this() nothrow @system {
		Release();
	}

	pxtnERR Decode(pxtnPulse_PCM* p_pcm) const nothrow @system {
		pxtnERR res = pxtnERR.VOID;

		OggVorbis_File vf;
		vorbis_info* vi;
		ov_callbacks oc;

		OVMEM ovmem;
		int current_section;
		ubyte[4096] pcmout = 0; //take 4k out of the data segment, not the stack

		ovmem.p_buf = _p_data;
		ovmem.pos = 0;
		ovmem.size = _size;

		// set callback func.
		oc.read_func = &_mread;
		oc.seek_func = &_mseek;
		oc.close_func = &_mclose_dummy;
		oc.tell_func = &_mtell;

		switch (ov_open_callbacks(&ovmem, &vf, null, 0, oc)) {
		case OV_EREAD:
			res = pxtnERR.ogg;
			goto term; //{printf("A read from media returned an error.\n");exit(1);}
		case OV_ENOTVORBIS:
			res = pxtnERR.ogg;
			goto term; //{printf("Bitstream is not Vorbis data. \n");exit(1);}
		case OV_EVERSION:
			res = pxtnERR.ogg;
			goto term; //{printf("Vorbis version mismatch. \n");exit(1);}
		case OV_EBADHEADER:
			res = pxtnERR.ogg;
			goto term; //{printf("Invalid Vorbis bitstream header. \n");exit(1);}
		case OV_EFAULT:
			res = pxtnERR.ogg;
			goto term; //{printf("Internal logic fault; indicates a bug or heap/stack corruption. \n");exit(1);}
		default:
			break;
		}

		vi = ov_info(&vf, -1);

		{
			int smp_num = cast(int) ov_pcm_total(&vf, -1);
			uint bytes;

			bytes = vi.channels * 2 * smp_num;

			res = p_pcm.Create(vi.channels, vi.rate, 16, smp_num);
			if (res != pxtnERR.OK) {
				goto term;
			}
		}
		// decode..
		{
			int ret = 0;
			ubyte* p = p_pcm.get_p_buf().ptr;
			do {
				ret = ov_read(&vf, cast(byte*) pcmout.ptr, 4096, 0, 2, 1, &current_section);
				if (ret > 0) {
					p[0 .. ret] = pcmout[0 .. ret]; //fwrite( pcmout, 1, ret, of );
				}
				p += ret;
			}
			while (ret);
		}

		// end.
		ov_clear(&vf);

		res = pxtnERR.OK;

	term:
		return res;
	}

	void Release() nothrow @system {
		if (_p_data) {
			deallocate(_p_data);
		}
		_p_data = null;
		_ch = 0;
		_sps2 = 0;
		_smp_num = 0;
		_size = 0;
	}

	bool GetInfo(int* p_ch, int* p_sps, int* p_smp_num) nothrow @safe {
		if (!_p_data) {
			return false;
		}

		if (p_ch) {
			*p_ch = _ch;
		}
		if (p_sps) {
			*p_sps = _sps2;
		}
		if (p_smp_num) {
			*p_smp_num = _smp_num;
		}

		return true;
	}

	int GetSize() const nothrow @safe {
		if (!_p_data) {
			return 0;
		}
		return cast(int)(int.sizeof * 4 + _size);
	}

	bool ogg_write(ref pxtnDescriptor desc) const nothrow @system {
		bool b_ret = false;

		if (!desc.w_asfile(_p_data)) {
			goto End;
		}

		b_ret = true;
	End:
		return b_ret;
	}

	pxtnERR ogg_read(ref pxtnDescriptor desc) nothrow @system {
		pxtnERR res = pxtnERR.VOID;

		_size = desc.get_size_bytes();
		if (!(_size)) {
			res = pxtnERR.desc_r;
			goto End;
		}
		_p_data = allocate!ubyte(_size);
		if (!(_p_data)) {
			res = pxtnERR.memory;
			goto End;
		}
		if (!desc.r(_p_data)) {
			res = pxtnERR.desc_r;
			goto End;
		}
		if (!_SetInformation()) {
			goto End;
		}

		res = pxtnERR.OK;
	End:

		if (res != pxtnERR.OK) {
			if (_p_data) {
				deallocate(_p_data);
			}
			_p_data = null;
			_size = 0;
		}
		return res;
	}

	bool pxtn_write(ref pxtnDescriptor p_doc) const nothrow @system {
		if (!_p_data) {
			return false;
		}

		if (!p_doc.w_asfile(_ch)) {
			return false;
		}
		if (!p_doc.w_asfile(_sps2)) {
			return false;
		}
		if (!p_doc.w_asfile(_smp_num)) {
			return false;
		}
		if (!p_doc.w_asfile(_size)) {
			return false;
		}
		if (!p_doc.w_asfile(_p_data)) {
			return false;
		}

		return true;
	}

	bool pxtn_read(ref pxtnDescriptor p_doc) nothrow @system {
		bool b_ret = false;

		if (!p_doc.r(_ch)) {
			goto End;
		}
		if (!p_doc.r(_sps2)) {
			goto End;
		}
		if (!p_doc.r(_smp_num)) {
			goto End;
		}
		if (!p_doc.r(_size)) {
			goto End;
		}

		if (!_size) {
			goto End;
		}

		_p_data = allocate!ubyte(_size);
		if (!(_p_data)) {
			goto End;
		}
		if (!p_doc.r(_p_data)) {
			goto End;
		}

		b_ret = true;
	End:

		if (!b_ret) {
			if (_p_data) {
				deallocate(_p_data);
			}
			_p_data = null;
			_size = 0;
		}

		return b_ret;
	}

	bool Copy(pxtnPulse_Oggv* p_dst) const nothrow @system {
		p_dst.Release();
		if (!_p_data) {
			return true;
		}

		p_dst._p_data = allocate!ubyte(_size);
		if (!(p_dst._p_data)) {
			return false;
		}
		p_dst._p_data[0 .. _size] = _p_data[0 .. _size];

		p_dst._ch = _ch;
		p_dst._sps2 = _sps2;
		p_dst._size = _size;
		p_dst._smp_num = _smp_num;

		return true;
	}
}
