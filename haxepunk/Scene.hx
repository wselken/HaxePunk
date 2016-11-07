package haxepunk;

import haxe.ds.IntMap;
import flash.display.Sprite;
import flash.geom.Point;
import haxepunk.ds.Dll;
import haxepunk.graphics.atlas.AtlasData;
import haxepunk.utils.MathUtil;

/**
 * Updated by `Engine`, main game container that holds all currently active Entities.
 * Useful for organization, eg. "Menu", "Level1", etc.
 */
@:allow(haxepunk.Entity)
class Scene extends Tweener
{
	/**
	 * If the render() loop is performed.
	 */
	public var visible:Bool;

	/**
	 * If true, Scenes behind this Scene in the stack will still be rendered
	 * (until the first non-transparent Scene is hit.)
	 * @since	2.6.0
	 */
	public var transparent:Bool = false;

	/**
	 * The scene's default camera. Entities with a null `cameras` field will be
	 * rendered to this camera.
	 */
	public var camera(default, set):Camera;
	inline function set_camera(camera:Camera)
	{
		_defaultCameras = [camera];
		return this.camera = camera;
	}

	/**
	 * All cameras available in the scene.
	 */
	public var cameras(default, set):Array<Camera>;
	inline function set_cameras(c:Array<Camera>)
	{
		if (cameras != null)
		{
			for (camera in cameras)
			{
				removeCamera(camera);
			}
		}
		else
		{
			cameras = new Array();
		}
		for (camera in c)
		{
			addCamera(camera);
		}
		return c;
	}

	public var width:Int = 0;
	public var height:Int = 0;

	/**
	 * Constructor.
	 */
	public function new()
	{
		super();
		visible = true;
		camera = new Camera();
		sprite = new Sprite();
		cameras = new Array();

		_add = new Array();
		_remove = new Array();
		_recycle = new Array();

		_update = new Dll();
		_layerDisplay = new Map();
		_types = new Map();

		_classCount = new Map();
		_recycled = new Map();
		_entityNames = new Map();

		renderList = new RenderList();

		addCamera(camera);
	}

	/**
	 * Override this; called when Scene is switched to, and set to the currently active scene.
	 */
	public function begin() {}

	/**
	 * Override this; called when Scene is changed, and the active scene is no longer this.
	 */
	public function end() {}

	public function resize()
	{
		if (width != HXP.width || height != HXP.height)
		{
			width = HXP.width;
			height = HXP.height;
			for (e in _update)
			{
				e.resized();
			}
			for (camera in cameras)
			{
				camera.resized();
			}
		}
	}

	/**
	 * Override this, called when game gains focus
	 */
	public function focusGained() {}

	/**
	 * Override this, called when game loses focus
	 */
	public function focusLost() {}

	/**
	 * Performed by the game loop, updates all contained Entities.
	 * If you override this to give your Scene update code, remember
	 * to call super.update() or your Entities will not be updated.
	 */
	override public function update()
	{
		// update the entities
		for (e in _update)
		{
			if (e.active)
			{
				if (e.hasTween) e.updateTweens();
				e.update();
			}
			if (e.graphic != null && e.graphic.active) e.graphic.update();
		}
		for (camera in cameras)
		{
			camera.update();
		}

		// updates the cursor
		if (HXP.cursor != null && HXP.cursor.active)
		{
			HXP.cursor.update();
		}
	}

	/**
	 * Toggles the visibility of a layer
	 * @param layer the layer to show/hide
	 * @param show whether to show the layer (default: true)
	 */
	public inline function showLayer(layer:Int, show:Bool=true):Void
	{
		_layerDisplay.set(layer, show);
	}

	/**
	 * Checks if a layer is visible or not
	 */
	public inline function layerVisible(layer:Int):Bool
	{
		return !_layerDisplay.exists(layer) || _layerDisplay.get(layer);
	}

	/**
	 * Performed by the game loop, renders all contained Entities.
	 * If you override this to give your Scene render code, remember
	 * to call super.render() or your Entities will not be rendered.
	 */
	public function render()
	{
		for (camera in cameras)
		{
			camera.render();
		}
	}

	/**
	 * X position of the mouse in the Scene.
	 */
	public var mouseX(get, null):Int;
	private inline function get_mouseX():Int
	{
		return Std.int(HXP.screen.mouseX + camera.x);
	}

	/**
	 * Y position of the mouse in the scene.
	 */
	public var mouseY(get, null):Int;
	private inline function get_mouseY():Int
	{
		return Std.int(HXP.screen.mouseY + camera.y);
	}

