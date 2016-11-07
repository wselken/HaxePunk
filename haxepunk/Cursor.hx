package haxepunk;

import haxepunk.Graphic;
import haxepunk.graphics.Image;
import haxepunk.input.Input;

class Cursor extends Entity
{
	/**
	 * Constructor.
	 * @param	graphic		Graphic to assign to the Entity.
	 * @param	mask		Mask to assign to the Entity.
	 */
	override public function new(image:ImageType)
	{
		var img:Image = new Image(image);
		img.smooth = true;
		img.scrollX = img.scrollY = 0;
		super(0, 0, img);
	}

	/**
	 * Updates the entitiy coordinates to match the cursor.
	 */
	override public function update()
	{
		super.update();
		x = Input.mouseX;
		y = Input.mouseY;
		var img:Image = cast graphic;
		if (img != null)
		{
			// scale to 1
			img.scaleX = 1 / HXP.screen.fullScaleX;
			img.scaleY = 1 / HXP.screen.fullScaleY;
		}
	}
}
