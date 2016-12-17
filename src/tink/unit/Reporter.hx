package tink.unit;

import tink.unit.TestRunner;
using tink.CoreApi;
using Lambda;

interface Reporter {
	function log(event:LogEvent):Void;
}

class SimpleReporter implements Reporter {
	public function new() {}
	public function log(event:LogEvent) {
		var str = switch event {
			case All(Begin):
				'';
			case All(End({total: total, errors: errors})):
				'\n$total Tests   ${total - errors} Success   $errors Errors\n';
			case Collection(info, Begin):
				info.name;
			case Collection(info, End(result)):
				null;
			case Individual(info, Begin):
				info.descriptions.map(function(d) return '   $d').join('\n');
			case Individual(info, End(Success(_))):
				null;
			case Individual(info, End(Failure(e))):
				'      ' + e.toString();
			

		}
		
		if(str != null) {
			#if travix
				travix.Logger.println(str);
			#elseif js
				untyped console.log(str);
			#elseif sys
				Sys.println(str);
			#end
		}
	}
}

enum LogEvent {
	All(progress:Progress<AllResult>);
	Collection(info:RunnerBase, progress:Progress<CollectionResult>);
	Individual(info:Test, progress:Progress<Outcome<Noise, Error>>);
}

enum Progress<T> {
	Begin;
	End(result:T);
}