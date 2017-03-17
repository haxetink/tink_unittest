package tink.unit;

#if !macro
import tink.testrunner.Batch;
import tink.testrunner.Suite;
#else
import haxe.macro.Expr;
using tink.MacroApi;
#end

class TestBatch #if !macro implements BatchObject #end {
	#if !macro
	public var info:BatchInfo;
	public var suites:Array<Suite>;
	
	public function new(suites:Array<TestSuite>) {
		var includeMode = false;
		for(s in suites) if(s.includeMode.value) {
			includeMode = true;
			break;
		}
		if(includeMode) for(s in suites) s.includeMode.value = true;
		this.suites = [for(s in suites) s];
	}
	#end
	
	public static macro function make(e:Expr) {
		return switch e.expr {
			case EArrayDecl(values):
				var suites = EArrayDecl(values.map(function(v) return macro tink.unit.TestSuite.make($v))).at(e.pos);
				macro new tink.unit.TestBatch($suites);
			default:
				e.pos.error('Expected Array');
		}
	}
}