# The Kobo Programming Language

Kobo is an AI-conscious, general-purpose programming language built for the
.NET ecosystem. Designed from the ground up with both human developers and AI
code generation in mind, Kobo emphasizes syntactic consistency, expressive
programming constructs, and reduced complexity. Unlike traditional languages
that evolved primarily around human-written code, Kobo recognizes AI as an
increasingly important participant in software development. Its predictable
grammar, consistent declaration patterns, and streamlined syntax aim to make
code easier to generate, understand, validate, and maintain. Kobo combines
modern language design with the maturity and performance of the .NET platform.

**Version:** `0.1.8-preview`

For installation and step-by-step standalone, mixed-project, and single-file
walkthroughs, start with [Get Started with Kobo](GET-STARTED.md). For the
language's design goals, see [Why Kobo?](WHY-KOBO.md).

## Hello, world

Kobo is a statically typed, object-oriented language for .NET. It combines a
compact declaration syntax with functions, generics, query expressions, and
the .NET library ecosystem.

Save the following program as `hello.kobo`:

```kobo
import System

module Examples/Hello

[public] class:Program
{
    [public, static] function:void Main(string[] args)
    {
        Console.WriteLine("Hello, world!")
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

Imports make the members of a namespace available without repeating its full name:

```kobo
import System
import System/Collections/Generic
import System/Linq
```

Kobo uses forward slashes for namespace paths. The notation follows the web's
familiar vocabulary of routes and resources: `Company/Commerce/Orders` reads as
a navigable hierarchy, from a broad domain to a focused capability. Dots remain
the language of member access, keeping namespace navigation visually distinct
from operations on values.

An import brings names into scope; it does not install a dependency.

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
their initializer. Variables require an initial value. Constants require
constant expressions and cannot subsequently be assigned.

Use explicit types for fields when compile-time checking is desired: inferred
fields use dynamic binding.

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
```

Import `System/Collections/Generic` for `List<T>`. Collection expressions use
square brackets. Explicit collection types make the intended shape unambiguous;
inference is available in supported contexts.

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

`while` repeats while its condition is true:

```kobo
var remaining = 3
while remaining > 0
{
    remaining -= 1
}
```

A `for` loop combines initialization, a condition, and an iteration expression:

```kobo
for (var i = 0; i < 3; i++)
{
    Console.WriteLine(i)
}
```

Use `break` to exit a loop, `continue` to begin its next iteration, and `return`
to leave the containing function.

## Functions

A function declares its return type before its name:

```kobo
[public, static] function:int Add(int left, int right)
{
    return left + right
}

[public, static] function:void Print(string message)
{
    Console.WriteLine(message)
}
```

Parameters must use `Type name`; `name: Type` declarations are rejected. The return type is required;
use `void` when no value is returned. The declaration keyword is `function`,
not `func`. Functions can be overloaded with different parameter signatures.

Global functions are declared outside types:

```kobo
function:int Square(int value)
{
    return value * value
}
```

Global functions in the same module share a generated `Global` container.
Duplicate signatures are errors; overloads are retained.

### Generics

```kobo
[public] class:Box<T>
{
    [public] property:T Value { get; set; }
}

[public, static] function:T Identity<T>(T value) where T : struct
{
    return value
}
```

Type parameters let classes and functions work with many types while preserving
type checking. Constraints restrict the acceptable type arguments.

## Lambdas and delegate types

A lambda describes an inline function:

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

## Classes and objects

Classes describe reference types with state and behavior:

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
        Console.WriteLine($"Hello, {Name}!")
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

### Inheritance, interfaces, and polymorphism

Use `is` to name a base class or implemented interface:

`is` is the only inheritance and interface-implementation syntax. Separate
multiple base types with commas, as in `class:Service is BaseService, IContract`.
Colon-based base lists and keywords such as `inherits`, `extends`, and
`implements` are rejected. Generic constraints still use `where T : Constraint`;
that colon is not an inheritance declaration.

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
`base.Member()` invokes an accessible base implementation.

### Structs and records

Structs define value types; records describe data-oriented types:

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

### Type extensions

Type extensions add methods, properties, and indexers to an existing type
without changing its original declaration. Declare these members inside an
`extension(Type receiver)` block:

```kobo
[public] extension(string text)
{
    [public] function:int CharacterCount()
    {
        return text.Length
    }

    [public] property:bool IsEmpty => text.Length == 0

    [public] indexer:char this[int index] => text[index];
    [public] indexer:char Characters[int index] => text[index];
}
```

Within the appropriate namespace, call `"Kobo".CharacterCount()` or access
`"Kobo".IsEmpty`. The indexer provides indexed access through the receiver.
The named indexer supports `"Kobo".Characters[0]`, which returns `'K'`.
Extension blocks share an `Extensions` container within a file. The block is
internal by default; `public` is its only supported explicit modifier. Blocks
in one file must agree on accessibility. Members have their own modifiers.

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
    [project <expression>]
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
import System
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
function signatures remain errors.

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

### Single-file application directives

A standalone app can describe its SDK, build properties, and package
dependencies at the top of its source file:

