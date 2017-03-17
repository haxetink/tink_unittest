package tink.unit.impl;

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;

using Lambda;
#if macro
using tink.MacroApi;
#end

class TinkBuilder {
	
	static var cache = new TypeMap();
	static var counter = 0;
	
	public static function build() {
		switch Context.getLocalType() {
			case TInst(_, [type]): 
				if(!cache.exists(type)) {
					
					var cls = switch type {
						case TInst(_.get() => cls, _): cls;
						default: throw 'assert';
					}
					
					var clsname = 'Suite_' + counter++;
					
					var suiteName = switch cls.meta.extract(':name') {
						case []: cls.name;
						case [{params: [p]}]: p.getString().sure();
						case v: v[0].pos.error('Expected only one @:name metadata with exactly one parameter');
					}
					
					var clstimeout = getTimeout(cls.meta);
					var ct = type.toComplex();
					var runnables = [
						Startup => [],
						Shutdown => [],
						Before => [],
						After => [],
					];
					
					var cases = [];
					
					var includeMode = false;
					
					var fields = [];
					for(field in cls.fields.get()) if(field.isPublic && field.kind.match(FMethod(_))) {
						var fname = field.name;
						
						var kind:Kind = null;
						function checkKind(meta:String, k:Kind) switch field.meta.extract(meta) {
							case []: // ok
							case v if(kind == null): kind = k;
							case v: v[0].pos.error('Cannot declare @$meta and @:${Std.string(kind).toLowerCase()} on the same function');
						}
						checkKind(':startup', Startup);
						checkKind(':shutdown', Shutdown);
						checkKind(':before', Before);
						checkKind(':after', After);
						if(kind == null) kind = Test;
						
						var description = switch field.meta.extract(':describe') {
							case []: fname;
							case v: [for(v in v) v.params[0].getString().sure()].join('\n');
						}
						var timeout = getTimeout(field.meta, clstimeout);
						
						var exclude = field.meta.extract(':exclude').length > 0;
						var include = field.meta.extract(':include').length > 0;
						if(include) includeMode = true;
						
						switch kind {
							case Test: 
								cases.push({
									description: description,
									timeout: timeout,
									exclude: exclude,
									include: include,
									runnable: macro function():tink.unit.Assertions return test.$fname(),
								});
							default:
								var name = 'run_$fname';
								fields.push({
									name: name,
									access: [APublic],
									kind: FFun({
										args: [],
										ret: macro:tink.core.Promise<tink.core.Noise>,
										expr: macro return test.$fname(),
									}),
									pos: field.pos,
								});
								runnables[kind].push(macro $i{name});
						}
					}
					
					
					cases = cases.filter(function(c) return !c.exclude && (!includeMode || c.include));
					var tinkCases = [];
					for(i in 0...cases.length) {
						var caze = cases[i];
						var befores = i == 0 ? macro startups.concat(befores) : macro befores;
						var afters = i == cases.length - 1 ? macro afters.concat(shutdowns) : macro afters;
						var info = macro {
							description: $v{caze.description},
							timeout: $v{caze.timeout},
						}
						tinkCases.push(macro new tink.unit.impl.TinkCase($info, $befores, $afters, ${caze.runnable}, includeMode, $v{caze.include}));
					}
					
					var def = macro class $clsname extends tink.unit.impl.TinkSuite.TinkSuiteBase<$ct> {
						
						public function new(test) {
							this.test = test;
							this.includeMode = $v{includeMode};
							info = {
								name: $v{suiteName},
							}
							startups = $a{runnables[Startup]};
							shutdowns = $a{runnables[Shutdown]};
							befores = $a{runnables[Before]};
							afters = $a{runnables[After]};
							cases = $a{tinkCases};
						}
					}
					def.fields = def.fields.concat(fields); 
					def.pack = ['tink', 'unit'];
					
					Context.defineType(def);
					cache.set(type, TPath('tink.unit.$clsname'.asTypePath()));
				}
				return cache.get(type);
				
			default: throw 'assert';
		}
	}
	
	static function getTimeout(meta:MetaAccess, def = 5000)
		return switch meta.extract(':timeout') {
			case []: def;
			case [v]: switch v.params {
					case [{expr: EConst(CInt(i))}]: Std.parseInt(i);
					case [{pos: pos}]: pos.error('Expected integer parameter for @:timeout');
					default: v.pos.error('Expected exactly one parameter for @:timeout');
				}
			case p: p[0].pos.error('Multiple @:timeout meta');
		} 
}

enum Kind {
	Startup;
	Shutdown;
	Before;
	After;
	Test;
}
