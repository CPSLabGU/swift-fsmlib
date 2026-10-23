# Generating Bundles with Templates

Write machines and arrangements through MTL templates that produce the same files as the Swift language bindings.

@Metadata {
  @PageKind(article)
}

## Overview

`FSMEcore` ships one template set for each output format that has a Swift language binding: C, Objective-C++ and SCXML. The templates read a machine or an arrangement in the structural metamodel and write every file of the bundle, byte for byte as the Swift bindings write them. This includes the generated code, the CMake files, the boilerplate and transition files, the layout and window layout files and, for Objective-C++ arrangements, the infrastructure headers.

Because the output is identical, a bundle written through the templates can be read back with the Swift readers, and the templates can take the place of a Swift language binding.

## Writing a Machine

``TemplateBinding`` is an output language whose files come from the templates. Render a machine with `TemplateBinding.make(for:named:format:isSuspensible:)` and write it as you would with any other language binding:

```swift
import FSM
import FSMEcore
import Foundation

let machine = try Machine(from: URL(fileURLWithPath: "Counter.machine"))
let binding = try await TemplateBinding.make(for: machine, named: "Counter", format: .c, isSuspensible: true)
try machine.write(to: URL(fileURLWithPath: "out/Counter.machine"), language: binding, isSuspensible: true)
```

The files are rendered for the name and format given to `make`; write the machine to a bundle with that name. A machine is rendered in both suspensibility variants, and its bundle receives the variant for the suspensibility that the machine storage being written declares, so that the result is the same as with the Swift language binding. A format that keeps a machine in a single file, such as SCXML, writes that file to the given location:

```swift
let scxml = try await TemplateBinding.make(for: machine, named: "Counter", format: .scxml, isSuspensible: true)
try machine.write(to: URL(fileURLWithPath: "out/Counter.scxml"), language: scxml, isSuspensible: true)
```

## Writing an Arrangement

Render an arrangement together with the bundles of its machines and write it through an `ArrangementWrapper` that uses the binding as its language:

```swift
let arrangement = try ArrangementWrapper(url: URL(fileURLWithPath: "Counters.arrangement")).arrangement
let binding = try await TemplateBinding.make(
    for: arrangement, named: "Counters", format: .objCX, isSuspensible: true)
let wrapper = ArrangementWrapper(
    directoryWithFileWrappers: [:], for: arrangement, named: "Counters.arrangement", language: binding)
wrapper.isSuspensible = true
try wrapper.write(to: URL(fileURLWithPath: "out/Counters.arrangement"))
```

The arrangement and its machines follow the suspensibility given to `make`. Instance names are made unique and each machine type is written once, as the Swift bindings do. Where the Swift arrangement code lists machine types in no particular order, the templates list them in the order of their first instance.

## Generating Individual Artefacts

``StructuralTemplateGenerator`` renders a machine in the format of its own language and writes either the whole bundle, the SCXML document, the CMake file or the layout files:

```swift
let generator = StructuralTemplateGenerator()
try await generator.generateCMakeLists(for: machine, named: "Counter", to: URL(fileURLWithPath: "CMakeLists.txt"))
```

## Template Sets

Each template set lives in its own directory below the structural template root, together with a `templateset.json` manifest that ``StructuralTemplateSet`` describes. The manifest names the formats the set writes, the language name its bundles declare, the module and templates to run, and whether it writes a single file. The main templates take the machine or arrangement, the bundle name without extension and whether to write the suspensible variant:

```mtl
[template public generateMachine(m : Machine, name : String, isSuspensible : Boolean)]
[template public generateArrangement(a : Arrangement, name : String, isSuspensible : Boolean)]
```

The sets share modules for the files that every machine bundle holds, for the layout property lists and for the instances of arrangements. Files that a set emits unchanged, such as the Objective-C++ infrastructure headers, are kept as plain resource files beside its templates.

In addition to the AQL library, templates can use ``StructuralTemplateServices`` (`formatted`, `base64Decoded` and `eIsSet`) and the `resourceText` and `resourceExists` services of `MTLResourceServices`, which read resource files relative to the directory of the template set.

## Layout Properties

Additional properties of a state layout, such as the colours an editor keeps, are stored in the structural model as typed property list entries, so that real, integer, Boolean, string, data, date, array and dictionary values keep their types and the layout file is written unchanged. Documents that store these properties as JSON text are still read.
