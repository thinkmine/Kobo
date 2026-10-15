# Why Kobo?

Kobo is an AI-conscious, general-purpose programming language built for the
.NET ecosystem. Designed from the ground up with both human developers and AI
code generation in mind, Kobo emphasizes syntactic consistency, expressive
programming constructs, and reduced complexity. Unlike traditional languages
that evolved primarily around human-written code, Kobo recognizes AI as an
increasingly important participant in software development. Its predictable
grammar, consistent declaration patterns, and streamlined syntax aim to make
code easier to generate, understand, validate, and maintain. Kobo combines
modern language design with the maturity and performance of the .NET platform.

Kobo aims to make everyday code easier to read and write without giving up the
reach of .NET. It is statically typed, object-oriented, and designed to work
with .NET libraries and applications. Its central design principle is
consistency: when two constructs express related ideas, their syntax should
make that relationship clear.

## A more consistent language

Languages evolve to meet new needs, and established languages must preserve
compatibility with existing code. Over time, that can leave similar concepts
with different declaration patterns. Kobo has an opportunity to build
consistency into its syntax from the start.

For example, typed locals, properties, and function return types put the type
after the declaration keyword. Parameters use the familiar `Type name` form,
and modifiers use a consistent bracketed prefix:

```kobo
[public] class:Person
{
    [public] property:string Name { get; set; }

    [public, static] function:int GetAge()
    {
        return 30
    }
}
```

The same conventions apply across declarations: `var:int age = 30` declares a
typed variable, `property:string Name` declares a property, and
`function:int GetAge()` declares a function returning an integer. The notation
`(int)->string` describes a function type. These patterns give related
constructs a recognizable shape while retaining compile-time type checking.

## Express intent with less ceremony

Kobo uses braces to delimit blocks, but ordinary single-line statements
generally do not require semicolons. Namespace paths use forward slashes, while
dots remain for member access. These choices help distinguish different kinds
of navigation and declaration without requiring extensive punctuation.

The goal is not terseness for its own sake. Consistent syntax can make the
structure of a program easier to scan, help developers recognize unfamiliar
constructs, and keep attention on what the code is doing.

## Compose queries naturally

Kobo supports select-first query expressions that translate into the .NET
sequence-query ecosystem:

```kobo
var names = select person from people
            where person.Age > 30
            orderby person.Name asc
            project person.Name;
```

The syntax lays out the source, filter, ordering, and projection in a consistent
sequence. Query expressions are part of the language, and the resulting
operations work with .NET types and libraries.

This is an area where composition matters: query syntax should work smoothly
with the rest of the language and its operators. C# already provides LINQ query
expressions; Kobo's opportunity is to explore a different, consistently
composable form rather than to claim language-integrated queries as a new idea.

## Use modern capabilities with .NET

Kobo includes features such as generics, lambdas, nullable types, classes,
asynchronous functions, and query expressions. The compiler builds Kobo code
into .NET assemblies, and existing C# projects can include Kobo files through
BuildTools. In that project workflow, Kobo and C# declarations participate in
the same compilation.

This lets a team evaluate Kobo incrementally: existing application code,
dependencies, and .NET runtime remain in place while a component or utility is
written in Kobo. The language is an additional way to express .NET programs,
not a replacement for the .NET platform or its ecosystem.

## Where Kobo fits

Kobo builds on the strengths of the .NET ecosystem rather than asking teams to
leave it behind. C# offers a mature language, extensive libraries, and
established tooling. F# provides a functional-first approach and powerful type
abstractions. Visual Basic .NET emphasizes readability and interoperability.
Kobo's opportunity is a fresh, consistent source-language design that combines
object-oriented familiarity with modern language features and direct access to
.NET.

## AI code generation is a core tenet

Kobo treats AI-assisted code generation as a core language-design tenet,
alongside consistency, expressiveness, and simplicity. It is not merely a use
case Kobo might support later: the language and its tooling should be designed
with both human developers and AI code generators in mind. This focus can
differentiate Kobo among .NET languages, while its practical benefits must be
validated through implementation and evaluation.

Several characteristics of Kobo's design may help make generated code more
predictable:

1. **Syntactic consistency.** Uniform declaration patterns, such as
   `var:string name` and `[public, static] function:int GetAge()`, give code
   generation fewer forms to choose between.
2. **Reduced ambiguity.** Predictable grammar and explicit types can make code
   easier to parse, generate, and validate.
3. **Less boilerplate.** Concise constructs can reduce the amount of code to
   generate while keeping intent visible.
4. **Intent-oriented syntax.** Kobo's query expressions describe the source,
   filtering, ordering, and projection in a regular sequence.
5. **.NET tooling.** Kobo's compiler and project integration provide a path to
   the established .NET compiler, runtime, and tooling ecosystem. Reliable,
   deterministic diagnostics and validation can make generated code easier to
   check and correct.

These are design opportunities, not evidence that Kobo already outperforms
other languages for AI code generation. Models have seen far more C# than
Kobo, and cleaner syntax alone does not establish an advantage. Kobo can,
however, be deliberately engineered so generated code is easier to validate
and correct, then evaluated against clear measures rather than assumed to be
better.

One possible public description is:

> Kobo is an AI-conscious, general-purpose programming language built for the
> .NET ecosystem. Designed with both human developers and AI-assisted code
> generation in mind, Kobo emphasizes syntactic consistency, expressive
> constructs, and reduced complexity. Its predictable grammar and streamlined
> syntax aim to make code easier to generate, understand, validate, and
> maintain, while drawing on the maturity of the .NET platform.

This principle should guide the evolution of the language. Each feature can be
considered against three questions:

- Is it intuitive for human developers?
- Can AI generate it reliably and consistently?
- Can the compiler detect and explain mistakes precisely enough for an AI
  assistant to correct them?

The last question makes compiler feedback especially important. Structured,
machine-readable diagnostics could help automated tools identify and repair
errors, and are a worthwhile direction for Kobo's developer tooling. The
broader goal is to support human-AI collaborative programming. This is a
foundational design objective, not a claim of unproven gains in code quality or
productivity.

## Room to evolve

Kobo is in preview, and its design is still evolving. Some ideas are part of
the current language; others are opportunities for future exploration. Possible
directions include:

| Area | Available today | Possible direction |
| --- | --- | --- |
| Declarations and types | Consistent modifier prefixes, typed declarations, and compile-time checking | Continue applying consistent conventions as the language grows |
| Queries and functions | Query expressions, function types, lambdas, and trailing lambdas | Further improve composition and unify related callable patterns |
| Functional programming | Lambdas, nullable types, and union types for variables | Explore broader immutable-data patterns, pattern matching, and expression-oriented control flow |
| Errors | Exception handling | Explore explicit error-result types alongside exceptions |
| Compile-time work | Compiler and project build tooling | Explore language-level generation and validation features |
| Developer tooling | VS Code extension and language-server support | Continue improving actionable and machine-readable diagnostics, transformations, and semantic tooling |

These are design directions, not promises that every capability is already
implemented.

## A guiding principle

Kobo's long-term direction can be summarized in one rule:

> If two constructs represent the same underlying concept, strive to express
> them using the same syntactic conventions.

That principle guides decisions about declarations, types, functions, queries,
and future language features. It aims to make Kobo predictable for developers
while letting them use the full .NET platform.

## Explore Kobo

- [Get started with Kobo](GET-STARTED.md)
- [Language specification and guide](KOBO-LANGUAGE.md)
- [Project overview](README.md)
