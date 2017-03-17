package tink.unit.impl;

#if !macro
import tink.unit.Case;
import tink.unit.Suite;

using tink.CoreApi;

@:genericBuild(tink.unit.impl.TinkBuilder.build())
class TinkSuiteBuilder<T> {}


class TinkSuiteBase<T> extends TinkSuite {
	var test:T;
	var startups:Services;
	var befores:Services;
	var afters:Services;
	var shutdowns:Services;
}
#end

class TinkSuite #if !macro implements SuiteObject #end {
	#if !macro
	public var info:SuiteInfo;
	public var cases:Array<Case>;
	public var includeMode:Ref<Bool>;
	#end
	
	public static macro function make(e:haxe.macro.Expr) {
		var ct = haxe.macro.Context.toComplexType(haxe.macro.Context.typeof(e));
		return macro new tink.unit.impl.TinkSuite.TinkSuiteBuilder<$ct>($e);
	}
}