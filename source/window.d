module dgs.window;

import gfm.sdl2;

class Window
{
	SDL2Window _window;

	alias _window this;

	this(int width, int height) 
	{
		_window = new SDL2Window(sdl2,
			SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
			width, height,
			SDL_WINDOW_OPENGL);
	}
}

private
{
	import std.experimental.logger;
	import gfm.sdl2 : SDL2;

	FileLogger logger;
	SDL2 sdl2;
}

static this()
{
	import std.stdio : stdout;
	import derelict.util.loader : SharedLibVersion;

	logger = new FileLogger(stdout, LogLevel.warning);

	// load dynamic libraries
	sdl2 = new SDL2(logger, SharedLibVersion(2, 0, 0));

	sdl2.subSystemInit(SDL_INIT_VIDEO);
	sdl2.subSystemInit(SDL_INIT_EVENTS);

	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
	SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
}

static ~this()
{
	sdl2.destroy;
}