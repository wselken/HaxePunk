package haxepunk.graphics;

import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import haxepunk.HXP;
import haxepunk.Camera;
import haxepunk.RenderMode;
import haxepunk.Graphic;
import haxepunk.graphics.Image;
import haxepunk.utils.Color;

/**
 * Automatic scaling 9-slice graphic.
 */
class NineSlice extends Graphic
{
	public var width:Float;
	public var height:Float;
	public var clip:Rectangle;
	public var smooth:Bool = false;

	public var color:Color = 0xFFFFFF;
	public var alpha:Float = 1;

	var source:ImageType;

	/**
	 * Constructor.
	 * @param	source Source image
	 * @param	leftWidth Distance from left side of the source image used for 9-Slicking the image
	 * @param	rightWidth Distance from right side of the source image used for 9-Slicking the image
	 * @param	topHeight Distance from top side of the source image used for 9-Slicking the image
	 * @param	bottomHeight Distance from bottom side of the source image used for 9-Slicking the image
	 */
	public function new(source:ImageType, leftWidth:Int = 0, rightWidth:Int = 0, topHeight:Int = 0, bottomHeight:Int = 0, ?clip:Rectangle)
	{
		super();
		this.source = source;

		var w = source.width,
			h = source.height;

		topL = getSegment(source, 0, 0, leftWidth, topHeight);
		topC = getSegment(source, leftWidth, 0, w - leftWidth - rightWidth, topHeight);
		topR = getSegment(source, w - rightWidth, 0, rightWidth, topHeight);
		medL = getSegment(source, 0, topHeight, leftWidth, h - topHeight - bottomHeight);
		medC = getSegment(source, leftWidth, topHeight, w - leftWidth - rightWidth, h - topHeight - bottomHeight);
		medR = getSegment(source, w - rightWidth, topHeight, rightWidth, h - topHeight - bottomHeight);
		botL = getSegment(source, 0, h - bottomHeight, leftWidth, bottomHeight);
		botC = getSegment(source, leftWidth, h - bottomHeight, w - leftWidth - rightWidth, bottomHeight);
		botR = getSegment(source, w - rightWidth, h - bottomHeight, rightWidth, bottomHeight);
		_sliceRect.setTo(leftWidth, topHeight, w - rightWidth, h - bottomHeight);

		width = w;
		height = h;

		this.clip = clip;

		blit = HXP.renderMode == RenderMode.BUFFER;
	}

	inline function getSegment(source:ImageType, x:Int, y:Int, width:Int, height:Int):Image
	{
		_rect.setTo(x, y, width, height);
		var segment = new Image(source, _rect);
		segment.originX = segment.originY = 0;
		return segment;
	}

	/**
	 * Updates the Image. Make sure to set graphic = output image afterwards.
	 * @param	width	New width
	 * @param	height	New height
	 * @return
	 */
	inline function renderSegments(renderFunc:Image -> Void, camera:Camera)
	{
		var x0 = camera.floorX(this.x),
			y0 = camera.floorY(this.y);
		var w = Std.int(width * camera.fullScaleX) / camera.fullScaleX,
			h = Std.int(height * camera.fullScaleY) / camera.fullScaleY;
		var leftWidth:Float = Std.int(Math.min(_sliceRect.left, w / 2)) / camera.fullScaleX,
			rightWidth:Float = Math.max(0, Math.min(Std.int((source.width - _sliceRect.width)) / camera.fullScaleX, w - leftWidth)),
			centerWidth:Float = w - leftWidth - rightWidth;
		var topHeight:Float = Std.int(Math.min(_sliceRect.top, h / 2)) / camera.fullScaleY,
			bottomHeight:Float = Math.max(0, Math.min(Std.int((source.height - _sliceRect.height)) / camera.fullScaleY, h - topHeight)),
			centerHeight:Float = h - topHeight - bottomHeight;

		var leftX = 0, centerX = leftX + leftWidth, rightX = centerX + centerWidth,
			topY = 0, centerY = topY + topHeight, bottomY = centerY + centerHeight;

		drawSegment(renderFunc, topL, leftX, topY, leftWidth, topHeight, camera);
		drawSegment(renderFunc, topC, centerX, topY, centerWidth, topHeight, camera);
		drawSegment(renderFunc, topR, rightX, topY, rightWidth, topHeight, camera);
		drawSegment(renderFunc, medL, leftX, centerY, leftWidth, centerHeight, camera);
		drawSegment(renderFunc, medC, centerX, centerY, centerWidth, centerHeight, camera);
		drawSegment(renderFunc, medR, rightX, centerY, rightWidth, centerHeight, camera);
		drawSegment(renderFunc, botL, leftX, bottomY, leftWidth, bottomHeight, camera);
		drawSegment(renderFunc, botC, centerX, bottomY, centerWidth, bottomHeight, camera);
		drawSegment(renderFunc, botR, rightX, bottomY, rightWidth, bottomHeight, camera);
	}

	inline function drawSegment(renderFunc:Image -> Void, segment:Image, x:Float, y:Float, width:Float, height:Float, camera:Camera)
	{
		var x0 = camera.floorX(this.x),
			y0 = camera.floorY(this.y);

		if (clip != null)
		{
			width = Math.min(clip.right - x, width);
			x = Math.max(clip.x, x);
			height = Math.min(clip.bottom - y, height);
			y = Math.max(clip.y, y);

			segment.visible = width > 0 && height > 0;
		}

		x += x0;
		y += y0;

		if (segment != null && segment.visible)
		{
			segment.x = x;
			segment.y = y;
			segment.scaleX = width / segment.width;
			segment.scaleY = height / segment.height;
			segment.smooth = this.smooth;
			segment.alpha = this.alpha;
			segment.color = this.color;
			renderFunc(segment);
		}
	}

	override public function render(target:BitmapData, point:Point, camera:Camera)
	{
		renderSegments(function(segment:Image) segment.render(target, point, camera), camera);
	}

	override public function renderAtlas(layer:Int, point:Point, camera:Camera)
	{
		renderSegments(function(segment:Image) segment.renderAtlas(layer, point, camera), camera);
	}

	var topL:Image;
	var topC:Image;
	var topR:Image;
	var medL:Image;
	var medC:Image;
	var medR:Image;
	var botL:Image;
	var botC:Image;
	var botR:Image;

	var _sliceRect:Rectangle = new Rectangle();
	var _rect:Rectangle = new Rectangle();
	var _matrix:Matrix = new Matrix();
}
