package tink.unit;

import haxe.PosInfos;
using tink.CoreApi;

abstract Assert(Outcome<Noise, Error>) from Outcome<Noise, Error> to Outcome<Noise, Error> {
	public static function equals<T>(expected:T, actual:T, ?errmsg:String, ?pos:PosInfos):Assert
		return expected == actual ? Success(Noise) : Failure(new Error(errmsg == null ? 'Expected $expected, but got $actual' : errmsg, pos));
		
	public static function notEquals<T>(expected:T, actual:T, ?errmsg:String, ?pos:PosInfos):Assert
		return isFalse(expected == actual, errmsg == null ? 'Expected actual vlaue to be different from $expected, but they are the same' : errmsg, pos);
		
	public static function isTrue(actual:Bool, ?errmsg:String, ?pos:PosInfos):Assert
		return equals(true, actual, errmsg, pos);
		
	public static function isFalse(actual:Bool, ?errmsg:String, ?pos:PosInfos):Assert
		return equals(false, actual, errmsg, pos);
		
	@:op(A&&B)
	public function and(b:Assert)
		return switch this {
			case Success(_): b;
			case Failure(f): Failure(f);
		}
}