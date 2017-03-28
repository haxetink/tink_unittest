package tink.unit;

import tink.testrunner.*;
import tink.streams.Accumulator;
import haxe.macro.Expr;

abstract AssertionBuffer(Accumulator<Assertion>) to Assertions {
	public inline function new()
		this = new Accumulator();
		
	public macro function assert(ethis:Expr, expr:ExprOf<Bool>, ?description:String):ExprOf<Assertion> {
		return macro $ethis.emit(tink.unit.Assert.assert($expr, $v{description}));
	}
		
	public inline function emit(assertion:Assertion)
		this.yield(Data(assertion));
	
	public inline function done() 
		this.yield(End);
}