package tink.unit;

import tink.testrunner.*;
import tink.streams.Stream;
import haxe.macro.Expr;

#if macro
using tink.MacroApi;
#end
using tink.CoreApi;

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


@:transitive
abstract AssertionBuffer(Impl) from Impl to Assertions {
	
	public macro function expectCompilerError(ethis:Expr, expr:Expr, ?pattern:ExprOf<EReg>, ?description:ExprOf<String>, ?pos:ExprOf<haxe.PosInfos>):ExprOf<Assertion> {
		var args = [expr, pattern, description];
		switch pos {
			case macro null:
			case _: args.push(pos);
		}
		return macro @:pos(ethis.pos) {
			var assertion = tink.unit.Assert.expectCompilerError($a{args});
			$ethis.emit(assertion);
			assertion;
		};
	}
	
	public macro function assert(ethis:Expr, result:ExprOf<Bool>, ?description:ExprOf<String>, ?pos:ExprOf<haxe.PosInfos>):ExprOf<Assertion> {
		var args = [result, description];
		switch pos {
			case macro null:
			case _: args.push(pos);
		}
		return macro @:pos(ethis.pos) {
			var assertion = tink.unit.Assert.assert($a{args});
			$ethis.emit(assertion);
			assertion;
		}
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
		
	public inline function fail(reason:FailingReason, ?pos:haxe.PosInfos):AssertionBuffer {
		this.yield(Fail(reason));
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
			case Failure(e): fail(e);
		}
	#end
}

@:forward
abstract FailingReason(Error) from Error to Error {
	@:from
	public static inline function ofString(e:String):FailingReason
		return new Error(e);
}