	/**
	 * Sprite used to store layer sprites when RenderMode.HARDWARE is set.
	 */
	public var sprite(default, null):Sprite;

	/**
	 * Adds the Entity to the Scene at the end of the frame.
	 * @param	e		Entity object you want to add.
	 * @return	The added Entity object.
	 */
	public function add<E:Entity>(e:E):E
	{
		_add[_add.length] = e;
		// any of this entity's cameras should be added to the screen
		for (camera in e.cameras)
		{
			if (cameras.indexOf(camera) == -1)
			{
				addCamera(camera);
			}
		}
		return e;
	}

	/**
	 * Removes the Entity from the Scene at the end of the frame.
	 * @param	e		Entity object you want to remove.
	 * @return	The removed Entity object.
	 */
	public function remove<E:Entity>(e:E):E
	{
		_remove[_remove.length] = e;
		return e;
	}

	/**
	 * Removes all Entities from the Scene at the end of the frame.
	 */
	public function removeAll()
	{
		for (e in _update)
		{
			_remove[_remove.length] = e;
		}
	}

	/**
	 * Adds multiple Entities to the scene.
	 * @param	...list		Several Entities (as arguments) or an Array/Vector of Entities.
	 */
	public function addList<E:Entity>(list:Iterable<E>)
	{
		for (e in list) add(e);
	}

	/**
	 * Removes multiple Entities from the scene.
	 * @param	...list		Several Entities (as arguments) or an Array/Vector of Entities.
	 */
	public function removeList<E:Entity>(list:Iterable<E>)
	{
		for (e in list) remove(e);
	}

	/**
	 * Adds an Entity to the Scene with the Graphic object.
	 * @param	graphic		Graphic to assign the Entity.
	 * @param	x			X position of the Entity.
	 * @param	y			Y position of the Entity.
	 * @param	layer		Layer of the Entity.
	 * @return	The Entity that was added.
	 */
	public function addGraphic(graphic:Graphic, layer:Int = 0, x:Float = 0, y:Float = 0):Entity
	{
		var e:Entity = new Entity(x, y, graphic);
		e.layer = layer;
		e.active = false;
		return add(e);
	}

	/**
	 * Adds an Entity to the Scene with the Mask object.
	 * @param	mask	Mask to assign the Entity.
	 * @param	type	Collision type of the Entity.
	 * @param	x		X position of the Entity.
	 * @param	y		Y position of the Entity.
	 * @return	The Entity that was added.
	 */
	public function addMask(mask:Mask, type:String, x:Int = 0, y:Int = 0):Entity
	{
		var e:Entity = new Entity(x, y, null, mask);
		if (type != "") e.type = type;
		e.active = e.visible = false;
		return add(e);
	}

	public function addCamera(camera:Camera)
	{
		cameras.push(camera);
		camera.scene = this;
		camera.added();
	}

	public function removeCamera(camera:Camera)
	{
		cameras.remove(camera);
		camera.removed();
	}

	/**
	 * Returns a new Entity, or a stored recycled Entity if one exists.
	 * 
	 * **Note**: The constructor is only called when creating a new entity,
	 * when using a recycled one the constructor (with constructorsArgs)
	 * isn't called. Instead use a function to initialize your entities.
	 * 
	 * @param	classType			The Class of the Entity you want to add.
	 * @param	addToScene			Add it to the Scene immediately.
	 * @param	constructorsArgs	List of the entity constructor arguments (optional).
	 * @return	The new Entity object.
	 */
	public function create<E:Entity>(classType:Class<E>, addToScene:Bool = true, ?constructorsArgs:Array<Dynamic>):E
	{
		var className:String = Type.getClassName(classType);
		var e:Entity = _recycled.get(className);
		if (e != null)
		{
			_recycled.set(className, e._recycleNext);
			e._recycleNext = null;
		}
		else
		{
			if (constructorsArgs != null)
				e = Type.createInstance(classType, constructorsArgs);
			else
				e = Type.createInstance(classType, []);
		}

		return cast (addToScene ? add(e) : e);
	}

	/**
	 * Removes the Entity from the Scene at the end of the frame and recycles it.
	 * The recycled Entity can then be fetched again by calling the create() function.
	 * @param	e		The Entity to recycle.
	 * @return	The recycled Entity.
	 */
	public function recycle<E:Entity>(e:E):E
	{
		_recycle[_recycle.length] = e;
		return remove(e);
	}

