package tink.unit;

import haxe.macro.Expr;
import tink.unit.TestCase;
using tink.CoreApi;

typedef Result = {
	total:Int,
	errors:Int,
	details:Array<{
		total:Int,
		errors:Array<Error>
	}>,
}
class TestRunner {
	
	public static macro function run(e:ExprOf<Array<Dynamic>>):ExprOf<Future<Result>>
		return Macro.run(e);
		
	public static function runAll(runners:Array<RunnerBase>):Future<Result> {
		log('');
		return Future.async(function(cb) {
			var iter = runners.iterator();
			var result = [];
			function next() {
				if(iter.hasNext()) {
					var current = iter.next(); 
					var name = current.name; 
					log(name);
					current.run().handle(function(o) {
						result.push({
							name: name,
							total: o.total,
							errors: o.errors,
						});
						next();
					});
				} else {
					var total = 0;
					var errors = 0;
					for(r in result) {
						total += r.total;
						errors += r.errors.length;
					}
					log('\n$total Tests   ${total - errors} Success   $errors Errors\n');
					cb({
						total: total,
						errors: errors,
						details: result,
					});
				}
			}
			next();
		});
	}
	
	public static function log(msg:String) {
		#if travix
			travix.Logger.println(msg);
		#elseif js
			untyped console.log(msg);
		#elseif sys
			Sys.println(msg);
		#end
	}
	
	public static function exit(code:Int) {
		#if travix
			travix.Logger.exit(code);
		#elseif js
			// TODO;
		#elseif sys
			Sys.exit(code);
		#end
	}
}

#if !macro @:genericBuild(tink.unit.Macro.buildRunner()) #end
class Runner<T> {}

class RunnerBase {
	public var name(default, null):String;
	
	var startups:Array<Test>;
	var shutdowns:Array<Test>;
	var befores:Array<Test>;
	var afters:Array<Test>;
	var tests:Array<Test>;
	
	var testing:Bool;
	var errors:Array<Error>;
	var total:Int;
	
	public function run() {
		errors = [];
		total = 0;
		testing = false;
		return _run(startups) >>
			function(_) {
				testing = true; 
				return _run(tests, befores, afters);
			} >>
			function(_) {
				testing = false; 
				return _run(shutdowns);
			} >>
			function(_) return {total: total, errors: errors}
	}
	
	public function _run(tests:Array<Test>, ?befores:Array<Test>, ?afters:Array<Test>):Future<Noise> {
		if(befores == null) befores = [];
		if(afters == null) afters = [];
		return Future.async(function(cb) {
			var iter = tests.iterator();
			function next() {
				if(iter.hasNext()) {
					
					function sub(tests) {
						return Future.async(function(cb) {
							var oldTesting = testing;
							testing = false;
							_run(tests).handle(function() {
								testing = oldTesting;
								cb(Noise);
							});
						});
					}
					
					sub(befores).handle(function(o) {
						// run test
						var current = iter.next();
						if(testing) {
							total++;
							for(desc in current.descriptions)
								log('  $desc');
						}
						var timer = null;
						var done = false;
						var run = current.run();
						var link = run.result.handle(function(o) {
							switch o {
								case Success(_): // ok
								case Failure(f):
									if(testing)
										errors.push(f);
									log('    ' + f.toString());
							}
							done = true;
							if(timer != null) timer.stop();
							sub(afters).handle(next);
						});
						
						if(!done)
							timer = haxe.Timer.delay(function() {
								link.dissolve();
								var error = new Error('Timeout after ${current.timeout}ms' #if !macro, run.pos #end);
								log('    ' + error.toString());
								if(testing) errors.push(error);
								sub(afters).handle(next);
							}, current.timeout);
					});
					
				} else {
					cb(Noise);
				}
			}
			next();
		});
	}
	
	public inline function asRunner():RunnerBase return this;
	inline function log(msg) TestRunner.log(msg);
}