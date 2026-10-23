# Option Reference

Every option of `fsmconvert`, as `fsmconvert --help` lists it.

@Metadata {
  @PageKind(article)
}

## Overview

| option | value | effect |
|---|---|---|
| `-f`, `--format` | a target | the native format, model document or kernel target to write (see <doc:Levels>) |
| `-o`, `--output` | a path | the machine, arrangement or document to write, or the directory of a kernel target (default `fsm.out`) |
| `-a`, `--arrangement` | | writes an arrangement of a single machine |
| `-n`, `--non-suspensible` | | writes non-suspensible machines |
| `-i`, `--introspectable` | | makes the generated code introspectable |
| `-v`, `--verbose` | | prints a summary of the machines read |
| `--debug` | | prints debugging output |
| `-q`, `--quiet` | | shows neither progress nor warnings |
| `--metamodel` | `structural`, `sectioned`, `kernel` | the level of `xmi` and `json` output; at the kernel level, `c`, `cpp`, `swift` and `java` name the kernel targets |
| `--transform` | `structural2machine`, `structural2scxml`, `structural2cmake`, `structural2layout` | runs a bundled structural template set; requires `--metamodel structural` |
| `--generator` | `mtl`, `swift` | writes native formats with the bundled templates (the default) or the Swift language bindings |
| `--validate` | | validates the kernel model of the input without writing anything |
| `--profile` | `strict`, `relaxed` | the validation profile of `--validate` (default `strict`), which kernel targets must also satisfy |
| `--semantics` | `option=value` | a semantic option of the encoding into the kernel (repeatable) |
| `--entry` | `ringlet`, `fused` | when the verification targets run the action of a state |
| `--max-rounds` | a whole number | the bound of the round counter of the verification targets |
| `--sanity` | | adds sanity properties to the verification targets |
| `--opaque` | `reject`, `havoc` | how the verification targets treat opaque nodes |
| `--param` | `name=value` | a template parameter (repeatable) |
| `--template-path` | a directory | a directory searched for imported template modules (repeatable) |
| `--reference-style` | `encoded`, `plain` | how written XMI spells references into itself |
| `--unset-features` | `defaults`, `undefined` | how transformations and templates read unset features |

A value that an option does not accept is reported with the values it does
accept, and `fsmconvert` exits with status 64. A conversion that fails exits
with status 1.

When standard error is a terminal, a progress bar shows how many files have
been written; `--quiet` hides it.

## Help

```
OVERVIEW: Convert, transform, validate and generate logic-labelled finite-state
machines.

fsmconvert reads .machine and .arrangement bundles, SCXML documents, and XMI or
JSON models at the structural, sectioned or kernel level, which it recognises
by the namespace of the root element. It transforms the model along the
shortest chain of levels to the one that --format needs, and writes a native
format, a model document or a kernel target.

Native formats: c, c++, cpp, cxx, objc, objc++, objcpp, scxml, swift, verilog,
vhdl. Model documents: xmi, json, structural-xmi, sectioned-xmi, kernel-xmi.
Kernel targets: kernel-c, kernel-cpp, kernel-swift, kernel-java, smv, tla, dot.
With --metamodel kernel, the names c, cpp, java, swift stand for the kernel
targets of those languages, and xmi and json write the level that --metamodel
names.

USAGE: fsmconvert [<options>] <input-machines> ...

ARGUMENTS:
  <input-machines>        The input machines, arrangements or model documents
                          to read.

OPTIONS:
  -a, --arrangement       Create an arrangement of a single FSM.
  -f, --format <format>   The output machine format, model document or kernel
                          target.
        One of c, c++, cpp, cxx, objc, objc++, objcpp, scxml, swift, verilog,
        vhdl, xmi, json, structural-xmi, sectioned-xmi, kernel-xmi, kernel-c,
        kernel-cpp, kernel-swift, kernel-java, smv, tla, dot, java.
  -i, --introspectable    Make the generated code introspectable.
  -n, --non-suspensible   Make the generated machine non-suspensible.
  -o, --output <output>   The output machine, arrangement or document, or the
                          directory of a kernel target. (default: fsm.out)
  -v, --verbose           Turn on verbose output.
  --debug                 Turn on debug output.
  -q, --quiet             Show neither progress nor warnings.
  --metamodel <metamodel> Use metamodel-backed conversion at the selected model
                          level. (values: structural, sectioned, kernel)
        The level of xmi and json output. At the kernel level, c, cpp, java,
        swift name the kernel targets of those languages. 'executable' is a
        deprecated name of 'sectioned'.
  --transform <transform> Apply a bundled structural MTL template after
                          metamodel loading.
  --generator <mtl|swift> The generator of native formats: mtl uses the bundled
                          templates, swift the Swift language bindings.
                          (values: mtl, swift; default: mtl)
  --validate              Transform the input to the kernel, validate it and
                          print the diagnostics without writing anything.
  --profile <strict|relaxed>
                          The validation profile of --validate (default
                          strict), which kernel targets must also satisfy.
                          (values: strict, relaxed)
  --semantics <option=value>
                          A semantic option of the encoding into the kernel as
                          option=value (can be specified multiple times).
        selfLoop=traditional|reentry, elideEmptySections=true|false,
        suspension=encode|omit, resumeFallback=initial|previous,
        time=external|clock, inState=expand|exact
  --entry <ringlet|fused> When the verification targets run the action of a
                          state: ringlet (the default) or fused. (values:
                          ringlet, fused)
  --max-rounds <N>        The bound of the round counter of the verification
                          targets (default 0: no counter).
  --sanity                Add sanity properties to the verification targets.
  --opaque <reject|havoc> How the verification targets treat opaque nodes:
                          reject (the default) or havoc. (values: reject, havoc)
  --param <param>         A parameter for the templates as name=value (can be
                          specified multiple times). Templates read it as the
                          variable [name/] or with parameter('name'), and test
                          for it with hasParameter('name'). The name must be an
                          identifier that is not a reserved keyword.
  --template-path <template-path>
                          A directory to search for imported modules (can be
                          specified multiple times)
  --reference-style <encoded|plain>
                          How an XMI model spells references into itself; plain
                          writes them as Eclipse writes XMI model files
                          (values: encoded, plain; default: encoded)
        With encoded, the default, an XMI model keeps its usual layout and a
        reference to an object of the same document keeps the leading # of its
        fragment, such as #//@classifiers.0. With plain, the model is written
        in the layout of the Eclipse Modeling Framework, with references as
        attribute values holding the fragment alone, such as //@classifiers.0,
        as Eclipse writes XMI model files. Both styles load again.
  --unset-features <defaults|undefined>
                          How unset features read: defaults (the default), as
                          in the Eclipse Modeling Framework, or undefined
                          (values: defaults, undefined; default: defaults)
        With defaults, an unset single-valued attribute reads as its declared
        default or the default of its data type (false, 0, 0.0 or the first
        enumeration literal), an unset many-valued feature as an empty
        collection, and an unset string or reference as undefined, as the
        Eclipse Modeling Framework and its engines read them. With undefined,
        every unset feature reads as undefined.
  -h, --help              Show help information.

```
