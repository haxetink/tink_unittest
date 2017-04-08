package tink.unit;

import tink.testrunner.*;
import tink.streams.Accumulator;
import haxe.macro.Expr;

using tink.CoreApi;

abstract AssertionBuffer(Accumulator<Assertion, tink.core.Error>) to Assertions {
	
	public macro function assert(ethis:Expr, expr:ExprOf<Bool>, ?description:String):ExprOf<Assertion> {
		return macro $ethis.emit(tink.unit.Assert.assert($expr, $v{description}));
	}
		
	#if !macro
	public inline function new()
		this = new Accumulator();
		
	public inline function emit(assertion:Assertion)
		this.yield(Data(assertion));
		
	public inline function fail(?code:Int, reason:FailingReason, ?pos:haxe.PosInfos) {
		if(code == null) code = reason.code;
		this.yield(Fail(new Error(code, reason.message, pos)));
		return this;
	}
	
	public inline function done():Assertions {
		this.yield(End);
		return this;
	}
	#end
}

@:forward
abstract FailingReason(Error) from Error to Error {
	@:from
	public static inline function ofString(e:String):FailingReason
		return new Error(e);
}