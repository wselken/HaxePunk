package com.haxepunk.graphics;

import flash.display.BitmapData;
import flash.display.Graphics;
import flash.geom.Point;
import flash.geom.Rectangle;
import com.haxepunk.HXP;
import com.haxepunk.graphics.atlas.AtlasRegion;

/**
 * Special Image object that can display blocks of tiles.
 */
class TiledImage extends Image
{
	/**
	 * Constructs the TiledImage.
	 * @param	texture		Source texture.
	 * @param	width		The width of the image (the texture will be drawn to fill this area).
	 * @param	height		The height of the image (the texture will be drawn to fill this area).
	 * @param	clipRect	An optional area of the source texture to use (eg. a tile from a tileset).
	 */
	public function new(texture:Dynamic, width:Int = 0, height:Int = 0, clipRect:Rectangle = null)
	{
		_graphics = HXP.sprite.graphics;
		_offsetX = _offsetY = 0;
		_width = width;
		_height = height;
		super(texture, clipRect);
	}

	/** @private Creates the buffer. */
	override private function createBuffer()
	{
		if (_width == 0) _width = Std.int(_sourceRect.width);
		if (_height == 0) _height = Std.int(_sourceRect.height);
		_buffer = HXP.createBitmap(_width, _height, true);
		_bufferRect = _buffer.rect;
	}

	/** @private Updates the buffer. */
	override public function updateBuffer(clearBefore:Bool = false)
	{
		if (blit)
		{
			if (_source == null) return;
			if (_texture == null)
			{
				_texture = HXP.createBitmap(Std.int(_sourceRect.width), Std.int(_sourceRect.height), true);
				_texture.copyPixels(_source, _sourceRect, HXP.zero);
			}
			_buffer.fillRect(_bufferRect, HXP.blackColor);
			_graphics.clear();
			if (_offsetX != 0 || _offsetY != 0)
			{
				HXP.matrix.identity();
				HXP.matrix.tx = Math.round(_offsetX);
				HXP.matrix.ty = Math.round(_offsetY);
				_graphics.beginBitmapFill(_texture, HXP.matrix);
			}
			else _graphics.beginBitmapFill(_texture);
			_graphics.drawRect(0, 0, _width, _height);
			_buffer.draw(HXP.sprite, null, _tint);
		}
		else
		{
			var rect = HXP.rect;
			// remainders
			var right = _width - offsetX % _region.width;
			var bottom = _height - offsetY % _region.height;

			if (right != 0)
			{
				// x = 0 and y = 0 inferred
				rect.width = right;
				rect.height = _region.height;
				_rightRegion = _region.clip(rect);
			}

			if (bottom != 0)
			{
				// x = 0 and y = 0 inferred
				rect.width = _region.width;
				rect.height = bottom;
				_bottomRegion = _region.clip(rect);
			}

			if (offsetX != 0)
			{
				rect.x = _region.width - offsetX;
				rect.y = 0;
				rect.width = offsetX;
				rect.height = _region.height;
				_leftRegion = _region.clip(rect);
			}

			if (offsetY != 0)
			{
				rect.x = 0;
				rect.y = _region.height - offsetY;
				rect.width = _region.width;
				rect.height = offsetY;
				_topRegion = _region.clip(rect);

				if (right != 0)
				{
					rect.x = 0;
					rect.y = 0;
					rect.width = right;
					rect.height = _topRegion.height;
					_rightRegion = _topRegion.clip(rect);
				}

				if (offsetX != 0)
				{
					rect.x = _topRegion.width - offsetX;
					rect.y = 0;
					rect.width = offsetX;
					rect.height = _topRegion.height;
					_topLeftRegion = _topRegion.clip(rect);
				}
			}
		}
	}

