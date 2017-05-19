package tink.unit;

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;

using Lambda;
using tink.CoreApi;
#if macro
using tink.MacroApi;
#end

class TestBuilder {
	
	static var cache = new TypeMap();
	static var infos = new TypeMap();
	static var counter = 0;
	static var POS_REGEX = ~/#pos([^:]*):([^:]*).*/;
	
	public static function build() {
		switch Context.getLocalType() {
			case TInst(_, [type]): 
				if(!cache.exists(type)) {
					
					var info = process(type);
					var clsname = 'Suite_' + counter++;
					var cases = [];
					var fields = [];
					var includeMode = false;
					var runnables = [
						Setup => [],
						Teardown => [],
						Before => [],
						After => [],
					];
					
					for(field in info.fields) {
						var fname = field.field.name;
						var cname = switch info.type {
							case TInst(_.get() => {name: name}, _): name;
							default: null;
						}
						
						switch [field.kind, field.variants] {
							case [Test, []]:
								var args = field.bufferIndex == -1 ? [] : [macro new tink.unit.AssertionBuffer()];
								cases.push({
									name: field.description,
									description: null,
									timeout: field.timeout,
									exclude: field.exclude,
									include: field.include,
									pos: transformPos(field.field.pos, fname, cname),
									runnable: macro @:pos(field.field.pos) function():tink.testrunner.Assertions return target.$fname($a{args}),
								});
								
							case [Test, variants]:
								for(v in variants) {
									var args = v.args.copy();
									if(field.bufferIndex != -1) args.insert(field.bufferIndex, macro new tink.unit.AssertionBuffer());
									cases.push({
										name: field.description,
										description: v.description,
										timeout: field.timeout,
										exclude: field.exclude,
										include: field.include,
										pos: transformPos(v.pos, fname, cname),
										runnable: macro @:pos(field.field.pos) function():tink.testrunner.Assertions return target.$fname($a{args}),
									});
								}
							
							default:
								var name = 'run_$fname';
								fields.push({
									name: name,
									access: [APublic],
									kind: FFun({
										args: [],
										ret: macro:tink.core.Promise<tink.core.Noise>,
										expr: macro return target.$fname(),
									}),
									pos: field.field.pos,
								});
								runnables[field.kind].push(macro $i{name});
						}
					}
					
					cases = cases.filter(function(c) return !c.exclude && (!includeMode || c.include));
					var tinkCases = [];
					for(i in 0...cases.length) {
						var caze = cases[i];
						if(!includeMode && caze.include) includeMode = true;
						var info = macro {
							name: $v{caze.name},
							description: $v{caze.description},
							pos: {
								lineNumber: $v{caze.pos.lineNumber},
								fileName: $v{caze.pos.fileName},
								methodName: $v{caze.pos.methodName},
								className: $v{caze.pos.className},
							}
						}
						tinkCases.push(macro {
							var pos = {
								lineNumber: $v{caze.pos.lineNumber},
								fileName: $v{caze.pos.fileName},
								methodName: $v{caze.pos.methodName},
								className: $v{caze.pos.className},
							}
							new tink.unit.TestCase($info, ${caze.runnable}, $v{caze.timeout}, $v{caze.include}, $v{caze.exclude}, pos);
						});
					}
					
					function makeServiceLoop(f:Array<Expr>) {
						var fields = f.copy();
						fields.reverse();
						var expr = fields.fold(function(f, expr) return macro $f().handle(function(o) switch o {
							case Success(_): $expr;
							case Failure(e): cb(tink.core.Outcome.Failure(e));
						}), macro cb(tink.core.Outcome.Success(tink.core.Noise.Noise.Noise)));
						return macro tink.core.Future.async(function(cb) $expr);
					}
					
					var ct = type.toComplex();
					var def = macro class $clsname extends tink.unit.TestSuite.TestSuiteBase<$ct> {
						
						public function new(target:$ct, ?name:String) {
							super({name: name == null ? $v{info.name} : name} , $a{tinkCases});
							this.target = target;
						}
						
						override function setup() return ${makeServiceLoop(runnables[Setup])};
						override function before() return ${makeServiceLoop(runnables[Before])};
						override function after() return ${makeServiceLoop(runnables[After])};
						override function teardown() return ${makeServiceLoop(runnables[Teardown])};
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
	
	static function process(type:Type):TestInfo {
		if(!infos.exists(type)) {
			
			var cls = switch type {
				case TInst(_.get() => cls, _): cls;
				default: throw 'assert';
			}
			
			var suiteName = switch cls.meta.extract(':name') {
				case []: cls.name;
				case [{params: [p]}]: p.getString().sure();
				case v: v[0].pos.error('Expected only one @:name metadata with exactly one parameter');
			}
			
			var fields = [];
			var clstimeout = 5000;
			
			if(cls.superClass != null) {
				var s = cls.superClass.t.get();
				var sinfo = process(Context.getType('${s.module}.${s.name}'));
				clstimeout = sinfo.timeout;
				fields = sinfo.fields.copy();
			}
			
			clstimeout = getTimeout(cls.meta, clstimeout);
					
			for(field in cls.fields.get()) if(field.isPublic && field.kind.match(FMethod(_))) {
				var fname = field.name;
				
				var kind:Kind = null;
				function checkKind(meta:String, k:Kind, ?alt:String) switch field.meta.extract(meta) {
					case []: // ok
					case v if(kind == null):
						kind = k;
						if(alt != null) Context.warning('@$meta is depcreated, use @$alt instead', v[0].pos);
					case v if(kind == k): 
						// duplicate, but ok
						if(alt != null) Context.warning('@$meta is depcreated, use @$alt instead', v[0].pos);
					case v:
						v[0].pos.error('Cannot declare @$meta and @:${Std.string(kind).toLowerCase()} on the same function');
				}
				checkKind(':setup', Setup);
				checkKind(':startup', Setup, ':setup');
				checkKind(':teardown', Teardown);
				checkKind(':shutdown', Teardown, ':teardown');
				checkKind(':before', Before);
				checkKind(':after', After);
				if(kind == null) kind = Test;
				
				var description = switch field.meta.extract(':describe') {
					case []: fname;
					case v: [for(v in v) v.params[0].getString().sure()].join('\n');
				}
				var timeout = getTimeout(field.meta, clstimeout);
				var variants = switch field.meta.extract(':variant') {
					case []: [];
					case v: 
						function subst(e:Expr)
							return switch e {
								case macro this.$field: 
									macro @:pos(e.pos) (@:privateAccess this.target.$field);
								case macro this: 
									macro @:pos(e.pos) (@:privateAccess this.target);
								default:
									e.map(subst);
							}
						
						var ret = [];
						for(v in v) {
							var desc, args;
							switch v.params {
								case [{expr: ECall(e, params)}]: 
									desc = e.getString().sure();
									args = params.map(subst);
								case p: 
									desc = [for(e in p) e.toString()].join(', ');
									args = p.map(subst);
							}
							ret.push({description: desc, pos: v.pos, args: args});
						}
						ret;
				}
				
				var exclude = field.meta.extract(':exclude').length > 0;
				var include = field.meta.extract(':include').length > 0;
				
				// inject AssertionBuffer
				var bufferIndex = -1;
				function prepareBuffer(type) {
					switch type {
						case TFun(args, ret):
							for(i in 0...args.length)
								switch args[i].t {
									case TDynamic(null): // ignore
									case t if(Context.unify(t, Context.getType('tink.unit.AssertionBuffer'))):
										bufferIndex = i;
										break;
									default:
								}
						case TLazy(f): prepareBuffer(f());
						default:
					}
				}
				prepareBuffer(field.type);
				
				fields.push({
					field: field,
					kind: kind,
					include: include,
					exclude: exclude,
					variants: variants,
					bufferIndex: bufferIndex,
					description: description,
					timeout: timeout,
				});
			}
			
			infos.set(type, {
				type: type,
				name: suiteName,
				timeout: clstimeout,
				fields: fields,
			});
		}
		
		return infos.get(type);
	}
	
	static function getTimeout(meta:MetaAccess, def:Int)
		return switch meta.extract(':timeout') {
			case []: def;
			case [v]: switch v.params {
					case [{expr: EConst(CInt(i))}]: Std.parseInt(i);
					case [{pos: pos}]: pos.error('Expected integer parameter for @:timeout');
					default: v.pos.error('Expected exactly one parameter for @:timeout');
				}
			case p: p[0].pos.error('Multiple @:timeout meta');
		} 
	
	static function transformPos(p:Position, ?methodName:String, ?className:String) {
		return if(POS_REGEX.match(Std.string(p))) {
			lineNumber: Std.parseInt(POS_REGEX.matched(2)),
			fileName: POS_REGEX.matched(1).split('/').pop(),
			methodName: methodName,
			className: className,
		} else null;
	}
}

private typedef TestInfo = {
	type:Type,
	name:String,
	timeout:Int,
	fields:Array<{
		field:ClassField,
		kind:Kind,
		include:Bool,
		exclude:Bool,
		variants:Array<{description:String, pos:Position, args:Array<Expr>}>,
		bufferIndex:Int,
		description:String,
		timeout:Int,
	}>,
}

private enum Kind {
	Setup;
	Teardown;
	Before;
	After;
	Test;
}
