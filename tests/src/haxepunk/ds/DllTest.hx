package haxepunk.ds;

import massive.munit.Assert;

class DllTest extends TestSuite
{
	static function assertArrayEqual<T>(expected:Array<T>, actual:Array<T>)
	{
		Assert.areEqual(expected.length, actual.length);
		Assert.areEqual(expected.toString(), actual.toString());
	}

	@Test
	public function testNew()
	{
		var list = new Dll<Int>();
		Assert.isTrue(true);
	}

	@Test
	public function testAdd()
	{
		var list = new Dll<Int>();
		list.add(1);
		list.add(2);
		list.add(3);
		assertArrayEqual([1, 2, 3], list.toArray());
		Assert.areEqual(3, list.length);
	}

	@Test
	public function testPush()
	{
		var list = new Dll<Int>();
		list.push(1);
		list.push(2);
		list.push(3);
		assertArrayEqual([3, 2, 1], list.toArray());
		Assert.areEqual(3, list.length);
	}

	@Test
	public function testRemove()
	{
		var list = new Dll<Int>();
		list.push(1);
		list.add(2);
		list.add(3);
		list.add(4);
		assertArrayEqual([1, 2, 3, 4], list.toArray());
		Assert.areEqual(4, list.length);
		list.remove(3);
		assertArrayEqual([1, 2, 4], list.toArray());
		Assert.areEqual(3, list.length);
		list.remove(1);
		assertArrayEqual([2, 4], list.toArray());
		Assert.areEqual(2, list.length);
		list.remove(4);
		assertArrayEqual([2], list.toArray());
		Assert.areEqual(1, list.length);
		list.remove(2);
		assertArrayEqual([], list.toArray());
		Assert.areEqual(0, list.length);
	}

	@Test
	public function testInsert()
	{
		var list = new Dll<Int>();
		list.add(1);
		list.add(10);
		list.add(100);
		assertArrayEqual([1, 10, 100], list.toArray());
		Assert.areEqual(3, list.length);

		list.insert(0, 0);
		assertArrayEqual([0, 1, 10, 100], list.toArray());
		Assert.areEqual(4, list.length);

		list.insert(1, 4);
		assertArrayEqual([0, 4, 1, 10, 100], list.toArray());
		Assert.areEqual(5, list.length);

		list.insert(2, 5);
		assertArrayEqual([0, 4, 5, 1, 10, 100], list.toArray());
		Assert.areEqual(6, list.length);

		list.insert(5, 6);
		assertArrayEqual([0, 4, 5, 1, 10, 6, 100], list.toArray());
		Assert.areEqual(7, list.length);

		list.insert(7, 7);
		assertArrayEqual([0, 4, 5, 1, 10, 6, 100, 7], list.toArray());
		Assert.areEqual(8, list.length);

		list.insert(10, 8);
		assertArrayEqual([0, 4, 5, 1, 10, 6, 100, 7, 8], list.toArray());
		Assert.areEqual(9, list.length);
	}
}
