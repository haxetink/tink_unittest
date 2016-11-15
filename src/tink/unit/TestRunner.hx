package tink.unit;

import tink.unit.TestCase;
using tink.CoreApi;

class TestRunner {
	
	public static macro function run(e:haxe.macro.Expr)
		return Macro.run(e);
		
	public static function runAll(cases:Array<TestCase>) {
		log('');
		return Future.async(function(cb) {
			var iter = cases.iterator();
			var result = [];
			function next() {
				if(iter.hasNext()) {
					var current = iter.next(); 
					log(current.name);
					runCase(current.tests.get()).handle(function(o) {
						result.push({
							name: current.name,
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
					cb(result);
				}
			}
			next();
		});
	}
	
	static function runCase(tests:Array<Test>) {
		return Future.async(function(cb) {
			var iter = tests.iterator();
			var errors = [];
			var total = 0;
			function next() {
				if(iter.hasNext()) {
					total++;
					var current = iter.next();
					log('  ' + current.description);
					var timer = null;
					var done = false;
					var link = current.result.get().handle(function(o) {
						switch o {
							case Success(_): // ok
							case Failure(f):
								errors.push(f);
								log('    ' + f.toString());
						}
						done = true;
						if(timer != null) timer.stop();
						next();
					});
					
					if(!done)
						timer = haxe.Timer.delay(function() {
							link.dissolve();
							var error = new Error('Timeout after ${current.timeout}ms');
							log('    ' + error.toString());
							errors.push(error);
							next();
						}, current.timeout);
				} else {
					cb({
						total: total,
						errors: errors,
					});
				}
			}
			next();
		});
	}
	
	static function log(msg:String) {
		#if travix
			travix.Logger.println(msg);
		#elseif js
			untyped console.log(msg);
		#elseif sys
			Sys.println(msg);
		#end
	}
	
	static function exit(code:Int) {
		#if travix
			travix.Logger.exit(code);
		#elseif js
			// TODO;
		#elseif sys
			Sys.exit(code);
		#end
	}
}