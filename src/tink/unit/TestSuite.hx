package tink.unit;

#if !macro
import tink.testrunner.Case;
import tink.testrunner.Suite;

using tink.CoreApi;

@:genericBuild(tink.unit.TestBuilder.build())
class TestSuiteBuilder<T> {}


class TestSuiteBase<T> extends TestSuite {
	var test:T;
	var startups:Services;
	var befores:Services;
	var afters:Services;
	var shutdowns:Services;
}
#end

class TestSuite #if !macro implements SuiteObject #end {
	#if !macro
	public var info:SuiteInfo;
	public var cases:Array<Case>;
	public var includeMode:Ref<Bool>;
	#end
	
	public static macro function make(e:haxe.macro.Expr) {
		var ct = haxe.macro.Context.toComplexType(haxe.macro.Context.typeof(e));
		return macro new tink.unit.TestSuite.TestSuiteBuilder<$ct>($e);
	}
}