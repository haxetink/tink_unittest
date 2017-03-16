package tink.unit;

import tink.streams.Stream;
import tink.streams.Accumulator;
import haxe.PosInfos;

using tink.CoreApi;

@:forward
abstract Assertions(Stream<Assertion>) from Stream<Assertion> to Stream<Assertion> {
	@:from
	public static inline function ofAssertion(o:Assertion):Assertions {
		var buffer = new AssertionBuffer();
		buffer.add(o);
		return buffer.complete();
	}
	
	@:from
	public static inline function ofFutureAssertion(p:Future<Assertion>):Assertions {
		var buffer = new AssertionBuffer();
		p.handle(function(o) {
			buffer.add(o);
			buffer.complete();
		});
		return buffer;
	}
	
	@:from
	public static inline function ofSurpriseAssertion(p:Surprise<Assertion, Error>):Assertions {
		return p >> function(o:Assertion) return ofAssertion(o);
	}
	
	@:from
	public static inline function ofOutcomeAssertions(o:Outcome<Assertions, Error>):Assertions {
		return ofSurpriseAssertions(Future.sync(o));
	}
	
	@:from
	public static inline function ofPromiseAssertions(p:Promise<Assertions>):Assertions {
		return ofSurpriseAssertions(p);
	}
	
	@:from
	public static inline function ofSurpriseAssertions(p:Surprise<Assertions, Error>):Assertions {
		return Stream.later((p:Surprise<Stream<Assertion>, Error>));
	}
}

@:forward
abstract AssertionBuffer(Accumulator<Assertion>) to Stream<Assertion> to Assertions {
	
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
	
	public inline function add(assertion:Assertion) {
		this.yield(Data(assertion));
	}
	
	public inline function complete():Stream<Assertion> {
		this.yield(End);
		return this;
	}
}