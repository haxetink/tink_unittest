package tink.unit;

import tink.streams.Stream;
import tink.streams.Accumulator;
import haxe.PosInfos;

using tink.CoreApi;

abstract AssertBuffer(Accumulator<Assertion>) to Stream<Assertion> {
	
	public inline function new()
		this = new Accumulator();
		
	public inline function equals<T>(expected:T, actual:T, ?errmsg:String, ?pos:PosInfos)
		add(Assertion.equals(expected, actual, errmsg, pos));
	
	public inline function notEquals<T>(expected:T, actual:T, ?errmsg:String, ?pos:PosInfos)
		add(Assertion.notEquals(expected, actual, errmsg, pos));
	
	public inline function isNull<T>(actual:T, ?errmsg:String, ?pos:PosInfos)
		add(Assertion.isNull(actual, errmsg, pos));
	
	public inline function notNull<T>(actual:T, ?errmsg:String, ?pos:PosInfos)
		add(Assertion.notNull(actual, errmsg, pos));
	
	public inline function isTrue(actual:Bool, ?errmsg:String, ?pos:PosInfos)
		add(Assertion.isTrue(actual, errmsg, pos));
	
	public inline function isFalse(actual:Bool, ?errmsg:String, ?pos:PosInfos)
		add(Assertion.isFalse(actual, errmsg, pos));
	
	#if deep_equal
	public inline function deepEquals(expected:Dynamic, actual:Dynamic, ?pos:PosInfos)
		add(Assertion.deepEquals(expected, actual, errmsg, pos));
	#end
	
	public function add(assertion:Assertion) {
		this.yield(Data(assertion));
	}
	
	public function complete():Stream<Assertion> {
		this.yield(End);
		return this;
	}
	
}