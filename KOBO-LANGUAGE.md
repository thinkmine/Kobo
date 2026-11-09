# The Kobo Programming Language

## Language version 0.1.47

This specification describes Kobo source as accepted by the version 0.1.47
compiler and runtime. Examples are Kobo unless marked as configuration or
console output. Language syntax, type rules, runtime behavior, errors, and
tooling limits are described separately; examples do not grant forms that
the accompanying rules reject.

### Reading this specification

- **Lexical forms and program structure:** source files, modules, imports,
  statement boundaries, comments, and literals.
- **Values and types:** declarations, nullability, collections, native JSON,
  console commands, unions, expressions, and conversions.
- **Control flow and functions:** branching, iteration, lambdas, delegates,
  generics, asynchronous operations, and exceptions.
- **Type declarations:** classes, interfaces, structs, records, enums,
  events, properties, indexers, constructors, operators, extensions, and
  native external calls.
- **Applications and tools:** scripts, application directives, typed AI
  prompts, project integration, editor behavior, and configuration.

The precise requirements within each section take precedence over a summary
or an illustrative snippet. A .NET library may expose additional types or
members; importing a namespace does not change Kobo's syntax or install a
dependency. A host/project must supply external dependencies separately.

### Lexical and binding conventions

Kobo is case-sensitive. Identifiers name types, modules, members, variables,
and parameters; a name must be declared in an accessible scope before it can
be used. A qualified module or import path separates namespace segments
with `/`; member access uses `.`. A declaration keyword and its colon/type
are adjacent (`function:int`, `var:string`, `class:Name`). A space after a
declaration colon is invalid. Parameters use `Type name`, and attributes
and modifiers precede declarations in square brackets.

