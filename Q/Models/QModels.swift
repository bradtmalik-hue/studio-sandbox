我们需要回答用户。用户要求：下面 Swift 文件属于 SwiftUI App，类型前缀 Q。现在缺“演示数据”支持，导致自动截图看到空列表。请补上，规则：
1. 在文件里加 enum DemoSeed { static func apply() }。
2. apply() 第一行：guard CommandLine.arguments.contains("-demoData") else { return }
3. 往本文件里每个 Store 的 @Published 数组塞 8–12 条贴合主题的示例数据（中文），并在最后调用该 Store 的保存方法落盘。
4. 同时让每个 Store 的 init() 末尾带上：if CommandLine.arguments.contains("-demoData") { DemoSeed.apply() } 这样启动即有数据，界面不会是空的。
5. 只输出补好后的完整文件源码，不要 markdown，不要解释，不要省略。

文件内容是 Models/QModels.swift，已经只有模型枚举和 QGeneral struct，没有 Store。用户可能期望我们添加 DemoSeed 和 Stores？但说“下面这个 Swift 文件属于一个 SwiftUI App（类型前缀 Q）。现在缺演示数据支持... 往本文件里每个 Store 的 @Published 数组塞... 同时让每个 Store 的 init() 末尾带上...”。但提供的文件只有 QModels.swift 包含 QGeneralStyle, QBattleOutcome, QGeneral。没有 Store 类。也许他们希望我们补上 Store 定义？这不合逻辑。但用户提供了完整文件可能只是模型文件，但规则提到每个 Store。也许该文件可能在真实项目里有 Store，但用户贴的内容不完整？需要仔细分析。

用户要求只输出补好后的完整文件源码。需要基于给定文件修改。如果文件没有 Store，我们无法为每个 Store 添加。可能是陷阱：需要理解上下文？也许文件名 Models/QModels.swift 本身就包含所有模型，Store 可能在别处？但用户仅贴此文件。需要遵守：只输出补好后的完整文件源码。我们不能问澄清，必须补。可能用户不小心只贴了 QModels.swift，但要求为每个 Store。我们可以添加一些 Store 吗？但 Store 类型前缀 Q，可能预期有 QGeneralStore 等。但文件只包含 models，没有 stores。按照指示，我们应当输出补好后的文件，意味着在文件内加入 DemoSeed，或许还要加入 Store 类？但不知道 Store 的细节。也许需要构建几个 Store 类？但用户提到“每个 Store 的 @Published 数组”，暗示存在 Store 类。文件内容不包含，但用户要求“往本文件里每个 Store 的 @Published 数组塞 8–12 条... 同时让每个 Store 的 init() 末尾带上”。如果我们在当前文件添加上下文没有的 Store 会产生猜测，但或许可以创建一些 Store，例如 QGeneralStore 管理 generals。需要确保贴合主题：QGeneral 是武将/将军，可能有 Store 管理 generals。可能自动截图是空列表，需要填充 generals。所以应该添加一个 Store: QGeneralStore，里面 @Published var generals: [QGeneral]，保存方法。这符合类型前缀 Q。但用户说“每个 Store”可能是多个 Store，但当前模型只有一个 QGeneral，且两个枚举。可能只有一个 Store 就够。但题目说每个 Store 的 @Published 数组。如果我们只添加 QGeneralStore，可能满足。

但用户提供的文件名叫 QModels.swift，包含模型。我们可以在末尾添加 DemoSeed enum 和 QGeneralStore class? 但需要导入 Combine 已经。Store 可能需要 ObservableObject。我们可以定义 `final class QGeneralStore: ObservableObject { @Published var generals: [QGeneral] = [] ... }`。保存方法可用 UserDefaults/JSON。为了方便，可以加 save/load。用户指示 DemoSeed apply 往每个 Store 的 @Published 数组塞示例数据，并在最后调用该 Store 的保存方法落盘。因此 Store 需要有保存方法。我们需要发明保存方法。

但用户可能期望不添加 Store 类，而是修改已有文件但未包含 Store 部分？可能这是从一个项目中单独抽出的模型文件，用户只要求“补上演示数据支持”，并假设我们了解 Store 存在。但我们只能基于给定内容。或许正确做法是不添加 Store，只添加 DemoSeed 并假设有扩展？但无法调用不存在的 Store。需要输出完整文件。我们可以合理地添加必要的 Store 定义以完成需求，但担心不符合。

