# Kobo

## Language version 0.1.40

Kobo is a programming language for .NET with compact, consistent declarations,
access to .NET libraries, and native AI prompts and tools.

## Explore the language

- [Language specification](KOBO-LANGUAGE.md): declarations, types, control
  flow, functions, generics, extensions, queries, scripts, JSON, and AI prompts.
- [Get started](GET-STARTED.md): standalone applications, existing .NET projects,
  and single-file utilities.
- [Imports and type replacement](IMPORTS.md): namespace imports, aliases,
  static members, generic type replacement, and lexical scopes.
- [Command-line guide](Kobo.Lang.Compiler/README.md): file and folder builds,
  scripts, and application directives.
- [BuildTools guide](Kobo.Lang.BuildTools/README.md): using Kobo files in
  existing .NET projects.
- [VS Code extension](Kobo.Lang.VSCode/README.md): diagnostics, highlighting,
  and workspace-wide completion.
- [Visual Studio 2026 extension](Kobo.Lang.VisualStudio/README.md): Kobo editing
  support on Windows through the shared language server.

## Language at a glance

Kobo uses `class:Name`, `function:Type Name(...)`, `property:Type Name`,
`var:Type name`, and `const:Type name`. Modules and imports use slash-separated
namespace paths. Functions support type parameters, delegates, lambdas, and
extension members. The language includes unions, select-first queries,
collection expressions, pattern matching, and async functions.

Locals and class, struct, or record fields can infer a fixed type with
`var name = value`. Use `var:Type` when a specific type is needed, or
`var:dynamic` for intentional dynamic binding.

```kobo
#:script

var:string name = Input("Your name: ")
Print("Hello, ${name}!")
```

`Print(...)` supports the `Console.WriteLine` overloads; `Input()` reads a
line, and `Input("prompt")` displays a prompt before reading. Text and raw
strings use `${expression}` interpolation.

Native `json` values support property and indexer access. `StringValue`
returns JSON text; implicit conversions between `json` and `string`
parse or serialize values. Invalid JSON text throws
`JsonException`.

```kobo
var:string source = raw """{"name":"Kobo"}"""
var:json details = source
Print(details.StringValue)
```

An AI prompt is declared with `prompt:Type name { ... }`. Its body is plain
text except for `${expression}` interpolations; `\${...}` stays literal.
Non-string prompts yield the requested type or the original response as a
string alternative. Mark functions with `[tool]` to make them available to
prompts. The runtime reads `kobo.ai.json` alongside the application; consult
the [AI section of the language specification](KOBO-LANGUAGE.md#native-ai-prompts)
and [AI tutorial](KoboLang.TestHarness/input/tutorials/11.ai.kobo) for examples.

Kobo is in preview. This documentation describes version 0.1.40, not a
guarantee of finalized syntax.