Braces delimit statement blocks and type bodies. Ordinary single-line
statements may omit their final semicolon; multiline query statements must
end with one. `//` starts a line comment; `/* ... */` encloses a block
comment. A line containing only `###` starts or ends a Markdown comment block;
the block may continue to the end of the file. Markdown comment blocks are
ignored as Kobo source and can contain prose and other Markdown. During
compilation, when at least one such block is present, the compiler also writes
a `.kobo.md` file containing the Markdown blocks as Markdown and the code
outside them in fenced `kobo` code blocks. String literals use quotes.
Within a Markdown comment block, `\###` is an escaped heading marker: it
remains in the comment and is emitted as `###`, without its backslash.
`verbatim "..."` disables escapes and
interpolation; `raw "..."` disables escapes but keeps interpolation.
`${expression}` interpolates Kobo expressions; `\${...}` remains literal. Prompt bodies have distinct lexical rules
documented under [native AI prompts](#native-ai-prompts).

Local `var` uses its initializer to infer a type. Explicit annotations are
available for variables, fields, parameters, members, and return values.
`?`, `?.`, and `??` handle nullable values. `union(T,U)` is permitted as a
variable type and preserves the declared case order. At a public API boundary,
ensure types are accessible from the consuming module. Name resolution,
assignments, overload selection, and operator legality are checked during
compilation; unknown names and incompatible types are errors rather than
implicit new declarations.

For installation and step-by-step standalone, mixed-project, and single-file
walkthroughs, start with [Get Started with Kobo](GET-STARTED.md).

## Hello, world

Kobo is a statically typed, object-oriented language for .NET. It combines a
compact declaration syntax with functions, generics, query expressions, and
the .NET library ecosystem.

Save the following program as `hello.kobo`:

```kobo
import * from System

module Examples/Hello

[public] class:Program
{
    [public, static] function:void Main(string[] args)
    {
        Print("Hello, world!")
    }
}
```

Install the command-line compiler with the .NET 11 SDK:

```sh
dotnet tool install --global thinkmine.kobo.lang --prerelease
kobo build hello.kobo --output-directory ./build --name Hello
dotnet ./build/Hello.dll
```

The build produces an assembly and, for an executable, a runtime configuration.
A static `Main` method supplies the application entry point. A program without
one builds as a library. `Main` can accept a `string[]` of command-line arguments;
an `int` return value supplies the application's exit code.

Kobo is currently a preview language. This guide describes the implemented
language and tooling; it is not a guarantee of a finalized language specification.

## Program structure

A source file can contain imports, a module declaration, types, global functions,
and extension blocks. Statements within function bodies execute in order.
Identifiers are case-sensitive. Braces delimit blocks; indentation communicates
structure to the reader but does not replace braces.

### Imports

See the [complete imports and type replacement guide](IMPORTS.md) for syntax,
scope rules, and migration examples.

`import` makes namespaces and types available in the current file. It does not
replace references in your source with fully qualified type names:

```kobo
import * from System
import * from System/Collections/Generic
import * from System/Linq

import * from
{
    System/Net,
    System/Collections/Generic,
    System/Linq
}
```

Group multiple wildcard namespaces in one brace-enclosed, comma-separated list;
each path is imported independently.

Namespace aliases, type aliases, and static directives are supported:

```kobo
import * as Sys from System
import Math from System
import Math as M from System
import { Console as Output, static Math } from System
```

Calls such as `M.Sqrt(144)`, `Sys.Math.Sqrt(144)`, and `Output.WriteLine(...)`
remain unchanged. All `import` forms must be at file scope, even when the file
has a `module`. `static` applies only to its own compound entry. Static aliases
and wildcards are rejected.

### Fully qualified type replacement

Use `using Type [as Alias] from Namespace/Path` to explicitly substitute the
fully qualified type name. Single types, aliases, generic definitions, and
compound/multiline lists are supported:

```kobo
using Math from System
using Math as M from System
using {
    HttpClient as Client,
    HttpRequestMessage as Request,
    HttpMethod
} from System/Net/Http

var twelve_2 = M.Sqrt(144)
var twelve_3 = Math.Sqrt(256)
```

Both calls resolve directly to the type `System.Math`, including in
`#:script` files. A type replacement does not add an import alias.

Replacement declarations can appear at file, class, function, or nested-block
scope. They take effect after the completed declaration and respect lexical
shadowing. Duplicate names in one scope and conflicts with declared types are
errors. `using` does not accept wildcard or static entries.

For generic definitions, write `using List as Items from System/Collections/Generic`
and use `Items<int>`. Named imports cannot alias an open generic definition;
use type replacement or `import * from System/Collections/Generic`.

Both keywords use `/` for namespace paths and `.` for member access. Neither
installs packages. Legacy `import Namespace`, bare `Type from Namespace`,
and bare `using System;` remain invalid. A namespace
alias uses `import * as Sys from System`, not the old `import System as Sys`.
Directly qualified external types remain restricted; use an import, namespace
alias, or explicit type replacement instead.

### Modules

A module gives the declarations in a file a namespace:

```kobo
module Company/Commerce/Orders

[public] class:Order
{
    [public] property:int Number
}
```

Files declaring the same module contribute to the same logical namespace.
A module does not need to match its source directory. Without a module,
declarations belong to the global namespace.

### Comments and statement boundaries

```kobo
// A single-line comment.
/* A comment that
   spans multiple lines. */

var count = 1
count += 1;
```

Markdown comments can document a Kobo source file and produce a Markdown
companion when compiled:

```kobo
###
# H1
## H2
\### H3
#### H4
##### H5

###
function:string Greeting() => "Hello"
```

The generated Markdown contains the headings as `# H1` through `##### H5`;
the backslash before `\### H3` is removed. The Kobo declaration is fenced as
code. An unescaped delimiter line must contain only `###` (surrounding
whitespace is allowed). Each delimiter toggles between Kobo source and
Markdown; an unmatched opening delimiter comments out everything through
end of file. Markdown comment text is excluded from Kobo transformation and
compiled code.

Semicolons are optional for ordinary single-line statements. Open parentheses
and brackets, trailing operators, and leading continuation operators can extend
an expression across lines. Multiline LINQ query statements always require an
explicit terminating semicolon, even when parenthesized.

Declaration colons must touch both sides: use `class:Person`, `var:int`, and
`function:void`, not `class: Person` or `var :int`.

## Types, values, and variables

Built-in types include `bool`, `byte`, `short`, `int`, `long`, their unsigned
counterparts, `float`, `double`, `decimal`, `char`, `string`, and `object`.
Types such as arrays, collections, dates, and tasks are available through .NET.

```kobo
var:int count = 3
var message = "Welcome to Kobo"
var:bool enabled = true
var:decimal price = 19.95m
var:char initial = 'K'
const:int MaximumAttempts = 5
```

`var:Type` declares an explicit type. Local `var` declarations infer a type from
their initializer. Variables require an initial value. Assigning to a name does
not declare a variable: `value = 42` requires an existing accessible declaration;
use `var value = 42` to declare it. Unknown names produce a compiler error
(`CS0103`), including when read in expressions or used in compound assignments.
The language server also reports unresolved names in standalone-file analysis.
Cross-file and project references are resolved by the full build.
Constants require
constant expressions and cannot subsequently be assigned.

Fields in a class, struct, or record can also use `var` to infer their type
from the initializer:

```kobo
class:Counter
{
    var count = 0                          // private int field
    [public] var Name = "Kobo"             // string field
    [public, static, readonly] var Limit = 10
    var:dynamic flexible = 0
}
```

An inferred field has a fixed compile-time type; subsequent assignments must
be compatible with it. Fields are private by default, and access, `static`, and
`readonly` modifiers apply normally. Instance initializers run for each
instance; static initializers run for the type. A field initializer cannot
directly reference an instance field, method, or property; initialize
dependent instance values in a constructor instead. Declare each inferred
field separately.

Use an explicit `var:Type` when the initializer cannot determine a usable type,
such as `null`, an empty collection, `new()`, a target-typed expression, an
unresolved name, or a circular dependency between inferred fields. A
top-level dynamic initializer also needs an explicit type. Use `var:dynamic`
when dynamic binding is intentional, or an explicit base, interface, nullable,
or collection type when that is the intended contract. Previous releases used
dynamic binding for untyped fields; migrate fields that depend on that behavior
to `var:dynamic`.

Use `readonly:Type Name = value` for an initialized, read-only field:

```kobo
class:Person
{
    readonly:int Age = 30
}
```

The shorthand is valid only for fields in a class, struct, or record. The
field is private unless an access modifier is specified.

### Nullability

```kobo
var:string? nickname = null
var displayName = nickname ?? "Guest"
var length = nickname?.Length ?? 0
```

`?` marks a nullable type. `?.` performs conditional member access, and `??`
provides a replacement for a null value. Nullable analysis can be configured
through build settings.

### Arrays and collections

```kobo
var:int[] scores = [10, 20, 30]
var:List<string> names = ["Ada", "Grace"]
names.Add("Linus")
var first = names[0]
var numbers = [1, 2, 3]
var:list<int> moreNumbers = new list<int> { 4, 5 }
var:dictionary<string, int> ages =
{
    "joe": 5,
    "smith": 9
}
var inferredAges = { "joe": 5, "smith": 9 }
```

Import `System/Collections/Generic` for `List<T>` and `Dictionary<K, V>`.
Lowercase `list<T>` and `dictionary<K, V>` map to those .NET types, including
inside nested generic types. List expressions use square brackets. Dictionary
initializers use `{ key: value }` and become `new Dictionary<K, V> { [key] = value }`.
For an untyped `var`, Kobo infers dictionary key and value types from their
entries; differing types become `object`. Empty dictionaries or entries with
unknown types require an explicit `var:dictionary<K, V>`.

### The json type

`json` is a native type for working with JSON documents. A `var:json`
declaration can be initialized directly from a JSON object literal:

```kobo
var:json information =
{
    "type": "music",
    "data":[
        "one",
        "two",
        "three",
    ],
    "contact":{
        "address":"1234 street",
        "phone": "3334445555"
    }
}
```

The opening `{` may also appear on the same line as `=`.

The literal must be valid JSON (trailing commas and comments are allowed),
except that values can be Kobo expressions evaluated when the declaration runs.
Quoted keys and values support `${expression}` interpolation. Expression results are
serialized as JSON values (not inserted as raw JSON text); strings are escaped
and numbers, booleans, null, arrays, and `json` values retain their JSON types.

```kobo
var n = 9
var:json details = {
    "type": n,
    "next": n + 1,
    "message": "Number ${n}",
    "items": [n, n * 2]
}
```
Properties are read and updated with natural member syntax:

```kobo
var kind = information.type                  // "music"
var:string[] data = information.data         // ["one", "two", "three"]
var address = information.contact.address    // "1234 street"

information.type = "rock"
information.contact.address = "99 avenue"
information.year = 2024                      // adds a new property
```

JSON strings, booleans and numbers unwrap to `string`, `bool`, `int`, `long`
or `double`. Homogeneous arrays unwrap to typed arrays such as `string[]`;
nested objects stay `json` values, so member access chains naturally. Values
assigned to properties — primitives, lists, dictionaries or other `json`
values — are converted back into the underlying JSON document.

`StringValue` returns JSON text. Assign JSON text to a `json` variable to
parse it, or assign a `json` value to a `string` variable to serialize it.
These conversions are implicit; invalid JSON text throws `JsonException`.

```kobo
var:string text = information.StringValue    // the JSON text
var:json reloaded = text                     // parses JSON text
var:string copy = reloaded                    // implicit conversion to string
```

`json` values can be shared across files compiled together. Converting
invalid JSON text implicitly throws `JsonException`.
Indexer access is also supported: `information["type"]` and
`information.data[0]`.

### Console commands

`Print(...)` writes a line and accepts no arguments, a value, a format string
with arguments, or a character array with an offset and count. `Input()` reads
a line; `Input("Name: ")` writes the prompt without a newline before reading
a line. At end of input, `Input` returns `null`. `Print` returns no value.

```kobo
Print("Name: {0}", Input("Enter your name: "))
```

### Union variables

A union variable can hold values from a specified set of case types:

```kobo
var:union(int,string) result = 42
var:union(int,string) description = "Complete"
```

Both variables use the same generated type, `union_of_int_string`. Repeated
case lists share one definition within their namespace, including across files
compiled together. Whitespace does not distinguish case lists; case order does.
Nested union case types are permitted.

Union syntax is restricted to variable type declarations. Standalone declarations
such as `union:Result {}` are errors. Initializers remain required. Case types
must be accessible to the generated public namespace-level union; enclosing
generic parameters cannot be captured. Union compilation requires a toolchain
with union support.

## Expressions and operators

Kobo provides arithmetic, comparison, logical, assignment, conditional, and
null-handling expressions:

```kobo
var sum = 10 + 20
var remainder = sum % 7
var eligible = sum >= 20 && remainder != 0
var label = eligible ? "Ready" : "Waiting"
sum += 1
```

Member access uses a dot: `person.Name`, `names.Count`, and `Console.WriteLine`.
Use parentheses to express grouping explicitly.

Equality alternatives can omit a repeated operand:

```kobo
if status == 200 || 201 || 204
{
    Console.WriteLine("Success")
}
```

This compares `status` with each alternative using short-circuit evaluation.
Resolved boolean operands retain their ordinary meaning. Repeated receiver
expressions are not cached; avoid side effects in expressions used this way.
Use parentheses when mixing conjunctions and disjunctions.

## Selection statements

```kobo
if score >= 90
{
    Console.WriteLine("Excellent")
}
else if score >= 60
{
    Console.WriteLine("Passed")
}
else
{
    Console.WriteLine("Try again")
}
```

Conditions must produce boolean values. Parentheses are optional when an `if`,
`else if`, or `while` condition occupies the rest of its line. A condition and
its body on the same line require parentheses:

```kobo
if (score < 0) return
```

Switch statements select among cases:

```kobo
switch (command)
{
    case "start":
        Console.WriteLine("Starting")
        break
    default:
        Console.WriteLine("Unknown command")
        break
}
```

## Iteration statements

`foreach` visits the elements of a sequence:

```kobo
foreach name in names
{
    Console.WriteLine(name)
}

foreach var:int score in scores
{
    Console.WriteLine(score)
}
```

`foreach` also iterates over an integer range using
`[start to end by increment]`. Square brackets and `to` are required; `by`
is optional. The end remains exclusive:

```kobo
foreach item in [0 to 5 by 2]
{
    Console.WriteLine(item)   // 0, 2, 4
}

foreach item in [10 to 5 by -2]
{
    Console.WriteLine(item)   // 10, 8, 6
}

foreach index in [first to last]
{
    Console.WriteLine(index)
}
```

Without `by`, the increment is `1` when the start is below the end and `-1`
when it is above the end. Equal bounds produce no items. An explicit positive
increment counts upward; a negative increment counts downward. The increment
must be positive when the start is below the end and negative when it is
above the end. A mismatched direction is an error (reported during transformation
when all three values are integer literals, otherwise as
`ArgumentOutOfRangeException` at runtime). Equal bounds allow either nonzero
increment and produce no items. A zero
increment is an error (reported during transformation for literal `0`,
otherwise as `ArgumentOutOfRangeException` at runtime).

Bounds and increments are integer expressions evaluated once, in order, at
loop entry. `foreach` retains its usual `break`, `continue`, and scoping
behavior.
The old `foreach item in 0..5` syntax is rejected; slice expressions such
as `items[1..3]` are unchanged.

`while` repeats while its condition is true:

```kobo
var remaining = 3
while remaining > 0
{
    remaining -= 1
}
```

There is no `for` statement in Kobo; using `for` is an error. Count with a
`foreach` range or a `while` loop instead.

Use `break` to exit a loop, `continue` to begin its next iteration, and `return`
to leave the containing function.

## Functions

A function declares its return type before its name:

```kobo
[public, static] function:int Add(int left, int right)
{
    return left + right
}

[public, static] function:void WriteMessage(string message)
{
    Print(message)
}
```

Parameters must use `Type name`; `name: Type` declarations are rejected.
`params` parameters are supported, for example
`function:int Count(params int[] values) => values.Length`. Callers may supply
zero or more individual arguments or pass an array.
The return type is required; use `void` when no value is returned. The declaration keyword is `function`,
not `func`. Type-member functions can be overloaded with different parameter signatures.

Global functions are declared outside types:

```kobo
function:int Square(int value)
{
    return value * value
}
```

Global functions in the same module share a generated `Global` container.
Global function names must be unique within a module, including across files.
Global functions cannot be overloaded, even with different parameter types,
parameter counts, return types, or generic arities. Type-member overloads remain allowed.
Top-level functions in a `#:script` file must also have unique names.

Global constants use `const:Type Name = value` outside any type. They are
available to other Kobo declarations in the same module and are exposed
through the module's `Global` type.

Unqualified calls to global functions are emitted as `Global.Name(arguments)`
when no local callable takes precedence. This includes repeated and nested calls
and functions with parameters. Required arguments must still be supplied; a
missing or incompatible argument produces a compilation error, not an
unknown-function error.

### Generics

```kobo
[public] class:Box<T>
{
    [public] property:T Value { get; set; }
}

[public, static] function:T Identity<T>(T value) where T is struct
{
    return value
}
```

Type parameters let classes and functions work with many types while preserving
type checking. Constraints restrict the acceptable type arguments.

### Function contracts

Attach one Boolean expression per `requires` or `ensures` line immediately
after a function or constructor header. Preconditions run before the body;
postconditions run before each successful return. `result` names the value
being returned in a non-void function. The editor highlights `result` as a
special contract identifier inside `ensures`; elsewhere, it remains an ordinary
identifier.

```kobo
function:int Divide(int numerator, int denominator)
    requires denominator != 0
    ensures result >= 0
{
    return numerator / denominator
}
```

Failed preconditions raise `ArgumentException`; failed postconditions raise
`InvalidOperationException`. Constant false conditions are rejected during
compilation. Expressions must be side-effect-free; calls, member access,
mutation, and allocation are not allowed in contracts. Constructors support
preconditions but not postconditions.
Contracts on iterators, ref-returning functions, multiline signatures, and
implicit member expressions are not currently supported.

## Lambdas and delegate types

A lambda describes an inline function:

Statements inside lambda blocks may end with a semicolon or simply a newline,
just like ordinary function statements. This applies to assigned lambdas,
lambda arguments, and trailing lambdas; both styles can be mixed in one block.

```kobo
var:(int)->int doubleValue = value => value * 2
var answer = doubleValue(21)

var:(string)->void write = message =>
{
    Console.WriteLine(message)
}
```

Delegate types have the form `(<parameter-types>)-><return-type>`.
Examples include `()->void`, `(string)->bool`, and `(int,int)->int`.

### Named delegate declarations

Declare a named delegate type with `delegate:(<parameters>)-> ReturnType Name`.
Parameters use the same `Type name` syntax as functions:

```kobo
[public] delegate:(int left, int right)-> int Combine
delegate:()-> void Notify
delegate:(T value)-> T TransformValue<T>
```

Use the name in variable and parameter types:

```kobo
var:Combine add = (left, right) => left + right
var result = add(20, 22)
```

Declarations may appear at global scope or inside types, not inside functions.
Access modifiers and attributes follow ordinary type rules; global delegates
default to `internal`, nested delegates to `private`. Generic constraints,
`ref`/`out`, defaults, and `params` parameters follow the matching Kobo
function parameter rules.
Declaration-ending semicolons are optional.

A lambda assigned to a `->void` delegate type cannot return a value; the
compiler reports an error pointing at the offending `return` statement.
A bare `return` is allowed, as are value returns inside nested lambdas.

A function with a final delegate parameter can accept a trailing lambda block:

```kobo
[static] function:string Find(List<string> names, (string)->bool predicate)
{
    foreach name in names
    {
        if predicate(name)
        {
            return name
        }
    }
    return "<not found>"
}
```

Inside another function:

```kobo
var:List<string> names = ["Ada", "Grace"]
var match = Find(names)
{
    name => name == "Grace"
}
```

The trailing block supplies the last argument; it is not an independent block.
Its opening `{` may appear on the call line or the next line, with or without
an argument list:

```kobo
error{
    Print("This is an error")
}

error
{
    Print("This is an error")
}
```

An explicit lambda arrow may be followed by the expression on the next line:

```kobo
Search(numbers){
    x =>
    x == 7
}
```

This predicate is evaluated as a lambda argument returning `x == 7`.

For a delegate with no parameters, the arrow can be omitted:

```kobo
function:void Run(()->void action)
{
    action()
}

// Inside another function:
Run{
    Console.WriteLine("First")
    Console.WriteLine("Second");
}
```

## Classes and objects

Classes describe reference types with state and behavior:

Classes must be declared at global scope. Declaring a class inside another
type is a Kobo error; nested classes are not supported. Other nested type
kinds, including structs, records, and delegates, are unaffected.

```kobo
[public] class:Person
{
    [private] var:int visits = 0
    [public] property:string Name { get; set; }
    [public] property:int Age
    [public] property:int NextAge => Age + 1

    [public] function:void Greet()
    {
        visits += 1
        Print("Hello, ${Name}!")
    }
}
```

Create and use an instance inside a function:

```kobo
var person = new Person()
person.Name = "Ada"
person.Age = 36
person.Greet()
```

### Accessibility and modifiers

Modifier lists precede declarations in square brackets:

```kobo
[public, sealed] class:Settings
{
    [public, static] property:string ApplicationName => "Kobo App"
}
```

Modifiers must be written inside a square-bracketed declaration list; a
modifier written outside the brackets is an error.

`public` exposes a declaration; `private` restricts it to its containing type;
`internal` restricts it to its assembly. `protected` exposes inherited members
to derived types. `static` associates a member with its type rather than an
instance. `readonly`, `abstract`, `virtual`, `override`, and `sealed` express
additional constraints where valid. Prefer explicit accessibility on APIs.

Attributes also appear in declaration lists:

```kobo
[public, Obsolete("Use NewService instead")]
class:OldService
{
}
```

Import `System` for `Obsolete`.

### Partner classes

Mark a class `[partner]` and list it with `partners` on each collaborator. A
partner class remains a normal standalone class; `new Identity(...)` and
`var:Identity` refer to that standalone type. Each collaborator receives its
own private nested partner implementation, so its CLR type is distinct from
the standalone class and from implementations in other collaborators.

Use `calls Identity(arguments)` in a collaborator constructor to initialize
its nested partner. Each constructor must initialize every declared partner
exactly once. If every partner has a public parameterless constructor, the
compiler creates the instances automatically when the collaborator has no
constructor or a constructor without a `calls` clause. A partner with no
declared constructor has an implicit public parameterless constructor.

Only partner fields, properties, and functions marked `[shared]` are available
inside a collaborator; other members remain inaccessible even if they are
non-private. Shared members are not added to the collaborator's public API.
Unqualified names resolve to locals and parameters first, then collaborator
members, then shared partner members. If multiple partners provide the same
name, qualify it with the partner name, such as `Identity.Name`.
`new Identity(...)` always creates the standalone class; the generated nested
implementation cannot be named or constructed in Kobo code.

```kobo
[partner] class:Identity
{
    [public, shared] var:string Name = ""
    [public] new(string name)
    {
        Name = name
    }
    [public, shared] function:string GetName() => Name
}

[public] class:Worker partners Identity
{
    [public] new(string name) calls Identity(name)
    {
    }

    [public] function:string GetName()
    {
        return Identity.Name
    }

    [public] function:string StandaloneName()
    {
        var:Identity other = new Identity("Jane")
        return other.GetName()
    }
}
```

The partner class and its collaborators must currently be in the same Kobo
file. Partner classes may inherit ordinary classes but cannot inherit other
partner classes.

### Inheritance, interfaces, and polymorphism

Use `is` to name a base class or implemented interface:

`is` is the only inheritance and interface-implementation syntax. Separate
multiple base types with commas, as in `class:Service is BaseService, IContract`.
Colon-based base lists and keywords such as `inherits`, `extends`, and
`implements` are rejected. Generic constraints use `where T is Constraint`.

```kobo
[public] interface:ISpeaker
{
    function:string Speak()
}

[public, abstract] class:Animal is ISpeaker
{
    [public, abstract] function:string Speak()
}

[public] class:Dog is Animal
{
    [public, override] function:string Speak()
    {
        return "Woof"
    }
}
```

Polymorphism selects the implementation belonging to the runtime object:

```kobo
var:Animal animal = new Dog()
Console.WriteLine(animal.Speak())
```

Abstract members require implementations in concrete derived classes.
Virtual members provide implementations that derived classes can override.
`parent.Member()` invokes an accessible parent implementation.

### Structs and records

Structs define value types; records describe data-oriented types:

Classes and structs cannot declare primary constructors: `class:Name(...)`
and `struct:Name(...)` are Kobo errors. Declare constructors inside the type
body instead. Positional records such as `record:Message(string Text)` remain
allowed.

```kobo
[public] struct:Point
{
    [public] property:int X
    [public] property:int Y
}

[public] record:Message
{
    [public] property:string Text { get; set; }
}
```

### Enums

Declare an enum with `enum:Name` and comma-separated members:

```kobo
[public] enum:Color
{
    Red,
    Green = 7,
    Blue
}
```

The enum has the specified members and values.
Use members as `Color.Green`. Values default to consecutive integers starting
at zero; an explicit value changes the following implicit values.

An underlying integer type may be specified with `enum:Color : byte`.
Attributes such as `[Flags]`, access modifiers, trailing commas, and compact
declarations (`enum:Color { Red, Green, Blue }`) are supported. Enums may be
top-level or nested inside types, but not inside functions. Enum members use
commas, not statement-ending semicolons. Enum values must fit the underlying
integer type.

### Events

Declare an event member with `event:DelegateType EventName`:

```kobo
[public] delegate:(int value)-> void ChangedHandler

[public] class:Publisher
{
    [public] event:ChangedHandler Changed

    [public] function:void Raise(int value)
    {
        Changed?.Invoke(value)
    }
}
```

Subscribe with `publisher.Changed += handler` and unsubscribe with
`publisher.Changed -= handler`. Events may use named delegates, imported delegate
types such as `Action`, or inline types such as `(int)->void`.

Events must be type members, not globals or local variables. Class, struct, and
record events default to `private`; interface events follow their declared
contract. Access modifiers, attributes, and `static` are supported.
Declaration-ending semicolons are optional. Only compatible delegates can
subscribe to an event; only its declaring type can invoke it.

### Indexers

Indexers expose indexed access to an object:

```kobo
[public] class:Directory
{
    var:List<string> names = ["Ada", "Grace"]
    [public] indexer:string this[int index] => names[index];
    [public] indexer:string Names[int index] => names[index];
}
```

The `this` form supports `directory[0]`; named indexers support
`directory.Names[0]`.

### Scoped member access

`scope` avoids repeating an object receiver:

```kobo
scope(person)
{
    .Name = "Grace"
    .Age = 40

    if .Age >= 18
    {
        .Name = .Name.ToUpper()
    }
}
```

Leading dots within the block refer to the scoped receiver. A scope body is a
regular block: it can contain local variables, conditional statements, loops,
function calls, and other ordinary logic.

A `scope` block cannot contain another `scope`, even inside a conditional or
loop in its body. Nested scopes are rejected with a Kobo diagnostic.

### Constructors

Inside a class, struct, or record, declare a constructor using `new(...)`:

```kobo
[public] class:TestClass is BaseClass
{
    [public] new() : this(10)
    {
    }

    [public] new(int value) calls parent(value)
    {
        parent.Initialize()
    }
}
```

The parameterless constructor delegates to the `int` overload; the second
invokes the base constructor. A bare `new()` constructor defaults to
`private`, like ordinary class members. Constructor access modifiers include
`protected internal` and `private protected`
combinations for classes. Struct constructors do not allow `protected`.
Other modifiers, such as `virtual`, `override`, or `static`, are rejected.
Parameters follow ordinary function rules. Initializers select another constructor with `: this(...)` or a parent
constructor with `calls parent(...)`. `parent.Member` accesses a parent member.

### Operator overloads and conversions

Declare operators inside classes, structs, or records:

```kobo
[public] operator:PersonBase +(PersonBase a, PersonBase b)
{
    // Return a PersonBase value.
}

[public] operator:PersonBase =(string str)
{
    // Implicit conversion from string to PersonBase.
}

[public] operator:PersonBase cast(string str)
{
    // Explicit conversion from string to PersonBase.
}
```

The `+` form overloads addition. `=` declares an implicit conversion and
`cast` declares an explicit conversion. Operators are public and static;
`static` need not be written. Unary and binary overloadable symbols are
supported. Bodies follow normal function rules, including expression bodies
and optional statement semicolons. The operator must have the proper number
of operands, involve its containing type, and obey paired-operator and
conversion rules. Operators cannot be declared globally or inside functions.

### Native extern functions

Declare native library functions with `extern:ReturnType Name(parameters)`.
The modifier/attribute list must contain exactly one `source("library")`, which
generates `[DllImport("library")]`. Kobo always generates `static extern` and
adds `using System.Runtime.InteropServices;` when an extern declaration is used.
Multiline parameter lists and an optional terminating semicolon are supported.
Extern functions cannot have bodies or generic type parameters.

```kobo
import * from System

[public, source("user32.dll")]
extern:int MessageBoxW(IntPtr hWnd,
    string text,
    string caption,
    uint type)
```

This generates a public static extern method with `[DllImport("user32.dll")]`
and a terminating semicolon. Global extern functions follow normal global
function access and name-uniqueness rules; extern type members follow normal
member access rules. `[source("library"), extern] function:...` is also supported.
The library must be available on the target platform when the method is called.

### Type extensions

Type extensions add methods, properties, and indexers to an existing type
without changing its original declaration. Declare these members inside an
`extension:Type` block:

Parentheses around the receiver type are optional: `extension:(string)` and
`extension:string` are equivalent.

Properties may be declared inside extension blocks using `property:Type Name`.
Expression-bodied properties and explicit `get`/`set` accessor bodies are
supported. Instance accessors can use `this` to read or update the receiver;
static properties cannot use `this`.

```kobo
extension:string
{
    [public] function:int CharacterCount()
    {
        return this.Length
    }

    [public] property:bool IsEmpty => this.Length == 0

    [public]
    property:int MeaninglessLength
    {
        get
        {
            return this.Length
        }
    }

    [public] indexer:char Characters[int index] => this[index];
}
```

Within the appropriate namespace, call `"Kobo".CharacterCount()` or access
`"Kobo".IsEmpty`. Extension indexers must be named; declarations using
`indexer:Type this[...]` are rejected. `this` remains valid inside their bodies.
The named indexer supports `"Kobo".Characters[0]`, which returns `'K'`.
Extension blocks share an `Extensions` container within a file. The block is
internal by default; `public` is its only supported explicit modifier. Blocks
in one file must agree on accessibility. Members have their own modifiers and
default to `private`, as in classes. `this` refers to the receiver in instance
methods, properties, and indexer bodies; it refers to the current receiver.
The receiver is always declared as `extension(Type @instance)`. Static members
have no receiver instance and using `this` inside them is a Kobo error.
The former `extension(Type receiver)` source syntax is no longer accepted.

## Query expressions

Import `System/Linq` to use the standard sequence query operators.

### Select-first queries

```kobo
var names = select person from people
            where person.Age > 30
            orderby person.Name asc
            project person.Name;
```

Clauses appear in the following order:

```text
select <identifier> from <expression>
    [join <identifier> from <expression> on <left> == <right>]*
    [where <condition>]
    [group <expression> by <expression> [into <identifier>]]
    [orderby <expression> [asc|desc]]
    [skip <count>] [take <count>]
    [project <expression> [| list|first|last|count|sum|average|min|max|average(<selector>)|min(<selector>)|max(<selector>)]]
```

Without `project`, the initial identifier is selected. Ordering defaults to
ascending. An anonymous projection collects several values:

```kobo
var results = select person from people
              join order from orders on person.Id == order.PersonId
              project {
                  person.Name,
                  order.Total
              };
```

Joins require an equality condition. Non-equality join conditions are errors.

Grouping produces sequences keyed by the `by` expression. Name the grouped
results with `into` before ordering or projecting them:

```kobo
var summaries = select person from people
                group person by person.Age into ages
                orderby ages.Key desc
                project { Age = ages.Key, Count = ages.Count() };
```

Without a subsequent projection, a grouping query returns its groups.

### Paging with `skip` and `take`

`skip <count>` passes over the first results and `take <count>` keeps at most
that many. Both are optional, appear after `where`, `group`, and `orderby`
clauses and before `project`, and `skip` comes before `take`. Counts can be
literals or any in-scope expression:

```kobo
var page_size = 5
var planets_that_start_with_m = select planet from planet_list
                                join name from names on planet == name
                                where planet.StartsWith('m')
                                skip 10 take page_size
                                project planet;
```

Paging applies to the complete query result, after ordering.

### Result steps with `|`

A query normally produces a lazily evaluated sequence. Follow the `project`
expression with `|` and a result step to produce a different result:

| Step | Result |
| --- | --- |
| `\| list` | A `List<T>` containing every result |
| `\| first` | The first result, or the type's default value when there are none |
| `\| last` | The last result, or the type's default value when there are none |
| `\| count` | The number of results, as an `int` |
| `\| average` | The average of numeric results |
| `\| sum` | The total of numeric results |
| `\| min` | The smallest result |
| `\| max` | The largest result |
| `\| average(selector)` | The average of the selector's numeric values |
| `\| min(selector)` | The smallest value the selector returns |
| `\| max(selector)` | The largest value the selector returns |

```kobo
var planets = select planet from planet_list
              where planet.StartsWith('m')
              project planet | list;
var first_match = select planet from planet_list orderby planet project planet | first
var matching = select planet from planet_list where planet.StartsWith('m') project planet | count

var average_age = select p from people
                      where p.Age > 25
                      project p.Age | average;
var youngest = select p from people project p.Age | min
```

`average` and `sum` require a numeric projection, such as `p.Age` or
`order.Total * 1.1`; projecting text reports an error at the `|`. `min` and
`max` are intended for numbers and also compare other ordered values, such as
dates. Project the value to aggregate, as in `project p.Age | average`, or give
`average`, `min`, or `max` a selector that picks the value from each result:

```kobo
var shortest_name = select planet from planet_list project planet | min(p => p.Length)
var longest_name = select planet from planet_list project planet | max(p => p.Length)
var average_age = select p from people project p | average(p => p.Age)
```

A selector is a single lambda (or delegate) applied to each projected result.
The step returns the selected value, not the item: `| min(p => p.Length)` is
the length of the shortest name. An `average` selector must return a number.
Only `average`, `min`, and `max` accept a selector; `list`, `first`, `last`,
`count`, and `sum` take no arguments. `sum` of an empty query is
`0`. `average`, `min`, and `max` of an empty query of numbers fail at run time
with `InvalidOperationException`, so check `| count` first when a query may have
no results.

A step applies after paging, so `skip 10 take 5 ... project item | count`
counts at most five results. A query that spans lines ends with `;`, and the
`|` may start a new line:

```kobo
var oldest = select p from people
             orderby p.Age
             project p.Age
             | max;
```

Only one step is allowed, and it must end the query. To combine the projected
value with another value using bitwise OR, parenthesize it:
`project (flags | mask)`. `skip`, `take`, and the step names keep their keyword
meaning only in these query positions, so they remain usable as variable names
elsewhere, including as the projected value itself (`project count`).

Queries must use the select-first form. From-first expressions
(`from person in people ...`) are rejected, including nested queries.
Multiline query statements require explicit terminating semicolons.

## Exceptions and resource management

Exceptions propagate until a matching handler processes them:

```kobo
try
{
    var number = int.Parse(text)
    Console.WriteLine(number)
}
catch FormatException error
{
    Console.WriteLine(error.Message)
}
finally
{
    Console.WriteLine("Finished")
}
```

Use `throw new InvalidOperationException("...")` to report an invalid operation.
Parentheses around a catch declaration are optional: `catch Exception error`
and `catch (Exception error)` are equivalent. Use `catch Exception` when the
exception value is not needed, or bare `catch` to handle any exception.
Each catch body is a braced block. Filters retain a parenthesized condition:

```kobo
catch Exception error when (error.Message.Length > 0)
{
    Console.WriteLine(error.Message)
}
```

Disposable resources can be enclosed in a `using` statement within a function:

```kobo
using (var reader = File.OpenText("message.txt"))
{
    Console.WriteLine(reader.ReadToEnd())
}
```

Import `System/IO` for file operations.

## Asynchronous functions

Import `System/Threading/Tasks` for task types:

```kobo
[public, static, async] function:Task Pause()
{
    await Task.Delay(100)
    Console.WriteLine("Ready")
}
```

`async` allows awaiting asynchronous operations. Awaiting suspends the function
without requiring the caller's thread to block for the duration.

## Building programs

### Single-file programs

```sh
kobo build hello.kobo
dotnet hello.dll
```

The default assembly name is the input filename without its extension. Output
is written beside the input unless `--output-directory` is supplied.
Use `--name` to change the assembly name.

### Multi-file compilation

Create these files in `GreetingApp`:

`Greeter.kobo`:

```kobo
module Examples/Greetings

[public] class:Greeter
{
    [public] function:string Message()
    {
        return "Hello from two files!"
    }
}
```

`Program.kobo`:

```kobo
import * from System
module Examples/Greetings

[public] class:Program
{
    [public, static] function:void Main()
    {
        var greeter = new Greeter()
        Console.WriteLine(greeter.Message())
    }
}
```

Build the folder into one assembly:

```sh
kobo build ./GreetingApp --output-directory ./build --name Greetings
dotnet ./build/Greetings.dll
```

All discovered files participate in one compilation. Files in the same module
share generated global-function containers and union definitions. Duplicate
global function names are errors, even when their signatures differ.

### Nested directory compilation

Given a tree such as:

```text
GreetingApp/
  Program.kobo
  Services/
    Greeter.kobo
  Models/
    Person.kobo
```

Build the tree recursively:

```sh
kobo build ./GreetingApp --recursive --output-directory ./build --name Greetings
```

Without `--recursive`, only the selected folder's immediate files are included.
Recursive discovery skips `bin`, `obj`, and symbolic-link directories.
Extensions are matched case-insensitively and files are processed in ordinal
path order. Folder structure does not declare modules automatically.

With no input path, `kobo build` selects the current folder:

```sh
kobo build
kobo build --recursive
```

When supplying both output options, place `--output-directory` before `--name`.
Quote paths containing spaces. An empty discovery result or failed compilation
is an error. `--recursive` is not valid with a single-file input.

If a compiled source or a file run with `kobo run` contains a Markdown comment
block, the compiler writes `<filename>.kobo.md` next to that source's output.
Markdown is extracted before Kobo code is transformed, so it is still written
when the remaining Kobo code has a compilation error. Use
`--markdown <relative-path>` to choose a different Markdown output path for a
single-file build; it is relative to the output directory. For a folder build,
the option names a relative output directory, and each generated
`<filename>.kobo.md` retains its source-relative path beneath that directory.
Sources without Markdown comment blocks do not produce Markdown files.

### Single-file application directives

A standalone app can describe its SDK, build properties, and package
dependencies at the top of its source file:

```kobo
#:sdk Microsoft.NET.Sdk
#:property Nullable=enable
#:package Newtonsoft.Json@13.0.3

import * from System
import * from Newtonsoft/Json

[public] class:Program
{
    [public, static] function:void Main()
    {
        Console.WriteLine(JsonConvert.SerializeObject(new { Message = "Hello!" }))
    }
}
```

Build and run it with the same single-file workflow:

```sh
kobo build app.kobo --output-directory ./build --name App
dotnet ./build/App.dll
```

| Directive | Purpose | Example |
| --- | --- | --- |
| `#:script` | Allows top-level Kobo statements and local functions in one source file. | `#:script` |
| `#:sdk` | Selects an SDK for the app build. SDK names may carry a version where supported by the installed SDK tooling. | `#:sdk Microsoft.NET.Sdk` |
| `#:property` | Supplies an MSBuild property using `Name=Value`. Repeat for additional properties. | `#:property Nullable=enable` |
| `#:package` | Adds a NuGet dependency, optionally pinned with `@version`. Repeat for additional dependencies. | `#:package Newtonsoft.Json@13.0.3` |

Use `#:script` to enable top-level Kobo statements in one source file.
The former `#:app` marker is no longer accepted. To execute a file directly,
place `#:script` as the first statement and use `kobo run path/to/file.kobo`.
Whitespace and Markdown comment blocks may precede the directive; they are
ignored while the script is identified and executed, and Markdown is written to
the companion file. No other Kobo statements may appear before `#:script`.
This requires the .NET 11 SDK: Kobo compiles and launches
`dotnet run --file`, forwarding console I/O and the application exit code.
Place it before Kobo code; it takes no value. Top-level variables become local
variables, and top-level functions become local functions that can capture
those variables. These functions are not emitted in the generated `Global`
class. Type declarations remain ordinary top-level Kobo types.

To pass command-line arguments, use
`kobo run path/to/file.kobo -- Ada "two words" --verbose`.
The required `--` separator is consumed by Kobo; everything after it is
available unchanged in the script's top-level `string[] args` array, including
empty quoted strings and values beginning with `-`. For this command,
`args[0]` is `"Ada"`, `args[1]` is `"two words"`, and `args[2]` is
`"--verbose"`. With no arguments, or just a trailing `--`, `args` is empty.
Additional arguments without the separator are rejected.

```kobo
#:script
import * from System

var:string message = "Hello from Kobo"
PrintMessage()

function:void PrintMessage()
{
    Console.WriteLine(message)
}
```

In a multi-file build, only the file marked with `#:script` gets these semantics;
global functions in other files continue to be generated in `Global`. Without
`#:script`, ordinary Kobo global-function behavior is unchanged.

#### `verbatim` and `raw` strings

Kobo has three string forms: ordinary quoted strings, `verbatim "..."`, and
`raw "..."`. Place `verbatim` or `raw` immediately before a quoted string to
turn off ordinary escape processing. Both are contextual keywords: they only
have this meaning when followed by a string, so `raw` and `verbatim` remain
usable as identifiers. The `@"..."` and triple-quoted (`"""..."""`) string
forms are not part of Kobo and are reported as errors.

`verbatim "..."` presents its text exactly as written. Backslashes are not
escapes and `${...}` is not interpolated. Write `""` for a quote character. A
verbatim string may span lines; line breaks and indentation are kept.

```kobo
var:string path = verbatim "c:${hello}//\\"     // c:${hello}//\\
var:string quoted = verbatim "say ""hi"""         // say "hi"
```

`raw "..."` ignores backslashes and other special characters, but `${...}`
interpolation continues to work. Code-looking text inside is never treated as
code. When the opening quote ends its line and the closing quote sits on its
own line, the closing quote's indentation is removed from every line, and the
first and last line breaks are not part of the value. Every content line must
start with that indentation.

```kobo
var:string x = raw "
                    The quick
                    brown
                    fox
                    jumped over the lazy dog!
                    "
var:string folder = raw "C:\files\${name}\{draft}"   // C:\files\Kobo\{draft}
```

The value of `x` is the four lines without their leading indentation.
Text that starts on the opening line keeps every character, including line
breaks and indentation. A `raw` string opened with one quote cannot contain
`"`; open it with three or more quotes, such as `raw """He said "hi" """`,
and close it with the same number. Use a longer delimiter, such as `raw """"`,
when the text contains three consecutive quotes. `raw ""` is an empty string.
Because backslashes are literal in a `raw` string, `\${...}` is a backslash
followed by an interpolation; write `${"$" + "{"}` to produce the text `${`.

#### String interpolation

`${expression}` is Kobo's interpolation syntax in ordinary quoted and
`raw "..."` strings. `verbatim "..."` strings never interpolate. The compiler
evaluates Kobo interpolation:

```kobo
var:string greeting = "hello ${first_name} ${last_name}"
```

Placeholder contents follow Kobo interpolation syntax:
`${expression[,alignment][:formatString]}`. Expressions support the same
operations used elsewhere in Kobo, including arithmetic, member/indexer
access, calls, casts,
object creation, nested strings, and `await` in an asynchronous context.
Alignment and format strings use .NET formatting rules:

```kobo
var:string total = "Total: ${price * quantity,12:F2}"
var:string padded = "Code: ${42:D4}"                 // Code: 0042
var:string label = "${name,-20}"                    // left-aligned
var:string choice = "${(count > 0 ? count : 0):D3}"
```

Parenthesize conditional expressions when combining them with
alignment or formatting; unformatted `${flag ? "yes" : "no"}` also remains
supported. Normal Kobo type and scope rules apply; alignment must be a
constant integer, and format strings use .NET formatting rules.
Literal braces are preserved. Except in `raw "..."` strings, write `\${name}`
to include the literal text `${name}`. `@{name}` has no special meaning. Other interpolation
prefixes (`$"..."`, `$@"..."`, `@$"..."`, and `$"""..."""`)
are errors, including inside Kobo placeholders. Only Kobo `${...}`
interpolation is allowed in source.

#### Native AI prompts

`prompt:Type name { ... }` declares a variable initialized by an asynchronous
AI request. Use it at native `#:script` top level or inside an `[async]` function
with a compatible task return type. Function signatures are not made async
implicitly.

```kobo
#:script
import * from System

var:string city = "Lagos"
prompt:int population {
    Estimate the population of ${city}. Return a JSON integer.
}
if population is int number
{
    Console.WriteLine(number)
}
else if population is string text
{
    Console.WriteLine("Unconverted response: ${text}")
}
```

The effective type is Kobo's existing `union(Type,string)`. A `string` prompt
remains a plain string. Primitive, custom object, and collection results use
JSON deserialization. For providers requiring object-shaped response schemas,
primitive and collection results are requested inside a JSON `value` property
and unwrapped before returning the typed Kobo value. A response that cannot be
converted to the requested type retains its original text in the string alternative. Authentication,
network, configuration, cancellation, timeout, and tool failures propagate as
exceptions rather than becoming successful string results.

Prompt bodies have their own lexical context: JSON, Markdown, XML, comments,
quotes, and balanced nested braces are literal text. `${expression}` evaluates
in the surrounding Kobo scope, `\${...}` escapes interpolation, and `@{...}`
is literal. Common leading indentation and surrounding blank lines are removed.
`prompt:union(int,bool)` result types, including nested unions, reuse existing
unions and add a string alternative only when absent. Their JSON alternatives
are tried in declaration order, preserving the requested union's nesting.

Place exactly `kobo.ai.json` next to the source application or in the
containing .NET project:

```json
{
  "provider": "Ollama",
  "model": "llama3.2",
  "endpoint": "http://localhost:11434",
  "options": {
    "temperature": 0.2,
    "maxOutputTokens": 1000,
    "timeoutSeconds": 120,
    "maxToolCalls": 10
  }
}
```

Supported providers are `Ollama`, `OpenAI`, and `AzureOpenAI` (case-insensitive).
OpenAI and AzureOpenAI require `key` (the existing `apiKey` name remains supported);
AzureOpenAI also requires `endpoint`,
and its `model` is the deployment name. For hosted providers, keep credentials
in the environment:

```json
{
  "provider": "OpenAI",
  "model": "gpt-4o-mini",
  "key": "${OPENAI_API_KEY}"
}
```

The key is passed as the provider credential: OpenAI uses bearer authentication,
AzureOpenAI uses its API-key authentication, and Ollama sends an optional
`Authorization: Bearer <key>` header for authenticated remote endpoints.
Ollama remains usable without a key. If both `key` and `apiKey` are specified,
their resolved values must match. Provider selection must match the endpoint's
API protocol; specifying a key does not turn an Ollama endpoint into an Azure one.

Environment substitution happens at runtime, not during compilation. Missing
variables, invalid options, and missing configuration fail explicitly without
printing credential values. Configuration is external and copied unchanged to
build/publish output, including when publishing a single-file executable.
Runtime discovery uses an explicitly supplied content root (or
`AppContext`'s `Kobo.ContentRoot`), otherwise the application directory, with an
explicit development project directory as a final option. Hosts may also pass
an explicit configuration path. There is no parent-directory search or
alternate filename fallback.

Mark eligible functions with `[tool]` to make them available automatically:

```kobo
[tool, description("Adds two integers")]
function:int Add(int left, int right) => left + right

prompt:int total {
    Use Add to calculate ${20} plus ${22}.
}
```

The compiler generates typed delegates, not reflection-based assembly scans.
Ordinary global functions and accessible static type methods are supported.
Native app-level local functions may capture initialized application variables.
Tools are combined across Kobo files; duplicate/overloaded tool names, invalid
attribute placement, instance methods without receivers, generic tools,
ref/out/ref-like signatures, and async void tools are rejected. Explicit
`[tools(...)]` prompt lists are not used. Descriptions and delegate parameter
metadata are retained.

The separate `Kobo.AI` runtime uses `Microsoft.Extensions.AI`, reuses one lazily
initialized client per application context, and isolates concurrent prompt
state. Requests have cancellation, timeout, and tool-count limits. Unknown
tools, invalid arguments, failed tools, denied approvals, and recursive AI calls
from tools fail explicitly. Hosted applications can create a
`KoboAIContext`, set `ToolApproval`, and enter its `EnterScope()` to provide a
policy or injected `IChatClient`; asynchronous disposal is supported. Such
hosts can pass cancellation tokens through the runtime API.

The Azure adapter is pinned to `Azure.AI.OpenAI` `2.8.0-beta.1` to match the
OpenAI 2.8 dependency required by `Microsoft.Extensions.AI.OpenAI` 10.3; the older
stable Azure 2.1 adapter is binary-incompatible with that combination.

A complete local-provider example is in
[`samples/native-ai`](samples/native-ai). Build it with
`kobo build samples/native-ai/main.kobo --output-directory ./build --name NativeAI`.
Run `dotnet ./build/NativeAI.dll` with Ollama running and `llama3.2` installed.

#### Referencing .NET libraries

Libraries included in the app's target framework are available without a package
directive. Import their namespaces using Kobo's forward-slash notation:

```kobo
import * from System/IO
import * from System/Net/Http
import * from System/Collections/Generic
```

For a library distributed through NuGet, add a `#:package` directive and then
import the namespace containing the types you want to use:

```kobo
#:package Newtonsoft.Json@13.0.3

import * from Newtonsoft/Json
```

Inside a function, its public APIs can then be called normally:

```kobo
var json = JsonConvert.SerializeObject(new { Name = "Ada" })
```

The package ID and namespace are separate names and need not match. `#:package`
adds the dependency; `import` only brings a namespace into scope. Repeat
`#:package` for each direct package dependency. Pinning a version with `@version`
makes the requested dependency version explicit.

The single-file CLI does not provide a directive for referencing an arbitrary
local DLL, and `#:project` is not supported. Distribute a reusable library as a
NuGet package, or use a project with BuildTools and configure its assembly or
project references there.

The compiler passes these directives through to the SDK, which validates their
values, resolves dependencies, and reports build failures. Directive-based
builds require the .NET SDK and use configured NuGet sources. They may need
network access for restoration. Native ahead-of-time publishing is disabled
by the current CLI's directive build path.

`#:project` is not supported. Use exactly `#:property`, not `#property`.
SDK, property, and package directives are restricted to standalone single-file
compilation; multi-file batches reject them. `#:script` may be used in one file
of a multi-file build. When using BuildTools in an existing project, configure
SDK selection, properties, and dependencies in that project rather than in
Kobo source files.

SDK properties that change the output type, assembly name, or output layout
can conflict with CLI output expectations. This workflow expects the named
assembly to be produced in the selected output directory.

## Editor and project integration

### Kobo files in a .NET project

BuildTools discovers `.kobo` files in an SDK-style .NET project and includes
their public declarations in its assembly. A project can contain multiple
Kobo modules, use referenced .NET libraries, and configure its dependencies,
build properties, and SDK in the project. BuildTools discovers nested Kobo
files automatically and excludes build-output directories.

Modules determine the namespace of Kobo declarations; directory names do
not. Imports remain local to each file. Kobo files in the same module share
global functions and union definitions. The project's final compilation
resolves accessible cross-file types; explicit annotations clarify public
contracts and help editor analysis.

For example, `Greeting.kobo` defines a reusable Kobo class:

```kobo
module Example/Greetings

[public] class:Greeting
{
    [public] function:string For(string name)
    {
        return "Hello, ${name}, from Kobo!"
    }
}
```

Other Kobo files can import `Example/Greetings` and use the public class.
When using BuildTools, no separate Kobo assembly is needed for each file.

### Project settings and editor support

For project-owned Kobo files, configure package dependencies, assembly
references, SDK selection, and build properties in the containing project.
Standalone app directives such as `#:package` are not accepted in these
files; `#:script` can mark one file for top-level statements. The Kobo VS
Code extension provides highlighting, diagnostics, and completion for Kobo
declarations, available .NET members, and symbols in other workspace `.kobo`
files, including unsaved open documents. Within prompt bodies, only
`${expression}` receives expression completion; surrounding text remains plain.
The language server does not load the consuming project's dependency graph,
so project-specific references are checked by the project compilation.

This preview requires a .NET 11 compiler host with Roslyn 5.9 or newer, including
the editor's compiler host. Selecting a project target framework does not itself
upgrade that host. If a project build succeeds but the editor cannot resolve
Kobo-defined types, check the editor's generator-loading diagnostics and host
compatibility, and reload the project after package changes.

See the [BuildTools guide](Kobo.Lang.BuildTools/README.md) for package details,
file-discovery controls, and compatibility requirements. For standalone Kobo
programs rather than embedded project files, use the command-line build workflow
described earlier in this guide.

For installation details, see the
[command-line compiler guide](Kobo.Lang.Compiler/README.md).