	/**
	 * Clears stored reycled Entities of the Class type.
	 * @param	classType		The Class type to clear.
	 */
	public function clearRecycled<E:Entity>(classType:Class<E>)
	{
		var className:String = Type.getClassName(classType),
			e:Entity = _recycled.get(className),
			n:Entity;
		while (e != null)
		{
			n = e._recycleNext;
			e._recycleNext = null;
			e = n;
		}
		_recycled.remove(className);
	}

	/**
	 * Clears stored recycled Entities of all Class types.
	 */
	public function clearRecycledAll()
	{
		var e:Entity;
		for (e in _recycled)
		{
			clearRecycled(Type.getClass(e));
		}
	}

	/**
	 * Brings the Entity to the front of its contained layer.
	 * @param	e		The Entity to shift.
	 * @return	If the Entity changed position.
	 */
	public function bringToFront(e:Entity):Bool
	{
		if (e._scene != this) return false;
		var list = renderList.layers.get(e._layer);
		list.remove(e);
		list.push(e);
		return true;
	}

	/**
	 * Sends the Entity to the back of its contained layer.
	 * @param	e		The Entity to shift.
	 * @return	If the Entity changed position.
	 */
	public function sendToBack(e:Entity):Bool
	{
		if (e._scene != this) return false;
		var list = renderList.layers.get(e._layer);
		list.remove(e);
		list.add(e);
		return true;
	}

	/**
	 * Shifts the Entity one place towards the front of its contained layer.
	 * @param	e		The Entity to shift.
	 * @return	If the Entity changed position.
	 */
	public function bringForward(e:Entity):Bool
	{
		if (e._scene != this) return false;
		// TODO: implement bringForward
		return true;
	}

	/**
	 * Shifts the Entity one place towards the back of its contained layer.
	 * @param	e		The Entity to shift.
	 * @return	If the Entity changed position.
	 */
	public function sendBackward(e:Entity):Bool
	{
		if (e._scene != this) return false;
		// TODO: implement sendBackward
		return true;
	}

	/**
	 * If the Entity as at the front of its layer.
	 * @param	e		The Entity to check.
	 * @return	True or false.
	 */
	public inline function isAtFront(e:Entity):Bool
	{
		return e == renderList.layers.get(e._layer).first();
	}

	/**
	 * If the Entity as at the back of its layer.
	 * @param	e		The Entity to check.
	 * @return	True or false.
	 */
	public inline function isAtBack(e:Entity):Bool
	{
		return e == renderList.layers.get(e._layer).last();
	}

	/**
	 * Returns the first Entity that collides with the rectangular area.
	 * @param	type		The Entity type to check for.
	 * @param	rX			X position of the rectangle.
	 * @param	rY			Y position of the rectangle.
	 * @param	rWidth		Width of the rectangle.
	 * @param	rHeight		Height of the rectangle.
	 * @return	The first Entity to collide, or null if none collide.
	 */
	public function collideRect(type:String, rX:Float, rY:Float, rWidth:Float, rHeight:Float, ?camera:Camera):Entity
	{
		if (_types.exists(type))
		{
			for (e in _types.get(type))
			{
				if (e.collidable && (camera == null || e.cameras.indexOf(camera) > -1) && e.collideRect(e.x, e.y, rX, rY, rWidth, rHeight)) return e;
			}
		}
		return null;
	}

	/**
	 * Returns the first Entity found that collides with the position.
	 * @param	type		The Entity type to check for.
	 * @param	pX			X position.
	 * @param	pY			Y position.
	 * @return	The collided Entity, or null if none collide.
	 */
	public function collidePoint(type:String, pX:Float, pY:Float, ?camera:Camera):Entity
	{
		var result:Entity = null;
		if (_types.exists(type))
		{
			for (e in _types.get(type))
			{
				// only look for entities that collide
				if (e.collidable && (camera == null || e.cameras.indexOf(camera) > -1) && e.collidePoint(e.x, e.y, pX, pY))
				{
					// the first one might be the front one
					if (result == null)
					{
						result = e;
					}
					// compare if the new collided entity is above the former one (lower valuer is toward, higher value is backward)
					else if (e.layer < result.layer)
					{
						result = e;
					}
				}
			}
		}
		return result;
	}

