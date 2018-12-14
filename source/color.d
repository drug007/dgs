module dgs.color;

struct Color
{
	this(ubyte r, ubyte g, ubyte b, ubyte a)
	{
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
	}

	ubyte r;
	ubyte g;
	ubyte b;
	ubyte a = 255;
}
