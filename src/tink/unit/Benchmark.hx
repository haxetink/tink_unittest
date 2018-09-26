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
					func.expr = macro return tink.unit.Assert.benchmark($v{i}, ${func.expr});
				case _: field.pos.error('Invalid use of @:benchmark. Only one @:benchmark is supported on each field and it should has exactly one Int parameter');
			}
		}
		
		return builder.export();
	}
}

#end