```kobo
#:sdk Microsoft.NET.Sdk
#:property Nullable=enable
#:package Newtonsoft.Json@13.0.3

import System
import Newtonsoft/Json

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
| `#:sdk` | Selects an SDK for the app build. SDK names may carry a version where supported by the installed SDK tooling. | `#:sdk Microsoft.NET.Sdk` |
| `#:property` | Supplies an MSBuild property using `Name=Value`. Repeat for additional properties. | `#:property Nullable=enable` |
| `#:package` | Adds a NuGet dependency, optionally pinned with `@version`. Repeat for additional dependencies. | `#:package Newtonsoft.Json@13.0.3` |

#### Referencing .NET libraries

Libraries included in the app's target framework are available without a package
directive. Import their namespaces using Kobo's forward-slash notation:

```kobo
import System/IO
import System/Net/Http
import System/Collections/Generic
```

For a library distributed through NuGet, add a `#:package` directive and then
import the namespace containing the types you want to use:

```kobo
#:package Newtonsoft.Json@13.0.3

import Newtonsoft/Json
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

`#:project` and all other `#:` app directives are rejected. Use exactly
`#:property`, not `#property`. App directives are restricted to standalone
single-file compilation; multi-file batches reject them. When using BuildTools
in an existing project, configure SDK selection, properties, and dependencies
in that project rather than in Kobo source files.

SDK properties that change the output type, assembly name, or output layout
can conflict with CLI output expectations. This workflow expects the named
assembly to be produced in the selected output directory.

## Editor and project integration

### Embedding Kobo in an existing C# project

BuildTools lets you add `.kobo` files directly to an existing SDK-style C#
project. You do not need to replace the project, move its existing code, or
create a separate Kobo library. Keep your current application structure and
introduce Kobo where its declaration syntax, type extensions, or query syntax
make a particular component easier to express.

This supports gradual adoption rather than an all-or-nothing migration. For
example, an application can keep its startup code, framework configuration, and
existing services in C#, while implementing a new model or utility in Kobo.
Teams can evaluate Kobo on a small, isolated part of an application without
first porting the rest of the codebase. Existing package references and project
build settings remain the place to configure the application's dependencies.

The important distinction is that the Kobo files are **part of the same
compilation**, not a separately built component. BuildTools transforms them
during the normal project build and contributes their generated declarations
to the project's compiler. C# code can construct Kobo-defined classes and call
their members directly. Kobo declarations can also refer to accessible types
defined elsewhere in the project; the final project compilation checks these
cross-file references. This does not make every inference step project-wide:
explicit types remain useful at language boundaries.

Because both sets of source files produce one project assembly, there is no
separate Kobo DLL to copy, no manual transpilation step to keep in sync, and no
extra build command to insert before `dotnet build`. The same workflow can run
locally and in continuous integration. Kobo files in the same namespace also
share generated global-function containers and union definitions.

### Example: call a Kobo class from C#

Start in the directory of an existing C# console project and install BuildTools:

```sh
dotnet add package thinkmine.kobo.lang.buildtools --prerelease
```

Add a file named `Greeting.kobo` alongside the project's existing source files:

```kobo
module Example/Greetings

[public] class:Greeting
{
    [public] function:string For(string name)
    {
        return $"Hello, {name}, from Kobo!"
    }
}
```

Use the class from the project's `Program.cs`:

```csharp
using Example.Greetings;

var greeting = new Greeting();
Console.WriteLine(greeting.For("Ada"));
```

Build and run the existing project normally:

```sh
dotnet build
dotnet run --no-build
```

Output:

```text
Hello, Ada, from Kobo!
```

The project might now contain:

```text
ExistingApp/
  ExistingApp.csproj
  Program.cs
  Greeting.kobo
```

No separate `kobo build` is needed. Installing the package registers recursive
Kobo file discovery automatically; subfolders do not require additional project
entries. Discovery excludes `bin`, `obj`, and configured build output paths,
and avoids duplicating existing additional-file entries. Namespace membership
still comes from each Kobo file's `module`, not its folder.

### Project settings and editor support

For embedded Kobo files, configure package dependencies, assembly references,
SDK selection, and build properties in the existing project. Standalone app
directives such as `#:package` are not accepted in generator inputs.
BuildTools is a build-time tool and does not require deploying the standalone
Kobo command-line compiler with the application.

The Kobo VS Code extension supplies highlighting and transformation diagnostics
when editing `.kobo` files. The C# language service supplies completion and type
checking for references to generated types when its compiler host can load and
run BuildTools. Installing the editor extension alone does not enable project
compilation; the project needs the BuildTools package.

This preview requires a .NET 11 compiler host with Roslyn 5.9 or newer, including
the editor's compiler host. Selecting a project target framework does not itself
upgrade that host. If command-line builds succeed but the editor cannot resolve
Kobo-defined types, check the editor's generator-loading diagnostics and host
compatibility, and reload the project after package changes.

See the [BuildTools guide](Kobo.Lang.BuildTools/README.md) for package details,
file-discovery controls, and compatibility requirements. For standalone Kobo
programs rather than embedded project files, use the command-line build workflow
described earlier in this guide.

For installation details, see the
[command-line compiler guide](Kobo.Lang.Compiler/README.md).
