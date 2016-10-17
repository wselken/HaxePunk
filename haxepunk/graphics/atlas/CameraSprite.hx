package haxepunk.graphics.atlas;

import flash.display.BitmapData;
import flash.geom.Rectangle;
import openfl.display.OpenGLView;

@:access(haxepunk.graphics.atlas.DrawCommand)
class CameraSprite extends OpenGLView
{
	public function new(camera:Camera)
	{
		super();
		this.camera = camera;
		render = renderCamera;
	}

	public function startFrame()
	{
		if (draw != null) draw.recycle();
		draw = last = null;
	}

	public function getDrawCommand(texture:BitmapData, smooth:Bool, blend:BlendMode)
	{
		if (last != null && last.texture == texture && last.smooth == smooth && last.blend == blend)
		{
			return last;
		}
		var command = DrawCommand.create(texture, smooth, blend);
		if (last == null)
		{
			draw = last = command;
		}
		else
		{
			last._next = command;
			last = command;
		}
		return command;
	}

	function renderCamera(rect:Rectangle)
	{
		var currentDraw:DrawCommand = draw;
		while (currentDraw != null)
		{
			Renderer.render(currentDraw, camera, rect);
			currentDraw = currentDraw._next;
		}
	}

	var camera:Camera;
	var draw:DrawCommand;
	var last:DrawCommand;
}
