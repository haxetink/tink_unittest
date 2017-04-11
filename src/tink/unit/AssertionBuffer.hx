package tink.unit;

import tink.testrunner.*;
import tink.streams.Accumulator;
import haxe.macro.Expr;

using tink.CoreApi;

abstract AssertionBuffer(Accumulator<Assertion #if pure , tink.core.Error #end>) to Assertions {
	
	public macro function assert(ethis:Expr, result:ExprOf<Bool>, ?description:ExprOf<String>, ?pos:ExprOf<haxe.PosInfos>):ExprOf<Assertion> {
		var args = [result, description];
		switch pos {
			case macro null:
			default: args.push(pos);
		}
		return macro $ethis.emit(tink.unit.Assert.assert($a{args}));
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