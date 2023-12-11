# CodeProber - Source code based exploration of program analysis results

An implementation of property probes.

Quick overview of features (5 minutes): https://www.youtube.com/watch?v=d-KvFy5h9W0

Installation & getting started: https://www.youtube.com/watch?v=1beyfNhUQEg

## Getting started

1) Download [code-prober.jar](https://github.com/lu-cs-sde/codeprober/raw/master/code-prober.jar) from this repository.
2) Start like this:
    ```
    java -jar code-prober.jar your-analyzer-or-compiler.jar [args-to-forward-to-compiler-on-each-request]
    ```

For example, if you have code-prober.jar in your downloads directory, and your tool is called `compiler.jar` and is located in your home directory, then run:
```
java -jar ~/Downloads/code-prober.jar ~/compiler.jar
```

Once started, you should open http://localhost:8000 in your browser.
When the page is loaded, you'll find a `Help` button on the right side which can help you further.

## Compatibility

To use CodeProber, you must have a compiler or analyzer that follows certain conventions.
Any tool built using [JastAdd](https://jastadd.cs.lth.se/web/) follow these conventions automatically. Support for non-JastAdd tools (and formalizing the conventions) is planned future work (also, see 'I didn't use JastAdd' below).

Even if you built your tool with JastAdd, you must add some way for CodeProber to transform a source file into an AST.
There are two options.

The first option is preferered, and it is to add a method `CodeProber_parse` method in your main class.
It can look like this:

```java
public static Object CodeProber_parse(String[] args) throws Throwable {
  // 'args' has at least one entry.
  // First are all optional args (see "args-to-forward-to-compiler-on-each-request" above).
  // The last entry in the array is path to a source file containing the CodeProber editor text.
  String sourceFile = args[args.length - 1];
  // "parse" is expected to take the path to a source file and transform it to the root of an AST
  return parse(sourceFile);
}
```
CodeProber will invoke this and use the return value as the entry point into your AST.

The second option is for CodeProber to use your normal main method as an entry point.
Since main cannot return anything, the resulting AST must instead be assigned to a static field within your main class.
In total, there are therefore two changes that are required:
In your main java file, add the following declaration:

```java
public static Object CodeProber_root_node;
```

Then, immediately after parsing the input file(s), assign the root of your AST to this variable. E.g:

```java
Program myAst = parse(...);
CodeProber_root_node = myAst;
```

The `CodeProber_root_node` variable will be used by CodeProber as an entry point.
Since many tools perform semantic analysis and call System.exit in main if an error is encountered, CodeProber attempts to install a System.exit interceptor when using the main method.
This has issues on newer versions of java (see "System.exit/SecurityManager problem" below).
If you have problems with this, consider using `CodeProber_parse` instead, which doesn't rely on intercepting System.exit.

If you define both `CodeProber_parse` and `CodeProber_root_node`, then `CodeProber_parse` takes precedence.

If you previously used `DrAST` (https://bitbucket.org/jastadd/drast/src/master/), then you likely have `DrAST_root_node` declared and assigned.
CodeProber will use this as a fallback if neither `CodeProber_parse` nor `CodeProber_root_node` is not defined, so you don't have to do any changes.
However, the help/warning messages inside `CodeProber` that reference the root node will reference `CodeProber_root_node`, even if you don't have it.
So for a more consistent experience, consider adding a specific declaration for CodeProber (or even better, use `CodeProber_parse`).

### Environment variables

There are a few optional environment variables that can be set.
| Key      | Default value | Description |
| ----------- | ----------- | ----------- |
| PORT | 8000 | The port to serve HTML/JS/websocket request on. This is the port you visit in your browser, e.g the '8000' in 'http://localhost:8000' |
| WEB_SERVER_PORT | null | The port for for HTML/JS (non-websocket) requests. If not set, PORT will be used. |
| WEBSOCKET_SERVER_PORT   | null        | The port for websocket requests.  This isn't visible to the user, and normally doesn't need to be changed. If not set, PORT will be used. This can be set to `http` to delegate all websocket traffic to normal HTTP requests instead. This is worse for performance, but can be necessary if hosting CodeProber in a place where websocket doesn't work as expected. |
| PERMIT_REMOTE_CONNECTIONS   | false        | Whether or not to permit unauthenticated remote (non-local) connections to the server. Most compilers/analyzers read/write files on your computer based on user input. By allowing remote connections, you open up a potential vulnerability. Only set to true when on a trusted network, or if running inside a sandboxed environment. |
| WEB_RESOURCES_OVERRIDE   | null        | A file path that should be used to serve web resources (e.g HTML/JS/etc). If null, then resources are read from the classpath. Setting this can be benificial during development of the code prober tool itself (set it to `client/public/`), but there is very little point in setting it for normal tool users. |
| CODESPACES_COMPATIBILITY_HACK   | true        | When running CodeProber inside the Github Codespaces web editor, CodeProber will need to modify the protocol and url used to connect to the websocket server. Normally, CodeProber connects to `ws://host:8080` (or whichever port is used). In Codespaces, CodeProber needs to connect to `wss://{host.replace(8000, 8080)}`, i.e `wss` instead of `ws`, and the port(s) are part of the host rather than the normal `:` port part of the URL. If the compatibility hack doesn't work for you, you can disable it by setting `CODESPACES_COMPATIBILITY_HACK=false`. If you get it to work without the hack; please open an issue on the CodeProber repository and tell us how you did it! Otherwise, try setting `WEBSOCKET_SERVER_PORT` to `http` instead. |

Example invocation where some of these are set:
```sh
PORT=8005 WEB_RESOURCES_OVERRIDE=client/public/ java -jar code-prober.jar /path/to/your/compiler/or/analyzer.jar
```

### Probe Result Visualisation

To tweak how CodeProber visualises events, they can implement a method
`cpr_getOutput()`, which may return objects, arrays, or collections
that are then suitably visualised.


The method `String cpr_getDiagnostic()` allows hoverable diagnostics and drawing edges.
If the `cpr_getDiagnostic()` method returns a string that matches one of the following formats,
it can generates *overlay markings* in the code editor:

| `ERR@S;E;MSG`         | Show a red squiggly line from `S` to `E` with a hover for `MSG` |
| `WARN@S;E;MSG`        | Like `ERR`, but yellow                                          |
| `INFO@S;E;MSG`        | Like `ERR`, but blue                                            |
| `HINT@S;E;MSG`        | Show three dots near `S` with a hover for `MSG`                 |
| `LINE-PP@S;E;COLOR`   | Draw line from `S` to `E` in colour `COLOR`                     |
| `LINE-PA@S;E;COLOR`   | Draw arrow from `S` to `E` in colour `COLOR`                    |
| `LINE-AP@S;E;COLOR`   | Draw arrow from `E` to `S` in colour `COLOR`                    |
| `LINE-AA@S;E;COLOR`   | Draw double-headed arrow between `S` and `E` in colour `COLOR`  |

- Locations S and E have the format `line << 12 | column`, with the topmost `line` and the leftmost `column` being `1`.
- `COLOR` is an RGBA quadruple in the format `#RGBA`  (Other CSS colours may be supported).
- `STYLE` specifications must refer to client style specifications, see below.

### Possibly unsupported- to check

The following might not be supported in the current version of CodeProber:

| `STYLE@S;E;S1,...,Sn` | Appply styles S1 through Sn to the area between `S` and `E`     |

Alternatively, the method can (instead of a string) return a `String[]` with the above four elements, in the same order.

#### [Probably unsupported] Custom Visualistion

Objects exposed by the AST under analysis can additionally provide a
method `public String cpr_getMarker()` to expose the above custom
stylings when probed.  The stylings will only appear while the probe is active.
This can be useful e.g. to visualise parts of a graph on demand.

When a CodeProber probe exposes an `Iterable` object, CodeProber
serialises all elements in the `Iterable` separately and recursively
(eliminating cycles), displaying elemnt per line.  To group multiple
elements on one line, the `Iterable` can provide a method
`public boolean cpr_singleLine() { return true; }`

#### [Probably unsupported] Client Style Specifications

To use STYLE specifications, the analyser-or-compiler jar file's main class must export a field
`public static String[] CodeProber_report_styles`.  Each element in the array can define
a style for `STYLE` overlay markings, by following the format

- `S={CSS}`
- `S#light={CSS}`
- `S#dark={CSS}`

where `S` is the name of the style and `{CSS}` is a Cascading Stylesheets style definition block.
CodeProber will automatically rename the style `S`, so it cannot be used elsewhere.
The styles `S#light` and `S#dark` override the "light mode" and "dark mode" variants of the style,
respectively.

## Troubleshooting

CodeProber should run on any OS on Java 8 and above. However, sometimes things don't work as they should. This section has some known issues and their workarounds.

### CodeProber is running, but I cannot access localhost:8000 in my browser

By default, CodeProber only accepts requests from localhost. When you run CodeProber inside a container (for example WSL or Docker) then requests from your host machine can appear as remote, not local. To solve this you have two options:

1) Use the URL printed to the terminal when you start CodeProber. It contains an authorization key that enables non-local access.
   If connecting to a non-localhost url, please make sure the "?auth=some_key_here" part of the URL printed to the terminal is included.
2) Add the `PERMIT_REMOTE_CONNECTIONS` environment variable mentioned above.

