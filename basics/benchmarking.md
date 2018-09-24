# Benchmarking

To benchmark a piece of code, make your class implements the `tink.unit.Benchmark` interface.
It will transform members functions tagged with `@:benchmark(iterations)` into a format compatible to the test runner.

```haxe
class MyTest implements tink.unit.Benchmark {
	@:benchmark(10000)
	public function bench() {
		for(i in 0...5000) Math.sqrt(i);
	}
}
```

The above code is essentially converted by the build macro to the following: 

```haxe
class MyTest {
	public function bench() {
		var start = haxe.Timer.stamp();
		for(_ in 0...10000) for(i in 0...5000) Math.sqrt(i);
		var dt = haxe.Timer.stamp() - start;
		return new tink.testrunner.Assertion(true, 'Benchmark: 10000 iterations = ${dt}s');
	}
}
```
