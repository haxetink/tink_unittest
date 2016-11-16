package tink.unit;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

#if macro
using tink.MacroApi;
#end
using StringTools;

class Macro {
	
	public static function buildRunner() {
		var type = switch Context.getLocalType() {
			case TInst(_, [type]): type;
			default: throw 'assert';
		}
		var cls = switch type {
			case TInst(_.get() => cls, _): cls;
			default: throw 'assert';
		}
		
		// TODO: may need a better way of caching to avoid hash clash
		var clsname = 'Runner_' + Context.signature(cls);
		try return Context.getType('tink.unit.$clsname') catch(e:Dynamic) {}
		
		var tname = switch cls.meta.extract(':name') {
			case []: cls.name;
			case [{params: [p]}]: p.getString().sure();
			case v: Context.fatalError('Expected only one @:name metadata with exactly one parameter', v[0].pos);
		}
		var ct = type.toComplex();
		var tests = [
			Startup => [],
			Shutdown => [],
			Before => [],
			After => [],
			Test => [],
		];
		for(field in cls.fields.get()) if(field.isPublic && field.kind.match(FMethod(_))) {
			var fname = field.name;
			
			var kind:Kind = null;
			function checkKind(meta:String, k:Kind) switch field.meta.extract(meta) {
				case []: // skip
				case v: 
					if(kind == null) kind = k
					else Context.fatalError('Cannot declare @$meta and @:${Std.string(kind).toLowerCase()} on the same function', v[0].pos); 
			}
			checkKind(':startup', Startup);
			checkKind(':shutdown', Shutdown);
			checkKind(':before', Before);
			checkKind(':after', After);
			if(kind == null) kind = Test;
			
			var description = switch field.meta.extract(':describe') {
				case []: [macro $v{fname}];
				case v: [for(v in v) macro $v{v.params[0].getString().sure()}];
			}
			var description = switch field.meta.extract(':describe') {
				case []: [macro $v{fname}];
				case v: [for(v in v) macro $v{v.params[0].getString().sure()}];
			}
			var timeout = switch field.meta.extract(':timeout') {
				case []: 5000;
				case [v]: switch v.params {
						case [{expr: EConst(CInt(i))}]: Std.parseInt(i);
						case [{pos: pos}]: Context.fatalError('Expected integer parameter for @:timeout', pos);
						default: Context.fatalError('Expected exactly one parameter for @:timeout', v.pos);
					}
				case p: Context.fatalError('Multiple @:timeout meta', p[0].pos);
			}
			tests[kind].push(macro @:pos(field.pos) ({
				descriptions: $a{description},
				timeout: $v{timeout},
				result: function() return test.$fname(),
			}:tink.unit.TestCase.Test));
		}
		
		var def = macro class $clsname extends tink.unit.TestRunner.RunnerBase {
			var test:$ct;
			public function new(test) {
				this.test = test;
				name = $v{tname};
				startups = $a{tests[Startup]};
				shutdowns = $a{tests[Shutdown]};
				befores = $a{tests[Before]};
				afters = $a{tests[After]};
				tests = $a{tests[Test]};
			}
		}
		def.pack = ['tink', 'unit'];
		
		Context.defineType(def);
		return Context.getType('tink.unit.$clsname');
	}
	
	public static function run(e:Expr) {
		switch e.expr {
			case EArrayDecl(values):
				var expr = [];
				for(v in values) {
					var type = Context.typeof(v);
					var ct = type.toComplex();
					expr.push(macro new tink.unit.TestRunner.Runner<$ct>($v));
				}
				return macro {
					var tests = $a{expr};
					tink.unit.TestRunner.runAll(tests);
				}
				
			default: Context.fatalError('Expected Array', e.pos);
		}
		return macro null;
	}
}

enum Kind {
	Startup;
	Shutdown;
	Before;
	After;
	Test;
}
