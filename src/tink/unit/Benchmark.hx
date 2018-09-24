package tink.unit;

#if !macro

@:autoBuild(tink.unit.Benchmark.build())
interface Benchmark {}

#else

using tink.MacroApi;

class Benchmark {
	public static function build() {
		var builder = new ClassBuilder();
		
		for(field in builder) {
			switch [field.kind, field.metaNamed(':benchmark')] {
				case [_, []]: // skip
				case [FFun(func), [meta = {pos: pos, params: [{expr: EConst(CInt(Std.parseInt(_) => i))}]}]]:
					field.meta.remove(meta);
					func.expr = macro @:pos(pos) {
						var start = haxe.Timer.stamp();
						for(_ in 0...$v{i}) ${func.expr};
						var dt = haxe.Timer.stamp() - start;
						return new tink.testrunner.Assertion(true, 'Benchmark: ' + $v{i} + ' iterations = ' + dt + 's');
					}
				case _: field.pos.error('Invalid use of @:benchmark. Only one @:benchmark is supported on each field and it should has exactly one Int parameter');
			}
		}
		
		return builder.export();
	}
}

#end