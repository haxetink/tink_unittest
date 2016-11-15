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
		
	@:timeout(1500) // in ms
	@:describe('Timeout test')
	public function timeout()
		return Future.async(function(cb) haxe.Timer.delay(function() cb(isTrue(true)), 1000));
		
		
	@:describe('Nest')
	@:describe('  your')
	@:describe('    descriptions')
	public function nestedDescriptions()
		return isTrue(true);
    
	@:describe('Multiple assertions')
	public function multiAssert()
		return isTrue(true) && isTrue(true) && isTrue(true);
}

@:await
class AwaitTest {
  public function new() {}
  
	@:describe('Async test powered by tink_await')
	@:async public function async() {
		var actual = @:await someAsyncValue();
		return equals('actual', actual);
	}
  
  function someAsyncValue() 
    return Future.async(function(cb) haxe.Timer.delay(function() cb('actual'), 1000));
}