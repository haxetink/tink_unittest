package tink.unit;

#if !macro
import tink.testrunner.Suite;

@:genericBuild(tink.unit.TestBuilder.build())
class TestSuiteBuilder<T> {}


class TestSuiteBase<T> extends BasicSuite {
	var target:T;
}
#end

class TestSuite {
	public static macro function make(e:haxe.macro.Expr, ?name:haxe.macro.Expr) {
		var ct = haxe.macro.Context.toComplexType(haxe.macro.Context.typeof(e));
		return macro new tink.unit.TestSuite.TestSuiteBuilder<$ct>($e, $name);
	}
}