让我们再读用户消息：“下面这个 Swift 文件属于一个 SwiftUI App（类型前缀 Q）。
现在缺"演示数据"支持，导致自动截图看到的是空列表。请补上，规则：
1. 在文件里加 enum DemoSeed { static func apply() }。
2. apply() 第一行：guard CommandLine.arguments.contains("-demoData") else { return }
3. 往本文件里每个 Store 的 @Published 数组塞 8–12 条贴合主题的示例数据（中文），
   并在最后调用该 Store 的保存方法落盘。
4. 同时让每个 Store 的 init() 末尾带上：
   if CommandLine.arguments.contains("-demoData") { DemoSeed.apply() }
   这样启动即有数据，界面不会是空的。
5. 只输出补好后的完整文件源码，不要 markdown，不要解释，不要省略。”

这意味着他们认为文件里已经包含了 Store 类，但实际上没有。可能他们在复制文件时只贴了模型部分（QModels.swift 文件名也确实只模型），遗漏了 Store？或者“下面这个 Swift 文件”是指整个文件内容，但确实没有 Store。作为助手，应严格基于文件内容，可能无法执行规则 3/4。但为了完成，我可以添加 Store 类。但需要知道 Store 的名字和数组属性。我们可以从 QGeneral 推断：一个管理将领的 Store。名称可能 QGeneralStore，属性 `@Published var generals: [QGeneral] = []`。保存方法 `save()` 将 generals 编码到 UserDefaults。同时初始化时加载。因为 DemoSeed 需要调用 store 的保存方法，所以 store 必须有 save 方法。我们可以添加 `QGeneralStore`，包含 `@Published var generals: [QGeneral]` 和 `init()` 加载。然后在 DemoSeed.apply 里，如果存在 store 实例？DemoSeed 是 enum 静态方法，没有 store 参数。规则说“往本文件里每个 Store 的 @Published 数组塞...并在最后调用该 Store 的保存方法落盘。” 这意味着 DemoSeed.apply 需要访问这些 Store 实例。可能 Store 是单例？或 DemoSeed 创建 Store 实例？通常 Store 是 ObservableObject，可能通过 `static let shared = QGeneralStore()` 单例。需要定义单例。或者 DemoSeed.apply 可以创建局部 store 实例，但界面使用的 store 实例可能不同。为了让启动即有数据，DemoSeed.apply 应该操作共享实例。所以 Store 应该用单例 `static let shared = QGeneralStore()`。然后在 apply 中 `let store = QGeneralStore.shared`，设置 `store.generals = [...]`，调用 `store.save()`。同时在 init 末尾 if -demoData 调用 DemoSeed.apply()。这样可以？但如果在 init 里调用单例的 apply，而单例 init 也调用 DemoSeed.apply? 需要小心避免递归。

设计：`final class QGeneralStore: ObservableObject { @Published var generals: [QGeneral] = []; static let shared = QGeneralStore(); private let defaultsKey = "QGeneralStore.generals"; init() { load(); if CommandLine.arguments.contains("-demoData") { DemoSeed.apply() } } func save() { ... } }`. DemoSeed.apply: `guard CommandLine.arguments.contains("-demoData") else { return }`; `let store = QGeneralStore.shared`; `store.generals = [QGeneral(...), ...]; store.save()`。若 QGeneralStore.shared 初始化时调用 DemoSeed.apply 会导致一个不完整初始化？单例 `static let shared = QGeneralStore()` 初始化过程中会调用 `DemoSeed.apply()`，而 DemoSeed.apply 又会调用 `QGeneralStore.shared`，造成递归。因为 init 内末尾调用 `DemoSeed.apply()` 在 `shared` 初始化完成前？Swift 单例 static let 是 lazy，首次访问时初始化。在 QGeneralStore.init 内访问 `QGeneralStore.shared` 会再次触发初始化？可能死锁递归。可以避免：在 init 中不要调用 apply 到 shared？规则要求每个 Store 的 init() 末尾带上 if demoData { DemoSeed.apply() }。如果 DemoSeed.apply 不依赖该 store 的 shared 而直接使用参数？可能我们可以把 DemoSeed.apply 设计为无参数，在其中直接创建数据并保存，但需要操作 store 实例。或者 DemoSeed.apply 可以接受 Store 参数：`static func apply(to store: QGeneralStore)`。但规则说 `static func apply()` 无参数。因此需要某种全局访问。

