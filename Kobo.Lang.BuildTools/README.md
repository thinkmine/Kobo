# Kobo.Lang.BuildTools

## Language version 0.1.40

**NuGet package:** `thinkmine.kobo.lang.buildtools`

Use the analyzer package in an SDK-style .NET project:

```sh
dotnet add package thinkmine.kobo.lang.buildtools --prerelease
```

This preview requires a .NET 11 compiler host with Roslyn 5.9 or newer,
including IDE compilation. Older .NET Framework-based Visual Studio analyzer
hosts are not supported. The consumer's target framework does not select the
analyzer host runtime.

The package automatically includes recursive `**/*.kobo` files as Roslyn
`AdditionalFiles`, excluding `bin`, `obj`, configured output/intermediate paths,
SDK default exclusions, and files already included as `AdditionalFiles`.
Existing additional-file metadata is preserved. Use `AdditionalFiles Remove`
after the package targets import to explicitly exclude individual Kobo files.

For example, create `Person.kobo`:

```text
module Example;
[public] class:Person
{
    [public] property:string Name { get; set; }
}
```

Other Kobo files in the project can import `Example` and use `Person`. No
separate Kobo compilation step is needed. Kobo source follows the language's
syntax, inference rules, and per-file semantics. Cross-file type references
are resolved in the consuming project compilation.

Single-file app directives (`#:sdk`, `#:property`, and `#:package`) are for
standalone CLI apps, not generator inputs. Configure these settings in the
consuming project instead. BuildTools reports an error if app directives appear
in a Kobo input.

Imports use the same unified syntax as the CLI: `import * from System`,
`import HttpClient as Client from System/Net/Http`, and compound forms such as
`import { static Math, Console } from System`. Imports bring names into scope
without replacing references. Namespace aliases use
`import * as Sys from System`. For lexical fully qualified type substitution,
use `using HttpClient as Client from System/Net/Http` or compound `using` lists.
This also supports open generic definitions, unlike named import aliases.
Replacements are resolved independently before combining generated globals and
unions; conflicting import directives in shared declarations are errors.
Group wildcard namespaces with `import * from { System/Net, System/Linq }`;
the comma-separated list may span lines and generates one namespace directive
per entry.
Configure dependencies with project `PackageReference` entries; imports
do not install packages. See the [imports guide](../IMPORTS.md).

Diagnostics:

| Code | Severity | Meaning |
| --- | --- | --- |
| KOBO0001 | Error | Kobo source contains a language error |
| KOBO0002 | Error | An additional file could not be read |
| KOBO0003 | Error | An unexpected compiler exception occurred |
| KOBO0004 | Warning | Semantic inference failed and the compiler used its existing simpler inference fallback |

Kobo diagnostics identify the original file and its one-based compiler line and
column (clamped to the available source). Project compiler diagnostics retain
their normal codes.

Union-typed variables such as `var:union(int,string) value = 42` use a shared
public union named `union_of_int_string` in the module namespace.
Union syntax is only allowed in variable type declarations (including nested
union case types). Standalone declarations such as `union:Hello {}` are rejected
with a Kobo diagnostic. Definitions are deduplicated across Kobo files in the
same namespace, with the contributing files' imports merged. Imported case
types must resolve consistently across those files. Variable modifiers remain
on variables, and initializers are still required. Union support requires a
compatible compiler host and consuming project configuration.

Global functions also share one `Global` class per namespace, using the same
compilation context as the multi-file compiler API.
Global function names must be unique within a namespace, including across files;
duplicate names and overloads are reported as Kobo errors. Type-member overloads
remain allowed. Conflicting import aliases in shared
declarations are reported as Kobo errors.

Ordinary files without inferred fields are analyzed independently and cached by
path/content and metadata references. Files with inferred fields, like AI files,
also use companion Kobo and project sources to resolve types, so changes to that
context invalidate their analysis. An inferred field has a fixed compile-time
type; use `var:Type` when the initializer cannot determine one, or `var:dynamic`
for intentional dynamic binding. Previous untyped fields used dynamic binding
and may need to be updated. Cancellation is propagated through file reads, compiler
phases, semantic-model construction, and source emission.

The package does not require the CLI tool or Zaria packages. It supplies
`thinkmine.kobo.ai` transitively for generated native AI code; applications that
do not execute prompts do not initialize AI clients or read AI configuration.

## Native AI

`prompt:Type name { ... }` and `[tool]` use the same compiler/runtime as the CLI.
The body stays plain text except for `${expression}`. `json.StringValue`,
implicit `json`/`string` conversions, `Print(...)`, and `Input()`/`Input("prompt")`
also work in Kobo files added to a project.
Keep `kobo.ai.json` in the consuming project; package targets copy it to build
and publish outputs and keep it external to single-file bundles. Environment
variables in configuration are substituted only at runtime. Prompts require
an async function or a native `#:script` top-level program. Only one application
file may supply top-level statements in a project.

Use `<LangVersion>preview</LangVersion>` for native union types.
See [native AI and interpolation](../KOBO-LANGUAGE.md#native-ai-prompts) for
providers, configuration, tool eligibility, error behavior, and hosting APIs.

## BuildTools versus the command-line compiler

With this package installed, use normal project workflows in the
consuming .NET project. Kobo files are discovered recursively automatically; no
`kobo build` command or `--recursive` option is needed.

For standalone Kobo assemblies, the separate CLI supports `kobo build` for the
current folder, `kobo build ./src` for a selected folder, and
`kobo build ./main.kobo` for one file. CLI folder builds are nonrecursive unless
`--recursive` is supplied, and compile discovered files together into one
assembly. See the [command-line compiler guide](../Kobo.Lang.Compiler/README.md)
for installation and output options.
