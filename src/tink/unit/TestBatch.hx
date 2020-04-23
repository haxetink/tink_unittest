package tink.unit;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;
#end

class TestBatch {
	public static macro function make(values:Array<Expr>) {
		switch values {
			case [{ expr: EArrayDecl(exprs) }]:
				values = exprs;
			default:
		}

		var suites = EArrayDecl(values.map(function(v) return macro tink.unit.TestSuite.make($v))).at();
		return macro new tink.testrunner.Batch($suites);
	}
}