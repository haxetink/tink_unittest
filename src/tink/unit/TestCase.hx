package tink.unit;

using tink.CoreApi;

typedef TestCase = {
	name:String,
	tests:Lazy<Array<Test>>,
}

typedef Test = {
	description:String,
	timeout:Int,
	result:Lazy<TestResult>,
}

@:forward
abstract TestResult(Surprise<Noise, Error>) from Surprise<Noise, Error> to Surprise<Noise, Error> {
	@:from
	public static inline function ofOutcome(v:Outcome<Noise, Error>):TestResult
		return Future.sync(v);
		
	@:from
	public static inline function ofNoise(v:Noise):TestResult
		return ofOutcome(Success(v));
		
	@:from
	public static inline function ofFuture(v:Future<Noise>):TestResult
		return v.map(function(r) return Success(r));
}