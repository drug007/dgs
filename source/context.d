module dgs.context;

import std.algorithm : min, max;
import std.container : Array;

import dgs.color : Color;
import dgs.math : Vec2, BBox2;
import dgs.cmdbuffer : DrawCmdBuffer;
import dgs.layoutbox : LayoutBox;
import dgs.backend : Backend;

enum MouseButton { Left, Middle, Right, }

struct Input
{
	import std.traits : EnumMembers;

	Vec2 mousePos, delta;
	bool[EnumMembers!MouseButton.length] down;
}

class Context
{
	LayoutBox[uint] layout_boxes;
	Array!LayoutBox layout_stack;
	LayoutBox box;
	int layout_tick;
	bool layout_invalidated;
	protected DrawCmdBuffer _drawlist;
	Input input;

	this()
	{
		layout_tick = 1;
	}

	LayoutBox getLayoutBox(uint id)
	{
		auto b = layout_boxes.get(id, null);
		if (!b)
			b = layout_boxes[id] = new LayoutBox(this, id);

		return b;
	}

	void beginLayoutBox(uint id)
	{
		auto new_box = getLayoutBox(id);
		if (box)
			box.children.insertBack(new_box);

		layout_stack.insertBack(box);
		box = new_box;
		if (box.last_assigned != layout_tick)
			box.assigned = BBox2();
	}

	void endLayoutBox()
	{
		_drawlist.strokeRect(box.assigned, Color(0xFF, 0xFF, 0xFF, 0xFF), 10.0f, 1.0f);
		box = layout_stack[layout_stack.length - 1];
		layout_stack.removeBack();
	}

	void beginHBox(uint id)
	{
		import std.algorithm;

		beginLayoutBox(id);
		auto d = distributor(box.assigned.min.x, box.assigned.max.x, box.children[].map!"a.desired.x");
		foreach (child; box.children)
		{
			auto x1 = cast(int) d.front[0];
			auto x2 = cast(int) d.front[1];
			import std.math : isNaN;
			// if child has no desired size then use the whole parent size
			auto desired_y = child.desired.y.isNaN ? (box.assigned.max.y - box.assigned.min.y) : child.desired.y;
			auto y1 = max(box.assigned.min.y, box.assigned.max.y - desired_y);
			auto y2 = box.assigned.max.y;
			child.assigned = BBox2(Vec2(x1, y1), Vec2(x2, y2));
			d.popFront;
		}
		box.children.clear();
	}

	void endHBox()
	{
		Vec2 desired;
		foreach (child; box.children)
		{
			desired.x += child.desired.x;
			desired.y = max(desired.y, child.desired.y);
		}
		box.desired = desired;
		endLayoutBox();
	}

	unittest
	{
		import std.algorithm : map;
		import std.stdio;
		double lo, hi, preferred;
		Vec2[] children;

		lo = 0;
		hi = 100;
		preferred = 50;

		distributor(lo, hi, children.map!"a.x").writeln;

		children ~= Vec2(30);
		distributorBackward(lo, hi, children.map!"a.x").writeln;
		distributor(lo, hi, children.map!"a.x").writeln;
		children ~= Vec2(30);
		distributorBackward(lo, hi, children.map!"a.x").writeln;
		distributor(lo, hi, children.map!"a.x").writeln;
		children ~= Vec2(30);
		distributorBackward(lo, hi, children.map!"a.x").writeln;
	}

	void beginVBox(uint id)
	{
		import std.algorithm;

		beginLayoutBox(id);
		auto d = distributor(box.assigned.min.y, box.assigned.max.y, box.children[].map!"a.desired.y");
		foreach (child; box.children)
		{
			auto y1 = cast(int) d.front[0];
			auto y2 = cast(int) d.front[1];
			auto x1 = box.assigned.min.x;
			import std.math : isNaN;
			// if child has no desired size then use the whole parent size
			auto desired_x = child.desired.x.isNaN ? (box.assigned.max.x - box.assigned.min.x) : child.desired.x;
			auto x2 = min(box.assigned.max.x, box.assigned.min.x + desired_x);
			child.assigned = BBox2(Vec2(x1, y1), Vec2(x2, y2));
			d.popFront;
		}
		box.children.clear();
	}

	void endVBox()
	{
		Vec2 desired;
		foreach (child; box.children)
		{
			desired.y = max(desired.y, child.desired.y);
			desired.x += child.desired.x;
		}
		box.desired = desired;
		endLayoutBox();
	}

	void clear()
	{
		_drawlist.clear;
	}

	void commit(Backend backend)
	{
		_drawlist.commit(backend);
	}

	void drawFillRect(BBox2 r, Color c)
	{
		_drawlist.fillRect(r, c, 10.0);
	}
}

auto distributor(Children)(double l, double h, Children children)
{
	return Distributor!Children(l, h, children);
}

auto distributorBackward(Children)(double l, double h, Children children)
{
	return DistributorBackward!Children(l, h, children);
}

struct Distributor(Children)
{
    import std.algorithm, std.typecons;
    double value, lo, hi, preferred, spacing;
    Children children;

    this(double l, double h, Children ch)
    {
        value = l;
        lo = l;
        hi = h;
        preferred = ch.sum;
        children = ch;
        auto excess = max(0, (hi - lo) - preferred);
        spacing = children.length > 1 ? excess / (children.length - 1) : 0;
    }

    auto front()
    {
        return tuple(value, min(value + children.front, hi));
    }
    
    void popFront()
    {
        import std.array;
        value = min(hi, value + children.front + spacing);
        children.popFront;
    }
    
    bool empty()
    {
        import std.array;
        return children.empty;
    }
}

struct DistributorBackward(Children)
{
    import std.algorithm, std.typecons;
    double value, lo, hi, preferred, spacing;
    Children children;

    this(double l, double h, Children ch)
    {
        value = h;
        lo = l;
        hi = h;
        preferred = ch.sum;
        children = ch;
        auto excess = max(0, (hi - lo) - preferred);
        spacing = children.length > 1 ? excess / (children.length - 1) : 0;
    }

    auto front()
    {
        return tuple(min(value - children.back, hi), value);
    }
    
    void popFront()
    {
        import std.array;
        value = max(lo, value - children.back - spacing);
        children.popBack;
    }
    
    bool empty()
    {
        import std.array;
        return children.empty;
    }
}