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
