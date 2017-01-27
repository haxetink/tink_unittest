package tink.unit;

import haxe.PosInfos;
using tink.CoreApi;

abstract Assert(Outcome<Noise, Error>) from Outcome<Noise, Error> to Outcome<Noise, Error> {
	public static function equals<T>(expected:T, actual:T, ?errmsg:String, ?pos:PosInfos):Assert
		return expected == actual ? Success(Noise) : Failure(new Error(errmsg == null ? 'Expected $expected, but got $actual' : errmsg, pos));
		
	public static function notEquals<T>(expected:T, actual:T, ?errmsg:String, ?pos:PosInfos):Assert
		return isFalse(expected == actual, errmsg == null ? 'Expected actual value to be different from $expected, but they are the same' : errmsg, pos);
		
	public static function isNull<T>(actual:T, ?errmsg:String, ?pos:PosInfos):Assert
		return equals(null, actual, errmsg, pos);
		
	public static function notNull<T>(actual:T, ?errmsg:String, ?pos:PosInfos):Assert
		return notEquals(null, actual, errmsg, pos);
		
	public static function isTrue(actual:Bool, ?errmsg:String, ?pos:PosInfos):Assert
		return equals(true, actual, errmsg, pos);
		
	public static function isFalse(actual:Bool, ?errmsg:String, ?pos:PosInfos):Assert
		return equals(false, actual, errmsg, pos);
		
	#if deep_equal
	public static function deepEquals(expected:Dynamic, actual:Dynamic, ?pos:PosInfos):Assert
		return deepequal.DeepEqual.compare(expected, actual, pos);
	#end
		
	@:op(A&&B)
	public function and(b:Assert)
		return switch this {
			case Success(_): b;
			case Failure(f): Failure(f);
		}
		
	@:op(A||B)
	public function or(b:Assert)
		return switch this {
			case Success(_): Success(Noise);
			case Failure(f): b;
		}
}