	/**
	 * Returns the first Entity found that collides with the line.
	 * @param	type		The Entity type to check for.
	 * @param	fromX		Start x of the line.
	 * @param	fromY		Start y of the line.
	 * @param	toX			End x of the line.
	 * @param	toY			End y of the line.
	 * @param	precision   Distance between consecutive tests. Higher values are faster but increase the chance of missing collisions.
	 * @param	p           If non-null, will have its x and y values set to the point of collision.
	 * @return	The first Entity to collide, or null if none collide.
	 */
	public function collideLine(type:String, fromX:Int, fromY:Int, toX:Int, toY:Int, precision:Int = 1, ?p:Point, ?camera:Camera):Entity
	{
		// If the distance is less than precision, do the short sweep.
		if (precision < 1) precision = 1;
		if (MathUtil.distance(fromX, fromY, toX, toY) < precision)
		{
			if (p != null)
			{
				if (fromX == toX && fromY == toY)
				{
					p.x = toX; p.y = toY;
					return collidePoint(type, toX, toY);
				}
				return collideLine(type, fromX, fromY, toX, toY, 1, p, camera);
			}
			else return collidePoint(type, fromX, toY, camera);
		}

		// Get information about the line we're about to raycast.
		var xDelta:Int = Std.int(Math.abs(toX - fromX)),
			yDelta:Int = Std.int(Math.abs(toY - fromY)),
			xSign:Float = toX > fromX ? precision : -precision,
			ySign:Float = toY > fromY ? precision : -precision,
			x:Float = fromX, y:Float = fromY, e:Entity;

		// Do a raycast from the start to the end point.
		if (xDelta > yDelta)
		{
			ySign *= yDelta / xDelta;
			if (xSign > 0)
			{
				while (x < toX)
				{
					if ((e = collidePoint(type, x, y, camera)) != null)
					{
						if (p == null) return e;
						if (precision < 2)
						{
							p.x = x - xSign; p.y = y - ySign;
							return e;
						}
						return collideLine(type, Std.int(x - xSign), Std.int(y - ySign), toX, toY, 1, p, camera);
					}
					x += xSign; y += ySign;
				}
			}
			else
			{
				while (x > toX)
				{
					if ((e = collidePoint(type, x, y, camera)) != null)
					{
						if (p == null) return e;
						if (precision < 2)
						{
							p.x = x - xSign; p.y = y - ySign;
							return e;
						}
						return collideLine(type, Std.int(x - xSign), Std.int(y - ySign), toX, toY, 1, p, camera);
					}
					x += xSign; y += ySign;
				}
			}
		}
		else
		{
			xSign *= xDelta / yDelta;
			if (ySign > 0)
			{
				while (y < toY)
				{
					if ((e = collidePoint(type, x, y, camera)) != null)
					{
						if (p == null) return e;
						if (precision < 2)
						{
							p.x = x - xSign; p.y = y - ySign;
							return e;
						}
						return collideLine(type, Std.int(x - xSign), Std.int(y - ySign), toX, toY, 1, p, camera);
					}
					x += xSign; y += ySign;
				}
			}
			else
			{
				while (y > toY)
				{
					if ((e = collidePoint(type, x, y, camera)) != null)
					{
						if (p == null) return e;
						if (precision < 2)
						{
							p.x = x - xSign; p.y = y - ySign;
							return e;
						}
						return collideLine(type, Std.int(x - xSign), Std.int(y - ySign), toX, toY, 1, p, camera);
					}
					x += xSign; y += ySign;
				}
			}
		}

		// Check the last position.
		if (precision > 1)
		{
			if (p == null) return collidePoint(type, toX, toY, camera);
			if (collidePoint(type, toX, toY, camera) != null) return collideLine(type, Std.int(x - xSign), Std.int(y - ySign), toX, toY, 1, p, camera);
		}

		// No collision, return the end point.
		if (p != null)
		{
			p.x = toX;
			p.y = toY;
		}
		return null;
	}

	/**
	 * Populates an array with all Entities that collide with the rectangle. This
	 * function does not empty the array, that responsibility is left to the user.
	 * @param	type		The Entity type to check for.
	 * @param	rX			X position of the rectangle.
	 * @param	rY			Y position of the rectangle.
	 * @param	rWidth		Width of the rectangle.
	 * @param	rHeight		Height of the rectangle.
	 * @param	into		The Array or Vector to populate with collided Entities.
	 */
	public function collideRectInto<E:Entity>(type:String, rX:Float, rY:Float, rWidth:Float, rHeight:Float, into:Array<E>, ?camera:Camera)
	{
		var n:Int = into.length;
		if (_types.exists(type))
		{
			for (e in _types.get(type))
			{
				if (e.collidable && (camera == null || e.cameras.indexOf(camera) > -1) && e.collideRect(e.x, e.y, rX, rY, rWidth, rHeight)) into[n++] = cast e;
			}
		}
	}