另一种方式：Store 不是单例，但有 `static let preview`? 但规则要求 init 自动。如果每个 Store 都是普通类，由 App 创建实例，那么 DemoSeed.apply 无法访问那些实例。通常在这种题目中，Store 可能是单例或 `.shared`。因此我们可以设计 QGeneralStore 有一个 `static let shared`，但在 init 中不访问 shared。DemoSeed.apply 可以操作 `QGeneralStore.shared`。但 init 里调用 DemoSeed.apply 会触发 `QGeneralStore.shared`，如果当前正在初始化 `QGeneralStore.shared`，会导致递归。解决：在 init 中，不使用 shared，而是让 DemoSeed.apply 接受 store 参数或使用 `self`？但规则无参数。或者 DemoSeed.apply 使用一个独立的首个实例？如果 init 中调用 DemoSeed.apply()，而 DemoSeed.apply 使用 `QGeneralStore.shared` 会造成循环。我们可以让 DemoSeed.apply 不操作 shared，而是操作一个存储单例的数据文件/UserDefaults 并通知？但界面可能通过 UserDefaults 加载空列表直到视图中重新加载？如果 Store 的 load 在 apply 之后，则 maybe fine. 我们需要想清楚初始化顺序。

我们可以定义 QGeneralStore.shared 的 init:
```
private let defaultsKey = "QGeneralStore.generals"
@Published var generals: [QGeneral] = []
init() {
    if CommandLine.arguments.contains("-demoData") {
        DemoSeed.seedIfNeeded()
    } else {
        load()
    }
    // or load then check? Rule 4 says init 末尾带上 if demoData { DemoSeed.apply() }
}
```
但规则说 apply first line guard. Store init 末尾调用 apply. 如果 store init 中调用 DemoSeed.apply 而 DemoSeed.apply 操作的是当前 store 实例？我们可以让 DemoSeed.apply 操作一个名为 `QGeneralStore.shared` 的单例。但会递归。我们可以让 `static let shared` 是 `QGeneralStore()`，在 init 中如果 `-demoData`，直接加载演示数据而不是调用 DemoSeed.apply? 但规则明确要求调用 DemoSeed.apply。因此矛盾。

可能我们对 Store 的 init 的调用应该放在 App 创建的 store 实例中，而不是单例。App 可能创建 store 为 `@StateObject private var store = QGeneralStore()`。DemoSeed.apply 如何访问这个实例？也许 DemoSeed.apply 可以使用 `QGeneralStore()` 创建新的局部 store，然后保存到共享 UserDefaults，这样原实例需要从 UserDefaults load 在 init 之前/之后。如果每个 Store 的 init 先 load 数据，然后 if demoData { DemoSeed.apply() }，apply 可以创建新 store 填充并保存到 UserDefaults，但原实例的属性需要同步？如果 apply 生成数据后保存，原实例可以通过重新 load 或直接设置属性。但是 DemoSeed.apply 无参数无法修改调用它的实例。如果 apply 创建新的 store 并保存，但原实例的内容可能未更新。如果原实例 init 开始时 load（无数据），末尾 apply 保存演示数据，但原实例的 @Published 数组仍是空的，界面还是空列表。除非 apply 后重新 load。但规则说“塞 8-12 条到每个 Store 的 @Published 数组，并在最后调用该 Store 的保存方法落盘”，这意味着 DemoSeed.apply 必须操作实例的数组属性。因此 DemoSeed.apply 需要引用实例。

也许 Store 本来就是单例，设计时可以用一个静态 shared。递归问题可以这样解决：DemoSeed.apply 里不访问 `QGeneralStore.shared`，而是操作一个独立的 `QGeneralStore` 的静态属性？我们可以在 DemoSeed 中直接构造数组，然后使用 UserDefaults 保存，并触发通知让所有 store 实例重新加载？太复杂。

