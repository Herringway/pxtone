import pxtone;

import std.experimental.logger;
import std.file;
import std.format;
import std.path;
import std.stdio;
import std.string;
import std.utf;
import bindbc.sdl : SDL_AudioCallback, SDL_AudioDeviceID;

enum _CHANNEL_NUM = 2;
enum _SAMPLE_PER_SECOND = 48000;
enum _BUFFER_PER_SEC = (0.3f);

__gshared SDL_AudioDeviceID dev;

bool _load_ptcop(ref pxtnService pxtn, void[] data, out pxtnERR p_pxtn_err) nothrow {
	bool okay;
	pxtnDescriptor* desc = allocate!pxtnDescriptor();

	scope (exit) {
		if (!okay) {
			pxtn.evels.Release();
		}
	}

	if (!desc.set_memory_r(data.ptr, cast(int) data.length)) {
		return false;
	}

	p_pxtn_err = pxtn.read(*desc);
	if (p_pxtn_err != pxtnERR.pxtnOK) {
		return false;
	}

	p_pxtn_err = pxtn.tones_ready();
	if (p_pxtn_err != pxtnERR.pxtnOK) {
		return false;
	}

	okay = true;
	return true;
}

bool initAudio(SDL_AudioCallback fun, ubyte channels, uint sampleRate, void* userdata = null) {
	import bindbc.sdl;

	assert(loadSDL() == sdlSupport);
	if (SDL_Init(SDL_INIT_AUDIO) != 0) {
		criticalf("SDL init failed: %s", SDL_GetError().fromStringz);
		return false;
	}
	SDL_AudioSpec want, have;
	want.freq = sampleRate;
	want.format = SDL_AudioFormat.AUDIO_S16;
	want.channels = channels;
	want.samples = 512;
	want.callback = fun;
	want.userdata = userdata;
	dev = SDL_OpenAudioDevice(null, 0, &want, &have, 0);
	if (dev == 0) {
		criticalf("SDL_OpenAudioDevice failed: %s", SDL_GetError().fromStringz);
		return false;
	}
	SDL_PauseAudioDevice(dev, 0);
	return true;
}

extern (C) void _sampling_func(void* user, ubyte* buf, int bufSize) nothrow {
	pxtnService* pxtn = cast(pxtnService*) user;
	pxtn.Moo(buf[0 .. bufSize]);
}

int main(string[] args) {
	if (args.length < 2) {
		return 1;
	}

	bool okay = false;
	pxtnERR pxtn_err = pxtnERR.pxtnERR_VOID;

	auto filePath = args[1];
	auto file = read(args[1]);

	// pxtone initialization
	pxtnService* pxtn = allocate!pxtnService();
	scope (exit) {
		if (!okay) {
			criticalf("pxtone: %s", pxtnError_get_string(pxtn_err).fromStringz);
		}
		deallocate(pxtn);
	}
	pxtn_err = pxtn.init_();
	if (pxtn_err != pxtnERR.pxtnOK) {
		return -1;
	}
	if (!pxtn.set_destination_quality(_CHANNEL_NUM, _SAMPLE_PER_SECOND)) {
		return -1;
	}

	// Load file
	if (!_load_ptcop(*pxtn, file, pxtn_err)) {
		return -1;
	}

	// Prepare to play music
	{
		pxtnVOMITPREPARATION prep;
		prep.flags |= pxtnVOMITPREPFLAG_loop;
		prep.start_pos_float = 0;
		prep.master_volume = 0.80f;

		if (!pxtn.moo_preparation(&prep)) {
			return -1;
		}
	}
	if (!initAudio(&_sampling_func, _CHANNEL_NUM, _SAMPLE_PER_SECOND, pxtn)) {
		return 1;
	}
	tracef("SDL audio init success");

	auto name = pxtn.text.get_name_buf();
	auto comment = pxtn.text.get_comment_buf();

	char[250] text = 0;
	writeln(sformat(text, "file: %s\nname: %s\ncomment: %s", filePath.baseName, name, comment));

	writeln("Press enter to exit");
	readln();

	okay = true;
	return 0;
}
