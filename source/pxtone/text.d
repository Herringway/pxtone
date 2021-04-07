module pxtone.text;
// '12/03/03

import pxtone.pxtn;

import pxtone.descriptor;

import core.stdc.stdlib;
import core.stdc.string;

bool _read4_malloc(char** pp, int* p_buf_size, pxtnDescriptor* p_doc) nothrow @system {
	if (!pp) {
		return false;
	}
	if (!p_doc.r(p_buf_size, 4, 1)) {
		return false;
	}
	if (*p_buf_size < 0) {
		return false;
	}

	bool b_ret = false;

	*pp = cast(char*) malloc(*p_buf_size + 1);
	if (!(*pp)) {
		return false;
	}

	memset(*pp, 0, *p_buf_size + 1);

	if (*p_buf_size) {
		if (!p_doc.r(*pp, char.sizeof, *p_buf_size)) {
			goto term;
		}
	}

	b_ret = true;
term:
	if (!b_ret) {
		free(*pp);
		*pp = null;
	}

	return b_ret;
}

static bool _write4(const char* p, int buf_size, pxtnDescriptor* p_doc) nothrow @system {
	if (!p_doc.w_asfile(&buf_size, 4, 1)) {
		return false;
	}
	if (!p_doc.w_asfile(p, 1, buf_size)) {
		return false;
	}
	return true;
}

struct pxtnText {
private:
	char* _p_comment_buf;
	int _comment_size;

	char* _p_name_buf;
	int _name_size;

public:
	 ~this() nothrow @system {
		SAFE_DELETE(_p_comment_buf);
		_comment_size = 0;
		SAFE_DELETE(_p_name_buf);
		_name_size = 0;
	}

	bool set_comment_buf(const(char)* comment, int buf_size) nothrow @system {
		if (!comment) {
			return false;
		}
		if (_p_comment_buf) {
			free(_p_comment_buf);
		}
		_p_comment_buf = null;
		if (buf_size <= 0) {
			_comment_size = 0;
			return true;
		}
		_p_comment_buf = cast(char*) malloc(buf_size + 1);
		if (!(_p_comment_buf)) {
			return false;
		}
		memcpy(_p_comment_buf, comment, buf_size);
		_p_comment_buf[buf_size] = '\0';
		_comment_size = buf_size;
		return true;
	}

	const(char)[] get_comment_buf() const nothrow @system {
		return _p_comment_buf[0 .. _comment_size];
	}

	bool is_comment_buf() const nothrow @safe {
		if (_comment_size > 0) {
			return true;
		}
		return false;
	}

	bool set_name_buf(const(char)* name, int buf_size) nothrow @system {
		if (!name) {
			return false;
		}
		if (_p_name_buf) {
			free(_p_name_buf);
		}
		_p_name_buf = null;
		if (buf_size <= 0) {
			_name_size = 0;
			return true;
		}
		_p_name_buf = cast(char*) malloc(buf_size + 1);
		if (!(_p_name_buf)) {
			return false;
		}
		memcpy(_p_name_buf, name, buf_size);
		_p_name_buf[buf_size] = '\0';
		_name_size = buf_size;
		return true;
	}

	const(char)[] get_name_buf() const nothrow @system {
		return _p_name_buf[0 .. _name_size];
	}

	bool is_name_buf() const nothrow @safe {
		if (_name_size > 0) {
			return true;
		}
		return false;
	}

	bool Comment_r(pxtnDescriptor* p_doc) nothrow @system {
		return _read4_malloc(&_p_comment_buf, &_comment_size, p_doc);
	}

	bool Comment_w(pxtnDescriptor* p_doc) nothrow @system {
		if (!_p_comment_buf) {
			return false;
		}
		return _write4(_p_comment_buf, _comment_size, p_doc);
	}

	bool Name_r(pxtnDescriptor* p_doc) nothrow @system {
		return _read4_malloc(&_p_name_buf, &_name_size, p_doc);
	}

	bool Name_w(pxtnDescriptor* p_doc) nothrow @system {
		if (!_p_name_buf) {
			return false;
		}
		return _write4(_p_name_buf, _name_size, p_doc);
	}
}
