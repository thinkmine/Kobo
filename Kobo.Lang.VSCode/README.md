# Kobo Language Support

## Language version 0.1.25

Kobo Language Support brings `.kobo` language support to Visual Studio Code. It starts the Kobo language server to provide semantic syntax highlighting and diagnostics for Kobo source files. The language server reports transform errors and unresolved names (including undeclared variables) in the editor. Name analysis uses the current file and available runtime references, not the complete consuming project; the full build resolves cross-file/project references. This extension does not build or run your program.

Completion suggests Kobo keywords and declarations, locals, members of imported
.NET types (including generic types and extension methods), namespace and type
import paths, and declarations in other `.kobo` files in the workspace.
Unsaved open files are included. In prompt bodies, completion is limited to
Kobo expressions inside `${...}`; surrounding prompt text remains plain text.
For suggestions from project-specific references, check the consuming
project; the language server does not load its dependency graph.

## Requirements

- Visual Studio Code 1.85 or later
- The .NET 11 runtime

The extension launches the language server with `dotnet`. If `dotnet` is not on your `PATH`, set **Kobo: Server Dotnet Path** (`kobo.server.dotnetPath`) to the path of your .NET CLI executable.

## Getting started

Open or create a file with the `.kobo` extension. VS Code activates Kobo language support for that file. Errors reported by the language server appear in the editor and the Problems panel. For server startup or runtime details, open **View → Output** and select **Kobo Language Server**.

## Building Kobo code

Building requires the .NET 11 SDK and separate compiler tooling; this extension
does not install the compiler or add a build command.

For standalone assemblies, install the CLI:

```sh
dotnet tool install --global thinkmine.kobo.lang --prerelease
kobo build
```

`kobo build` builds the current folder. Supply a file or folder path to select
another input, and use `--recursive` only with folder builds:

```sh
kobo build ./main.kobo
kobo build ./src
kobo build ./src --recursive --output-directory ./build --name MyApp --publish-code
```

Folder builds produce one assembly from the discovered Kobo files, sharing
generated globals and unions by namespace. They are nonrecursive by default;
recursive discovery skips `bin`, `obj`, and symbolic-link directories.
Output options also work without an input path. See the
[command-line compiler guide](https://github.com/thinkmine/KoboLang/blob/master/Kobo.Lang.Compiler/README.md)
for output defaults and error handling.

For Kobo types used directly in a .NET project, use `thinkmine.kobo.lang.buildtools`
instead and use normal `dotnet build` operations. That package discovers Kobo
files recursively automatically. See the
[BuildTools guide](https://github.com/thinkmine/KoboLang/blob/master/Kobo.Lang.BuildTools/README.md)
for setup and generated source inspection.

## Language basics

Kobo is a compact language for .NET. A simple file can look like this:

```kobo
import * from System

module Example/Math

[public] class:Calculator
{
    [public, static] function:int Add(int left, int right)
    {
        return left + right
    }
}
```

Some core syntax:

- **Imports and modules:** Write namespace segments with `/`, as in `import * from System/Net/Http` and `module Example/Math`.
- **Import directives:** `import HttpClient as Client from System/Net/Http`, `import { HttpClient, HttpMethod } from System/Net/Http`, and `import { static Math, Console as Output } from System` bring names into scope without rewriting references. Namespace aliases use `import * as Sys from System`. Static wildcards and legacy forms are rejected.
- **Grouped wildcard imports:** `import * from { System/Net, System/Collections/Generic, System/Linq }` accepts comma-separated namespace paths over multiple lines.
- **Explicit type replacement:** `using Math as M from System` identifies the fully qualified type. Single types, aliases, compound/multiline lists, open generic definitions, and lexical scopes are supported. Completion, hover, definition, and highlighting distinguish these replacements from import directives and namespace aliases. See the [complete guide](https://github.com/thinkmine/KoboLang/blob/master/IMPORTS.md).
- **Types:** Declare types with a colon after the keyword: `class:Name`, `struct:Name`, or `interface:Name`. Use square brackets for modifiers and attributes, such as `[public, abstract]`.
- **Inheritance:** Use only `is`, as in `class:Child is Base, IContract`. Colon-based base lists and `inherits`, `extends`, or `implements` are rejected.
- **Functions:** Use `function:<return-type> <name>(<parameters>)`, for example `function:void Print(string message)`. Put modifiers before `function`, such as `[static]`.
- **Parameters:** Declare parameters as `Type name`, such as `int count`. The `name: Type` form is not supported.
- **Variables and constants:** Use `var:Type name = value` for an explicitly typed variable, `var name = value` for an inferred variable, and `const:Type name = value` for a constant.
- **Collection types:** Lowercase `list<T>` and `dictionary<K, V>` receive the same type highlighting as `List<T>` and `Dictionary<K, V>`. Dictionary literals use `{ key: value }`.
- **Properties:** Use `property:Type Name { get; set; }` or an expression-bodied property such as `property:int Doubled => Value * 2`.
- **Lambdas and delegates:** `x => x + 1` is a lambda. Delegate types can be written as `(int)->int` or `(string)->void`.
- **Optional semicolons:** Semicolons are generally optional at the end of single-line statements.
- **Console commands:** `Print(...)` writes a line using supported argument forms; `Input()` reads a line and `Input("Name: ")` writes a prompt first.
- **JSON:** `json` supports property and indexer access. `StringValue` returns JSON text, and implicit conversions between `json` and `string` parse or serialize it. Invalid JSON text throws `JsonException`.
- **Prompts and tools:** `prompt:Type name { ... }` requests a typed AI result or its original text. Only `${expression}` is evaluated in the otherwise plain-text prompt body. `[tool]` exposes eligible functions. See the [AI tutorial](https://github.com/thinkmine/KoboLang/blob/master/KoboLang.TestHarness/input/tutorials/11.ai.kobo).
- **Catch declarations:** Parentheses are optional: `catch Exception error` or
  `catch Exception`. Bare `catch` and parenthesized forms remain supported.
  Catch bodies use braces; `when` filter conditions retain parentheses.
- **Multiline LINQ:** Query statements spanning multiple lines require an explicit terminating `;`, even inside parentheses. A missing terminator is reported as a Kobo error.
- **Query form:** Only select-first queries are accepted. From-first `from ... in ...` expressions, including nested queries, report a Kobo error.
- **Select-first LINQ:** `select person from people where person.Age > 30 project person.Name` lowers to standard LINQ. Supports equality joins, `group ... by ... into name`, `orderby ... asc|desc`, and anonymous projections with `project { ... }`. Without `project`, selects the initial identifier or returns groups.

Kobo also supports constructs such as generics, trailing-lambda calls, `scope(expr)` member shorthand, and `extension:Type` blocks. Instance extension members use `this` for their receiver; static extension members cannot use `this`. Extension indexers must be named; `this` indexer declarations are rejected, while `this` remains valid in instance indexer bodies. For a fuller language reference and more examples, see the [KoboLang repository README](https://github.com/thinkmine/KoboLang#language-summary-and-syntax).



## License

MIT. See [LICENSE.txt](./LICENSE.txt).
