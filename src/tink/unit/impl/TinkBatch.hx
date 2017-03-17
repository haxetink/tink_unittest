package tink.unit.impl;

#if !macro
import tink.unit.Batch;
import tink.unit.Suite;
#else
import haxe.macro.Expr;
using tink.MacroApi;
#end

class TinkBatch #if !macro implements BatchObject #end {
	#if !macro
	public var info:BatchInfo;
	public var suites:Array<Suite>;
	
	public function new(suites:Array<TinkSuite>) {
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
				EArrayDecl(values.map(function(v) return macro tink.unit.impl.TinkSuite.make($v))).at(e.pos);
			default:
				e.pos.error('Expected Array');
		}
	}
}