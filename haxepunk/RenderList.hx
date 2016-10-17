package haxepunk;


/**
 * Stores layer information for entities that need to be rendered.
 */
@:dox(hide)
class RenderList
{
	public var layerList:Array<Int>;
	public var layers:Map<Int, List<Entity>>;

	public function new()
	{
		layerList = new Array<Int>();
		layers = new Map<Int, List<Entity>>();
	}

	public function addRender(e:Entity)
	{
		var list:List<Entity>;
		if (layers.exists(e.layer))
		{
			list = layers.get(e.layer);
		}
		else
		{
			// Create new layer with entity.
			list = new List<Entity>();
			layers.set(e.layer, list);

			if (layerList.length == 0)
			{
				layerList[0] = e.layer;
			}
			else
			{
				HXP.insertSortedKey(layerList, e.layer, layerSort);
			}
		}
		list.add(e);
	}

	public function removeRender(e:Entity)
	{
		var list = layers.get(e.layer);
		list.remove(e);
		if (list.length == 0)
		{
			layerList.remove(e.layer);
			layers.remove(e.layer);
		}
	}

	/**
	 * Sorts layer from highest value to lowest
	 */
	static function layerSort(a:Int, b:Int):Int
	{
		return b - a;
	}
}