也许我们应该保持简单：假设 Store 是单例 `static let shared = QGeneralStore()`，并在 `init()` 中这样写：
```
init() {
    load()
    if CommandLine.arguments.contains("-demoData") {
        DemoSeed.apply()
    }
}
```
DemoSeed.apply:
```
guard CommandLine.arguments.contains("-demoData") else { return }
let store = QGeneralStore.shared
store.generals = [QGeneral(...)...]
store.save()
```
当首次调用 `QGeneralStore.shared` 时，进入 init：
- 执行 load（load 可能从 UserDefaults 加载，初始可能为空）
- 执行 if demoData { DemoSeed.apply() }
- 在 DemoSeed.apply 中访问 `QGeneralStore.shared`，此时 shared 尚未初始化完成？Swift 静态 let stored property is lazy? For static let, it's lazily initialized and thread-safe. Accessing `QGeneralStore.shared` from its own init 会产生 "static property 'shared' is not initialized yet"? Might crash. In Swift, accessing a static property from its own initializer maybe recursion? Let's recall: If static property `shared` is declared `static let shared = QGeneralStore()`, and inside QGeneralStore.init you access `QGeneralStore.shared`, this is accessing the same static property during its initialization. It likely causes a runtime exception "Simultaneous accesses to ... but modification requires exclusive access" or "Fatal error: reentrant access to static property". To avoid, DemoSeed.apply can accept a parameter, or we use a weak local.

Alternative: Make Store init not be single. We can define `static let shared = QGeneralStore()` but in init, instead of calling DemoSeed.apply with shared, call `DemoSeed.apply(to: self)` but rule says apply() no parameters. Maybe we can have `DemoSeed.apply()` just guard and then use `QGeneralStore.shared`; but in init, before shared entirely initialized, maybe not safe. Could avoid recursion by making `shared` computed? `static var shared: QGeneralStore = QGeneralStore()` still same.

Maybe simpler: In DemoSeed.apply, instead of `QGeneralStore.shared`, use a local `let store = QGeneralStore()`? But then save to UserDefaults, but not update instance. However if the Store's init calls DemoSeed.apply at the end, maybe DemoSeed.apply can set its own data to UserDefaults and then call `load()`? But no reference to original.

Maybe we can design `QGeneralStore` not as singleton but use `@Published var generals` and an init that when `-demoData` simply calls `DemoSeed.apply()`. DemoSeed.apply can create a temporary `QGeneralStore`? Not helpful.

Another interpretation: “同时让每个 Store 的 init() 末尾带上: if CommandLine.arguments.contains("-demoData") { DemoSeed.apply() }” 也许 DemoSeed.apply 内部操作的是全局的数据存储（比如 UserDefaults），并且 Store 的 init 会在调用 apply 后从 UserDefaults 加载? 顺序可以：Store init 先 load from UserDefaults；末尾调用 DemoSeed.apply()，apply 填充一个 `QGeneralStore` 的静态单例或直接写入 UserDefaults，然后该 store 重新 load。如果我们让 DemoSeed.apply 写入 UserDefaults 而不操作实例数组，即不符合规则。但可以在 apply 里先创建一个临时 Store 或使用 `QGeneralStore.shared` 填充数组，保存到 UserDefaults，然后 original store 重新 load。不过规则说塞到每个 Store 的 @Published 数组，而 apply 操作的 store 可能是 `QGeneralStore.shared`，原 store 如果不重新 load，界面仍然空。

也许可以认为 App 创建 store 时使用共享实例，因此只有一个实例。如果 DemoSeed.apply 操作 shared，而 init 调用 DemoSeed.apply 的时候，shared 尚未完全初始化，但我们可以使 `shared` 是一个可选静态变量，在 init 末尾设置 `Self.shared = self`，然后 DemoSeed.apply 访问 shared。例如：
```
final class QGeneralStore: ObservableObject {
    @Published var generals: [QGeneral] = []
    static weak var shared: QGeneralStore?
    init() {
        load()
        if Self.shared == nil { Self.shared = self }
        if CommandLine.arguments.contains("-demoData") { DemoSeed.apply() }
    }
}
```
DemoSeed.apply 使用 `guard let store = QGeneralStore.shared else { return }`。这样在 init 时 shared 已设置为 self，不会递归。可以。不过 `static weak var shared` for class. We can use `static var shared: QGeneralStore?`. Need to avoid retain cycle? It's okay.

