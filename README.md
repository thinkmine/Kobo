KoboLang
=======

Overview
--------

New to Kobo? Follow [Get Started with Kobo](GET-STARTED.md) to build hello world,
embed Kobo in an existing console project, or write a single-file utility.

Read [The Kobo Programming Language](KOBO-LANGUAGE.md) for a Kobo-first guide
covering the language, executable examples, file and folder builds, and
single-file application directives.

KoboLang is a small source-to-source compiler / transpiler that converts a compact, C-like domain specific language (DSL) called Kobo (based on an earlier "Harmony" syntax) into C# source. The project contains:

- Kobo.Lang: the core transformer and semantic model that parses Kobo source, infers types, maps language constructs to C#, and uses reflection to resolve external .NET types.
- KoboLang.TestHarness: a minimal test runner and tokenizer used during development. It includes an example input file at `KoboLang.TestHarness/input/main.kobo` and writes generated C# to `KoboLang.TestHarness/output/main.output.cs`.

Goals
-----

- Provide a terse, readable syntax for declaring modules, types and members.
- Infer types where reasonable and map Kobo language constructs to idiomatic C# (including delegates, lambdas, extension methods, indexers, and generics).
- Produce a C# file that can be compiled with Roslyn or the .NET SDK.

Build and run
-------------

Requirements: .NET 11 SDK (project targets .NET 11) and Visual Studio / dotnet tooling.

To generate C# from the sample file using the test harness:

1. Open the solution `KoboLang.slnx` in Visual Studio or use the dotnet CLI.
2. Run the `KoboLang.TestHarness` project. It reads `KoboLang.TestHarness/input/main.kobo`, runs the transform, and writes generated C# to `KoboLang.TestHarness/output/main.output.cs`.

To run the Kobo language server over standard input/output:

```sh
dotnet run --project Kobo.Lang.Server/Kobo.Lang.Server.csproj
```

To run the equality-alternative regression checks:

```sh
dotnet run --project KoboLang.TestHarness/KoboLang.TestHarness.csproj -- --self-test
```

### Transforming multiple Kobo files

Pass named source inputs to `Transform.ToCSharp` to generate one C# compilation
unit with a shared registry of generated types:

```csharp
var result = Transform.ToCSharp(
[
    new KoboSourceFile("First.kobo", File.ReadAllText("First.kobo")),
    new KoboSourceFile("Second.kobo", File.ReadAllText("Second.kobo"))
]);
if (!result.Success)
    throw new InvalidOperationException(string.Join(Environment.NewLine, result.Errors));
File.WriteAllText("combined.cs", result.Code);
```

The overload accepts `IEnumerable<KoboSourceFile>`, optional assembly reference
paths, and a cancellation token. The compiler does not read the input paths:
they identify diagnostics, available through `result.Diagnostics[*].FilePath`.
Every file is validated independently, preserving its local error line/column.
Any fatal input error fails the entire batch without returning partial code.
Input paths must be nonempty and unique; an empty collection is accepted.

Files in the same module share one generated `Global` class containing all
their global functions and one definition of each generated union. Different
modules have independent generated types. Duplicate function signatures are
retained so C# reports the error; functions are not silently discarded.
Registry state is local to the call and never leaks into another compilation.

Use the same named inputs with `Transform.Compile` to emit one assembly:

```csharp
var compiled = Transform.Compile(
[
    new KoboSourceFile("First.kobo", File.ReadAllText("First.kobo")),
    new KoboSourceFile("Second.kobo", File.ReadAllText("Second.kobo"))
], "output", assemblyName: "MyApplication", publishCode: true);
if (!compiled.Success)
    throw new InvalidOperationException(string.Join(Environment.NewLine, compiled.Errors));
```

The multi-file overload supports the same output directory, assembly name,
assembly references, and `publishCode` options as single-source compilation,
plus an optional cancellation token. It emits a library unless any input
contributes a static `Main`, in which case it emits a console application and
runtime configuration. `publishCode` writes the combined C# to the output
directory. Fatal transform errors include the input path and produce no partial
output; C# emission failures return compiler errors and retain published source
when requested.

The combined output uses block-scoped namespaces, preserving imports on ordinary
types within each file's namespace block. Shared generated declarations merge
their contributing files' imports; conflicting aliases are reported as transform
errors instead of silently choosing one. Imports for files without a module must
be hoisted to the combined C# compilation-unit scope. Imported case type names
must resolve consistently across files sharing a generated union.

The test harness also accepts multiple input paths and writes their combined C#
to its normal output file. Run the focused regressions with:

```sh
dotnet run --project KoboLang.TestHarness -- --multi-file-self-test
```

### Automatic compilation in C# projects

Install `thinkmine.kobo.lang.buildtools` to compile `.kobo` files as part of normal C#
builds, with generated types available directly to C#:

