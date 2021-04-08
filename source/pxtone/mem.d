module pxtone.mem;

import core.stdc.stdlib;
import core.stdc.string;

bool pxtnMem_zero(void* p, size_t byte_size) nothrow @system {
	(cast(ubyte*) p)[0 .. byte_size] = 0;
	return true;
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
T[] allocate(T)(size_t count) {
	import std.conv : emplace;

	auto result = (cast(T*) malloc(T.sizeof * count))[0 .. count];
	foreach (idx, _; result) {
		emplace(&result[idx]);
	}
	return result;
}
T* allocateC(T)(size_t count) {
	import std.conv : emplace;

	auto result = cast(T*) malloc(T.sizeof * count);
	foreach (ref element; result[0 .. count]) {
		element = T.init;
	}
	return result;
}

void deallocate(T)(ref T[] array) nothrow @system {
	if (!array) {
		return;
	}
	free(array.ptr);
	array = null;
}
void deallocate(T)(ref T* ptr) nothrow @system {
	if (!ptr) {
		return;
	}
	free(ptr);
	ptr = null;
}
