module dgs.layoutbox;

import dgs.context : Context;

class LayoutBox
{
	import std.container : Array;
	import dgs.math : Vec2, BBox2;

	this(Context parent, uint id)
	{
		this._parent = parent;
		this._id = id;
		this.last_assigned = -1;
		this._last_desired  = -1;
	}


	Array!LayoutBox children;
	int last_assigned;
	private
	{
		Context _parent;
		BBox2   _assigned;
		uint    _id;
		Vec2    _desired;
		int     _last_desired;
	}

	auto id() { return _id; }

	Vec2 desired()
	{
		_last_desired = _parent.layout_tick;
		return _desired;
	}

	void desired(Vec2 v)
	{
		if (v != _desired)
		{
			_desired = v;
			// if during current layouting `desired` was called once again
			// with other arguments then it means that layout has to be recalculated
			if (_last_desired == _parent.layout_tick)
				_parent.layout_invalidated = true;
		}
	}

	BBox2 assigned()
	{
		return _assigned;
	}

	void assigned(BBox2 r)
	{
		last_assigned = _parent.layout_tick;
		_assigned = r;
	}
}
