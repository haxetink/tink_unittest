package tink.unit;

#if !macro
import tink.testrunner.Case;
import tink.testrunner.Suite;
import tink.testrunner.Services;

using tink.CoreApi;

@:genericBuild(tink.unit.TestBuilder.build())
class TestSuiteBuilder<T> {}


class TestSuiteBase<T> extends TestSuite {
	var test:T;
}
#end

class TestSuite #if !macro extends SuiteObject #end {
	public static macro function make(e:haxe.macro.Expr) {
		var ct = haxe.macro.Context.toComplexType(haxe.macro.Context.typeof(e));
		return macro new tink.unit.TestSuite.TestSuiteBuilder<$ct>($e);
	}
}