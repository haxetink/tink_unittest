package tink.unit;

import tink.testrunner.*;
import tink.streams.Stream;
import haxe.macro.Expr;

using tink.CoreApi;

typedef Impl =
#if pure 
{trigger:SignalTrigger<Yield<Assertion, Error>>, stream:Stream<Assertion, Error>}
#else
tink.streams.Accumulator<Assertion>
#end ;

abstract AssertionBuffer(Impl) {
	
	public macro function assert(ethis:Expr, result:ExprOf<Bool>, ?description:ExprOf<String>, ?pos:ExprOf<haxe.PosInfos>):ExprOf<Assertion> {
		var args = [result, description];
		switch pos {
			case macro null:
			default: args.push(pos);
		}
		return macro $ethis.emit(tink.unit.Assert.assert($a{args}));
	}
		
	#if !macro
	public inline function new() {
		#if pure 
		var trigger = Signal.trigger();
		this = {
			trigger: trigger,
			stream: new SignalStream(trigger.asSignal()),
		}
		#else
		this = new tink.streams.Accumulator();
		#end
	}
	
	inline function yield(data)
		#if pure
		this.trigger.trigger(data);
		#else
		this.yield(data);
		#end
		
	public inline function emit(assertion:Assertion)
		yield(Data(assertion));
		
	public inline function fail(?code:Int, reason:FailingReason, ?pos:haxe.PosInfos) {
		if(code == null) code = reason.code;
		yield(Fail(new Error(code, reason.message, pos)));
		return toAssertions();
	}
	
	public inline function done():Assertions {
		yield(End);
		return toAssertions();
	}
	
	@:to
	public inline function toAssertions():Assertions
		return 
			#if pure
			this.stream;
			#else
			this;
			#end
	#end
}

@:forward
abstract FailingReason(Error) from Error to Error {
	@:from
	public static inline function ofString(e:String):FailingReason
		return new Error(e);
}