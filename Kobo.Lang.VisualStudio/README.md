# Kobo Language Support for Visual Studio

## Extension version 0.1.26 (Kobo language 0.1.25)

This VSIX adds `.kobo` editing support to Visual Studio 2022 (17.14 or later)
and Visual Studio 2026 (Community, Professional, and Enterprise). It shares the
Kobo language server and TextMate
grammar with the VS Code extension. It provides syntax highlighting, completion,
hover information, go to definition, and diagnostics. Prompt bodies remain plain
text except for `${...}` Kobo expressions. The editor uses the shared grammar for
coloring; Visual Studio may not apply every semantic token provided by the server.

The extension does not compile Kobo itself. Kobo compilation in projects is
provided by the separate `thinkmine.kobo.lang.buildtools` NuGet package.

## Project integration and templates

When a `.kobo` file is added to an SDK-style C# project in a solution, the
extension offers to install BuildTools 0.1.26 if it is not already installed.
The prompt appears at most once per project per Visual Studio session; declining
leaves the project unchanged. Installation uses the project's configured
NuGet sources and reports failures in a dialog and the Visual Studio Activity
Log. The package automatically includes Kobo files during project compilation.
Standalone files, non-C# projects, and legacy C# project files are unaffected.

The **Kobo Console Application** template creates a Kobo-only `net11.0`
console project with a Kobo `Main` method. The **Kobo Enabled Console
Application** template creates a C# `net11.0` console project with a Kobo
source file compiled alongside it. Both templates reference BuildTools 0.1.26.
Project builds require a .NET 11 compiler host with Roslyn 5.9 or later;
older .NET Framework-based Visual Studio analyzer hosts cannot run the generator.
The BuildTools package also requires `thinkmine.kobo.ai` 0.1.26 to be
available on a configured NuGet source.

## Requirements

- Visual Studio 2022 17.14 or later, or Visual Studio 2026 for Windows, with the core editor
- .NET 11 runtime, with `dotnet` available on `PATH`; .NET 11 SDK to build projects

Opening a `.kobo` file starts the bundled language server. If it cannot start,
Visual Studio shows an InfoBar; details from the server appear in the Visual
Studio Activity Log. Install the .NET 11 runtime if `dotnet` is unavailable.

## Build and install

On Windows, install the Visual Studio extension development workload and the
.NET 11 SDK. Build `Kobo.Lang.VisualStudio.csproj` in Visual Studio 2026 or with
MSBuild. The project publishes the language server into the VSIX automatically.
Open the generated `.vsix` on a machine with a supported Visual Studio to install it,
then restart Visual Studio. On macOS, use `python3 build_vsix.py` with the .NET
11 SDK and Mono to package the extension with the official VSSDK tool. The
package includes the VSSDK-generated `manifest.json` and `catalog.json` needed
by the Visual Studio Marketplace, plus project template discovery manifests.
Visual Studio itself is required on Windows
to test installation and editor integration.

The VSIX installation target uses stable API version 17.14 as its lower bound,
which the Visual Studio Marketplace accepts and Visual Studio 2026 supports.

To publish this VSIX, choose **New extension → Visual Studio** in the
[Visual Studio Marketplace](https://marketplace.visualstudio.com/vs). The
Visual Studio Code extension has a separate VSIX and upload category; uploading
this Visual Studio VSIX as a Visual Studio Code extension is not supported.

Open a folder or individual file to use the language server. In an open folder,
completion can use other Kobo files in that workspace, including unsaved open
files. Dependency-specific suggestions still depend on the references known
to the language server.