	/** Renders the image. */
	override public function renderAtlas(layer:Int, point:Point, camera:Point)
	{
		// determine drawing location
		_point.x = point.x + x - originX - camera.x * scrollX;
		_point.y = point.y + y - originY - camera.y * scrollY;

		// TODO: properly handle flipped tiled spritemaps
		if (_flipped) _point.x += _sourceRect.width;
		var fsx = HXP.screen.fullScaleX,
			fsy = HXP.screen.fullScaleY,
			sx = fsx * scale * scaleX * (_flipped ? -1 : 1),
			sy = fsy * scale * scaleY,
			y = 0.0;

		if (offsetY != 0)
		{
			renderAtlasRow(_topLeftRegion, _topRegion, _topRightRegion,
				point.x, _point.y + y, sx, sy, fsx, fsy,
				angle, layer);
			y += _topRegion.height;
		}

		while (y + _region.height < _height)
		{
			renderAtlasRow(_leftRegion, _region, _rightRegion,
				point.x, _point.y + y, sx, sy, fsx, fsy,
				angle, layer);
			y += _region.height;
		}

		if (y < _height)
		{
			renderAtlasRow(_bottomLeftRegion, _bottomRegion, _bottomRightRegion,
				point.x, _point.y + y, sx, sy, fsx, fsy,
				angle, layer);
		}
	}

	/**
	 * Renders a row with specific clipped regions
	 * @param l left region for offsetX
	 * @param m middle region, always drawn
	 * @param r right region for widths that don't match than the tile width
	 * @param px the x axis to start drawing
	 * @param py the y axis to start drawing
	 * @param sx the x axis object scale
	 * @param sy the y axis object scale
	 * @param fsx x axis full screen scale
	 * @param fsy y-axis full screen scale
	 * @param angle the angle to rotate
	 * @param layer the layer to render on
	 */
	private inline function renderAtlasRow(l:AtlasRegion, m:AtlasRegion, r:AtlasRegion,
		px:Float, py:Float, sx:Float, sy:Float, fsx:Float, fsy:Float,
		angle:Float, layer:Int)
	{
		var x:Float = 0;

		if (offsetX != 0)
		{
			l.draw(Math.floor((px + x) * fsx), Math.floor(py * fsy),
					layer, sx, sy, angle,
					_red, _green, _blue, _alpha);
			x += l.width;
		}

		while (x + m.width < _width)
		{
			m.draw(Math.floor((px + x) * fsx), Math.floor(py * fsy),
				layer, sx, sy, angle,
				_red, _green, _blue, _alpha);
			x += m.width;
		}

		if (x < _width)
		{
			r.draw(Math.floor((px + x) * fsx), Math.floor(py * fsy),
				layer, sx, sy, angle,
				_red, _green, _blue, _alpha);
		}
	}

	/**
	 * The x-offset of the texture.
	 */
	public var offsetX(get, set):Float;
	private function get_offsetX():Float { return _offsetX; }
	private function set_offsetX(value:Float):Float
	{
		if (_offsetX == value) return value;
		_offsetX = value;
		updateBuffer();
		return _offsetX;
	}

	/**
	 * The y-offset of the texture.
	 */
	public var offsetY(get, set):Float;
	private function get_offsetY():Float { return _offsetY; }
	private function set_offsetY(value:Float):Float
	{
		if (_offsetY == value) return value;
		_offsetY = value;
		updateBuffer();
		return _offsetY;
	}

	/**
	 * Sets the texture offset.
	 * @param	x		The x-offset.
	 * @param	y		The y-offset.
	 */
	public function setOffset(x:Float, y:Float)
	{
		if (_offsetX == x && _offsetY == y) return;
		_offsetX = x;
		_offsetY = y;
		updateBuffer();
	}

	// Drawing information.
	private var _graphics:Graphics;
	private var _texture:BitmapData;
	private var _width:Int;
	private var _height:Int;
	private var _offsetX:Float;
	private var _offsetY:Float;

	private var _topLeftRegion:AtlasRegion;
	private var _topRegion:AtlasRegion;
	private var _topRightRegion:AtlasRegion;
	private var _leftRegion:AtlasRegion;
	private var _rightRegion:AtlasRegion;
	private var _bottomLeftRegion:AtlasRegion;
	private var _bottomRegion:AtlasRegion;
	private var _bottomRightRegion:AtlasRegion;
}
