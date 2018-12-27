import gfm.math, gfm.sdl2;

import dgs.color : Color;
import dgs.math : Vec2, BBox2;
import dgs.layoutbox : LayoutBox;
import dgs.window : Window;
import dgs.context : Context;

class Widget
{
	Color color;
	int _width, _height;
	bool visible;

	auto width() { return _width; }
	Widget width(int v) { if (v >= 0) _width = v; return this; }

	auto height() { return _height; }
	Widget height(int v) { if (v >= 0) _height = v; return this; }

	this(int w, int h, Color c)
	{
		width = w;
		height = h;
		color = c;
		visible = true;
	}
}

class UI : Context
{
	Widget w1, w2, w3;

	this()
	{
		w1 = new Widget(100,  50, Color(0xFF, 0x00, 0x00, 0xFF));
		w2 = new Widget( 50, 150, Color(0x00, 0xFF, 0x00, 0xFF));
		w3 = new Widget(150, 100, Color(0x00, 0x00, 0xFF, 0xFF));
	}

	void leaf(uint id, Widget w)
	{
		import std.algorithm : min, max;
		beginLayoutBox(id);
		assert(!box.empty);
		BBox2 r = box.front.assigned;
		r.max.x = min(r.max.x, r.min.x + w.width);
		r.max.y = min(r.max.y, r.min.y + w.height);
		if (r.contains(input.mousePos))
		{
			import dgs.context : MouseButton;
			ubyte red =  input.down[MouseButton.Left] ? 255 : 127;
			drawFillRect(r, Color(red, 127, 127, 255));
		}
		else
			drawFillRect(r, w.color);
		box.front.desired = Vec2(w.width, w.height);
		endLayoutBox();
	}

	void draw()
	{
		LayoutBox root = getLayoutBox(0);
		root.assigned = BBox2(Vec2(50, 50), Vec2(500, 400));

		beginVBox(0);
		beginHBox(4);
		if (w1.visible)
		{
			
			leaf(1, w1);
		}
		if (w2.visible) leaf(2, w2);
		if (w3.visible) leaf(3, w3);
		endHBox();
		endVBox();
	}
}

int growth = 10;

int main(string[] args)
{
	auto width  = 640;
	auto height = 480;

	auto window = new Window(width, height);
	scope(exit) window.destroy;

	version(all)
	{
		import dgs.backend : NvgBackend;
		auto backend = new NvgBackend(window);
		scope(exit) backend.destroy;
	}
	else
	{
		import dgs.backend : Sdl2Backend;
		auto backend = new Sdl2Backend(window);
		scope(exit) backend.destroy;
	}

	window.setTitle("Hi there!");

	auto ui = new UI();
	scope(exit) destroy(ui);

	for (;;) {
		SDL_Event event;

		// mouse update
		{
			SDL_PumpEvents();

			while (SDL_PeepEvents(&event, 1, SDL_GETEVENT, SDL_MOUSEMOTION, SDL_MOUSEWHEEL))
			{
				import dgs.context : MouseButton;

				switch (event.type)
				{
				case SDL_MOUSEBUTTONDOWN:
					switch(event.button.button)
					{
						case SDL_BUTTON_LEFT:
							ui.input.down[MouseButton.Left  ] = true;
						break;
						case SDL_BUTTON_MIDDLE:
							ui.input.down[MouseButton.Middle] = true;
						break;
						case SDL_BUTTON_RIGHT:
							ui.input.down[MouseButton.Right ] = true;
						break;
						default:
					}
					break;
				case SDL_MOUSEBUTTONUP:
					switch(event.button.button)
					{
						case SDL_BUTTON_LEFT:
							ui.input.down[MouseButton.Left  ] = false;
						break;
						case SDL_BUTTON_MIDDLE:
							ui.input.down[MouseButton.Middle] = false;
						break;
						case SDL_BUTTON_RIGHT:
							ui.input.down[MouseButton.Right ] = false;
						break;
						default:
					}
					break;
				case SDL_MOUSEMOTION:
					ui.input.mousePos = Vec2(event.motion.x, event.motion.y);
					ui.input.delta = Vec2(event.motion.xrel, event.motion.yrel);
					ui.input.down[MouseButton.Left  ] = (event.motion.state & SDL_BUTTON_LMASK) != 0;
					ui.input.down[MouseButton.Middle] = (event.motion.state & SDL_BUTTON_MMASK) != 0;
					ui.input.down[MouseButton.Right ] = (event.motion.state & SDL_BUTTON_RMASK) != 0;
					break;
				case SDL_MOUSEWHEEL:
					break;
				default:
				}
			}
		}

		while (SDL_PollEvent(&event))
		{
			switch (event.type)
			{
			case SDL_QUIT:
				return 0;
			case SDL_KEYDOWN:
				bool mod_pressed = (event.key.keysym.mod & KMOD_SHIFT) == 0;
				switch (event.key.keysym.sym)
				{
				case SDLK_q:
					ui.w1.visible = !ui.w1.visible;
					break;
				case SDLK_a:
					ui.w1.height = ui.w1.height + (mod_pressed ? -growth : growth);
					break;
				case SDLK_z:
					ui.w1.width = ui.w1.width + (mod_pressed ? -growth : growth);
					break;
				case SDLK_w:
					ui.w2.visible = !ui.w2.visible;
					break;
				case SDLK_s:
					ui.w2.height = ui.w2.height + (mod_pressed ? -growth : growth);
					break;
				case SDLK_x:
					ui.w2.width = ui.w2.width + (mod_pressed ? -growth : growth);
					break;
				case SDLK_e:
					ui.w3.visible = !ui.w3.visible;
					break;
				case SDLK_d:
					ui.w3.height = ui.w3.height + (mod_pressed ? -growth : growth);
					break;
				case SDLK_c:
					ui.w3.width = ui.w3.width + (mod_pressed ? -growth : growth);
					break;
				default:
				}
				break;
			default:
			}
		}

		ui.clear;
		ui.layout_invalidated = false;
		ui.draw;
		if (ui.layout_invalidated)
		{
			SDL_Log("Layout invalidated: %d\n", ui.layout_tick);
			ui.layout_tick++;
			ui.clear;
			ui.layout_invalidated = false;
			ui.draw;
			if (ui.layout_invalidated)
				SDL_Log("DOUBLE INVALIDATION BUG: %d\n", ui.layout_tick);
		}
		ui.layout_tick++;
		
		backend.setColor(Color(0x00, 0x00, 0x00, 0xFF));
		backend.clear;
		ui.commit(backend);
		backend.present;

		window.swapBuffers();
	}
}