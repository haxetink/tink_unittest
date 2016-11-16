# Tink Unit Test Framework

## Usage

Tag instance methods with metadata and pass them to `TestRunner.run()`

Supported metadata:

- `@:startup`: Run once before all tests
- `@:before`: Run before each tests
- `@:after`: Run after each tests
- `@:shutdown`: Run once after all tests
- `@:timeout(int)`: Set timeout (in ms), default: 5000 (you can also put this at class-level)
- `@:describe(string)`: Set description of test, default: name of function

```haxe
import tink.unit.TestRunner.*;
import tink.unit.Assert.*;
using tink.CoreApi;

class RunTests {
	static function main() {
		run([
			new NormalTest(),
			new AwaitTest(),
		]).handle(function(result) {
			exit(result.errors);
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
		return true ? Success(Noise) : Failure(new Error('Errored!'));
    
	@:describe('Test using Assert')
	public function syncAssert()
		return isTrue(true);
		
	@:describe('Async test')
	public function async()
		return Future.sync(true ? Success(Noise) : Failure(new Error('Errored!')));
		
	@:describe('Async test using Assert')
	public function asyncAssert()
		return Future.sync(isTrue(true));
		
	@:timeout(500) // in ms
	@:describe('Timeout test')
	public function timeout()
		return Future.async(function(cb) haxe.Timer.delay(function() cb(isTrue(true)), 1000));
		
		
	@:describe('Nest')
	@:describe('  your')
	@:describe('    descriptions')
	public function nestedDescriptions()
		return isTrue(true);
}

@:await
class AwaitTest {
  public function new() {}
  
	@:describe('Async test powered by tink_await')
	@:async public function async() {
		var actual = @:await someAsyncValue();
		return equals('expected', actual);
	}
  
  function someAsyncValue() 
    return Future.async(function(cb) haxe.Timer.delay(function() cb('actual'), 1000));
}
```