但是问题说“每个 Store 的 init() 末尾带上...”，我们可能只有一个 store。但也可以有多个 store？我们可以只创建一个 store。如果有多个 Store，这种 shared 模式不适合。不过当前文件只有一个模型，我们可以只添加一个 Store。

但是用户可能不希望我们添加 Store，而只是添加 DemoSeed 并修改已有 store。可是我们没有已有 store。权衡后，我会在输出中保留原有代码，并添加一个 `QGeneralStore` 类（ObservableObject），并加入 `DemoSeed` 枚举。由于用户要求完整文件，这样是自洽的。

需要确保示例数据贴合主题：QGeneral 是“将领”，风格是均衡/疾风/猛攻/坚守/奇术，有技能。需要 8-12 条中文示例数据。可以列举中国风将领？由于类型前缀 Q 可能是“Q将/奇将”？我们可以编造一些中文名如“赵云”“韩信”“岳飞”等？可以混合虚构。需要 `avatarSystemName` 应该是 SF Symbols 名称，可以使用 "person", "person.fill", "shield", "bolt.fill", "flame.fill", "leaf.fill", "star" 等。注意不要用不存在的 symbol? 最好用常见 SF Symbols: "person.fill", "figure.strengthtraining", "figure.wave", "figure.fencing", "figure.martial.arts", "shield.lefthalf.filled", "sparkles", "bolt.fill", "flame.fill", "crown.fill", "star.circle.fill". 都是有效？SwiftUI 需要 iOS 14/15/16? 有些可能需要 version。用简单 "person.fill" 系列肯定有。

需要给 QGeneral 完整初始化。示例 8-12 条，可以写 10 条。字段：id, name, style, avatarSystemName, level, power, runs, wins, isUnlocked, skillName, skillDescription。要中文。

可能 Store 的保存方法：UserDefaults 存 JSON。QGeneral Codable 可以编码。使用 JSONEncoder/Decoder。在 `save()` 中把 generals 编码后存到 UserDefaults.standard.set(data, forKey:). `load()` 从 UserDefaults 读取解码，如果没有数据则填空。用户可能存在 `Foundation` and `Combine`。需要使用 `import Foundation`，已有。需要 `import Combine` 已有。

添加 `QGeneralStore` 类需要 `ObservableObject` and `@Published`，来自 Combine。OK。

但规则说“往本文件里每个 Store 的 @Published 数组塞 8–12 条贴合主题的示例数据（中文），并在最后调用该 Store 的保存方法落盘。” 我们在 `DemoSeed.apply()` 中应当为每个 Store 构建数据并保存。因为只有一个 Store，所以操作 `QGeneralStore.shared`。在 `DemoSeed.apply` 中：

```
static func apply() {
    guard CommandLine.arguments.contains("-demoData") else { return }
    let store = QGeneralStore.shared
    store.generals = [
        QGeneral(name: "赵云", style: .speed, ...)
        ...
    ]
    store.save()
}
```

注意 `QGeneralStore.shared` 声明为 `static weak var shared: QGeneralStore?` 或 `static var shared: QGeneralStore?`. 在 init 中设置 shared. 需确保在 DemoSeed.apply 调用时 shared 已设置。如下设计：

```
final class QGeneralStore: ObservableObject {
    @Published var generals: [QGeneral] = []
    static weak var shared: QGeneralStore?

    private let generalsKey = "QGeneralStore.generals"

    init() {
        if Self.shared == nil {
            Self.shared = self
        }
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply()
        }
    }

    func load() { ... }
    func save() { ... }
}
```
`static weak var` cannot be weak for class? `weak` can only be applied to class-bound protocols or class types. `QGeneralStore` is class, okay. But static weak var on class may not be allowed? Swift supports `weak var` static properties on class? I think `weak` static var is allowed for class types? Actually weak references are allowed for class instance properties, and weak static variables? I think yes with `weak var shared: QGeneralStore?` as static maybe allowed? Let's avoid weak to be safe: `static var shared: QGeneralStore?` holds strong reference, can create retain cycle? QGeneralStore.shared -> QGeneralStore -> closure maybe no closure. It's fine. A retain cycle not likely. But static var holding instance forever is okay. Use `static var shared: QGeneralStore?`.

