package tink.unit;

import haxe.macro.Expr;
import haxe.PosInfos;

using haxe.macro.Tools;

@:forward
abstract Assertion(tink.testrunner.Assertion) from tink.testrunner.Assertion to tink.testrunner.Assertion {
	public inline function new(holds, description, ?pos:haxe.PosInfos)
		this = new tink.testrunner.Assertion(holds, description, pos);
	
	public static macro function assert(expr:ExprOf<Bool>, ?description:String):ExprOf<Assertion> {
		if(description == null) description = expr.toString();
		return macro new tink.testrunner.Assertion($expr, $v{description});
	}
}