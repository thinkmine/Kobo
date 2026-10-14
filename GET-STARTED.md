# Get Started with Kobo

Kobo lets you build standalone .NET programs, add Kobo source files to an
existing C# project, or keep a small utility and its build settings in one file.
This guide walks through each approach.

## 1. Prepare your environment

Install the [.NET 11 SDK](https://dotnet.microsoft.com/download/dotnet).
The SDK includes the tools needed to build and run the examples.

Check your installation:

```sh
dotnet --list-sdks
```

Confirm that an `11.0` SDK is listed. If your working directory inherits a
`global.json`, ensure it selects a compatible installed SDK.

Kobo is currently a preview. The examples use prerelease packages; your
configured NuGet sources must contain them. If you are using locally built
packages rather than a published feed, see
[Building from source](Kobo.Lang.Compiler/README.md#building-from-source).

### Optional: set up VS Code

Install the **Kobo** extension, published by **thinkmine**, for `.kobo`
highlighting and language-server support. If installing a locally packaged
extension, open the Command Palette, choose **Extensions: Install from VSIX...**,
and select the Kobo VSIX.

For the mixed C#/Kobo example, also install Microsoft's C# language support.
The editor's compiler host must support .NET 11 and Roslyn 5.9 or newer to load
the current BuildTools generator. An SDK-compatible command-line build does
not automatically guarantee an editor-compatible compiler host.

The Kobo extension is editor tooling, not the compiler. Choose the standalone
CLI or project package below to enable builds.

## 2. Build your first Kobo program

### Install the command-line compiler

```sh
dotnet tool install --global thinkmine.kobo.lang --prerelease
```

If already installed, update it instead:

```sh
dotnet tool update --global thinkmine.kobo.lang --prerelease
```

Ensure the .NET global tools directory is on your `PATH`. It is usually
`$HOME/.dotnet/tools` on macOS/Linux and `%USERPROFILE%\.dotnet\tools` on Windows.
Open a new terminal after changing `PATH`.

### Create a working folder

```sh
mkdir KoboHello
cd KoboHello
```

Create `hello.kobo` with this content:

```kobo
import System

module Examples/Hello

[public] class:Program
{
    [public, static] function:void Main(string[] args)
    {
        Console.WriteLine("Hello, world!")
    }
}
```

Here is what the program declares:

- `import System` makes standard console APIs available.
- `module Examples/Hello` places the program in a namespace. Forward slashes
  express its hierarchy as a readable path.
- `class:Program` declares a class; `[public]` supplies its accessibility.
- `function:void Main(string[] args)` declares the entry-point function.
  Parameters use `Type name`.
- `[static]` allows the runtime to call `Main` without creating an instance.

### Build and run

```sh
kobo build hello.kobo --output-directory ./build --name Hello
dotnet ./build/Hello.dll
```

Expected output:

```text
Hello, world!
```

The output folder contains `Hello.dll` and `Hello.runtimeconfig.json`.
Keep both when running this standalone executable.

### Grow into multiple files

To compile all Kobo files directly in the current folder together:

```sh
kobo build --output-directory ./build --name Hello
```

To include Kobo files in subfolders:

```sh
kobo build --recursive --output-directory ./build --name Hello
```

You can also select a folder explicitly with `kobo build ./src --recursive`.
Folder builds produce one assembly, not one assembly per file. Recursive
discovery skips `bin`, `obj`, and symbolic-link directories.

Files sharing a module share its namespace and generated globals and unions.
Folder names do not assign modules automatically. When supplying both output
options, put `--output-directory` before `--name`.

## 3. Add Kobo to an existing C# console application

Use **BuildTools** when you want Kobo and C# files in the same project.
Your existing application remains the host: its project controls dependencies,
configuration, and the output assembly. A separate Kobo build is unnecessary.

This is useful for introducing Kobo gradually. Keep your current startup code
and services, add a Kobo component, and call it directly from existing code.
The component participates in the same compilation instead of becoming a
separately managed library.

### Open the console project

Change into the directory containing its `.csproj` file. If you do not already
have a console project, create one to try the example:

```sh
dotnet new console --name MixedApp --framework net11.0
cd MixedApp
```

### Install BuildTools

```sh
dotnet add package thinkmine.kobo.lang.buildtools --prerelease
```

The package automatically registers Kobo files as compiler inputs. You do not
need the standalone `kobo` tool for this workflow or manual `.csproj` edits to
include each Kobo file.

### Add a Kobo class

Create `Greeting.kobo` in the project folder:

```kobo
module Example/Greetings

[public] class:Greeting
{
    [public] function:string For(string name)
    {
        return $"Hello, {name}, from Kobo!"
    }
}
```

### Call it from C#

In a new console project, replace `Program.cs` with the following. In an
existing application, incorporate the same call into your normal startup code:

```csharp
using Example.Greetings;

var greeting = new Greeting();
Console.WriteLine(greeting.For("Ada"));
```

The relevant project files are now:

```text
MixedApp/
  MixedApp.csproj
  Program.cs
  Greeting.kobo
```

### Build and run the project

```sh
dotnet build
dotnet run --no-build
```

Expected output:

```text
Hello, Ada, from Kobo!
```

Use `dotnet build`, not a separate `kobo build`, for this workflow. BuildTools
discovers Kobo files recursively, excludes build output directories, and adds
their generated declarations to the project compilation.

Configure NuGet dependencies, local DLL references, SDK selection, and build
properties in the project. Do not put single-file app directives in embedded
Kobo files. See the [BuildTools guide](Kobo.Lang.BuildTools/README.md) for
compatibility and file-discovery details.

## 4. Write a single-file scripting utility

For a small automation task, keep the program and its build settings in one
`.kobo` file, without creating or maintaining a project file. This workflow
still compiles an executable: it is not an interpreted REPL, and the current
CLI uses separate build and run commands.

Use the standalone compiler installed in step 2. Create a separate working
folder and save this as `greet.kobo`:

```kobo
#:sdk Microsoft.NET.Sdk
#:property Nullable=enable

import System

[public] class:Program
{
    [public, static] function:void Main(string[] args)
    {
        var name = args.Length > 0 ? args[0] : "world"
        Console.WriteLine($"Hello, {name}!")
        Console.WriteLine($"Today is {DateTime.Now:yyyy-MM-dd}.")
    }
}
```

### Build and pass script arguments

```sh
kobo build greet.kobo --output-directory ./build --name Greet
dotnet ./build/Greet.dll Ada
```

The program prints `Hello, Ada!` followed by the current date. Without an
argument, it greets `world`. After editing the source, rebuild before running.

### Add a library dependency

Framework APIs such as `Console` and `DateTime` need no package directive.
For a NuGet library, add a package directive at the top of the file:

```kobo
#:package Newtonsoft.Json@13.0.3
```

Add its namespace with the other imports:

```kobo
import Newtonsoft/Json
```

You can then use its APIs inside `Main`:

```kobo
Console.WriteLine(JsonConvert.SerializeObject(new { Name = name }))
```

Build again with the same command. The SDK restores the package using configured
NuGet sources; restoration may require network access. A package ID identifies
the dependency, while an import brings its namespace into scope.

### Supported app directives

| Directive | Purpose | Example |
| --- | --- | --- |
| `#:sdk` | Selects the SDK used to build the single-file app. | `#:sdk Microsoft.NET.Sdk` |
| `#:property` | Sets a build property as `Name=Value`. | `#:property Nullable=enable` |
| `#:package` | Adds a NuGet dependency, optionally with an explicit version. | `#:package Newtonsoft.Json@13.0.3` |

Repeat property or package directives as needed. Other app directives, including
`#:project`, are rejected. App directives are for standalone single-file apps,
not multi-file batches or BuildTools inputs.

The single-file CLI does not directly reference arbitrary local DLLs. Package
such a library into a local NuGet source, or use a project with BuildTools and
configure an assembly reference there. Setting a property named `Reference`
does not add an assembly reference.

## Choose your next step

| Goal | Workflow |
| --- | --- |
| Build a standalone Kobo program | `kobo build file.kobo` |
| Compile a folder of Kobo files together | `kobo build ./src` |
| Include nested source folders | `kobo build ./src --recursive` |
| Mix Kobo and C# in an existing project | Install BuildTools and use `dotnet build` |
| Keep a utility and dependencies in one file | Use app directives and the single-file build/run workflow |

Continue with [The Kobo Programming Language](KOBO-LANGUAGE.md) for variables,
control flow, type extensions, classes, inheritance, lambdas, and queries.
See the [compiler guide](Kobo.Lang.Compiler/README.md) for installation and
command-line details, or the [VS Code guide](Kobo.Lang.VSCode/README.md) for
editor setup.
