import pxtone;

import std.experimental.logger;
import std.exception;
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

void _write_ptcop(ref pxtnService pxtn, ref File file) {
	auto desc = pxtnDescriptor();

	desc.set_file_w(file);

	pxtn.write(desc, false, 0);
}

bool initAudio(SDL_AudioCallback fun, ubyte channels, uint sampleRate, void* userdata = null) {
	import bindbc.sdl;

	enforce(loadSDL() == sdlSupport);
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
	sharedLog = new FileLogger(stdout, LogLevel.trace);

	auto filePath = args[1];
	auto file = cast(ubyte[])read(args[1]);

	// pxtone initialization
	auto pxtn = pxtnService();
	trace("Initializing pxtone");
	pxtn.initialize();
	trace("Setting quality");
	pxtn.set_destination_quality(_CHANNEL_NUM, _SAMPLE_PER_SECOND);

	trace("Loading ptcop");
	// Load file
	pxtn.load(file);

	trace("Preparing pxtone");
	// Prepare to play music
	{
		pxtnVOMITPREPARATION prep;
		prep.flags |= pxtnVOMITPREPFLAG_loop;
		prep.start_pos_float = 0;
		prep.master_volume = 0.80f;

		pxtn.moo_preparation(prep);
	}
	if (!initAudio(&_sampling_func, _CHANNEL_NUM, _SAMPLE_PER_SECOND, &pxtn)) {
		return 1;
	}
	trace("SDL audio init success");

	writefln!"file: %s"(filePath.baseName);
	writefln!"name: %s"(pxtn.text.get_name_buf());
	writefln!"comment: %s"(pxtn.text.get_comment_buf());

	debug foreach (voice; 0 .. pxtn.Woice_Num()) {
		import std.algorithm : map;
		import std.range : iota;
		auto woice = pxtn.Woice_Get(voice);
		writefln!"Voice %d \"%s\": %s - %s"(voice, woice.get_name_buf(), woice.get_type(), iota(woice.get_voice_num()).map!(x => woice.get_voice(x).type));
	}

	writeln("Press enter to exit");
	readln();

	return 0;
}
