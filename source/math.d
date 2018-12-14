module dgs.math;

import gfm.math : vec2f, box2f;

alias Vec2 = vec2f;
alias BBox2 = box2f;

struct Rect2
{
	this(Vec2 pos, Vec2 size)
	{
		this.pos  = pos;
		this.size = size;
	}

	Vec2 pos;
	Vec2 size;
}