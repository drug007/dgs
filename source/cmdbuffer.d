module dgs.cmdbuffer;

import dgs.color : Color;
import dgs.math : Vec2, BBox2, Rect2;

struct CmdScissor
{
    short x, y;
    ushort w, h;
}

struct CmdLine
{
    ushort line_thickness;
    Vec2 begin;
    Vec2 end;
    Color color;
}

// struct Cmd curve
// {
//     ushort line_thickness;
//     struct nk_Vec2 begin;
//     struct nk_Vec2 end;
//     struct nk_Vec2 ctrl[2];
//     struct nk_color color;
// }

struct CmdRect
{
	Vec2 pos;
	Vec2 size;
	Color color;
	float rounding;
	float line_thickness;
}

struct CmdRectFilled
{
	Vec2 pos;
	Vec2 size;
	Color color;
	float rounding;
}

// struct Cmd rect_multi_color
// {
//     short x, y;
//     ushort w, h;
//     struct nk_color left;
//     struct nk_color top;
//     struct nk_color bottom;
//     struct nk_color right;
// }

// struct Cmd triangle
// {
//     ushort line_thickness;
//     struct nk_Vec2 a;
//     struct nk_Vec2 b;
//     struct nk_Vec2 c;
//     struct nk_color color;
// }

// struct Cmd triangle_filled
// {
//     struct nk_Vec2 a;
//     struct nk_Vec2 b;
//     struct nk_Vec2 c;
//     struct nk_color color;
// }

// struct Cmd circle
// {
//     short x, y;
//     ushort line_thickness;
//     ushort w, h;
//     struct nk_color color;
// }

// struct Cmd circle_filled
// {
//     short x, y;
//     ushort w, h;
//     struct nk_color color;
// }

// struct Cmd arc
// {
//     short cx, cy;
//     ushort r;
//     ushort line_thickness;
//     float a[2];
//     struct nk_color color;
// }

// struct Cmd arc_filled
// {
//     short cx, cy;
//     ushort r;
//     float a[2];
//     struct nk_color color;
// }

// struct Cmd polygon
// {
//     struct nk_color color;
//     ushort line_thickness;
//     ushort point_count;
//     struct nk_Vec2 points[1];
// }

// struct Cmd polygon_filled
// {
//     struct nk_color color;
//     ushort point_count;
//     struct nk_Vec2 points[1];
// }

// struct Cmd polyline
// {
//     struct nk_color color;
//     ushort line_thickness;
//     ushort point_count;
//     struct nk_Vec2 points[1];
// }

// struct Cmd image
// {
//     short x, y;
//     ushort w, h;
//     struct nk_image img;
//     struct nk_color col;
// }

// typedef void (*nk_Cmd_custom_callback)(void *canvas, short x,short y,
//     ushort w, ushort h, nk_handle callback_data);
// struct Cmd custom
// {
//     short x, y;
//     ushort w, h;
//     nk_handle callback_data;
//     nk_Cmd_custom_callback callback;
// }

// struct Cmd text
// {
//     const struct nk_user_font *font;
//     struct nk_color background;
//     struct nk_color foreground;
//     short x, y;
//     ushort w, h;
//     float height;
//     int length;
//     char string[1];
// }

// enum nk_Cmd_clipping {
//     NK_CLIPPING_OFF = nk_false,
//     NK_CLIPPING_ON = nk_true
// }

// struct Cmd buffer
// {
//     struct nk_buffer *base;
//     struct nk_rect clip;
//     int use_clipping;
//     nk_handle userdata;
//     nk_size begin, end, last;
// }

import sumtype;
alias DrawCommand = SumType!(CmdScissor, CmdLine, CmdRectFilled, CmdRect);

struct DrawCmdBuffer
{
	import dgs.backend : Backend;
	import std.container : Array;
	Array!DrawCommand _cmd_buffer;

	void clear()
	{
		_cmd_buffer.clear;
	}

	void fillRect(BBox2 bbox, Color color, float rounding)
	{
		Vec2 pos = bbox.min, size = bbox.max - bbox.min;
		DrawCommand cmd = CmdRectFilled(pos, size, color, rounding);
		_cmd_buffer.insertBack(cmd);
	}

	void strokeRect(BBox2 bbox, Color color, float rounding, float thickness)
	{
		Vec2 pos = bbox.min, size = bbox.max - bbox.min;
		DrawCommand cmd = CmdRect(pos, size, color, rounding, thickness);
		_cmd_buffer.insertBack(cmd);
	}

	void commit(Backend backend)
	{
		foreach (ref cmd; _cmd_buffer)
		{
			cmd.match!(
				(CmdRectFilled cmd) {
					backend.setColor(cmd.color);
					backend.fillRect(Rect2(cmd.pos, cmd.size), cmd.rounding);
				},
				(CmdRect cmd) {
					backend.setColor(cmd.color);
					backend.strokeRect(Rect2(cmd.pos, cmd.size), cmd.rounding, cmd.line_thickness);
				},
				(CmdScissor cmd) {},
				(CmdLine cmd) {},
			);
		}
	}
}
