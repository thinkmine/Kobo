# Kobo repository agent guidance

## Language version 0.1.53

When creating or editing Kobo programs, read
[the AI coding guide](KOBO-AI-CODING-GUIDE.md) and the relevant parts of
[the language specification](KOBO-LANGUAGE.md) first. Use the actual `.kobo`
syntax, preserve the surrounding project's conventions, and validate the
requested behavior before delivering it.

Use documented Kobo syntax; imports do not install dependencies. Prefer Kobo
for application logic and available .NET libraries. Describe integration
boundaries when a required framework feature needs an external host. Never
commit credentials or present unverified examples as working programs.

## Required release completion check

Whenever Kobo packages are rebuilt for a new version:

- Create `<repository-root>/artifacts/<version>/` and copy the compiler,
  BuildTools, and AI NuGet packages plus the VS Code and Visual Studio VSIX
  packages into it.
- Run `python3 .github/skills/update-packages/scripts/collect_packages.py <version>`
  from the repository root. This required completion gate checks all five
  packages' embedded versions and verifies copied files against their build
  outputs using SHA-256.
- Do not report the release task complete unless the command succeeds.
  Report packaging, copying, or verification failures explicitly.
- Include the artifact directory and links to all five packages in the final
  response. Do not publish packages unless explicitly requested.