### System.exit/SecurityManager problem

If you run Java version 17+ then you may run into error messages that mention "Failed installing System.exit interceptor".
For many language tools, the main function behaves like this:

1) Parse the incoming document
2) Perform semantic analysis, print results
3) If any errors were detected, call System.exit(1);

To avoid the System.exit call killing the CodeProber process, CodeProber uses `System.setSecurityManager(..)` to intercept all calls to System.exit.
As of Java 17, this feature is disabled by default. You can re-enable it by adding the system property 'java.security.manager=allow'. I.e run CodeProber with:

```bash
java -Djava.security.manager=allow -jar code-prober.jar path/to/your/analyzer-or-compiler.jar [args-to-forward-to-compiler-on-each-request]
```

Alterntiavely, add a `CodeProber_parse` method as mentioned above in the `Compatibility` section.
Here, CodeProber does not use a System.exit interceptor, so this issue will not appear.

For more information about this issue, see https://openjdk.org/jeps/411 and https://bugs.openjdk.org/browse/JDK-8199704.

### My problem isn't listed above

Check the terminal where you started code-prober.jar If no message there helps you, please open an issue in this repository!

## Building - Client

The client is built with TypeScript. Do the following to generate the JavaScript files:

```sh
cd client/ts
npm install
npm run bw
```

