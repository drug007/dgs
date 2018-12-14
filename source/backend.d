module dgs.backend;

import dgs.color : Color;
import dgs.math : Rect2;

class Backend
{
	abstract void clear();

	abstract void setColor(Color clr);

	abstract void fillRect(Rect2 rect, float rounding);

	abstract void strokeRect(Rect2 rect, float rounding, float thickness);

	abstract void present();
}

class Sdl2Backend : Backend
{
	import gfm.sdl2 : SDL2Renderer, SDL_RENDERER_ACCELERATED;
	import dgs.window : Window;

	SDL2Renderer _renderer;

	this(Window window)
	{
		_renderer = new SDL2Renderer(window, SDL_RENDERER_ACCELERATED);
	}

	override void clear()
	{
		_renderer.clear;
	}

	override void setColor(Color clr)
	{
		with (clr) _renderer.setColor(r, g, b, a);
	}

	override void fillRect(Rect2 rect, float rounding)
	{
		_renderer.fillRect(cast(int)rect.pos.x, cast(int)rect.pos.y, cast(int)rect.size.x, cast(int)rect.size.y);
	}

	override void strokeRect(Rect2 rect, float rounding, float thickness)
	{
		_renderer.drawRect(cast(int)rect.pos.x, cast(int)rect.pos.y, cast(int)rect.size.x, cast(int)rect.size.y);
	}

	override void present()
	{
		_renderer.present;
	}

	~this()
	{
		destroy(_renderer);
	}
}

class NvgBackend : Backend
{
	import dgs.window : Window;
	import gfm.opengl: OpenGL;
	import arsd.nanovega;

	Window window;
	OpenGL gl;
	NVGContext nvg;
	NVGColor color;

	this(Window window)
	{
		this.window = window;
		import dgs.window : logger;
		gl = new OpenGL(logger);
		gl.reload;
		gl.redirectDebugOutput();

		nvg = nvgCreateContext(NVGContextFlag.Debug);
		import std.exception : enforce;
		enforce(nvg !is null, "cannot initialize NanoGui");
	}

	override void clear()
	{
		import gfm.opengl;

		glViewport(0, 0, window.getWidth, window.getHeight);
		glClearColor(color.r/255.0, color.g/255.0, color.b/255.0, color.a/255.0);
		glClear(glNVGClearFlags); // use NanoVega API to get flags for OpenGL call

		nvg.beginFrame(window.getWidth, window.getHeight);
	}

	override void setColor(Color clr)
	{
		with(clr) color = NVGColor(r, g, b, a);
	}

	override void fillRect(Rect2 rect, float rounding)
	{
		nvg.beginPath;
		nvg.roundedRect(rect.pos.x, rect.pos.y, rect.size.x, rect.size.y, rounding);
		nvg.fillColor(color);
		nvg.fill;
	}

	override void strokeRect(Rect2 rect, float rounding, float thickness)
	{
		nvg.beginPath;
		nvg.roundedRect(rect.pos.x, rect.pos.y, rect.size.x, rect.size.y, rounding);
		nvg.strokeColor(color);
		nvg.stroke;
	}

	override void present()
	{
		nvg.endFrame();

		window.swapBuffers;
	}

	~this()
	{
		destroy(nvg);
	}
}