	/**
	 * Populates an array with all Entities that collide with the circle. This
	 * function does not empty the array, that responsibility is left to the user.
	 * @param	type 		The Entity type to check for.
	 * @param	circleX		X position of the circle.
	 * @param	circleY		Y position of the circle.
	 * @param	radius		The radius of the circle.
	 * @param	into		The Array or Vector to populate with collided Entities.
	 */
	public function collideCircleInto<E:Entity>(type:String, circleX:Float, circleY:Float, radius:Float, into:Array<E>, ?camera:Camera)
	{
		if (!_types.exists(type)) return;
		var n:Int = into.length;

		radius *= radius;//Square it to avoid the square root
		for (e in _types.get(type))
		{
			if (e.collidable && (camera == null || e.cameras.indexOf(camera) > -1) && MathUtil.distanceSquared(circleX, circleY, e.x, e.y) < radius)
				into[n++] = cast e;
		}
	}

	/**
	 * Populates an array with all Entities that collide with the position. This
	 * function does not empty the array, that responsibility is left to the user.
	 * @param	type		The Entity type to check for.
	 * @param	pX			X position.
	 * @param	pY			Y position.
	 * @param	into		The Array or Vector to populate with collided Entities.
	 */
	public function collidePointInto<E:Entity>(type:String, pX:Float, pY:Float, into:Array<E>, ?camera:Camera)
	{
		if (!_types.exists(type)) return;
		var n:Int = into.length;
		for (e in _types.get(type))
		{
			if (e.collidable && (camera == null || e.cameras.indexOf(camera) > -1) && e.collidePoint(e.x, e.y, pX, pY)) into[n++] = cast e;
		}
	}

	/**
	 * Finds the Entity nearest to the rectangle.
	 * @param	type		The Entity type to check for.
	 * @param	x			X position of the rectangle.
	 * @param	y			Y position of the rectangle.
	 * @param	width		Width of the rectangle.
	 * @param	height		Height of the rectangle.
	 * @return	The nearest Entity to the rectangle.
	 */
	public function nearestToRect(type:String, x:Float, y:Float, width:Float, height:Float):Entity
	{
		if (!_types.exists(type)) return null;
		var nearDist:Float = MathUtil.NUMBER_MAX_VALUE,
			near:Entity = null, dist:Float;
		for (e in _types.get(type))
		{
			dist = squareRects(x, y, width, height, e.x - e.originX, e.y - e.originY, e.width, e.height);
			if (dist < nearDist)
			{
				nearDist = dist;
				near = e;
			}
		}
		return near;
	}

	/**
	 * Finds the Entity nearest to another.
	 * @param	type		The Entity type to check for.
	 * @param	e			The Entity to find the nearest to.
	 * @param	useHitboxes	If the Entities' hitboxes should be used to determine the distance. If false, their x/y coordinates are used.
	 * @return	The nearest Entity to e.
	 */
	public function nearestToEntity(type:String, e:Entity, useHitboxes:Bool = false):Entity
	{
		if (!_types.exists(type)) return null;
		if (useHitboxes) return nearestToRect(type, e.x - e.originX, e.y - e.originY, e.width, e.height);
		var nearDist:Float = MathUtil.NUMBER_MAX_VALUE,
			near:Entity = null,
			dist:Float,
			x:Float = e.x - e.originX,
			y:Float = e.y - e.originY;
		for (n in _types.get(type))
		{
			dist = (x - n.x) * (x - n.x) + (y - n.y) * (y - n.y);
			if (dist < nearDist)
			{
				nearDist = dist;
				near = n;
			}
		}
		return near;
	}


	/**
	 * Finds the Entity nearest to another.
	 * @param	type		The Entity type to check for.
	 * @param	e			The Entity to find the nearest to.
	 * @param	classType	The Entity class to check for.
	 * @param	useHitboxes	If the Entities' hitboxes should be used to determine the distance. If false, their x/y coordinates are used.
	 * @return	The nearest Entity to e.
	 */
	public function nearestToClass<T>(type:String, e:Entity, classType:Class<T>, useHitboxes:Bool = false):Entity
	{
		if (!_types.exists(type)) return null;
		if (useHitboxes) return nearestToRect(type, e.x - e.originX, e.y - e.originY, e.width, e.height);
		var nearDist:Float = MathUtil.NUMBER_MAX_VALUE,
			near:Entity = null,
			dist:Float,
			x:Float = e.x - e.originX,
			y:Float = e.y - e.originY;
		for (n in _types.get(type))
		{
			dist = (x - n.x) * (x - n.x) + (y - n.y) * (y - n.y);
			if (dist < nearDist && Std.is(e, classType))
			{
				nearDist = dist;
				near = n;
			}
		}
		return near;
	}