Where 'bw' stands for 'build --watch'.
All HTML, JavaScript and CSS files should now be available in the `client/public` directory.

## Build - Server

The server is written in Java and has primarily been developed in Eclipse, and there are `.project` & `.classpath` files in the repository that should let you import the project into your own Eclipse instance.
That said, release builds should be performed on the command line. To build, do the following:

```sh
cd server
./build.sh
```

If your git status is non-clean (any untracked/staged/modified files present), then this will generate a single file: `code-prober-dev.jar`.

If your git status is clean, then this will instead generate two files: `code-prober.jar` and `VERSION`.

`code-prober.jar` is the tool itself.

`VERSION` is a file containing the current git hash. This is used by the client to detect when new versions are available.

If you want to "deploy" a new version, i.e make the tiny "New version available" prompt appear in the corner for everybody using the tool, then you must first commit your changes, make sure `git status` says `working tree clean`, and then build, and commit again.

## I didn't use JastAdd, what now?

It is possible that your AST will just "magically" work with CodeProber. Add `CodeProber_parse` or `CodeProber_root_node` as described above and just try running with it.
CodeProber has a few different styles of ASTs it tries to detect and interact with.

If that doesn't work, the quickest way to get started is to use the [minimal-prober-wrapper example implementation](minimal-probe-wrapper).

