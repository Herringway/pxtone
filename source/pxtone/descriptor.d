module pxtone.descriptor;
// '11/08/12 pxFile.h
// '16/01/22 pxFile.h
// '16/04/27 pxtnFile. (int)
// '16/09/09 pxtnDescriptor.

import pxtone.error;
import pxtone.pxtn;

import std.exception;
import std.stdio;
import std.traits;

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

	void set_file_r(ref File fd) @safe {
		enforce(fd.isOpen, new PxtoneException("File must be opened for reading"));

		fd.seek(0, SEEK_END);
		ulong sz = fd.tell;
		fd.seek(0, SEEK_SET);
		file = fd;

		_size = cast(int) sz;

		_b_file = true;
		_b_read = true;
		_cur = 0;
	}

	void set_file_w(ref File fd) @safe {
		file = fd;
		_size = 0;
		_b_file = true;
		_b_read = false;
		_cur = 0;
	}

	void set_memory_r(ubyte[] buf) @safe {
		enforce(buf.length >= 1, new PxtoneException("No data to read in buffer"));
		_p_desc = buf;
		_b_file = false;
		_b_read = true;
		_cur = 0;
	}

	void seek(pxtnSEEK mode, int val) @safe {
		if (_b_file) {
			int[pxtnSEEK.num] seek_tbl = [SEEK_SET, SEEK_CUR, SEEK_END];
			file.seek(val, seek_tbl[mode]);
		} else {
			switch (mode) {
			case pxtnSEEK.set:
				enforce(val < _p_desc.length, "Unexpected end of data");
				enforce(val >= 0, "Cannot seek to negative position");
				_cur = val;
				break;
			case pxtnSEEK.cur:
				enforce(_cur + val < _p_desc.length, "Unexpected end of data");
				enforce(_cur + val >= 0, "Cannot seek to negative position");
				_cur += val;
				break;
			case pxtnSEEK.end:
				enforce(_p_desc.length + val < _p_desc.length, "Unexpected end of data");
				enforce(_p_desc.length + val >= 0, "Cannot seek to negative position");
				_cur = cast(int)_p_desc.length + val;
				break;
			default:
				break;
			}
		}
	}

	void w_asfile(T)(const T p) @system if (!is(T : U[], U)) {
		w_asfile((&p)[0 .. 1]);
	}
	void w_asfile(T)(scope const(T)[] p) @system {
		enforce(isOpen && _b_file && !_b_read, new PxtoneException("File must be opened for writing"));

		file.rawWrite(p);
		_size += p.length * T.sizeof;
	}

	void r(T)(T[] p) @safe {
		enforce(isOpen, new PxtoneException("File must be opened for reading"));
		enforce(_b_read, new PxtoneException("File must be opened for reading"));

		if (_b_file) {
			file.trustedRead(p);
		} else {
			for (int i = 0; i < p.length; i++) {
				enforce(_cur + T.sizeof < _p_desc.length, new PxtoneException("Unexpected end of buffer"));
				p[i] = (cast(T[])_p_desc[_cur .. _cur + T.sizeof])[0];
				_cur += T.sizeof;
			}
		}
	}
	void r(T)(ref T p) @safe if (!is(T : U[], U)) {
		enforce(isOpen, new PxtoneException("File must be opened for reading"));
		enforce(_b_read, new PxtoneException("File must be opened for reading"));

		if (_b_file) {
			p = file.trustedRead!T();
		} else {
			enforce(_cur + T.sizeof < _p_desc.length, new PxtoneException("Unexpected end of buffer"));
			p = (cast(T[])_p_desc[_cur .. _cur + T.sizeof])[0];
			_cur += T.sizeof;
		}
	}

	// ..uint
	void v_w_asfile(int val) @system {
		int dummy;
		v_w_asfile(val, dummy);
	}
	void v_w_asfile(int val, ref int p_add) @system {
		enforce(isOpen && _b_file && !_b_read, new PxtoneException("File must be opened for writing"));

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
		file.rawWrite(b[0 .. bytes]);
		p_add += bytes;
		_size += bytes;
	}
	// 可変長読み込み（int  までを保証）
	void v_r(ref int p) @safe {
		enforce(isOpen && _b_read, new PxtoneException("File must be opened for reading"));

		int i;
		ubyte[5] a = 0;
		ubyte[5] b = 0;

		for (i = 0; i < 5; i++) {
			r(a[i]);
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
			throw new PxtoneException("Integer too large");
		default:
			break;
		}

		p = (cast(int[]) b[0 .. 4])[0];
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

T trustedRead(T)(File file) @safe if (!hasIndirections!T) {
	T[1] p;
	file.trustedRead(p);
	return p[0];
}

void trustedRead(T)(File file, T[] arr) @trusted if (!hasIndirections!T) {
	file.rawRead(arr);
}
