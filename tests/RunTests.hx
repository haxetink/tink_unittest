package ;

using tink.CoreApi;

class RunTests {

  static function main() {
    var result = tink.unit.TestRunner.run([
      new MyTest(),
      new MyTest2(),
      new MyTest3(),
    ]);
    // result.handle(function(o) trace(haxe.Json.stringify(o)));
  }
  
}

class MyTest {
  public function new() {
    
  }
  
  @:describe("My assertion")
  public function mytest() {
    return Future.async(function(cb) haxe.Timer.delay(cb.bind(Success(Noise)), 1000));
  }
  
  @:describe("My assertion b")
  public function mytest2() {
    return Future.sync(Failure(new Error('j')));
  }
}

class MyTest2 {
  public function new() {
    
  }
  
  @:timeout(500)
  @:describe("My assertion2")
  public function mytest() {
    return Future.async(function(cb) haxe.Timer.delay(cb.bind(Success(Noise)), 1000));
  }
  public function testSync() {
    return Noise;
  }
  public function testOutcome() {
    return Success(Noise);
  }
  public function testFuture() {
    return Future.sync(Noise);
  }
}


@:await
class MyTest3 {
  public function new() {
    
  }
  
  @:async public function mytest0() {
    @:await Future.async(function(cb) haxe.Timer.delay(cb.bind(Noise), 1000));
    return Noise;
  }

  @:async public function mytest1() {
    @:await Future.async(function(cb) haxe.Timer.delay(cb.bind(Noise), 1000));
    return Noise;
  }

  @:async public function mytest2() {
    @:await Future.async(function(cb) haxe.Timer.delay(cb.bind(Noise), 1000));
    return Noise;
  }

  @:async public function mytest3() {
    @:await Future.async(function(cb) haxe.Timer.delay(cb.bind(Noise), 1000));
    return Noise;
  }
}