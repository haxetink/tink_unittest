package tink.unit;

#if macro
import haxe.macro.Expr;
using tink.MacroApi;
#end

class TestBatch {
	public static macro function make(e:Expr) {
		return switch e.expr {
			case EArrayDecl(values):
				var suites = EArrayDecl(values.map(function(v) return macro tink.unit.TestSuite.make($v))).at(e.pos);
				macro new tink.testrunner.Batch($suites);
			default:
				e.pos.error('Expected Array');
		}
	}
}