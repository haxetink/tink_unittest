package tink.unit;

import tink.testrunner.*;
import tink.streams.Stream;
import haxe.macro.Expr;

using tink.CoreApi;

#if pure 
private class Impl extends SignalStream<Assertion, Error> {
	var trigger:SignalTrigger<Yield<Assertion, Error>>;
	public function new() {
		var trigger = Signal.trigger();
		super(trigger.asSignal());
		this.trigger = trigger;
	}
	public inline function yield(data)
		trigger.trigger(data);
}
#else
private typedef Impl = tink.streams.Accumulator<Assertion>;
#end



abstract AssertionBuffer(Impl) from Impl to Assertions {
	
	public macro function assert(ethis:Expr, result:ExprOf<Bool>, ?description:ExprOf<String>, ?pos:ExprOf<haxe.PosInfos>):ExprOf<Assertion> {
		var args = [result, description];
		switch pos {
			case macro null:
			case _: args.push(pos);
		}
		return macro @:pos(ethis.pos) $ethis.emit(tink.unit.Assert.assert($a{args}));
	}
	
	#if deep_equal
	
	public macro function compare(ethis:Expr, expected:Expr, actual:Expr, ?description:ExprOf<String>, ?pos:ExprOf<haxe.PosInfos>) {
		var args = [expected, actual, description];
		switch pos {
			case macro null:
			case _: args.push(pos);
		}
		return macro @:pos(ethis.pos) $ethis.emit(tink.unit.Assert.compare($a{args}));
	}
		
	#end
		
	#if !macro
	public inline function new()
		this = new Impl();
		
	public inline function emit(assertion:Assertion)
		this.yield(Data(assertion));
		
	public inline function fail(?code:Int, reason:FailingReason, ?pos:haxe.PosInfos):AssertionBuffer {
		if(code == null) code = reason.code;
		this.yield(Fail(new Error(code, reason.message, pos)));
		return this;
	}
	
	public function defer(f:Void->Void):AssertionBuffer {
		Callback.defer(f);
		return this;
	}
	
	public inline function done():AssertionBuffer {
		this.yield(End);
		return this;
	}
	
	public function handle<T>(outcome:Outcome<T, Error>)
		switch outcome {
			case Success(_): done();
			case Failure(e): fail(e.code, e);
		}
	#end
}

@:forward
abstract FailingReason(Error) from Error to Error {
	@:from
	public static inline function ofString(e:String):FailingReason
		return new Error(e);
}
