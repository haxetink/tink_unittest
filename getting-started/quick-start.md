# Quick Start

## Install

### With Haxelib

`haxelib install tink_unittest`

### With Lix

`lix install haxelib:tink_unittest`

## A Basic Test

```haxe
import tink.unit.*;
import tink.unit.Assert.*;
import tink.testrunner.*;

class Main {
	static function main() {
		Runner.run(TestBatch.make([
			new Test(),
		])).handle(Runner.exit);
	}
}

class Test {
	public function new() {}
	
	public function test()
		return assert(true);
}
```

1. Copy the code above and save it as `Main.hx`
1. Build it with: `haxe -js tests.js -lib hxnodejs -lib tink_unittest -main Main`
1. Run the test: `node tests.js`
