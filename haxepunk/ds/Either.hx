package haxepunk.ds;

@:dox(hide)
@:generic
enum Either<L, R>
{
	Left(v:L);
	Right(v:R);
}
