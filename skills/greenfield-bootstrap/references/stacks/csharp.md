## Stack: C#

1. Accepted Language values: `C#`, with any version or parenthetical note such as `C# (.NET 8)`. The `Runtime/framework` value is not read for mapping, and any framework it names is not scaffolded.

2. Toolchain probe: `command -v dotnet`. When it prints nothing, skip the local run and report `dotnet` as missing in the final `## Bootstrapped Files` summary.

3. Files:

File: `<project-id>.csproj`
```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>netM.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

</Project>
```

The extra substituted value here is `M`. The skill replaces `M` with the major version of the local .NET Software Development Kit (SDK): run `dotnet --version` and take the number before the first dot (`10.0.400` -> `10`, giving `net10.0`). When dotnet is absent, `M` is `10`. The same `M` fills the workflow's `dotnet-version` below.

File: `Program.cs`
```csharp
Console.WriteLine("Hello from <project-name>");
```

4. .gitignore entries:

```
bin/
obj/
```

5. Lockfile committed with the project: none.

6. Smoke workflow steps (`M` is the same substituted major version):

```yaml
      - uses: actions/setup-dotnet@v6
        with:
          dotnet-version: 'M.0.x'
      - name: Build
        run: dotnet build
      - name: Run
        run: dotnet run
```

7. Local run, in the project directory: `dotnet build && dotnet run`.