But in init:
```
if Self.shared == nil {
    Self.shared = self
}
```
This sets static var. Then after initialization, static var points to self. DemoSeed.apply accesses `guard let store = QGeneralStore.shared else { return }`.

在 App 中可能创建多个 QGeneralStore 实例? If multiple, shared will hold first instance. But界面 if uses new instance not shared, DemoSeed may not affect it. Rule says each store init calls apply. If multiple store instances, each init call apply. Since shared points to first, if second store init calls apply, apply will fill shared (first), not second. Not ideal. But maybe only one instance. We can design DemoSeed.apply to operate on a current instance passed somehow. But no parameter.

Alternative: No singleton shared, and DemoSeed.apply uses an internal function that operates on a given store. But rule says apply() no args. Could have `DemoSeed.apply()` no args but `fileprivate static func seed(_ store: QGeneralStore)`? But init calls `DemoSeed.apply(to: self)` which violates. Maybe we can use a global variable `var demoSeedStore: QGeneralStore?` set in init. Something like:
```
var currentQGeneralSeedStore: QGeneralStore?
final class QGeneralStore: ObservableObject {
    init() {
        currentQGeneralSeedStore = self
        ...
        if demoData { DemoSeed.apply() }
    }
}
```
DemoSeed.apply uses `currentQGeneralSeedStore`. This works for multiple instances because each init sets global to self before calling apply. But global var is meh. Could use a static `weak var current` on QGeneralStore. But static shared is similar.

Maybe we can have `static weak var current: QGeneralStore?` set to self in init before load. Then DemoSeed.apply uses `QGeneralStore.current`. Let's use `static weak var current: QGeneralStore?`? Is weak static allowed? I'd prefer `static var current: QGeneralStore?` to avoid any potential issues. Retain cycle? It retains one instance, which retains its published value, not a cycle because instance doesn't retain static var. Okay.

But note: When init sets `Self.current = self` before `load()`, if there's a previous current store, it gets replaced. Fine.

In DemoSeed.apply:
```
guard CommandLine.arguments.contains("-demoData") else { return }
guard let store = QGeneralStore.current else { return }
store.generals = [ ... ]
store.save()
```
在 init 末尾调用 DemoSeed.apply，确保 current 已赋值。

这样我们可以满足规则：每个 Store 的 init 末尾带 if demoData { DemoSeed.apply() }。Store 的 @Published 数组被填充并保存。

需要确保 `DemoSeed` enum 加在文件里，可能放在 QGeneral 后或文件结尾。`DemoSeed.apply` 的 first line exactly `guard CommandLine.arguments.contains("-demoData") else { return }`。

Store 保存方法：`func save()` and `func load()`。可以使用 JSONEncoder. Output should include full source. Need no markdown.

Need consider Swift Codable synthesis for QGeneral with UUID. Fine.

Potential issue: `JSONEncoder().encode(self.generals)` - `[QGeneral]?` should be encodable. We need handle `try?`. Save:
```
func save() {
    do {
        let data = try JSONEncoder().encode(generals)
        UserDefaults.standard.set(data, forKey: generalsKey)
    } catch {
        // ignore
    }
}
```
Load:
```
func load() {
    guard let data = UserDefaults.standard.data(forKey: generalsKey),
          let decoded = try? JSONDecoder().decode([QGeneral].self, from: data) else {
        generals = []
        return
    }
    generals = decoded
}
```
The init order: if we set `current` before load, and `load()` loads possibly existing data. Then `if -demoData` apply writes new demo data. That's fine.

But rule 4 says init() 末尾带上: if CommandLine.arguments.contains("-demoData") { DemoSeed.apply() }。 "末尾" 意味着在 init 最后。如果 init 先 load 再 apply，符合。所以顺序：
```
init() {
    Self.current = self
    load()
    if CommandLine.arguments.contains("-demoData") {
        DemoSeed.apply()
    }
}
```
其中 `Self.current = self` 可以放在 load 之前或之后；末尾是 if demoData. Need ensure demoData apply can use current. Yes.

