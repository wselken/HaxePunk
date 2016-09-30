package haxepunk;

import flash.geom.Point;


class Camera extends Point
{
	public var scale:Float;
	public var scaleX:Float;
	public var scaleY:Float;

	public var pixelSnap:Bool = false;
	

	public var fullScaleX(get, never):Float;
	inline function get_fullScaleX() { return scale * scaleX * HXP.screen.fullScaleX; }

	public var fullScaleY(get, never):Float;
	inline function get_fullScaleY() { return scale * scaleY * HXP.screen.fullScaleY; }
}
