module pxtone.pxtn;

import core.stdc.stdlib;

// '16/04/28 pxtn.h
// '16/12/03 pxtnRESULT.
// '16/12/15 pxtnRESULT -> pxtnERR/pxtnOK.

enum pxtn_H;

struct pxtnPOINT {
	int x;
	int y;
}

void* allocate(size_t size) nothrow @system {
	return malloc(size);
}

T* allocate(T)() {
	import std.conv : emplace;

	auto result = cast(T*) malloc(T.sizeof);
	emplace(result);
	return result;
}

void SAFE_DELETE(void* p) nothrow @system {
	if (p) {
		free(p);
		p = null;
	}
}
