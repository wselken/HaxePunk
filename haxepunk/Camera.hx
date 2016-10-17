package haxepunk;

import flash.display.BitmapData;
import flash.display.Sprite;
import flash.geom.Point;
import flash.geom.Rectangle;
import haxepunk.graphics.atlas.AtlasData;
import haxepunk.graphics.atlas.CameraSprite;
import haxepunk.utils.Color;

/**
 * Controls camera position and zoom.
 * @since	4.0.0
 */
@:allow(haxepunk.Scene)
class Camera extends Point
{
	public var bgColor:Color;
	public var bgAlpha:Float = 0;

	public var scene:Scene;

	/**
	 * Camera scale.
	 */
	public var scale:Float = 1;
	public var scaleX:Float = 1;
	public var scaleY:Float = 1;

	/**
	 * Camera display area.
	 */
	public var displayX:Int = 0;
	public var displayY:Int = 0;
	public var width(get, set):Int;
	inline function get_width() return (_width == 0 ? HXP.width : _width);
	inline function set_width(w:Int) return _width = w;
	public var height(get, set):Int;
	inline function get_height() return (_height == 0 ? HXP.height : _height);
	inline function set_height(h:Int) return _height = h;

	public var visible:Bool = true;

	/**
	 * Sprite used to store layer sprites when RenderMode.HARDWARE is set.
	 */
	public var sprite(default, null):CameraSprite;

	/**
	 * Buffer used for this camera when RenderMode.BUFFER is set.
	 */
	public var buffer(default, null):BitmapData;

	public var fullScaleX(get, never):Float;
	inline function get_fullScaleX() return scale * scaleX * HXP.screen.fullScaleX;

	public var fullScaleY(get, never):Float;
	inline function get_fullScaleY() return scale * scaleY * HXP.screen.fullScaleY;

	/**
	 * @param	displayX	Camera display area's starting X coordinate, in game coordinates.
	 * @param	displayY	Camera display area's starting Y coordinate, in game coordinates.
	 * @param	width		Camera display area's width. 0 to fill the visible area of the screen.
	 * @param	height		Camera display area's height. 0 to fill the visible area of the screen.
	 * @param	scale		Camera's initial scale.
	 */
	public function new(scene:Scene, displayX:Int = 0, displayY:Int = 0, width:Int = 0, height:Int = 0, scale:Float = 1)
	{
		super(0, 0);

		this.scene = scene;
		this.displayX = displayX;
		this.displayY = displayY;
		_width = width;
		_height = height;
		this.scale = scale;

		if (HXP.renderMode == RenderMode.HARDWARE)
		{
			sprite = new CameraSprite(this);
		}
		else
		{
			buffer = new BitmapData(HXP.width, HXP.height);
		}

		renderList = new RenderList();
	}

	public function resize() {}

	function render(renderCursor:Bool = false)
	{
		sprite.startFrame();
		if (!visible) return;

		var sx = HXP.screen.fullScaleX,
			sy = HXP.screen.fullScaleY;
		sprite.x = displayX * sx;
		sprite.y = displayY * sy;
		_scrollRect.width = width * sx;
		_scrollRect.height = height * sy;
		sprite.scrollRect = _scrollRect;

		if (HXP.renderMode == RenderMode.HARDWARE)
			AtlasData.startScene(this);

		// render the entities in order of depth
		for (layer in renderList.layerList)
		{
			if (!scene.layerVisible(layer)) continue;
			for (e in renderList.layers.get(layer))
			{
				if (e.visible) e.render(this);
			}
		}

		if (renderCursor && HXP.cursor != null && HXP.cursor.visible)
		{
			HXP.cursor.render(this);
		}
	}

	/**
	 * X position of the mouse in the camera.
	 */
	public var mouseX(get, null):Int;
	private inline function get_mouseX():Int
	{
		return Std.int(HXP.screen.mouseX - displayX + x);
	}

	/**
	 * Y position of the mouse in the camera.
	 */
	public var mouseY(get, null):Int;
	private inline function get_mouseY():Int
	{
		return Std.int(HXP.screen.mouseY - displayY + y);
	}

	var _width:Int = 0;
	var _height:Int = 0;
	var renderList:RenderList;
	var _scrollRect:Rectangle = new Rectangle();
}
