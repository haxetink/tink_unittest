package tink.unit;

import tink.unit.Suite;
import tink.unit.Case;
import tink.unit.Runner;
using tink.CoreApi;

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
		Sys.println(Std.string(type));
		return noise;
	}
}