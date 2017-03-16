package tink.unit;

@:forward
abstract Batch(BatchObject) from BatchObject to BatchObject {
	@:from
	public static inline function ofSuites<T:Suite>(suites:Array<T>):Batch
		return {
			info: {},
			suites: cast suites,
		}
		
	@:from
	public static inline function ofSuite(suite:Suite):Batch
		return ofSuites([suite]);
	
	@:from
	public static inline function ofCases<T:Case>(cases:Array<T>):Batch
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
