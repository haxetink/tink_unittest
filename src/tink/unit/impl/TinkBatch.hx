package tink.unit.impl;

import tink.unit.Batch;
import tink.unit.Suite;

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