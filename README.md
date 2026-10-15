<img src="kobo-emerald.png" alt="Kobo logo" width="48" height="48" />

# Kobo

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

Kobo is currently in preview. It brings a compact, statically typed,
object-oriented syntax to .NET, with support for classes, functions, generics,
query expressions, and the libraries and types available to .NET applications.

## How Kobo works

Kobo source files use the `.kobo` extension. The compiler builds them into
standard .NET assemblies, so programs can run with the .NET runtime and use
the .NET libraries. You can build one file or compile a directory of Kobo
files together into a single assembly.

Kobo can also be added to an existing SDK-style C# project with BuildTools.
In that setup, Kobo and C# files participate in the same project compilation:
there is no separate Kobo assembly to manage, and either language can use
accessible declarations from the other.

The syntax has a few conventions that help distinguish language constructs:

- Declarations use a colon with no surrounding spaces, as in `class:Person`,
  `var:int`, and `function:void`.
- Namespace paths use forward slashes, as in `Company/Commerce/Orders`;
  dots are reserved for member access, as in `order.Number`.
- Braces delimit blocks, while ordinary single-line statements generally do
  not need semicolons.
- Imports bring namespaces into scope; they do not add package dependencies.
  Standalone files can declare NuGet dependencies with `#:` directives.

Kobo is under active development, so its implemented features and tooling may
evolve. The language guide describes the current behavior.

## Get started

The getting started guide covers installing the .NET 11 SDK, building a
standalone program, integrating Kobo into a C# project, and writing a
single-file utility.

- [Why Kobo?](WHY-KOBO.md)
- [Get Started with Kobo](GET-STARTED.md)
- [Kobo language specification and guide](KOBO-LANGUAGE.md)