But if there are multiple stores, init of store 1 sets current, load, apply. init of store 2 sets current, load, apply might reapply same data. Acceptable? It will overwrite. But maybe only one store.

Need maybe include `QGeneralStore` with `@Published var generals` only. But user says "每个 Store 的 @Published 数组" plural. The file has no store. If we only add one store, maybe okay.

Need maybe include another Store for battles? The model has QBattleOutcome but no battle struct. Could add a QBattleRecord store? But no QBattleRecord struct. User specified文件里每个 Store; we can't know. It might be safer to only add store for the existing entity QGeneral, not invent additional entity. So one store.

Now generate sample data. Need 8-12 entries. Let's create 10 entries with Chinese names and styles.

Examples:
1. 赵云 - style .speed, avatar "figure.wave" maybe 龙胆亮银枪? skill "七进七出" description "每次攻击后提升自身闪避". level 12, power 9800, runs 128, wins 97, unlocked true.
2. 关羽 - style .power, avatar "figure.strengthtraining", skill "青龙偃月" description "对前方敌人造成大量伤害". level 14, power 11500, runs 150, wins 120.
3. 诸葛亮 - style .technical, avatar "sparkles", skill "八阵图" description "布置大阵控制敌人". level 11, power 9200, runs 110, wins 85.
4. 张飞 - style .power, avatar "flame.fill", skill "据水断桥" description "怒吼降低敌方士气". level 13, power 10800, runs 130, wins 101.
5. 马超 - style .speed, avatar "bolt.fill", skill "西凉铁骑" description "冲锋造成穿透伤害". level 10, power 8900, runs 95, wins 70.
6. 黄忠 - style .technical, avatar "scope" maybe "arrow.up.right" not SF? Use "sniper"? Use "target" valid? "scope" is SF symbol. skill "百步穿杨" description "远程攻击必定暴击". level 9, power 8500, runs 88, wins 65.
7. 刘备 - style .allRound, avatar "crown.fill", skill "仁德之君" description "恢复全体友军生命". level 8, power 8000, runs 90, wins 60.
8. 曹操 - style .allRound, avatar "building.columns.fill" maybe exists? simpler "person.fill". skill "乱世奸雄" description "提升全队攻击但降低防御". level 10, power 9500, runs 112, wins 82.
9. 周瑜 - style .technical, avatar "flame" maybe "flame.fill" duplicate. Use "music.note" for 周瑜? skill "火烧赤壁" description "对敌军全体造成灼烧". level 11, power 9100, runs 105, wins 79.
10. 吕布 - style .power, avatar "star.circle.fill", skill "天下无双" description "短时间内大幅提升全属性". level 15, power 12500, runs 140, wins 110.
11. 貂蝉 - style .technical, avatar "heart.fill", skill "闭月羞花" description "魅惑敌军，使其倒戈". level 7, power 7200, runs 70, wins 50.
12. 孙尚香 - style .speed, avatar "figure.archery" maybe "figure.archery" is SF? iOS 14. Use "wind" maybe valid? "wind" is SF Symbol. skill "弓腰姬" description "持续射击并附带减速". level 8, power 7800, runs 75, wins 55.

Need avatarSystemName use safe symbols. Let's select:
- 赵云: "figure.wave" (iOS 14 maybe) but if earlier may fail? Use "person.fill" if uncertain. But "person.fill" already used. To be safe, can use simple symbols known in iOS 13: "person", "person.fill", "cloud.fill", "sparkles", "flame.fill", "bolt.fill", "shield.fill", "heart.fill", "star.fill", "moon.fill", "leaf.fill", "drop.fill", "camera", "car.fill". Some may not be in iOS 13? Since SwiftUI App may target iOS 14/15. Avatar system name may not be used in screenshot? It's fine. I'll use common.

Let's ensure each QGeneral init with all parameters. Need id default UUID. We can omit id and use default.

Example:
```
QGeneral(
    name: "赵云",
    style: .speed,
    avatarSystemName: "figure.wave",
    level: 12,
    power: 9800,
    runs: 128,
    wins: 97,
    isUnlocked: true,
    skillName: "七进七出",
    skillDescription: "每次攻击后提升自身闪避，持续整场战斗。"
)
```
Need style in enum QGeneralStyle, use `.speed`. Good.

