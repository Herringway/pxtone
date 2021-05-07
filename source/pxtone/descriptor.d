module pxtone.descriptor;
// '11/08/12 pxFile.h
// '16/01/22 pxFile.h
// '16/04/27 pxtnFile. (int)
// '16/09/09 pxtnDescriptor.

import pxtone.pxtn;

import std.stdio;

enum pxSCE = false;

enum pxtnSEEK {
	set = 0,
	cur,
	end,
	num
}

struct pxtnDescriptor {
private:
	ubyte[] _p_desc;
	File file;
	bool _b_file;
	bool _b_read;
	int _size;
	int _cur;

	bool isOpen() nothrow @safe {
		return (_p_desc != null) || file.isOpen;
	}
public:

	bool set_file_r(ref File fd) nothrow @system {
		if (!fd.isOpen) {
			return false;
		}

		ulong sz;
		try {
			fd.seek(0, SEEK_END);
			sz = fd.tell;
			fd.seek(0, SEEK_SET);
			file = fd;
		} catch (Exception) {
			return false;
		}

		_size = cast(int) sz;

		_b_file = true;
		_b_read = true;
		_cur = 0;
		return true;
	}

	bool set_file_w(ref File fd) nothrow @safe {
		if (!fd.isOpen) {
			return false;
		}
		try {
			file = fd;
		} catch (Exception) {
			return false;
		}
		_size = 0;
		_b_file = true;
		_b_read = false;
		_cur = 0;
		return true;
	}

	bool set_memory_r(ubyte[] buf) nothrow @safe {
		if (buf.length < 1) {
			return false;
		}
		_p_desc = buf;
		_b_file = false;
		_b_read = true;
		_cur = 0;
		return true;
	}

	bool seek(pxtnSEEK mode, int val) nothrow @safe {
		if (_b_file) {
			int[pxtnSEEK.num] seek_tbl = [SEEK_SET, SEEK_CUR, SEEK_END];
			try {
				file.seek(val, seek_tbl[mode]);
			} catch (Exception) {
				return false;
			}
		} else {
			switch (mode) {
			case pxtnSEEK.set:
				if (val >= _p_desc.length) {
					return false;
				}
				if (val < 0) {
					return false;
				}
				_cur = val;
				break;
			case pxtnSEEK.cur:
				if (_cur + val >= _p_desc.length) {
					return false;
				}
				if (_cur + val < 0) {
					return false;
				}
				_cur += val;
				break;
			case pxtnSEEK.end:
				if (_p_desc.length + val >= _p_desc.length) {
					return false;
				}
				if (_p_desc.length + val < 0) {
					return false;
				}
				_cur = cast(int)_p_desc.length + val;
				break;
			default:
				break;
			}
		}
		return true;
	}

	bool w_asfile(T)(const T p) nothrow @system if (!is(T : U[], U)) {
		return w_asfile((&p)[0 .. 1]);
	}
	bool w_asfile(T)(scope const(T)[] p) nothrow @system {
		if (!isOpen || !_b_file || _b_read) {
			return false;
		}

		try {
			file.rawWrite(p);
		} catch (Exception) {
			return false;
		}
		_size += p.length * T.sizeof;
		return true;
	}

	bool r(T)(T[] p) nothrow @system {
		if (!isOpen) {
			return false;
		}
		if (!_b_read) {
			return false;
		}

		bool b_ret = false;

		if (_b_file) {
			try {
				file.rawRead(p);
			} catch (Exception) {
				goto End;
			}
		} else {
			for (int i = 0; i < p.length; i++) {
				if (_cur + T.sizeof > _p_desc.length) {
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
	bool r(T)(ref T p) nothrow @system if (!is(T : U[], U)) {
		if (!isOpen) {
			return false;
		}
		if (!_b_read) {
			return false;
		}

		bool b_ret = false;

		if (_b_file) {
			ubyte[T.sizeof] buf;
			try {
				file.rawRead(buf[]);
			} catch (Exception) {
				goto End;
			}
			p = (cast(T[])(buf[]))[0];
		} else {
			if (_cur + T.sizeof > _p_desc.length) {
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
	int v_w_asfile(int val) nothrow @system {
		int dummy;
		return v_w_asfile(val, dummy);
	}
	int v_w_asfile(int val, ref int p_add) nothrow @system {
		if (!isOpen) {
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
		try {
			file.rawWrite(b[0 .. bytes]);
		} catch (Exception) {
			return false;
		}
		p_add += bytes;
		_size += bytes;
		return true;

		//return false;
	}
	// 可変長読み込み（int  までを保証）
	bool v_r(int* p) nothrow @system {
		if (!isOpen) {
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
		return _b_file ? _size : cast(int)_p_desc.length;
	}
}

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