	/**
	 * Finds the Entity nearest to the position.
	 * @param	type		The Entity type to check for.
	 * @param	x			X position.
	 * @param	y			Y position.
	 * @param	useHitboxes	If the Entities' hitboxes should be used to determine the distance. If false, their x/y coordinates are used.
	 * @return	The nearest Entity to the position.
	 */
	public function nearestToPoint(type:String, x:Float, y:Float, useHitboxes:Bool = false):Entity
	{
		if (!_types.exists(type)) return null;
		var nearDist:Float = MathUtil.NUMBER_MAX_VALUE,
			near:Entity = null,
			dist:Float;
		if (useHitboxes)
		{
			for (n in _types.get(type))
			{
				dist = squarePointRect(x, y, n.x - n.originX, n.y - n.originY, n.width, n.height);
				if (dist < nearDist)
				{
					nearDist = dist;
					near = n;
				}
			}
		}
		else
		{
			for (n in _types.get(type))
			{
				dist = (x - n.x) * (x - n.x) + (y - n.y) * (y - n.y);
				if (dist < nearDist)
				{
					nearDist = dist;
					near = n;
				}
			}
		}
		return near;
	}

	/**
	 * How many Entities are in the Scene.
	 */
	public var count(get, never):Int;
	private inline function get_count():Int return _update.length;

	/**
	 * Returns the amount of Entities of the type are in the Scene.
	 * @param	type		The type (or Class type) to count.
	 * @return	How many Entities of type exist in the Scene.
	 */
	public inline function typeCount(type:String):Int
	{
		return _types.exists(type) ? _types.get(type).length : 0;
	}

	/**
	 * Returns the amount of Entities of the Class are in the Scene.
	 * @param	c		The Class type to count.
	 * @return	How many Entities of Class exist in the Scene.
	 */
	public inline function classCount(c:String):Int
	{
		return _classCount.exists(c) ? _classCount.get(c) : 0;
	}

	/**
	 * Returns the amount of Entities are on the layer in the Scene.
	 * @param	layer		The layer to count Entities on.
	 * @return	How many Entities are on the layer.
	 */
	public inline function layerCount(layer:Int):Int
	{
		return renderList.layers.exists(layer) ? renderList.layers.get(layer).length : 0;
	}

	/**
	 * The first Entity in the Scene.
	 */
	public var first(get, null):Entity;
	private inline function get_first():Entity return _update.first();

	/**
	 * How many Entity layers the Scene has.
	 */
	public var layers(get, null):Int;
	private inline function get_layers():Int return renderList.layerList.length;

	/**
	 * A list of Entity objects of the type.
	 * @param	type 		The type to check.
	 * @return 	The Entity list.
	 */
	public inline function entitiesForType(type:String):Dll<Entity>
	{
		return _types.exists(type) ? _types.get(type) : null;
	}

	/**
	 * The first Entity of the Class.
	 * @param	c		The Class type to check.
	 * @return	The Entity.
	 */
	public function classFirst<E:Entity>(c:Class<E>):E
	{
		for (e in _update)
		{
			if (Std.is(e, c)) return cast e;
		}
		return null;
	}

	/**
	 * The first Entity on the Layer.
	 * @param	layer		The layer to check.
	 * @return	The Entity.
	 */
	public function layerFirst(layer:Int):Entity
	{
		return renderList.layers.exists(layer) ? renderList.layers.get(layer).first() : null;
	}

	/**
	 * The last Entity on the Layer.
	 * @param	layer		The layer to check.
	 * @return	The Entity.
	 */
	public function layerLast(layer:Int):Entity
	{
		return renderList.layers.exists(layer) ? renderList.layers.get(layer).last() : null;
	}

	/**
	 * The Entity that will be rendered first by the Scene.
	 */
	public var farthest(get, null):Entity;
	private function get_farthest():Entity
	{
		if (renderList.layerList.length == 0) return null;
		return renderList.layers.get(renderList.layerList[renderList.layerList.length - 1]).last();
	}

	/**
	 * The Entity that will be rendered last by the scene.
	 */
	public var nearest(get, null):Entity;
	private function get_nearest():Entity
	{
		if (renderList.layerList.length == 0) return null;
		return renderList.layers.get(renderList.layerList[0]).first();
	}