If you have a little more time and want to create a richer CodeProber experience then the best thing would be to adapt to one of the AST structures CodeProber expects. [AstNodeApiStyle.java](server/src/codeprober/metaprogramming/AstNodeApiStyle.java) is an enum representing the different options currently supported. CodeProber tries to detect which style is present by experimentally invoking some methods within each style.
For some more examples, you can also look in [TestData.java->Node](server/src-test/codeprober/ast/TestData.java), which shows the non-JastAdd node implementation used for test cases.

CodeProber needs to know a shared supertype of all AST nodes. Any subtype of this supertype is expected to implement the "AST API style" mentioned above. CodeProber tries to automatically detect the common supertype with the following pseudocode:

```
def find_super(type)
  if (type.supertype.package == type.package)
    return find_super(type.supertype)
  else
    return type
```

`find_super` is called with your AST root (returned from `CodeProber_parse` or `CodeProber_root_node`). In other words, it finds the top supertype that belongs to the same package as the AST root.
If your native AST structure uses a hierarchy of packages rather than a single flat package, then this will likely cause problems so you should probably rely on a wrapper type instead.

## Tracing

In the CodeProber settings panel there is a checkbox with the label `Capture traces`.
This allows you to capture information about indirect dependencies of properties.
For this to work, the AST root must have a function `cpr_setTraceReceiver` that looks like this:

```java
public void cpr_setTraceReceiver(java.util.function.Consumer<Object[]> recv) {
  // 'recv' records trace information.
  // You should assign it to a field for later use.
  this.theTraceReceiver = recv;
}

// Later, when something should be added to a trace, call it
// It will be non-null if `Capture traces` is checked.
if (this.theTraceReceiver != null) {
  this.theTraceReceiver.accept(new Object[]{ ... })
}
```

If `recv` is called while CodeProber is evaluating a property, then the information there will be visible in the CodeProber UI, *if* the user has checked `Capture traces`.


### Kinds of trace events

CodeProber will `toString` the first element in the object array to identify the kinds of trace event.
Currently, two types of events are supported, and they match tracing events produced by JastAdd:


#### COMPUTE_BEGIN

Expected structure:
```
["COMPUTE_BEGIN", ASTNode node, String attribute, Object params, Object value]
```
Example invocation to `recv` in `cpr_setTraceReceiver`:
```java
recv.accept(new Object[]{ "COMPUTE_BEGIN", someAstNode, "foo()", null, null })
```

#### COMPUTE_END
Expected structure:
```
["COMPUTE_END", ASTNode node, String attribute, Object params, Object value]
```
Example invocation to `recv` in `cpr_setTraceReceiver`:
```java
recv.accept(new Object[]{ "COMPUTE_END", someAstNode, "foo()", null, "ResultValue" })
```

### Tracing locator issues

Tracing can be tricky to get right. You may get errors in the terminal where you started `code-prober.jar` stating something like:
```
Failed creating locator for AstNode< [..]
```
This happens if one of the AST nodes passed to a trace events aren't attached to the AST anymore. This can happen for example if you mutate the tree through rewrites.
You can try toggling the `flush tree first` checkbox under `Capture traces` on and off. You can also try changing the `cache strategy` values back and forth. Some combination of the two might work.

If changing the settings doesn't work, then you must change which events are reported to CodeProber. Try to avoid setting the `ASTNode` arguments to nodes that get removed from the tree.

## Artifact

If you want to try CodeProber, but don't have an analysis tool of your own, you can try out the playground at https://github.com/Kevlanche/codeprober-playground/.

You can also download the artifact to our Property probe paper, found here: https://doi.org/10.5281/zenodo.7185242.

Both options let you use CodeProber with a Java compiler/analyzer called IntraJ (https://github.com/lu-cs-sde/IntraJ).
