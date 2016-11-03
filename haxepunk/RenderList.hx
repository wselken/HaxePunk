package haxepunk;

import haxepunk.ds.Dll;

/**
 * Stores layer information for entities that need to be rendered.
 */
@:dox(hide)
class RenderList
{
	public var layerList:Array<Int>;
	public var layers:Map<Int, Dll<Entity>>;

	public function new()
	{
		layerList = new Array();
		layers = new Map();
	}

	public function addRender(e:Entity)
	{
		var list:Dll<Entity>;
		if (layers.exists(e.layer))
		{
			list = layers.get(e.layer);
		}
		else
		{
			// Create new layer with entity.
			list = new Dll<Entity>();
			layers.set(e.layer, list);

			if (layerList.length == 0)
			{
				layerList.push(e.layer);
			}
			else
			{
				insertSortedKey(layerList, e.layer, layerSort);
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

	/**
	 * Binary insertion sort
	 * @param list     A list to insert into
	 * @param key      The key to insert
	 * @param compare  A comparison function to determine sort order
	 */
	@:generic public static function insertSortedKey<T>(list:Array<T>, key:T, compare:T->T->Int):Void
	{
		var result:Int = 0,
		mid:Int = 0,
		min:Int = 0,
		max:Int = list.length - 1;
		while (max >= min)
		{
			mid = min + Std.int((max - min) / 2);
			result = compare(list[mid], key);
			if (result > 0) max = mid - 1;
			else if (result < 0) min = mid + 1;
			else return;
		}

		list.insert(result > 0 ? mid : mid + 1, key);
	}
}