	/**
	 * The layer that will be rendered first by the Scene.
	 */
	public var layerFarthest(get, null):Int;
	private function get_layerFarthest():Int
	{
		if (renderList.layerList.length == 0) return 0;
		return renderList.layerList[renderList.layerList.length - 1];
	}

	/**
	 * The layer that will be rendered last by the Scene.
	 */
	public var layerNearest(get, null):Int;
	private function get_layerNearest():Int
	{
		if (renderList.layerList.length == 0) return 0;
		return renderList.layerList[0];
	}

	/**
	 * How many different types have been added to the Scene.
	 */
	public var uniqueTypes(get, null):Int;
	private inline function get_uniqueTypes():Int
	{
		var i:Int = 0;
		for (type in _types) i++;
		return i;
	}

	/**
	 * Pushes all Entities in the Scene of the type into the Array or Vector. This
	 * function does not empty the array, that responsibility is left to the user.
	 * @param	type		The type to check.
	 * @param	into		The Array or Vector to populate.
	 */
	public function getType<E:Entity>(type:String, into:Array<E>)
	{
		if (!_types.exists(type)) return;
		var n:Int = into.length;
		for (e in _types.get(type))
		{
			into[n++] = cast e;
		}
	}

	/**
	 * Pushes all Entities in the Scene of the Class into the Array or Vector. This
	 * function does not empty the array, that responsibility is left to the user.
	 * @param	c			The Class type to check.
	 * @param	into		The Array or Vector to populate.
	 */
	public function getClass<T, E:Entity>(c:Class<T>, into:Array<E>)
	{
		var n:Int = into.length;
		for (e in _update)
		{
			if (Std.is(e, c))
				into[n++] = cast e;
		}
	}

	/**
	 * Pushes all Entities in the Scene on the layer into the Array or Vector. This
	 * function does not empty the array, that responsibility is left to the user.
	 * @param	layer		The layer to check.
	 * @param	into		The Array or Vector to populate.
	 */
	public function getLayer<E:Entity>(layer:Int, into:Array<E>)
	{
		var n:Int = into.length;
		for (e in renderList.layers.get(layer))
		{
			into[n++] = cast e;
		}
	}

	/**
	 * Pushes all Entities in the Scene into the array. This
	 * function does not empty the array, that responsibility is left to the user.
	 * @param	into		The Array or Vector to populate.
	 */
	public function getAll<E:Entity>(into:Array<E>)
	{
		var n:Int = into.length;
		for (e in _update)
		{
			into[n++] = cast e;
		}
	}

	/**
	 * Returns the Entity with the instance name, or null if none exists
	 * @param	name
	 * @return	The Entity.
	 */
	public function getInstance(name:String):Entity
	{
		return _entityNames.get(name);
	}

	/**
	 * Updates the add/remove lists at the end of the frame.
	 * @param	shouldAdd	If new Entities should be added to the scene.
	 */
	public function updateLists(shouldAdd:Bool = true)
	{
		var e:Entity;

		if (HXP.cursor != null)
		{
			HXP.cursor._scene = this;
		}

		// remove entities
		if (_remove.length > 0)
		{
			for (e in _remove)
			{
				if (e._scene == null)
				{
					var idx = HXP.indexOf(_add, e);
					if (idx >= 0) _add.splice(idx, 1);
					continue;
				}
				if (e._scene != this)
					continue;
				e.removed();
				removeUpdate(e);
				removeRender(e);
				e._scene = null;
				if (e._type != "") removeType(e);
				if (e._name != "") unregisterName(e);
				if (e.autoClear && e.hasTween) e.clearTweens();
			}
			HXP.clear(_remove);
		}

		// add entities
		if (shouldAdd && _add.length > 0)
		{
			for (e in _add)
			{
				if (e._scene != null) continue;
				e._scene = this;
				addUpdate(e);
				addRender(e);
				if (e._type != "") addType(e);
				if (e._name != "") registerName(e);
				e.added();
			}
			HXP.clear(_add);
		}

		// recycle entities
		if (_recycle.length > 0)
		{
			for (e in _recycle)
			{
				if (e._scene != null || e._recycleNext != null)
					continue;

				e._recycleNext = _recycled.get(e._class);
				_recycled.set(e._class, e);
			}
			HXP.clear(_recycle);
		}
	}

	/** @private Adds Entity to the update list. */
	private function addUpdate(e:Entity)
	{
		// add to update list
		_update.add(e);
		if (_classCount.get(e._class) != 0) _classCount.set(e._class, 0);
		_classCount.set(e._class, _classCount.get(e._class) + 1); // increment
	}

