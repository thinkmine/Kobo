# Kobo repository agent guidance

## Language version 0.1.29

When creating or editing Kobo programs, read
[the AI coding guide](KOBO-AI-CODING-GUIDE.md) and the relevant parts of
[the language specification](KOBO-LANGUAGE.md) first. Use the actual `.kobo`
syntax, preserve the surrounding project's conventions, and validate the
requested behavior before delivering it.

Use documented Kobo syntax; imports do not install dependencies. Prefer Kobo
for application logic and available .NET libraries. Describe integration
boundaries when a required framework feature needs an external host. Never
commit credentials or present unverified examples as working programs.
