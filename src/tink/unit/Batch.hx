package tink.unit;

@:forward
abstract Batch(BatchObject) from BatchObject to BatchObject {
	@:from
	public static inline function ofSuites(suites:Array<Suite>):Batch
		return {
			info: {},
			suites: suites,
		}
		
	@:from
	public static inline function ofSuite(suite:Suite):Batch
		return ofSuites([suite]);
	
	@:from
	public static inline function ofCases(cases:Array<Case>):Batch
		return ofSuite(cases);
		
	@:from
	public static inline function ofCase(caze:Case):Batch
		return ofCases([caze]);
}

typedef BatchObject = {
	var info:BatchInfo;
	var suites:Array<Suite>;
}

typedef BatchInfo = {
	
}
