package haxepunk.graphics.atlas;

@:enum
abstract BlendMode(Int) from Int to Int
{
	var Add = 0;
	var Multiply = 9;
	var Normal = 10;
	var Screen = 12;
	var Subtract = 14;
}
