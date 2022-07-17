module pxtone.util;

package:

float reinterpretInt(int val) @safe nothrow pure @nogc {
	int[1] tmp = [val];
	return (cast(float[])(tmp[]))[0];
}

int reinterpretFloat(float val) @safe nothrow pure @nogc {
	float[1] tmp = [val];
	return (cast(int[])(tmp[]))[0];
}
