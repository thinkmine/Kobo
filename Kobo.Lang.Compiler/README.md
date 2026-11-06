# Kobo command-line compiler

## Language version 0.1.29

**NuGet package:** `thinkmine.kobo.lang`

**Command:** `kobo`

Kobo is a compact, modern language for writing .NET code. Its declarations,
optional semicolons, delegate shorthand, and trailing lambdas are compiled into
one .NET assembly from a single `.kobo` source file or a folder of Kobo files.

This package is a preview. The NuGet package ID is separate from the command name: install `thinkmine.kobo.lang`, then invoke `kobo`.

## Install and update

Install the .NET 11 SDK for .NET tool management and development. Running the compiler and generated applications requires a compatible .NET 11 runtime.

```sh
dotnet tool install --global thinkmine.kobo.lang --prerelease
```

To update an existing installation:

```sh
dotnet tool update --global thinkmine.kobo.lang --prerelease
```

For a repository-local tool installation:

```sh
dotnet new tool-manifest
dotnet tool install thinkmine.kobo.lang --prerelease
dotnet tool run kobo build hello.kobo
```

Create the tool manifest only if the repository does not already have one. Restore tools in an existing checkout with `dotnet tool restore`. These installation commands require the package to be available from a configured NuGet source; see [Building from source](#building-from-source) for local packages.

## Write, build, and run a program

For a single-file script, put `#:script` on the exact first line:

```kobo
#:script
import * from System
Console.WriteLine("Hello from Kobo!")
```

Run it directly with the .NET 11 SDK:

```sh
kobo run hello.kobo
```

`kobo run` compiles and executes the script. It requires a
single `.kobo` file with `#:script` as its exact first line (no preceding
blank lines, comments, or whitespace). The old `#:app` marker is rejected.
SDK, property, and package directives are preserved. Native AI scripts receive
the compiler's runtime references and the adjacent `kobo.ai.json` configuration.
AI scripts default to managed execution (`PublishAot=false`) to preserve the
runtime's reflection-based JSON serialization.
The application runs with the source directory as its working directory;
standard input/output/error are inherited and its exit code is returned.
Temporary files are removed after execution. Compilation or build
errors prevent execution and produce a nonzero exit code.

For a conventional program with an explicit entry point:

Save this as `hello.kobo`:

```kobo
import * from System

module Examples/Hello

[public] class:Program
{
    [public, static] function:void Main(string[] args)
    {
        var message = "Hello from Kobo!"
        Console.WriteLine(message)
    }
}
```

Build and run:

```sh
kobo build hello.kobo --output-directory ./build --name Hello
dotnet ./build/Hello.dll
```

The compiler writes `Hello.dll` and, for a console application, `Hello.runtimeconfig.json`.

### Compiler options

```text
kobo build [<input.kobo>|<folder>] [--recursive] [--output-directory <directory>] [--name <assembly-name>] [--publish-code]
kobo --version
```

Run `kobo --version` by itself to print the compiler's NuGet package version.

| Option | Behavior |
| --- | --- |
| `<input.kobo>` or `<folder>` | Builds one file or all Kobo files in a folder. With no input, builds the current directory. Quote paths containing spaces. |
| `--recursive` | Includes subfolders in directory builds. Not valid for a file input. |
| `--output-directory <directory>` | Writes output to this directory, creating it if needed. Defaults to the input file's directory or the folder being built. |
| `--name <assembly-name>` | Sets the output assembly name. Defaults to the input filename without its extension, or the folder name. |
| `--publish-code` | Also saves a compiler source listing for inspection. |

When using both named options, put `--output-directory` before `--name`, as shown above; this matches the current CLI command patterns. The `--publish-code` flag can accompany any build command.

The compiler emits a console application when a static `Main` method is present,
and a library otherwise. Use a supported Kobo entry-point signature such as
the `Main` above. A library has no entry point and cannot run independently.

On successful compilation, the CLI reports whether it produced a console application or library and prints the output paths. Compilation errors go to standard error with exit code `1`; an unrecognized command prints usage with exit code `2`.

### Building a folder

Build all `.kobo` files directly inside a folder into **one assembly**:

```sh
kobo build ./src
```

The same `build` command handles file paths and folder paths automatically;
there is no separate folder-build command. Omit the path to build the current
directory, optionally including its subfolders:

```sh
kobo build
kobo build --recursive
kobo build --output-directory ./build --name MyApp --publish-code
```

Include subfolders of an explicit folder with `--recursive`:

```sh
kobo build ./src --recursive --output-directory ./build --name MyApp --publish-code
```

Files share a compilation context, including one generated `Global` class and
one definition of each generated union per namespace. Without `--recursive`,
subfolders are not searched. Discovery is case-insensitive for `.kobo` extensions
and files are processed in ordinal path order. Recursive discovery skips `bin`,
`obj`, and symbolic-link directories.

Output defaults to the input folder, with the folder name as the assembly name.
The output options work for file and folder inputs; when both are specified,
`--output-directory` must precede `--name`. `--recursive` and `--publish-code`
can appear anywhere after the command. A missing/unreadable folder, no matching
files, or a compilation failure reports an error and exits with code `1`.
Any static `Main` in the combined sources selects a console application;
otherwise the result is a library.

From a source checkout, run the unified file/folder build regression checks with
`dotnet run --project KoboLang.TestHarness -- --folder-build-self-test`.

## Language guide

For a complete Kobo-first introduction, see
[The Kobo Programming Language](https://github.com/thinkmine/KoboLang/blob/master/KOBO-LANGUAGE.md).
Version 0.1.29 supports `Print(...)` and `Input()`/`Input("prompt")`, native
`json` values with `StringValue` and implicit string conversion, and
`prompt:Type` declarations with `${expression}` interpolation and `[tool]`
functions. Prompt text outside interpolations is literal, even when it contains
JSON or braces. See the [AI tutorial](https://github.com/thinkmine/KoboLang/blob/master/KoboLang.TestHarness/input/tutorials/11.ai.kobo);
the sample `kobo.ai.json` reads `OPENAI_API_KEY` from the environment at runtime.
Standalone single-file builds accept `#:sdk`, `#:property`, and `#:package`;
these are passed to the SDK build. Other app directives, including `#:project`,
are rejected. Multi-file builds do not accept app directives.

Kobo reuses familiar .NET types, expressions, method calls, and brace-delimited blocks while providing its own declaration syntax. Explicit types are useful at API boundaries; local variables and fields can use inference.

### Multiline LINQ queries

LINQ query expressions spanning multiple lines must end their statement with an
explicit semicolon, including when the query is parenthesized:

```kobo
var items = select item from args
            where item.Length > 0
            project item;
```

Omitting the semicolon reports a `KOBO0001` error at the query's `select` keyword.
Single-line queries retain optional semicolons.

### Select-first LINQ syntax

Kobo accepts the following select-first query syntax:

```text
select <identifier> from <expression>
    [join <identifier> from <expression> on <left> == <right>]*
    [where <condition>]
    [group <expression> by <expression> [into <identifier>]]
    [orderby <expression> [asc|desc]]
    [project <expression>]
```

Clauses must appear in this order. Without `project`, the query selects the
initial identifier. A `group` clause returns groups; use `into name` to refer to
them in subsequent `orderby` or `project` clauses. Without `project`, a group
continuation selects that group identifier. Ordering defaults to ascending.
Join conditions must be equality expressions.

```kobo
var results = select person from people
              join order from orders on person.Id == order.PersonId
              where person.Age > 30
              orderby order.Total desc
              project {
                  person.Name,
                  order.Total
              };
```

`project { ... }` creates an anonymous object.
Other projections, such as `project person.Name`, select that value.
From-first `from ... in ...` query expressions are rejected, including
nested queries. Query statements require an explicit terminating semicolon when
spanning multiple lines.

### Imports and modules

Use `/` to separate namespace segments:

```kobo
import * from System
import * from System/Collections/Generic
import * from System/Net/Http

module Examples/Collections
```

`import ... from ...` brings names into the file without rewriting type
references. Wildcards import namespace members and can be grouped:

```kobo
import * from
{
    System/Net,
    System/Collections/Generic,
    System/Linq
}
```

`import * as Sys from System` introduces a namespace alias.
`import HttpClient as Client from System/Net/Http` introduces a type alias,
and compound imports can mix aliases and per-entry
static imports: `import { static Math, Console as Output } from System`.
Static wildcards are not supported.

Use `using Type [as Alias] from Namespace/Path` for explicit fully qualified
type replacement, including class/function/block scopes. For example,
`using Math as M from System` turns `M.Sqrt(144)` into
`global::System.Math.Sqrt(144)`. Compound lists and open generic definitions
are supported by `using`; `import` cannot alias an open generic definition.
Both APIs and native scripts follow these same rules. Old import forms are rejected.
See the [imports guide](../IMPORTS.md) for all forms and migration examples.
A module becomes a file-scoped namespace, so `module Examples/Collections`
maps to `namespace Examples.Collections;`.

### Types, modifiers, and inheritance

Union syntax is restricted to variable types, such as
`var:union(int,string) value = 1`. Standalone declarations like `union:Hello {}`
are not supported and report a Kobo error.

Declare types with `class:Name`, `struct:Name`, `interface:Name`, or `record:Name`. Put modifiers and attributes in square brackets before the declaration. Use `is` for inheritance:

`is` is the only supported form for inheritance and interface implementation.
Separate multiple bases with commas. Colon-based base lists, `inherits`,
`extends`, and `implements` are rejected. Generic `where` constraints retain
their constraint colon.

```kobo
interface:IGreeter
{
    function:void Greet()
}

[public, abstract] class:BaseGreeter is IGreeter
{
    [public, abstract] function:void Greet()
}

[public] class:Greeter is BaseGreeter
{
    [public, override] function:void Greet()
    {
        Console.WriteLine("Welcome!")
    }
}
```

Modifier lists can include declarations such as `public`, `static`, `abstract`, `virtual`, and `override`. Attributes can also appear in the list, for example `[public, AttributeUsage(AttributeTargets.Class)]` on an attribute class.

### Functions, parameters, and generics

Always use `function:<return-type> <name>(<parameters>)`:

```kobo
[public, static] function:int Add(int left, int right)
{
    return left + right
}

[public, static] function:string Describe(string value)
{
    return value
}

[public, static] function:T Identity<T>(T value) where T : struct
{
    return value
}
```

Parameters must use `Type name`; `name: Type` declarations are rejected.
Generic type parameters and `where` constraints are supported on types and
functions.

Function declarations require an explicit return type, including `void` for functions that return nothing. `func` is not a supported declaration keyword, and `function Name(...) -> Type` is not the supported function form.

### Variables, constants, and collections

```kobo
var:int count = 3
var message = "Kobo"
const:int limit = 10
var:List<int> numbers = [1, 2, 3]
var names = ["Ada", "Grace", "Linus"]
var:dictionary<string, int> ages =
{
    "joe": 5,
    "smith": 9
}
var inferredAges = { "joe": 5, "smith": 9 }
```

Use `var:Type` for explicit typing and `var` to infer local variables and
class, struct, or record fields from their initializers. An inferred field has
a fixed compile-time type, is private by default, and supports normal access,
`static`, and `readonly` modifiers. Use explicit types for null, empty,
target-typed, unresolved, or circular initializers, and `var:dynamic` when
dynamic binding is intentional. Untyped fields previously used dynamic binding;
change those declarations to `var:dynamic` if they depend on that behavior.
Constants must be compile-time expressions.

Collection literals use square brackets. Kobo can infer collection element types in supported cases, but explicit types make the intended collection shape clearer.
Import `System/Collections/Generic` for collection types. Lowercase `list<T>` and
`dictionary<K, V>` map to `List<T>` and `Dictionary<K, V>`, including in nested
generics. Dictionary entries use `key: value` inside braces and generate indexed
initializers. For untyped dictionaries, key and value types are inferred
from their entries; mixed types become `object`. An empty
dictionary or an entry whose type cannot be inferred needs `var:dictionary<K, V>`.

### Properties and indexers

```kobo
[public] class:Person
{
    var:List<string> _names = ["Ada", "Grace"]

    [public] property:string? Name { get; set; }
    [public] property:int Age
    [public] property:int DoubledAge => Age * 2

    [public] indexer:string Names[int i] => _names[i];
}
```

Properties support accessor blocks, shorthand auto-properties, and expression bodies. Nullable types such as `string?` can be used in typed declarations.

Indexers use `indexer:Type Name[parameters]`. Named indexers support
`receiver.Name[index]`; the `this` form supports `receiver[index]`.

### Control flow and statement layout

```kobo
var total = 0
var numbers = [1, 2, 3]

foreach number in numbers
{
    total += number
}

if total > 0
{
    Console.WriteLine(total)
}

while total > 0
{
    total -= 1
}
```

- Semicolons are optional at the end of single-line statements; explicit semicolons are also accepted.
- Parentheses around `if`, `else if`, and `while` conditions can be omitted when the condition ends on that line and the body follows.
- A condition and its statement on the same line require parentheses: `if (ready) return value`.
- `foreach name in items`, `foreach var name in items`, and `foreach var:int name in items` are supported, as are parenthesized headers.
- Braces can appear on the next line. Use braces to make multi-statement blocks explicit.
- Catch declarations have optional parentheses: `catch Exception error` and
  `catch (Exception error)` are equivalent. Type-only `catch Exception` and bare
  `catch` are supported. Bodies require braces; filters retain parentheses,
  for example `catch Exception error when (error.Message.Length > 0)`.
- Use `//` for single-line comments.

### Lambdas, delegate types, and trailing blocks

Delegate types use `(<parameter-types>)-><return-type>`:

| Kobo type | Generated .NET delegate |
| --- | --- |
| `(string)->bool` | `Func<string, bool>` |
| `(int,string)->void` | `Action<int, string>` |
| `()->void` | `Action` |

Inline lambdas can have expression or block bodies:

```kobo
var:(int)->int doubled = x => x * 2
var answer = doubled(21)
```

A function whose last parameter is a delegate can be called with a trailing lambda block:

```kobo
[static] function:string Search(List<string> names, (string)->bool filter)
{
    foreach name in names
    {
        if filter(name)
        {
            return name
        }
    }

    return "<not found>"
}
```

Call it from another function:

```kobo
var names = ["Ada", "Grace", "Linus"]
var result = Search(names)
{
    name => name == "Grace"
}
```

The trailing block supplies the final delegate argument rather than starting a separate statement.

### Updating an object with `scope`

Use `scope` to avoid repeating a receiver when updating its members:

```kobo
var person = new Person()
scope(person)
{
    .Name = "Ada"
    .Age = 36
}
```

Leading member dots in the scope are rewritten using the receiver, for example `.Age = 36` becomes `person.Age = 36`.

The body is a regular block and can contain variables, conditionals, loops,
function calls, and other logic. A `scope` cannot appear inside another `scope`,
including within a conditional or loop in its body; nested scopes are rejected.

### Type extensions

Type extensions can declare methods, properties, and indexers for an existing
type inside an `extension(Type receiver)` block.

```kobo
extension(string text)
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

The named indexer supports `"Kobo".Characters[0]`, which returns `'K'`.

Extension blocks generate members in a shared `static partial class Extensions`, which is `internal` by default. Use `[public] extension(string text)` to make that class public. Only `public` is allowed on the extension block itself, and all extension blocks in a file must have the same effective access modifier. Individual members still use their own modifier lists.

### Syntax rules to remember

Keep declaration colons adjacent to both the keyword and type/name: `class:Person`, `function:void`, and `var:int`, not `class: Person` or `var :int`. Parameters use `Type name`, without a colon. Generic constraints use `where T : struct`.

Use Kobo declaration forms such as `class:Person`. Kobo is a preview
language. If an expression or declaration fails to compile, inspect the
diagnostics.

## Editor workflow

The **Kobo** VS Code extension recognizes `.kobo` files and launches the Kobo language server for semantic highlighting and transform diagnostics. It does not compile or run your program; use the CLI separately.

The extension requires VS Code 1.85 or later and the .NET 11 runtime. If `dotnet` is not on your `PATH`, configure `kobo.server.dotnetPath`. Server output is available in the **Kobo Language Server** output channel.



If the tool is already installed, use `dotnet tool update` instead of `dotnet tool install`.

## Further reading

- [Project overview and language reference](https://github.com/thinkmine/KoboLang#language-summary-and-syntax)
- [VS Code extension documentation](https://github.com/thinkmine/KoboLang/blob/master/Kobo.Lang.VSCode/README.md)
- [Example Kobo source](https://github.com/thinkmine/KoboLang/blob/master/KoboLang.TestHarness/input/main.kobo)

## License

This package is licensed under the [MIT License](https://opensource.org/license/mit).
