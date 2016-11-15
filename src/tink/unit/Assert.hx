package tink.unit;

import haxe.PosInfos;
using tink.CoreApi;

class Assert {
	public static function equals<T>(expected:T, actual:T, ?errmsg:String, ?pos:PosInfos)
		return expected == actual ? Success(Noise) : Failure(new Error(errmsg == null ? 'Expected $expected, but got $actual' : errmsg, pos));
		
	public static function notEquals<T>(expected:T, actual:T, ?errmsg:String, ?pos:PosInfos)
		return isFalse(expected == actual, errmsg == null ? 'Expected $actual to be different from $expected' : errmsg, pos);
		
	public static function isTrue(actual:Bool, ?errmsg:String, ?pos:PosInfos)
		return equals(true, actual, errmsg, pos);
		
	public static function isFalse(actual:Bool, ?errmsg:String, ?pos:PosInfos)
		return equals(false, actual, errmsg, pos);
}