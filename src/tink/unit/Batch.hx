package tink.unit;

import tink.unit.Suite;

@:forward
abstract Batch(BatchObject) from BatchObject to BatchObject {
	@:from
	public static function fromSuites(v:Array<Suite>):Batch
		return {
			info: null,
			suites: v,
		}
}

typedef BatchObject = {
	var info:BatchInfo;
	var suites:Array<Suite>;
}

typedef BatchInfo = {
	
}

class TinkBatch {
	public var info:BatchInfo;
	public var suites:Array<Suite>;
	
	public function new(suites:Array<TinkSuite>) {
		var includeMode = false;
		for(s in suites) if(s.includeMode.value) {
			includeMode = true;
			break;
		}
		if(includeMode) for(s in suites) s.includeMode.value = true;
		this.suites = [for(s in suites) s];
	}
}