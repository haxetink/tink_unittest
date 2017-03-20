package tink.unit;

import tink.testrunner.Assertion;
import haxe.macro.Expr;
import haxe.macro.Context;

#if macro
using tink.MacroApi;
#end

class Assert {
	public static macro function assert(expr:ExprOf<Bool>, ?description:String):ExprOf<Assertion> {
		if(description == null) {
			description = expr.toString();
			switch expr.expr {
				case EBinop(op, e1, e2):
					
					var operator = new haxe.macro.Printer().printBinop(op);
					var operation = EBinop(op, macro lh, macro rh).at(expr.pos);
					var lt = Context.typeof(e1).toComplex();
					var rt = Context.typeof(e2).toComplex();

					return macro (function(lh:$lt, rh:$rt) {
						return new tink.testrunner.Assertion($operation, $v{description} + ' (' + lh + ' ' + $v{operator} + ' ' + rh + ')');
					})($e1, $e2);
				default:
					
			}	
		}
		return macro new tink.testrunner.Assertion($expr, $v{description});
	}
}