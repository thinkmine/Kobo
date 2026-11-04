# Writing applications in Kobo with AI

## Language version 0.1.25

Use this guide as context for ChatGPT, Codex, Claude, and other coding agents
asked to create or modify Kobo programs. The authoritative syntax reference is
the [language specification](KOBO-LANGUAGE.md); consult its relevant section
before using an unfamiliar feature. See the [imports guide](IMPORTS.md) for
namespaces and aliases and the [tutorials](KoboLang.TestHarness/input/tutorials/)
for additional examples. Do not treat this guide as a replacement for the
compiler: validate the resulting program.

Kobo is a .NET language with its own grammar and type rules. Use the supported
Kobo constructs and .NET APIs to implement the requested application. When a
particular framework capability needs another host, keep the application
logic in Kobo and describe that integration boundary. Never invent syntax
or claim that an unverified feature works.

## Agent workflow

1. Establish whether the deliverable is a `#:script` single-file program, a
   multi-file Kobo application/library, or Kobo code in an existing .NET
   project. Identify target framework, entry point, dependencies, storage,
   error handling, platforms, and testable behavior.
2. Read the relevant sections of [the specification](KOBO-LANGUAGE.md).
   Inspect nearby `.kobo` files and preserve their module paths, imports,
   naming, and layout. Prefer existing .NET APIs over invented Kobo libraries.
3. Implement a complete program, not disconnected snippets: entry point or
   public API, supporting types, imports, explicit data contracts, expected
   error handling, and tests or reproducible verification. Put dependencies in
   the owning app/project rather than assuming an import installs a package.
4. Validate with the repository's Kobo CLI or consuming project checks.
   Exercise important paths, including invalid input. Fix Kobo diagnostics,
   .NET type errors, and failing tests before claiming success. If a provider,
   platform SDK, device, or secret is unavailable, state what was not verified.
5. Never hard-code API keys. Use environment-variable substitution for
   `kobo.ai.json` and keep secrets outside source control.

## Kobo syntax at a glance

| Need | Kobo form |
| --- | --- |
| Namespace and type imports | `import * from System/Collections/Generic`; `import HttpClient as Client from System/Net/Http` |
| Module | `module Acme/Orders` |
| Type and inheritance | `[public] class:Order is IOrder` |
| Function and parameter | `[public] function:int Count(string filter)` |
| Member or field | `[public] property:string Name { get; set; }`; `readonly:int limit = 10` |
| Typed/inferred local | `var:int count = 0`; `var name = "Kobo"` |
| Constructor | `[public] new(string name) { Name = name }` inside a type |
| Interpolation | `"Hello, ${name}!"` |
| Console | `Print(value)`; `Input()`; `Input("Name: ")` |
| Nullable value | `var:string? name = null`; `name?.Length ?? 0` |
| Union value | `var:union(int,string) result = 42` |
| Delegate | `var:(int)->int doubleValue = value => value * 2` |
| Select-first query | `select item from items where item.Active project item.Name;` |
| JSON text | `var:json value = text`; `var:string text = value`; `value.StringValue` |

Declaration colons have **no surrounding whitespace**: `class:Name`, not
`class: Name`. Parameters use `Type name`, not `name: Type`. Braces delimit
blocks; most single-line statements omit semicolons. Multiline query
statements **require** a terminating semicolon. Names and .NET member casing
are significant. Use `/` in namespace paths and `.` for member access. A
Kobo import is not a package dependency. Use
`using HttpClient as Client from System/Net/Http` for lexical, fully qualified
type replacement; this differs from an `import` alias.

Global functions cannot be overloaded within a module, even with different
parameters. Type-member functions can be overloaded. Union declarations are
available as variable types, not standalone `union:Name` declarations. Consult
the specification for accessibility, generic constraints, `this`, events,
operator overloads, and native extern signatures.

## Complete single-file example

The following is an entire `greet.kobo` program. `#:script` must be its exact
first line. Top-level statements run in order; top-level functions can use
values from the script's scope.

```kobo
#:script

var:string name = Input("Name: ")
if name == null || name.Length == 0
{
    Print("A name is required.")
}
else
{
    Print(Greeting(name))
}

function:string Greeting(string name) => "Hello, ${name}!"
```