	/** @private Removes Entity from the update list. */
	private function removeUpdate(e:Entity)
	{
		_update.remove(e);
		_classCount.set(e._class, _classCount.get(e._class) - 1); // decrement
	}

	/** @private Adds Entity to the render list. */
	@:allow(haxepunk.Entity)
	private function addRender(e:Entity)
	{
		renderList.addRender(e);
		for (camera in e.cameras)
		{
			camera.renderList.addRender(e);
		}
	}

	/** @private Removes Entity from the render list. */
	@:allow(haxepunk.Entity)
	private function removeRender(e:Entity)
	{
		for (camera in e.cameras)
		{
			camera.renderList.removeRender(e);
		}
		renderList.removeRender(e);
	}

	/** @private Adds Entity to the type list. */
	@:allow(haxepunk.Entity)
	private function addType(e:Entity)
	{
		var list:Dll<Entity>;
		// add to type list
		if (_types.exists(e._type))
		{
			list = _types.get(e._type);
		}
		else
		{
			list = new Dll<Entity>();
			_types.set(e._type, list);
		}
		list.push(e);
	}

	/** @private Removes Entity from the type list. */
	@:allow(haxepunk.Entity)
	private function removeType(e:Entity)
	{
		if (!_types.exists(e._type)) return;
		var list = _types.get(e._type);
		list.remove(e);
		if (list.length == 0)
		{
			_types.remove(e._type);
		}
	}

	/** @private Register the entities instance name. */
	@:allow(haxepunk.Entity)
	private inline function registerName(e:Entity)
	{
		_entityNames.set(e._name, e);
	}

	/** @private Unregister the entities instance name. */
	@:allow(haxepunk.Entity)
	private inline function unregisterName(e:Entity):Void
	{
		_entityNames.remove(e._name);
	}

	/** @private Calculates the squared distance between two rectangles. */
	private static function squareRects(x1:Float, y1:Float, w1:Float, h1:Float, x2:Float, y2:Float, w2:Float, h2:Float):Float
	{
		if (x1 < x2 + w2 && x2 < x1 + w1)
		{
			if (y1 < y2 + h2 && y2 < y1 + h1) return 0;
			if (y1 > y2) return (y1 - (y2 + h2)) * (y1 - (y2 + h2));
			return (y2 - (y1 + h1)) * (y2 - (y1 + h1));
		}
		if (y1 < y2 + h2 && y2 < y1 + h1)
		{
			if (x1 > x2) return (x1 - (x2 + w2)) * (x1 - (x2 + w2));
			return (x2 - (x1 + w1)) * (x2 - (x1 + w1));
		}
		if (x1 > x2)
		{
			if (y1 > y2) return MathUtil.distanceSquared((x2 + w2), (y2 + h2), x1, y1);
			return MathUtil.distanceSquared(x2 + w2, y2, x1, y1 + h1);
		}
		if (y1 > y2) return MathUtil.distanceSquared(x2, y2 + h2, x1 + w1, y1);
		return MathUtil.distanceSquared(x2, y2, x1 + w1, y1 + h1);
	}

	/** @private Calculates the squared distance between a rectangle and a point. */
	private static function squarePointRect(px:Float, py:Float, rx:Float, ry:Float, rw:Float, rh:Float):Float
	{
		if (px >= rx && px <= rx + rw)
		{
			if (py >= ry && py <= ry + rh) return 0;
			if (py > ry) return (py - (ry + rh)) * (py - (ry + rh));
			return (ry - py) * (ry - py);
		}
		if (py >= ry && py <= ry + rh)
		{
			if (px > rx) return (px - (rx + rw)) * (px - (rx + rw));
			return (rx - px) * (rx - px);
		}
		if (px > rx)
		{
			if (py > ry) return MathUtil.distanceSquared(rx + rw, ry + rh, px, py);
			return MathUtil.distanceSquared(rx + rw, ry, px, py);
		}
		if (py > ry) return MathUtil.distanceSquared(rx, ry + rh, px, py);
		return MathUtil.distanceSquared(rx, ry, px, py);
	}

	var renderList:RenderList;

	var _defaultCameras:Array<Camera>;

	var _add:Array<Entity>;
	var _remove:Array<Entity>;
	var _recycle:Array<Entity>;

	var _update:Dll<Entity>;
	var _layerDisplay:Map<Int, Bool>;
	var _classCount:Map<String, Int>;
	var _types:Map<String, Dll<Entity>>;

	var _recycled:Map<String, Entity>;
	var _entityNames:Map<String, Entity>;
}
