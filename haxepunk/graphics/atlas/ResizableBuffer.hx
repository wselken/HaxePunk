package haxepunk.graphics.atlas;

class ReusableBuffer<T>
{
	public var buffer:ArrayAccess<T>;

	var factory:Int->ArrayAccess<T>;
	var pos:Int = 0;
	var len:Int = 0;

	public function new(initialSize:Int = 16, factory:Int->ArrayAccess<T>)
	{
		this.factory = factory;
		buffer = factory(initialSize);
		len = initialSize;
	}

	public function ensureSpace(elements:Int):Void
	{
		if (len - pos < elements)
		{
			var newLen = Std.int(Math.max(len - pos, len + (len >> 1)));
			buffer = factory(newLen);
			len = newLen;
		}
	}

	public function reset():Void
	{
		len = 0;
	}

	@:arrayAccess public inline function get(i:Int):T
	{
		return buffer[i];
	}

	public function write(value:T)
	{
		buffer[pos++] = value;
	}
}
