<img src="kobo-emerald.png" alt="Kobo logo" width="48" height="48" />

# Kobo

## Language version 0.1.25

Kobo is an AI-conscious, general-purpose programming language built for the
.NET ecosystem. Designed from the ground up with both human developers and AI
code generation in mind, Kobo emphasizes syntactic consistency, expressive
programming constructs, and reduced complexity. Unlike traditional languages
that evolved primarily around human-written code, Kobo recognizes AI as an
increasingly important participant in software development. Its predictable
grammar, consistent declaration patterns, and streamlined syntax aim to make
code easier to generate, understand, validate, and maintain. Kobo combines
modern language design with the maturity and performance of the .NET platform.

Currently in preview, Kobo includes classes, functions, generics, query
expressions, native JSON, console commands, typed AI prompts and tools, and
the libraries and types available to .NET applications.

## How Kobo works

Kobo source files use the `.kobo` extension. The compiler builds them into
standard .NET assemblies, so programs can run with the .NET runtime and use
the .NET libraries. You can build one file or compile a directory of Kobo
files together into a single assembly.

Kobo files can also be added to an SDK-style .NET project with BuildTools.
They participate in the same project compilation: there is no separate Kobo
assembly to manage for each source file, and accessible declarations can be
shared across Kobo files.

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
standalone program, integrating Kobo into a .NET project, and writing a
single-file utility.

- [Why Kobo?](WHY-KOBO.md)
- [Get Started with Kobo](GET-STARTED.md)
- [Kobo language specification and guide](KOBO-LANGUAGE.md)
- [Imports and type replacement](IMPORTS.md)
