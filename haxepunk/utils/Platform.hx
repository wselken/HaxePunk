package haxepunk.utils;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;

class Platform
{
	static function run()
	{
		if (Context.defined("flash")) {}
		else
		{
			Compiler.define("tile_shader");
		}
	}
}
#end
