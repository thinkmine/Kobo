# Kobo Language Support for Visual Studio

## Extension version 0.1.53 (Kobo language 0.1.53)

This VSIX adds `.kobo` and `.kb` editing support to Visual Studio 2022 (17.14 or later)
and Visual Studio 2026 (Community, Professional, and Enterprise) on x64 and
ARM64 Windows. A single VSIX supports both architectures. It shares the
Kobo language server and TextMate
grammar with the VS Code extension. It provides syntax highlighting, completion,
hover information, go to definition, and diagnostics. Prompt bodies remain plain
text except for `${...}` Kobo expressions. The editor uses the shared grammar for
coloring; Visual Studio may not apply every semantic token provided by the server.
Inferred fields have fixed compile-time types. The server provides completion and
diagnostics for types it can resolve from the current file and runtime references;
full project and cross-file inference is resolved by the build.

The extension does not compile Kobo itself. Kobo compilation in projects is
provided by the separate `thinkmine.kobo.lang.buildtools` NuGet package.

## Project integration and templates

When a `.kobo` or `.kb` file is added to a supported SDK-style .NET project in a solution, the
extension offers to install BuildTools 0.1.53 if it is not already installed.
The prompt appears at most once per project per Visual Studio session; declining
leaves the project unchanged. Installation uses the project's configured
NuGet sources and reports failures in a dialog and the Visual Studio Activity
Log. The package automatically includes Kobo files during project compilation.
Standalone files, unsupported projects, and legacy project files are unaffected.

The **Kobo Console Application** template creates a Kobo-only `net11.0`
console project with a Kobo `Main` method. The **Kobo Enabled Console
Application** template creates a `net11.0` console project with a Kobo
source file compiled alongside it. Both templates reference BuildTools 0.1.53.
Project builds require a .NET 11 compiler host with Roslyn 5.9 or later;
older .NET Framework-based Visual Studio analyzer hosts cannot run the generator.
The BuildTools package also requires `thinkmine.kobo.ai` 0.1.53 to be
available on a configured NuGet source.

## Requirements

- Visual Studio 2022 17.14 or later, or Visual Studio 2026 for Windows, with the core editor
- .NET 11 runtime matching the Windows architecture (x64 or ARM64), with
  `dotnet` available on `PATH`; .NET 11 SDK to build projects

Opening a `.kobo` or `.kb` file starts the bundled language server. If it cannot start,
Visual Studio shows an InfoBar; details from the server appear in the Visual
Studio Activity Log. Install the .NET 11 runtime if `dotnet` is unavailable.

## Install and use

Install the Visual Studio VSIX on a supported Windows machine, then restart
Visual Studio.

Open a folder or individual file to use the language server. In an open folder,
completion can use other Kobo files in that workspace, including unsaved open
files. Dependency-specific suggestions still depend on the references known
to the language server.
