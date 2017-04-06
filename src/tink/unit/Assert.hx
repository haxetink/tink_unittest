package tink.unit;

import tink.testrunner.Assertion;
import haxe.macro.Expr;
import haxe.macro.Context;

#if macro
using tink.MacroApi;
#end

class Assert {
	static var printer = new haxe.macro.Printer();
	
	public static macro function assert(expr:ExprOf<Bool>, ?description:String):ExprOf<Assertion> {
		var pre = macro {};
		var assertion = expr;
		var desc = null;
		
		if(description != null)
			desc = macro $v{description};
		else {
			desc = macro $v{expr.toString()};
			switch expr.expr {
				case EBinop(op, e1, e2):
					
					var operator = printer.printBinop(op);
					var operation = EBinop(op, macro lh, macro rh).at(expr.pos);
					
					pre = macro {
						// store the values to avoid evaluating the expressions twice
						var lh = $e1; 
						var rh = $e2;
					}
					assertion = operation;
					desc = macro $desc + ' (' + lh + ' ' + $v{operator} + ' ' + rh + ')';
					
				default:
			}	
		}
		
		return pre.concat(macro @:pos(expr.pos) new tink.testrunner.Assertion($assertion, $desc));
	}
}