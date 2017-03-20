package tink.unit;

import tink.testrunner.Assertion;
import haxe.macro.Expr;

using haxe.macro.Tools;

class Assert {
	public static macro function assert(expr:ExprOf<Bool>, ?description:String):ExprOf<Assertion> {
		if(description == null) description = expr.toString();
		return macro new tink.testrunner.Assertion($expr, $v{description});
	}
}