```sh
dotnet add package thinkmine.kobo.lang.buildtools --prerelease
```

This preview requires a .NET 11/Roslyn 5.9+ compiler host, including in the IDE.
See [the BuildTools package guide](Kobo.Lang.BuildTools/README.md) for automatic
file discovery, diagnostics, generated source inspection, host compatibility,
and local packaging instructions.

### Command-line compiler

Install the packed .NET tool and compile a Kobo file with:

```sh
dotnet tool install --global --add-source ./artifacts thinkmine.kobo.lang --prerelease
kobo build path/to/source.kobo
```

Build all Kobo files in a folder into one assembly with `kobo build ./src`.
With no input path, `kobo build` builds the current folder. An explicit file path
builds just that file. Add `--recursive` to include subfolders for folder builds:

```sh
kobo build
kobo build --recursive
kobo build ./src
kobo build ./src --recursive --output-directory ./build --name MyApp --publish-code
```

Without `--recursive`, folder builds only include files directly in the selected
folder. `--recursive` is not valid with a file input. All file and folder builds
use `build`; there is no separate folder-build command.

Folder builds share generated globals and unions by namespace. They default to
the folder's name and output directory; recursive discovery skips `bin`, `obj`,
and symbolic-link directories. Discovery accepts `.kobo` extensions
case-insensitively. An empty folder build is an error.

The compiler emits a library when no static `Main` method is present and a console application when one is present. Use `--output-directory <directory>` and `--name <assembly-name>` to customize the output. Add `--publish-code` to also write the generated C# source (`<assembly-name>.cs`) next to the assembly. The generated assembly is a `.dll`; console applications also receive a `.runtimeconfig.json` and can be run with `dotnet <assembly>.dll`.

When both output options are supplied, put `--output-directory` before `--name`.
These options also work when the input path is omitted. Quote paths containing
spaces. See the [command-line compiler guide](Kobo.Lang.Compiler/README.md)
for defaults, error handling, and examples.

To create the NuGet tool package, run:

```sh
dotnet pack Kobo.Lang.Compiler/Kobo.Lang.Compiler.csproj -c Release -o ./artifacts
```

The server supports `.kobo` documents, publishes transform errors as editor diagnostics, and provides semantic syntax highlighting for Kobo/C# keywords, modifiers, types, identifiers, strings, comments, numbers, and operators. Block braces are tokenized independently of line layout, including C#-style braces on the following line.

### VS Code extension

The `Kobo.Lang.VSCode` folder contains the VS Code extension. Open that folder in VS Code and run **Developer: Install Extension from Location...** to install it for local development. The extension registers the `kobo` language ID for `.kobo` files and starts the language server using the packaged server when available, or the server project in a source checkout.

The extension also assigns C#-style modifier scopes to Kobo modifier keywords, including modifiers inside square-bracket declaration lists.

To create an installable VSIX, run `npm install` and `npm run package` from `Kobo.Lang.VSCode`. The packaging script builds the client and publishes the server into the extension directory so an installed extension can launch it. A .NET 11 runtime is required.

Language summary and syntax
---------------------------

Multiline LINQ query statements require an explicit terminating semicolon:

```kobo
var items = select item from args
            project item;
```

This also applies to parenthesized multiline queries. A missing semicolon is a
`KOBO0001` error; single-line queries retain optional semicolons.

Select-first queries are also supported:

```kobo
var names = select person from people
            where person.Age > 30
            project person.Name;
```

