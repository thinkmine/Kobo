# Imports and fully qualified type replacement in Kobo

## Language version 0.1.29

Kobo separates two operations:

- **`import`** makes namespaces, types, and static members available in the
  current file without changing their names in Kobo source.
- **`using`** replaces a named type or alias with its fully qualified type name.
  It supports lexical scopes.

Both use `... from Namespace/Path`, with `/` between namespace segments.
Member access uses `.`, and final semicolons are optional.

## Import directives

| Kobo | Effect |
| --- | --- |
| `import * from System` | Use public types in `System` by name. |
| `import * as Sys from System` | Use `Sys` as a namespace alias. |
| `import Math from System` | Use `Math` as a type name. |
| `import Math as M from System` | Use `M` as a type alias. |
| `import static Math from System` | Use accessible static members of `Math` by name. |

For example:

```kobo
import * as Sys from System
import Math as M from System
import Console as Output from System

// Inside a function:
var result = M.Sqrt(144)
Output.WriteLine(Sys.DateTime.Now)
```

The calls retain their names. A namespace alias does not introduce its
types as unqualified names: use `Sys.Math` or `Sys.DateTime`.

All import declarations must be at **file scope**, not inside a type, function,
or block. Place them before the module and declarations. Imports apply to their
file, not to other input files, and follow Kobo name lookup rules.

### Wildcards and extension methods

```kobo
import * from System
import * from System/Collections/Generic
import * from System/Linq
```

A wildcard imports types and extension methods from that namespace, not its
child namespaces. Repeated identical wildcard imports are deduplicated.
Ambiguous type names are diagnosed when used; select a type alias or use
explicit replacement to disambiguate.

For several namespaces, group wildcard imports in one multiline declaration:

```kobo
import * from
{
    System/Net,
    System/Collections/Generic,
    System/Linq
}
```

Each path still names
one namespace; child namespaces are not imported implicitly. Paths are
comma-separated, and an empty list or trailing comma is invalid.

### Compound, multiline, and static imports

```kobo
import {
    HttpClient as Client,
    HttpRequestMessage as Request,
    HttpMethod
} from System/Net/Http

import {
    static Math,
    Console as Output,
    String
} from System
```

Each entry is independent. `static` applies only to the entry
that carries it. It exposes the accessible static members of the **type**, so
`Sqrt(144)` is available after `import static Math from System`.

Static imports do not select individual methods:
`import static Sqrt from System/Math` is invalid. Static aliases, static wildcards,
wildcards inside compound lists, and a global `static` modifier on a compound
list are rejected. Write `import { static Math, static Convert } from System`
to import two types' static members.

Open generic types cannot be named import aliases: `import List from System/Collections/Generic`
is rejected. Use a wildcard namespace import or `using List from System/Collections/Generic`
and supply generic arguments at the use site.

## Explicit fully qualified type replacement

```kobo
using Math from System
using Math as M from System

// Inside a function, or at the top level of a #:script:
var twelve_2 = M.Sqrt(144)
var twelve_3 = Math.Sqrt(256)
```

Both names identify the same type. This also applies to native scripts.

Single types, aliases, and compound/multiline lists are supported:

```kobo
using {
    HttpClient as Client,
    HttpRequestMessage as Request
} from System/Net/Http
using { List as Items, Dictionary as Map } from System/Collections/Generic
```

Use `Items<string>` or `Map<string, int>` in your code; do not put generic
arguments in the declaration itself. Replacements work in type annotations,
return/parameter types, generic arguments, constructors, inheritance, casts,
type tests, and static member receivers. Normal local variables, parameters,
and generic type parameters retain their binding rules.

`using` accepts **named types only**, not namespaces, wildcards, or static entries.

### Lexical scope

Replacement declarations may appear at file/module, class, function, or
nested-block scope:

```kobo
class:Example
{
    using HttpClient as Client from System/Net/Http
    function:Client Create() => new Client()

    function:void Build()
    {
        using List from System/Collections/Generic
        var:List<string> names = new List<string>();
        {
            using ArrayList as List from System/Collections
            var:List inner = new List()
        }
        var:List<int> numbers = new List<int>()
    }
}
```

Names become available on lines after the **completed** declaration, through
the end of its lexical scope. Inner replacements can shadow outer names.
Declarations are not retroactive and do not leak between files. Compound
entries all take effect after the closing `} from ...` line.

Duplicate local names within a scope, including collisions between an import
alias and a replacement, are errors. An alias cannot conflict with a type
declared in the same scope.

## Dependencies and multi-file builds

Neither keyword installs a dependency or includes a source file. A `module`
determines the namespace of the file's own declarations independently.

For scripts, use `#:package` for NuGet dependencies:

```kobo
#:script
#:package Newtonsoft.Json@13.0.3
import * from Newtonsoft/Json
import * from System

var json = JsonConvert.SerializeObject(new { Name = "Ada" })
Console.WriteLine(json)
```

Run with `kobo run example.kobo`. In a .NET project using BuildTools, use a project
`PackageReference`. Framework namespaces need no additional package directive.

CLI builds, BuildTools, and the language server use the same syntax.
Multi-file builds preserve import directives on ordinary file declarations.
Global functions and unions share declarations per module, so their
contributing imports must be compatible. Conflicting aliases are reported.
Use lexical `using` replacements when independent files need the same local
name for different types.

## Migration and errors

| Intent or old syntax | Current syntax |
| --- | --- |
| Namespace import `import System/Net/Http` | `import * from System/Net/Http` |
| Namespace alias `import System as Sys` | `import * as Sys from System` |
| Static import `import static System/Math` | `import static Math from System` |
| Selective list `import System/IO/{File, Directory}` | `import { File, Directory } from System/IO` |
| Explicit FQN substitution previously done by a named import | `using HttpClient as Client from System/Net/Http` |
| Bare `HttpClient from System/Net/Http` | Add `using` for replacement or `import` for an alias |
| Open generic named import | `using List from System/Collections/Generic` or wildcard namespace import |
| Namespace path without `from` | `import * from System` |

Existing named `import` declarations introduce aliases rather than substitute
references. Move class/function/block-level named imports to `using` to preserve
lexical behavior. Dotted namespace paths, invalid aliases, inaccessible or
ambiguous named types, empty/trailing entries, and conflicting names are errors.

Directly qualified external types such as `System.Math` remain restricted;
use an import alias, namespace alias, or explicit replacement. Qualified names
of Kobo-defined types remain supported.

## Related documentation

- [Language reference](/docs/language-reference.md#imports)
- [Command-line compiler](https://github.com/thinkmine/KoboLang/blob/master/Kobo.Lang.Compiler/README.md)
- [BuildTools integration](/docs/buildtools.md)
