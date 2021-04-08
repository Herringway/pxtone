module pxtone.descriptor;
// '11/08/12 pxFile.h
// '16/01/22 pxFile.h
// '16/04/27 pxtnFile. (int)
// '16/09/09 pxtnDescriptor.

import pxtone.pxtn;

import core.stdc.stdio : fwrite, fread, fseek, fpos_t, fgetpos, SEEK_END, SEEK_SET, SEEK_CUR;
import core.stdc.stdio : REALFILE = FILE;

struct _iobuf;
alias FILE = _iobuf;

enum pxSCE = false;

enum pxtnSEEK {
	pxtnSEEK_set = 0,
	pxtnSEEK_cur,
	pxtnSEEK_end,
	pxtnSEEK_num
}

struct pxtnDescriptor {
private:
	enum {
		_BUFSIZE_HEEP = 1024,
		_TAGLINE_NUM = 128,
	};

	void* _p_desc;
	bool _b_file;
	bool _b_read;
	int _size;
	int _cur;

public:

	bool set_file_r(FILE* fd) nothrow @system {
		if (!fd) {
			return false;
		}

		fpos_t sz;
		if (fseek(cast(REALFILE*) fd, 0, SEEK_END)) {
			return false;
		}
		if (fgetpos(cast(REALFILE*) fd, &sz)) {
			return false;
		}
		if (fseek(cast(REALFILE*) fd, 0, SEEK_SET)) {
			return false;
		}
		_p_desc = fd;

		static if (pxSCE) {
			_size = cast(int) sz._Off;
		} else {
			_size = cast(int) sz;
		}

		_b_file = true;
		_b_read = true;
		_cur = 0;
		return true;
	}

	bool set_file_w(FILE* fd) nothrow @safe {
		if (!fd) {
			return false;
		}

		_p_desc = fd;
		_size = 0;
		_b_file = true;
		_b_read = false;
		_cur = 0;
		return true;
	}

	bool set_memory_r(void* p_mem, int size) nothrow @safe {
		if (!p_mem || size < 1) {
			return false;
		}
		_p_desc = p_mem;
		_size = size;
		_b_file = false;
		_b_read = true;
		_cur = 0;
		return true;
	}

	bool seek(pxtnSEEK mode, int val) nothrow @system {
		if (_b_file) {
			int[pxtnSEEK.pxtnSEEK_num] seek_tbl = [SEEK_SET, SEEK_CUR, SEEK_END];
			if (fseek(cast(REALFILE*) _p_desc, val, seek_tbl[mode])) {
				return false;
			}
		} else {
			switch (mode) {
			case pxtnSEEK.pxtnSEEK_set:
				if (val >= _size) {
					return false;
				}
				if (val < 0) {
					return false;
				}
				_cur = val;
				break;
			case pxtnSEEK.pxtnSEEK_cur:
				if (_cur + val >= _size) {
					return false;
				}
				if (_cur + val < 0) {
					return false;
				}
				_cur += val;
				break;
			case pxtnSEEK.pxtnSEEK_end:
				if (_size + val >= _size) {
					return false;
				}
				if (_size + val < 0) {
					return false;
				}
				_cur = _size + val;
				break;
			default:
				break;
			}
		}
		return true;
	}

	bool w_asfile(const(void)* p, int size, int num) nothrow @system {
		bool b_ret = false;

		if (!_p_desc || !_b_file || _b_read) {
			goto End;
		}

		if (fwrite(p, size, num, cast(REALFILE*) _p_desc) != num) {
			goto End;
		}
		_size += size * num;

		b_ret = true;
	End:
		return b_ret;
	}

	bool r(T)(T[] p) nothrow @system {
		if (!_p_desc) {
			return false;
		}
		if (!_b_read) {
			return false;
		}

		bool b_ret = false;

		if (_b_file) {
			if (fread(p.ptr, T.sizeof, p.length, cast(REALFILE*) _p_desc) != p.length) {
				goto End;
			}
		} else {
			for (int i = 0; i < p.length; i++) {
				if (_cur + T.sizeof > _size) {
					goto End;
				}
				p[i] = (cast(T[])_p_desc[_cur .. _cur + T.sizeof])[0];
				_cur += T.sizeof;
			}
		}

		b_ret = true;
	End:
		return b_ret;
	}
	bool r(T)(ref T p) nothrow @system {
		if (!_p_desc) {
			return false;
		}
		if (!_b_read) {
			return false;
		}

		bool b_ret = false;

		if (_b_file) {
			if (fread(&p, T.sizeof, 1, cast(REALFILE*) _p_desc) != 1) {
				goto End;
			}
		} else {
			if (_cur + T.sizeof > _size) {
				goto End;
			}
			p = (cast(T[])_p_desc[_cur .. _cur + T.sizeof])[0];
			_cur += T.sizeof;
		}

		b_ret = true;
	End:
		return b_ret;
	}

