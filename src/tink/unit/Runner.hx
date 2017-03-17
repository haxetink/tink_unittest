package tink.unit;

import tink.unit.Case;
import tink.unit.Suite;
import tink.unit.Reporter;
import tink.unit.Timer;
import tink.unit.impl.HaxeTimer;

using tink.CoreApi;

class Runner {
	
	public static function run(batch:Batch, ?reporter:Reporter, ?timers:TimerManager):Future<BatchResult> {
		
		if(reporter == null) reporter = new BasicReporter();
		if(timers == null) timers = new HaxeTimerManager();
		
		return Future.async(function(cb) {
			reporter.report(RunnerStart).handle(function(_) {
				var iter = batch.suites.iterator();
				var results:BatchResult = [];
				function next() {
					if(iter.hasNext()) {
						var suite = iter.next();
						runSuite(suite, reporter, timers).handle(function(o) {
							results.push(o);
							reporter.report(SuiteFinish(o)).handle(next);
						});
					} else {
						reporter.report(RunnerFinish(results)).handle(cb.bind(results));
					}
				}
				next();
			});
		});
	}
	
	
	static function runSuite(suite:Suite, reporter:Reporter, timers:TimerManager):Future<SuiteResult> {
		return Future.async(function(cb) {
			reporter.report(SuiteStart(suite.info)).handle(function(_) {
				var iter = suite.cases.iterator();
				var results = [];
				function next() {
					if(iter.hasNext()) {
						var caze = iter.next();
						runCase(caze, reporter, timers).handle(function(r) {
							results.push(r);
							next();
						});
					} else {
						cb({
							info: suite.info,
							cases: results,
						});
					}
				}
				
				next();
			});
		});
	}
	
	static function runCase(caze:Case, reporter:Reporter, timers:TimerManager):Future<CaseResult> {
		return Future.async(function(cb) {
			reporter.report(CaseStart(caze.info)).handle(function(_) {
				
				function complete(assertions) {
					var results = {
						info: caze.info,
						results: assertions,
					}
					reporter.report(CaseFinish(results)).handle(function(_) cb(results));
				}
				
				var done = false;
				var timer = null;
				var link = caze.execute().collect().handle(function(o) {
					done = true;
					if(timer != null) timer.stop();
					complete(switch o {
						case Success(assertions): assertions;
						case Failure(e): [Failure(e)];
					});
				});
				
				var timeout = caze.info != null && caze.info.timeout != null ? caze.info.timeout : 5000;
				
				if(!done)
					timer = timers.schedule(timeout, function() {
						if(!done) link.dissolve();
						timer = null;
						complete([Failure(new Error('Timed out after $timeout ms'))]);
					});
			});
		});
	}
}

@:forward
abstract BatchResult(Array<SuiteResult>) from Array<SuiteResult> to Array<SuiteResult> {
	public function errors() {
		var ret = [];
		for(s in this) for(c in s.cases) for(a in c.results)
			switch a {
				case Success(_): // skip
				case Failure(_): ret.push(a);
			}
		return ret;
	}
}

typedef SuiteResult = {
	info:SuiteInfo,
	cases:Array<CaseResult>,
}

typedef CaseResult = {
	info:CaseInfo,
	results:Array<Assertion>,
}