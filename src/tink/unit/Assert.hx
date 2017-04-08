package tink.unit;

import tink.testrunner.Assertion;
import haxe.macro.Expr;
import haxe.macro.Context;

#if macro
using tink.MacroApi;
#end

class Assert {
	static var printer = new haxe.macro.Printer();
	
	public static macro function assert(expr:ExprOf<Bool>, ?description:String, ?pos:ExprOf<haxe.PosInfos>):ExprOf<Assertion> {
		var pre = macro {};
		var assertion = expr;
		var desc = null;
		
		if(description != null)
			desc = macro $v{description};
		else {
			desc = macro $v{expr.toString()};
			
			// TODO: we can actually do a recursive breakdown: e.g. `a == 1 && b == 2`
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
		
		var args = [assertion, desc];
		switch pos {
			case macro null: // skip
			case v: args.push(v);
		}
		return pre.concat(macro @:pos(expr.pos) new tink.testrunner.Assertion($a{args}));
	}
}