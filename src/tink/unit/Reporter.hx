package tink.unit;

import tink.unit.Suite;
import tink.unit.Case;
import tink.unit.Runner;

using tink.CoreApi;
using Lambda;

interface Reporter {
	function report(type:ReportType):Future<Noise>;
}

enum ReportType {
	RunnerStart;
	SuiteStart(info:SuiteInfo);
	CaseStart(info:CaseInfo);
	CaseFinish(result:CaseResult);
	SuiteFinish(result:SuiteResult);
	RunnerFinish(result:Array<SuiteResult>);
}

class BasicReporter implements Reporter {
	
	var noise = Future.sync(Noise);
	
	public function new() {}
	
	public function report(type:ReportType):Future<Noise> {
		switch type {
			case RunnerStart:
				
			case SuiteStart(info):
				Sys.println(info.name);
				
			case CaseStart(info):
				Sys.println(info.description);
				
			case CaseFinish({results: results}):
				
			case SuiteFinish(result):
				
			case RunnerFinish(result):
				var total = 0;
				var errors = 0;
				for(s in result) {
					for(c in s.cases) {
						total += c.results.length;
						errors += c.results.count(function(r) return !r.isSuccess());
					}
				}
				var success = total - errors;
				Sys.println('$total Assertions   $success Success   $errors Errors');
				
		}
		return noise;
	}
}