For a conventional app, define a `[public, static] function:void Main(string[]
args)` inside a class; a library has no entry point. In a multi-file program,
put related declarations in the same `module Company/Area`; imports remain
per-file. See [program structure](KOBO-LANGUAGE.md#program-structure) and
[application forms](KOBO-LANGUAGE.md#building-programs).

## Reusable types and library APIs

```kobo
import * from System/Collections/Generic
module Example/Inventory

[public] class:Catalog
{
    [public] property:string Title { get; set; }

    [public] new(string title)
    {
        Title = title
    }

    [public] function:List<string> Labels(List<string> names)
    {
        var:List<string> result = []
        foreach name in names
        {
            result.Add("${Title}: ${name}")
        }
        return result
    }
}
```

Collections support arrays, `List<T>`, `Dictionary<K,V>`, lowercase
`list<T>`/`dictionary<K,V>`, collection expressions, and indexed access.
`[public] class:Name`, `struct:Name`, `record:Name`, `interface:Name`,
`enum:Name`, properties, indexers, constructors, operators, events, generic
functions, inheritance with `is`, and `extension:Type` blocks are documented
in [the specification](KOBO-LANGUAGE.md#classes-and-objects). Follow the
documented Kobo syntax in `.kobo` files.

Use `if`/`else`, `switch`, `while`, `for`, `foreach`, `try`/`catch`/`finally`,
`throw`, and `using (var resource = ...)` as described in
[control flow](KOBO-LANGUAGE.md#selection-statements) and
[resource management](KOBO-LANGUAGE.md#exceptions-and-resource-management).
Async functions require an `[async]` modifier and a task-compatible return
type; import `System/Threading/Tasks` and use `await` within them. Use
`System/Linq` for select-first queries and extension methods. For third-party
APIs, ensure the dependency is available to the consuming project; standalone
single-file applications support `#:package Package.Name@version`. Imports
alone never fetch dependencies.

For web APIs, services, desktop/mobile apps, data access, messaging, or
platform-specific features, select the appropriate .NET library/host and put
domain types and logic in Kobo. Public Kobo declarations can participate in
the containing project's API. Do not assume a built-in Kobo web/UI
framework, automatic package installation, or access to arbitrary project
references in a standalone script. Prefer the consuming project for complex
framework dependencies and entry points. See
[project integration](KOBO-LANGUAGE.md#editor-and-project-integration).

## JSON, text, and console I/O

`json` supports object literals and nested property/indexer reads and writes.
Assign JSON text to a `json` variable to parse it; assign a `json` value to a
`string` variable, or read its `StringValue`, for serialized text. Implicit
conversions between `json` and `string` are available; converting invalid JSON
text throws `JsonException`. JSON object properties are dynamic, so check the
shape before depending on an external response. `StringValue` yields formatted
JSON; do not assume the original whitespace is retained. Begin a multiline
JSON object literal with `= {` on the declaration line.

```kobo
#:script

var:string source = """{"name":"Kobo"}"""
var:json details = source
var:string text = details
var:json copy = text
Print(copy.StringValue)
```

`Print(...)` accepts values, format arguments, or no arguments.
`Input("prompt")` prints without a newline and reads a line. Input
may be null at end of stream. For structured logs, streaming I/O, files,
networking, serialization, databases, and concurrency use the appropriate
.NET APIs rather than treating `Print`/`Input` as general-purpose substitutes.
See the [console tutorial](KoboLang.TestHarness/input/tutorials/1.variables.kobo)
and [JSON tutorial](KoboLang.TestHarness/input/tutorials/3.variables-advanced.kobo).

## Native AI prompts and tools

Use prompts in a `#:script` or an `[async]` function with a compatible
task return type. The body between `{` and `}` is **plain text**, including
JSON and nested braces. Only `${expression}` evaluates Kobo code;
`\${...}` and `@{...}` remain literal. `[tool]` on an eligible function
makes it available to the AI client; tools can be defined in other Kobo files.

```kobo
#:script

[tool, description("Adds two integers")]
function:int Add(int first, int second) => first + second

prompt:int answer {
    Use Add to calculate ${20} plus ${22}.
    Return an integer.
}

if answer is int number
{
    Print(number)
}
else if answer is string response
{
    Print("Unconverted response: ${response}")
}
```

A non-string `prompt:Type` has an effective `union(Type,string)` result.
Primitives, objects, and collections are supported; unconvertible responses
remain in the string alternative. A `prompt:string` yields a string. Errors
from configuration, authentication, network calls, tools, or cancellation
propagate as errors, not successful response strings. Do not assume the AI
will return correct values without checking results.

Runtime configuration is named exactly `kobo.ai.json`; it is loaded by the AI
runtime, not by a visible call in the script. It belongs alongside the
application or in the consuming project and uses `Ollama`, `OpenAI`, or
`AzureOpenAI`. Match the provider, endpoint protocol, model/deployment, and
credential. Do not paste secrets into the file; use a placeholder such as
`"key": "${OPENAI_API_KEY}"` backed by the environment. Consult
[the prompt specification](KOBO-LANGUAGE.md#native-ai-prompts) and
[AI tutorial](KoboLang.TestHarness/input/tutorials/11.ai.kobo) for config
and usage details.

## Pre-delivery review

- Every `.kobo` file has the correct module, imports, API surface, and source
  placement. `#:script` is first when using direct script execution.
- No invented Kobo keywords, unsupported string prefixes, malformed
  declaration colons, or from-first queries slipped into source.
- Dependencies and configuration are specified where the actual host can
  resolve them; no secrets are committed.
- Nullable input, invalid JSON, unavailable I/O, prompt conversion, and
  failures from external services have an explicit behavior.
- Relevant tests or example execution prove the requested behavior. Report
  unavailable external integrations honestly instead of claiming unverified
  runtime success.
