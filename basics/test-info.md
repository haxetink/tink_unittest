# Test Info

## Test Description

By default, the test method name will be used as the test description.
One can override the behavior by tagging the test method with `@:describe`

```haxe
@:describe('Awesomeness should be awesome')
public function awesome() {...}
```