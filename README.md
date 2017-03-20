# Tink Unit Test Framework [![Build Status](https://travis-ci.org/haxetink/tink_unittest.svg?branch=master)](https://travis-ci.org/haxetink/tink_unittest)

## Usage

1. Tag instance methods with metadata (see below)
2. Create a test batch with `TestBatch.make([...])`
3. Run it with `Runner.run(batch)`
4. Handle the results and exit accordingly

Supported metadata:

- `@:startup`: Run once before all tests
- `@:before`: Run before each tests
- `@:after`: Run after each tests
- `@:shutdown`: Run once after all tests
- `@:timeout(int)`: Set timeout (in ms), default: 5000 (you can also put this at class-level)
- `@:describe(string)`: Set description of test, default: name of function
- `@:variant(params)`: Add variants to a test (see example below)
- `@:include`: Only run tests tagged with `@:include`
- `@:exclude`: Exclude this test

```haxe
import tink.testrunner.Runner;
import tink.unit.Assert.assert;

using tink.CoreApi;

class RunTests {
	static function main() {
		Runner.run(TestBatch.make([
			new NormalTest(),
			new AwaitTest(),
		])).handle(function(result) {
			exit(result.summary().failures.length);
		});
	}
}

class NormalTest {
	public function new() {}
	
	@:before public function before() return Noise;
	@:after public function after() return Noise;
	@:startup public function startup() return Noise;
	@:shutdown public function shutdown() return Noise;
	
	@:describe('Sync test')
	public function sync()
		return new Assertion(true, 'Always true');
    
	@:describe('Test using Assert')
	public function syncAssert()
		return assert(true);
		
	@:describe('Async test')
	public function async()
		return Future.sync(new Assertion(true, 'Always true'));
		
	@:describe('Async test using Assert')
	public function asyncAssert()
		return Future.sync(assert(true));
		
	@:timeout(500) // in ms
	@:describe('Timeout test')
	public function timeout()
		return Future.async(function(cb) haxe.Timer.delay(function() cb(assert(true)), 1000));
		
		
	@:describe('Nest')
	@:describe('  your')
	@:describe('    descriptions')
	public function nestedDescriptions()
		return assert(true);
		
	@:describe('Variants')
	@:variant("Variant description" (1, 1))
	@:variant(2, 2)
	@:variant(target.myInt, 3) // access public fields of "this" with "target.field"
	public function variant(a:Int, b:Int) {
		debug('variant$a');
		return assert(a == b);
	}
	
	public var myInt = 3;
}

@:await
class AwaitTest {
  public function new() {}
  
	@:describe('Async test powered by tink_await')
	@:async public function async() {
		var actual = @:await someAsyncValue();
		return assert('expected' == actual);
	}
	
	function someAsyncValue() 
		return Future.async(function(cb) haxe.Timer.delay(function() cb('actual'), 1000));
}
```