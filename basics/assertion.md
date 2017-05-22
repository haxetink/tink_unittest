# Assertions

In addition to the ways to construct an assertion as [mentioned](https://haxetink.github.io/tink_testrunner/#/basics/assertion) in `tink_testrunner`, `tink_unittest` provides a handy function ease the process.

## Macro solution

By using `tink.unit.Assert.assert` to create an `Assertion`, 
the description will be automatically filled by the stringified input expression.

```haxe
tink.unit.Assert.assert(value == 1);
```

will be transformed to:

```haxe
new Assertion(value == 1, 'value == 1');
```

In other words, your Haxe code will be printed on screen so that one can easily
identify what the assertion is about.