This lowers to `from person in people where person.Age > 30 select person.Name`.
Kobo source accepts only select-first queries; from-first query expressions,
including nested ones, are rejected.
Optional clauses support equality joins, grouping with `into`, and ordering with
`asc`/`desc`. `project { ... }` creates an anonymous object. Without a projection,
the initial identifier is selected, or groups are returned for grouping queries.
See the [select-first LINQ guide](Kobo.Lang.Compiler/README.md#select-first-linq-syntax)
for clause ordering and examples.

The Kobo language is designed to be compact while still expressing types, generics, extension methods and modern C# constructs. Below is a concise description of the supported syntax and notable rules.

Top-level structure
- import statements
  - All imports emit file-level C# directives; references are not rewritten.
  - Syntax: `import * from Namespace/SubNamespace;` (use `/` not `.`)
  - Example: `import * from System/Net/Http;`
  - Multiple namespaces: `import * from { System/Net, System/Linq };` (the brace list can span lines)
  - Named types: `import HttpClient as Client from System/Net/Http;`
  - Namespace aliases: `import * as Sys from System;`
  - Compound: `import { HttpClient as Client, HttpMethod } from System/Net/Http;`
  - Static members: `import static Math from System;`, or `import { static Math, Console } from System;`
  - Static wildcards and legacy import forms are rejected. See [the imports guide](IMPORTS.md) for scopes and migration.
- explicit fully qualified type replacement
  - `using Math as M from System;` replaces `M.Sqrt(144)` with `global::System.Math.Sqrt(144)`.
  - Single types, aliases, compound lists, generic definitions, and file/class/function/block lexical scopes are supported.
  - Use `using List from System/Collections/Generic` for generic substitution; `import` aliases cannot name open generic definitions.

- module declaration (file-scoped)
  - Syntax: `module My/Name;` -> becomes `namespace My.Name;` in C#

Types (classes, structs, interfaces, records)
- Declaration
  - Syntax: `[modifiers] class:Name [Bases] { ... }`.
  - Modifiers and attributes are written in square brackets before the declaration, e.g. `[public, abstract] class:MyClass is Base`.
  - C#-style `class Name` declarations are rejected; use the colon form.
  - Inheritance and interface implementation use only `is`, with comma-separated
    bases. Colon-based base lists and `inherits`/`extends`/`implements` are errors.

- The only supported form is `function:<return-type> <name>(<parameters>)`.
- Example: `function:int DoWork(string s, int n)`
- Omitting the return type or placing it after the parameter list using `->` produces an error.

- `function` is the only function declaration keyword. Using `func` produces an error.
- Modifiers appear in attributes before the `function:` token and apply to the function (e.g. `[public, static] function:void Main(string[] args)`). Whitespace, including line breaks, may separate the attribute list and declaration, but no whitespace is allowed around the declaration colon.
- Declaration keywords that use a colon separator (such as `class`, `struct`, `function`, and `var`) must have no whitespace before or after `:`, e.g. `var:int` rather than `var: int`.

- Generics and constraints
  - Generic functions: `function:TName<T>(T arg) where T : struct`
  - Generic type parameters are supported on types and functions.

Parameters
- Parameter forms
  - Parameters must use `Type name`, for example `string message`.
  - The former `name: Type` parameter form is rejected with a Kobo diagnostic.
  - Delegate parameter types can use the arrow form: `(string)->bool filter` maps to `Func<string,bool> filter`.

Variables, constants and fields
- var/const declarations
  - `var:Type name = expr` or `var name = expr`
  - Un-typed `var` fields outside functions are treated as `dynamic` (C# field compatibility).
  - `const:Type name = value` declares compile-time constants where possible.
  - `readonly:Type name = value` declares an initialized readonly field inside a class, struct, or record. It emits `readonly Type name = value;` and uses C#'s default private accessibility.

  Union-typed variables (C# 15)
  - `var:union(int,string) x = 42` and `var:union(int, string) y = "hello"`
    both use `union_of_int_string`. The transformer emits one namespace-level
    `public union union_of_int_string(int, string);` declaration, reusing it for
    subsequent variables. Case order is preserved; whitespace is ignored.
  - Union variables still require initializers. Existing variable modifier and
    attribute rules apply unchanged; modifiers stay on the variable, not the
    generated public union.
  - Generated unions live in the file's module namespace (or the global namespace
    without a module). Case types must be accessible there and publicly accessible
    for use in a public union; enclosing class/method type parameters cannot be
    captured. Complex case types have a readable name plus a deterministic digest
    to avoid identifier collisions.
  - BuildTools also deduplicates unions across Kobo files in the same namespace.
    Imported case type names must have the same meaning in those files.
  - Compilation requires C# 15 union support. The embedded Roslyn compiler uses
    preview parsing; SDK consumers using a preview implementation may need
    `<LangVersion>preview</LangVersion>`.
  - Run the union regressions with
    `dotnet run --project KoboLang.TestHarness -- --union-self-test`.
    Run unions, equality alternatives, BuildTools, and NuGet consumer checks
    together with `dotnet run --project KoboLang.TestHarness -- --compiler-regression-tests`.

Properties and indexers
- Properties
  - `property:Type Name { get; set; }` or short forms `property:Type Name => expr` are supported.

- Indexers
  - `indexer:Type Name[params] { ... }` or `indexer:Type this[params]` maps to C# indexers. Named indexers generate helper nested types.

Lambdas and delegates
- Arrow delegate syntax
  - `(<types>) -> <ret>` maps to `Func`/`Action` as appropriate. Examples:
	- `(string)->bool` => `Func<string,bool>`
	- `(int,string)->void` => `Action<int,string>`

- Inline lambdas
  - `x => x.ToLower()` and `(x,y) => x + y` are supported. Bodies can be expressions or blocks.

- Trailing lambda blocks
  - Functions whose last parameter is a delegate may be called with a trailing block:
	- `Search(names) { x => x == "three" }` becomes `Search(names, (x) => { return x == "three"; });`

Scope substitution
- `scope(expr) { .Member = value }` replaces leading `.` in lines with the `expr` identifier — convenient for object initializer style updates.
- A scope body is a regular block and can contain variables, conditionals, loops,
  calls, and other logic. Nested `scope` blocks are not allowed, even inside
  another block within the outer scope, and produce a Kobo error.

Native extern functions
- `[source("library")] extern:ReturnType Name(parameters)` generates a static
  extern method with `[DllImport("library")]` and automatically imports
  `System.Runtime.InteropServices`. Multiline signatures are supported; bodies
  and generic extern methods are not allowed.

Type extensions
- `extension:Type { ... }` adds methods, properties, and indexers to an existing
  type without modifying its original declaration. All extension blocks are
  emitted into a shared `static partial class Extensions`, which is `internal`
  by default.
- `[public] extension:Type { ... }` makes the shared `Extensions` class public. `public` is the only allowed modifier; other modifiers and attributes are rejected. All extension blocks in a file must have the same effective access modifier.
- Instance members use `this` for the receiver, which is generated as `@instance`.
  Static extension members cannot use `this`. Member access defaults to private,
  as in classes.
- Extension indexers must be named, such as `indexer:char Characters[int index]`.
  `indexer:Type this[...]` is not allowed in extension blocks; `this` is still
  allowed in instance indexer bodies.

Semicolons and statement termination
- Catch declarations can omit parentheses: `catch Exception error` or
  `catch Exception`. Parenthesized declarations and bare `catch` remain valid.
  Catch bodies use braces; filter conditions keep parentheses:
  `catch Exception error when (error.Message.Length > 0)`.
- Semicolons are optional at the end of single-line statements. The transformer inserts semicolons where necessary. Multi-line statements, block ends and explicit `;` terminate statements as expected.
- Parentheses around an `if` or `while` condition are optional when the condition runs to the end of the line: `if filter(name)` becomes `if (filter(name))`, whether the body is a `{` block or a single indented statement (`if .Age > 10` followed by `.Name = "David"`). This also applies to `else if` and `while`. When the `if`/`while` and its statement share a line, the condition must be parenthesized: `if (x) return y`.
- Equality chains may omit the repeated left operand and `==` after `||` or `&&`: `if v == 30 || 45 || 50` becomes `if (v == 30 || v == 45 || v == 50)`, and `if v == 30 && 45 && 50` becomes `if (v == 30 && v == 45 && v == 50)`. The latter requires every comparison to be true (so distinct numeric constants cannot match). Operands can be literals, variables, or expressions, such as `v == first || next + 1 || GetValue()`. Each comparison repeats the left expression with normal C# short-circuit evaluation; it is not evaluated or cached in advance. Resolved boolean operands retain their usual meaning (`v == 30 || isReady` and `v == 30 && isReady` are unchanged). An explicit equality starts a new chain (`v == 30 || other == 45 || 50` compares `other` with `50`). Normal C# operator precedence applies; use parentheses to group chains when mixing `||` and `&&`. This rule also applies in parenthesized conditions, `else if`, loops, and other expressions. Unresolved operand types are left unchanged and require an explicit comparison.
- `foreach` headers can also omit the parentheses: `foreach var name in names`, `foreach name in names` and `foreach var:<type> name in names` become `foreach (var name in names)` or `foreach (<type> name in names)`. The type after `var:` follows the same translation as other typed variables (for example `var:(string)->int f` becomes `Func<string,int> f`). A header that already has parentheses is left unchanged.

Type inference and semantic modeling
- The SemanticModel attempts to infer local and return types by scanning function bodies for `return` expressions and by inspecting expressions. The transformer resolves many .NET types by reflection (see ExternalTypes in Kobo.Lang/Code) to produce accurate C# types when possible.

Examples
- Function (new form):

  [static] function:int Add(int a, int b)
  {
	  return a + b
  }

- Trailing lambda call:

  var result = Search(names)
  {
	  x => x.ToLower() == "three"
  }

Notes and compatibility
- The project aims to be permissive for development convenience while requiring the single `function:<return-type> <name>(<parameters>)` function declaration form.

Contribution
------------

Contributions are welcome. Focus areas:

- expanding the semantic model and type resolution
- adding more diagnostics and better error messages
- expanding the test suite and example programs

License
-------

This repository does not include a license file by default. Add a LICENSE file if you plan to redistribute or open-source the project.

Files of interest
-----------------

- Kobo.Lang/Code/Transform.cs — main parser and source-to-C# conversion
- Kobo.Lang/Code/SemanticModel.cs — symbol table and type inference
- Kobo.Lang/Code/ExternalTypes.cs — resolves .NET types and extension methods by reflection
- KoboLang.TestHarness — example runner and test harness with sample input

Contact
-------

This README was generated by an automated assistant. For questions about the code, inspect the Transform and SemanticModel implementations in `Kobo.Lang/Code`.
