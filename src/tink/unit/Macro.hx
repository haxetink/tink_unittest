package tink.unit;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

#if macro
using tink.MacroApi;
#end
using StringTools;

class Macro {
	public static function run(e:Expr) {
		switch e.expr {
			case EArrayDecl(values):
				var caseType = (macro:tink.unit.TestCase).toType().sure();
				var cases = [];
				for(v in values) {
					var type = Context.typeof(v);
					var cls:ClassType = switch type {
						case TInst(_.get() => cls, _): cls;
						default: Context.fatalError('Expected class instance', v.pos);
					}
					
					var tests = [];
					for(field in cls.fields.get()) if(field.isPublic) {
						var name = field.name;
						var description = switch field.meta.extract(':describe') {
							case []: name;
							case v: [for(v in v) v.params[0].getString().sure()].join('\n');
						}
						var timeout = switch field.meta.extract(':timeout') {
							case []: 5000;
							case [v]: switch v.params {
									case [{expr: EConst(CInt(i))}]: Std.parseInt(i);
									case [{pos: pos}]: Context.fatalError('Expected integer parameter for @:timeout', pos);
									default: Context.fatalError('Expected exactly one parameter for @:timeout', v.pos);
								}
							default: Context.fatalError('Multiple @:timeout meta', v.pos);
						}
						tests.push(macro ({
							description: $v{description},
							timeout: $v{timeout},
							result: function() return t.$name(),
						}:tink.unit.TestCase.Test));
					}
					
					cases.push(macro {
						name: $v{cls.name},
						tests: {
							var t = $v;
							function() return $a{tests};
						}
					});
				}
				
				return macro {
					var cases = $a{cases};
					tink.unit.TestRunner.runAll(cases);
				}
				
			default: Context.fatalError('Expected Array', e.pos);
		}
		return macro null;
	}
}