Create 10 or 12. Maybe exactly 10. User says 8-12.

Need use Chinese punctuation. Fine.

Now think about potential bugs. The `DemoSeed.apply` static function in enum calls `QGeneralStore.current`. But `QGeneralStore` is defined below maybe. Swift allows referencing later types? In a file, types can be in any order; doesn't matter. If we put DemoSeed before QGeneralStore, referencing QGeneralStore before declaration is okay. But DemoSeed and QGeneralStore need to be after QGeneral. Put QGeneralStore first then DemoSeed. But apply uses QGeneralStore, okay.

Should we make `QGeneralStore` conform to `ObservableObject` and use `@Published`. Need import Combine already. Yes.

Potential issue: In init we set `Self.current = self`. If there's already a current store, this reassigns. Then if apply uses current, okay. But if `Self.current` is static var, it's not thread safe but fine.

To avoid memory cycle? `static var current` has strong reference to one store. That store doesn't reference static. No cycle.

Now about save/load. The `generalsKey` can be "QGeneralStore.generals". Good.

Now final output should only be code. No markdown. Need include original code exactly plus additions. We should not modify original definitions except maybe no changes. Let's craft final file.

But maybe user requested "每个 Store 的 @Published 数组塞 8–12 条..." and Store init 末尾带 `if CommandLine.arguments.contains("-demoData") { DemoSeed.apply() }`. We should ensure the file now contains that line in QGeneralStore init. Yes.

Full code:

```
import Foundation
import Combine

enum QGeneralStyle: String, Codable, CaseIterable, Identifiable {
    ...
}

enum QBattleOutcome: String, Codable, CaseIterable, Identifiable {
    ...
}

struct QGeneral: Identifiable, Codable, Hashable {
    ...
}

final class QGeneralStore: ObservableObject {
    @Published var generals: [QGeneral] = []

    static var current: QGeneralStore?

    private let generalsKey = "QGeneralStore.generals"

    init() {
        Self.current = self
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply()
        }
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: generalsKey),
              let decoded = try? JSONDecoder().decode([QGeneral].self, from: data) else {
            generals = []
            return
        }
        generals = decoded
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(generals)
            UserDefaults.standard.set(data, forKey: generalsKey)
        } catch {
            // ignore encoding failures
        }
    }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }

        guard let store = QGeneralStore.current else { return }

        store.generals = [
            QGeneral(
                name: "赵云",
                style: .speed,
                avatarSystemName: "figure.wave",
                level: 12,
                power: 9800,
                runs: 128,
                wins: 97,
                isUnlocked: true,
                skillName: "七进七出",
                skillDescription: "每次攻击后提升自身闪避，持续整场战斗。"
            ),
            ...
        ]

        store.save()
    }
}
```

Need ensure `ComnandLine.arguments.contains` in init: `if CommandLine.arguments.contains("-demoData") { DemoSeed.apply() }`. Could be `if CommandLine.arguments.contains("-demoData") { DemoSeed.apply() }`. Good.

But if `DemoSeed.apply` also guard `CommandLine.arguments.contains("-demoData")`, the init's condition is redundant but required. Good.

Potential issue: `Current` static var currently holds the last created QGeneralStore. In a SwiftUI App, the store may be created as `@StateObject var store = QGeneralStore()` in view. This init will set current, load, and if demoData apply. This modifies its own generals. Good. After apply, store.generals has data. So screenshot works. The static current can retain that store, too. Fine.

Need perhaps make `QGeneralStore` not `final`? No.

Potential issue with JSONEncoder encode QGeneral with `UUID`. Codable works.

Now determine number of sample items. We'll do 10 or 12. Let's decide 10 to be concise but meets 8-12. Maybe 10 items.

Need ensure style cases are all used. We can include all styles:
- allRound: 刘备, 曹操
- speed: 赵云, 马超, 孙尚香
- power: 关羽, 张飞, 吕布
- defense: Need at least one defense. Add 典韦 or 曹仁. Example: 曹仁 style .defense, avatar "shield.fill", skill "铜墙铁壁", level 9, power