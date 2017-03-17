package tink.unit;

@:forward
abstract Batch(BatchObject) from BatchObject to BatchObject {
	@:from
	public static inline function ofSuites<T:Suite>(suites:Array<T>):Batch
		return new BasicBatch({}, cast suites);
		
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

interface BatchObject {
	var info:BatchInfo;
	var suites:Array<Suite>;
}

typedef BatchInfo = {
	
}

class BasicBatch implements BatchObject {
	public var info:BatchInfo;
	public var suites:Array<Suite>;
	
	public function new(info, suites) {
		this.info = info;
		this.suites = suites;
	}
}