	// ..uint
	int v_w_asfile(int val, int* p_add) nothrow @system {
		if (!_p_desc) {
			return 0;
		}
		if (!_b_file) {
			return 0;
		}
		if (_b_read) {
			return 0;
		}

		ubyte[5] a = 0;
		ubyte[5] b = 0;
		uint us = cast(uint) val;
		int bytes = 0;

		a[0] = *(cast(ubyte*)(&us) + 0);
		a[1] = *(cast(ubyte*)(&us) + 1);
		a[2] = *(cast(ubyte*)(&us) + 2);
		a[3] = *(cast(ubyte*)(&us) + 3);
		a[4] = 0;

		// 1byte(7bit)
		if (us < 0x00000080) {
			bytes = 1;
			b[0] = a[0];
		}  // 2byte(14bit)
		else if (us < 0x00004000) {
			bytes = 2;
			b[0] = ((a[0] << 0) & 0x7F) | 0x80;
			b[1] = (a[0] >> 7) | ((a[1] << 1) & 0x7F);
		}  // 3byte(21bit)
		else if (us < 0x00200000) {
			bytes = 3;
			b[0] = ((a[0] << 0) & 0x7F) | 0x80;
			b[1] = (a[0] >> 7) | ((a[1] << 1) & 0x7F) | 0x80;
			b[2] = (a[1] >> 6) | ((a[2] << 2) & 0x7F);
		}  // 4byte(28bit)
		else if (us < 0x10000000) {
			bytes = 4;
			b[0] = ((a[0] << 0) & 0x7F) | 0x80;
			b[1] = (a[0] >> 7) | ((a[1] << 1) & 0x7F) | 0x80;
			b[2] = (a[1] >> 6) | ((a[2] << 2) & 0x7F) | 0x80;
			b[3] = (a[2] >> 5) | ((a[3] << 3) & 0x7F);
		}  // 5byte(32bit)
		else {
			bytes = 5;
			b[0] = ((a[0] << 0) & 0x7F) | 0x80;
			b[1] = (a[0] >> 7) | ((a[1] << 1) & 0x7F) | 0x80;
			b[2] = (a[1] >> 6) | ((a[2] << 2) & 0x7F) | 0x80;
			b[3] = (a[2] >> 5) | ((a[3] << 3) & 0x7F) | 0x80;
			b[4] = (a[3] >> 4) | ((a[4] << 4) & 0x7F);
		}
		if (fwrite(b.ptr, 1, bytes, cast(REALFILE*) _p_desc) != bytes) {
			return false;
		}
		if (p_add) {
			*p_add += bytes;
		}
		_size += bytes;
		return true;

		//return false;
	}
	// 可変長読み込み（int  までを保証）
	bool v_r(int* p) nothrow @system {
		if (!_p_desc) {
			return false;
		}
		if (!_b_read) {
			return false;
		}

		int i;
		ubyte[5] a = 0;
		ubyte[5] b = 0;

		for (i = 0; i < 5; i++) {
			if (!r(a[i])) {
				return false;
			}
			if (!(a[i] & 0x80)) {
				break;
			}
		}
		switch (i) {
		case 0:
			b[0] = (a[0] & 0x7F) >> 0;
			break;
		case 1:
			b[0] = cast(ubyte)(((a[0] & 0x7F) >> 0) | (a[1] << 7));
			b[1] = (a[1] & 0x7F) >> 1;
			break;
		case 2:
			b[0] = cast(ubyte)(((a[0] & 0x7F) >> 0) | (a[1] << 7));
			b[1] = cast(ubyte)(((a[1] & 0x7F) >> 1) | (a[2] << 6));
			b[2] = (a[2] & 0x7F) >> 2;
			break;
		case 3:
			b[0] = cast(ubyte)(((a[0] & 0x7F) >> 0) | (a[1] << 7));
			b[1] = cast(ubyte)(((a[1] & 0x7F) >> 1) | (a[2] << 6));
			b[2] = cast(ubyte)(((a[2] & 0x7F) >> 2) | (a[3] << 5));
			b[3] = (a[3] & 0x7F) >> 3;
			break;
		case 4:
			b[0] = cast(ubyte)(((a[0] & 0x7F) >> 0) | (a[1] << 7));
			b[1] = cast(ubyte)(((a[1] & 0x7F) >> 1) | (a[2] << 6));
			b[2] = cast(ubyte)(((a[2] & 0x7F) >> 2) | (a[3] << 5));
			b[3] = cast(ubyte)(((a[3] & 0x7F) >> 3) | (a[4] << 4));
			b[4] = (a[4] & 0x7F) >> 4;
			break;
		case 5:
			return false;
		default:
			break;
		}

		*p = *(cast(int*) b.ptr);

		return true;
	}

	int get_size_bytes() const nothrow @safe {
		return _size;
	}
};

int pxtnDescriptor_v_chk(int val) nothrow @safe {
	uint us;

	us = cast(uint) val;
	if (us < 0x80) {
		return 1; // 1byte( 7bit)
	}
	if (us < 0x4000) {
		return 2; // 2byte(14bit)
	}
	if (us < 0x200000) {
		return 3; // 3byte(21bit)
	}
	if (us < 0x10000000) {
		return 4; // 4byte(28bit)
	}
	//	if( value < 0x800000000 ) return 5;	// 5byte(35bit)
	if (us <= 0xffffffff) {
		return 5;
	}

	return 6;
}
