package haxepunk.ds;

@:generic class ListNode<T>
{
	public var value:T;
	public var prev:ListNode<T>;
	public var next:ListNode<T>;

	public inline function new(t:T)
	{
		value = t;
	}
}

@:generic private class DllIterator<T> {
	var dll:Dll<T>;
	var head:ListNode<T>;

	public inline function new(dll:Dll<T>)
	{
		this.dll = dll;
		reset();
	}

	public inline function hasNext():Bool
	{
		return head != null;
	}

	public inline function next():T
	{
		var val = head.value;
		head = head.next;
		return val;
	}

	public inline function reset():Void
	{
		this.head = dll.head;
	}
}

@:generic class Dll<T>
{
	public var length:Int = 0;
	public var head:ListNode<T>;
	public var tail:ListNode<T>;

	var _iter:DllIterator<T>;

	public function new()
	{
		_nodes = new Array();
		_iter = new DllIterator<T>(this);
	}

	public function push(t:T):ListNode<T>
	{
		var node = newNode(t);
		if (head == null)
		{
			// list was empty
			head = tail = node;
		}
		else
		{
			// node is the new head
			head.prev = node;
			node.next = head;
			head = node;
		}
		++length;
		return node;
	}

	public function add(t:T):ListNode<T>
	{
		var node = newNode(t);
		if (head == null)
		{
			// list was empty
			head = tail = node;
		}
		else
		{
			// node is the new tail
			tail.next = node;
			node.prev = tail;
			tail = node;
		}
		++length;
		return node;
	}

	public function remove(value:T):T
	{
		var node = head;
		while (node != null)
		{
			if (node.value == value)
			{
				removeNode(node);
				break;
			}
			node = node.next;
		}
		return value;
	}

	public function removeNode(node:ListNode<T>):T
	{
		if (head == node) head = node.next;
		if (tail == node) tail = node.prev;
		if (node.prev != null) node.prev.next = node.next;
		if (node.next != null) node.next.prev = node.prev;
		--length;
		var val = node.value;
		node.value = null;
		_nodes.push(node);
		return val;
	}

	public function insert(index:Int, value:T):ListNode<T>
	{
		var at = head;
		if (at == null || index == 0)
		{
			return push(value);
		}
		else
		{
			while (index-- > 0 && at.next != null)
			{
				at = at.next;
			}
			if (index >= 0)
			{
				return add(value);
			}
			else
			{
				var node = newNode(value);
				at.prev.next = node;
				node.prev = at.prev;
				at.prev = node;
				node.next = at;
				++length;
				return node;
			}
		}
	}

	public function pop():Null<T>
	{
		return head == null ? null : removeNode(head);
	}

	public function clear():Void
	{
		while (tail != null)
		{
			pop();
		}
	}


	public inline function iterator():DllIterator<T>
	{
		_iter.reset();
		return _iter;
	}

	public inline function first():Null<T>
	{
		return (head == null) ? null : head.value;
	}

	public inline function last():Null<T>
	{
		return (tail == null) ? null : tail.value;
	}

	public inline function toArray():Array<T>
	{
		return [for (value in iterator()) value];
	}

	inline function newNode(t:T):ListNode<T>
	{
		var node:ListNode<T>;
		if (_nodes.length > 0)
		{
			node = _nodes.pop();
			node.value = t;
			node.prev = node.next = null;
		}
		else
		{
			node = new ListNode<T>(t);
		}

		return node;
	}

	var _nodes:Array<ListNode<T>>;
}
