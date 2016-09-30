package haxepunk;

import flash.geom.Point;


class Camera extends Point
{
	public var scale:Float = 1;
	public var scaleX:Float = 1;
	public var scaleY:Float = 1;
	public var screenX:Float = 0;
	public var screenY:Float = 0;

	public var pixelSnap:Bool = false;

	public var fullScaleX(get, never):Float;
	inline function get_fullScaleX() { return scale * scaleX * HXP.screen.fullScaleX; }

	public var fullScaleY(get, never):Float;
	inline function get_fullScaleY() { return scale * scaleY * HXP.screen.fullScaleY; }
}
