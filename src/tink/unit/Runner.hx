package tink.unit;

import tink.unit.Case;
import tink.unit.Suite;
import tink.unit.Reporter;

using tink.CoreApi;

class Runner {
	
	public static function run(batch:Batch, ?reporter:Reporter):Future<BatchResult> {
		
		if(reporter == null) reporter = new BasicReporter();
		
		return Future.async(function(cb) {
			reporter.report(RunnerStart).handle(function(_) {
				var iter = batch.suites.iterator();
				var results:BatchResult = [];
				function next() {
					if(iter.hasNext()) {
						var suite = iter.next();
						runSuite(suite, reporter).handle(function(o) {
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
	
	
	static function runSuite(suite:Suite, reporter:Reporter):Future<SuiteResult> {
		return Future.async(function(cb) {
			reporter.report(SuiteStart(suite.info)).handle(function(_) {
				var iter = suite.cases.iterator();
				var results = [];
				function next() {
					if(iter.hasNext()) {
						var caze = iter.next();
						runCase(caze, reporter).handle(function(r) {
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
	
	static function runCase(caze:Case, reporter:Reporter):Future<CaseResult> {
		return Future.async(function(cb) {
			reporter.report(CaseStart(caze.info)).handle(function(_) {
				
				// TODO: add timeout
				caze.execute().collect().handle(function(o) {
					var results = {
						info: caze.info,
						results: switch o {
							case Success(assertions): assertions;
							case Failure(e): [Failure(e)];
						}
					}
					reporter.report(CaseFinish(results)).handle(function(_) cb(results));
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