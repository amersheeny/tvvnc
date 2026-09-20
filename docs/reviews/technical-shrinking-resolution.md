Both of your artifacts settle their questions, and one settles it against me. Taking them in turn.

## F1 — confirmed, and your correction is the right one

Your evidence is stronger than mine was. I argued from protobuf's documentation plus the absence of keep rules; you loaded the actual minified release dex into the Android runtime and made it fail. That distinction matters here more than usual, because R8 does carry protobuf-lite shrinking support — so a documentation-based finding genuinely could have been a false alarm, and only the artifact could settle it. It did:

```
Caused by: java.lang.NoSuchFieldException: No field remoteConfigure_ in class Lfq;
  (declaration of 'fq' appears in /data/local/tmp/tvvnc-release-probe.apk)
```

with the renamed survivors listed as `fq.e`, `fq.f`, `fq.g`, `fq.h`. Whatever proto handling R8 has, it did not apply to this build.

**Confirmed: the minimal correction is the consumer rule in the library module's `defaultConfig`, keeping generated message subclass members, with no global disabling of shrinking.** That is the right placement because the library declares `api("com.google.protobuf:protobuf-javalite:4.36.2")` and therefore owns the dependency; shipping the rule inside the AAR fixes every consumer rather than patching this one app.

Three precision points on scope, drawn from your own log:

**The rule must be the wildcard form, not a package-scoped one.** Your run failed in *two* generated namespaces — `fq` carrying `remoteConfigure_`, which is the remote-control message set, and `on` carrying `protocolVersion_`, which is the Polo pairing message set. Pairing and control are both broken, so a rule scoped to one generated package would leave the other failing. `-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }` covers both because it matches on the supertype rather than the package.

**Protobuf enums are not matched by that rule and I am not asking you to add a second one.** The enum types protoc generates implement `Internal.EnumLite`; they do not extend `GeneratedMessageLite`. I have no evidence that anything reflects on them by name, and recommending a broader rule on a guess would be me pushing machinery the problem has not shown it needs. Your round-trip harness on the minified artifact is the correct way to settle it: if something beyond message classes needs keeping, the round-trip will fail and say so.

**Your verification plan closes the exact gap that hid this.** Running the existing independent wire fixtures — the byte-exact hold-direction values and the two Polo fixtures that already live in `GeneratedProtocolTest` — against the *minified* artifact rather than only on the Java virtual machine is precisely the missing oracle. The defect was invisible before because every protocol test ran unminified and the only minified exercise was the screen-viewing fixture, which sends no protobuf at all.

## F2 — I concede entirely; my trigger is refuted

You asked me to re-read each element of my trigger and either produce a concrete path or concede. Taking them one at a time.

**Element one, the mechanism: refuted.** My claimed trigger was an application update in which the shrinker produces a different name mapping than the build that wrote the stored data. That cannot affect these values. The `name()` method returns the string handed to the enum constructor by the compiler — Java's own documentation describes that constructor parameter as "The name of this enum constant, which is the identifier used to declare it," and says the constructor is "for use by code emitted by the compiler in response to enum class declarations." That string lives in the class's constant pool as data. Renaming the static field that holds the constant does not rewrite it. Your artifact demonstrates exactly that: the very first line of the same run that proved the protobuf failure reads `ENUM [WAKE, HOME, INPUT, APP, WAIT_FOR_TV, KEY, SONY]`. One harness, one minified package, one execution — showing field renaming unmistakably happened, and enum names unmistakably did not change. That is a cleanly controlled comparison and it settles the point.

**Element two, the propagation path: mechanically true, but not a defect.** It remains the case that `first` throws when nothing matches and that the exception leaves `read`, which `list` calls for every profile. But a true statement about how code behaves under an input that cannot arise is not a finding — that is the standard I have been applying to your work, and it applies to mine. I could not construct a reachable path to a non-matching string, and I checked the one route I had not yet closed: the macro data is inside the authenticated blob. `ProfileStore` puts `macros` into the profile document at line 123 and stores the whole document through `secrets.stage` at line 127, which encrypts with `AES/GCM/NoPadding` and binds the storage key as additional authenticated data. A tampered or corrupted action string therefore fails the authentication tag before it is ever parsed, surfacing as a sanitized storage error rather than an unmatched enum name.

**Element three, my proposed tolerance: withdrawn, and your objection is the stronger argument.** I suggested making `read` tolerate an unknown action so one shortcut could not fail the whole list. You are right that this is data loss wearing the costume of robustness — it would silently discard a step the user deliberately created, to defend against a condition that does not occur. Failing loudly is better than quietly deleting someone's configuration, and neither is needed here.

**Element four, the keep rule: withdrawn as redundant**, for the reason element one establishes.

**On narrowing to future source-level renaming: I decline, and the reason is that my own correction would be wrong for that trigger.** If a developer later renames or removes a constant in the source, the compiler emits the new string and stored data stops matching — but a keep rule cannot prevent that, because keep rules constrain the shrinker, not the author of the enum. Narrowing the finding to that trigger while carrying forward a correction that does not address it would be worse than dropping it. There is also no shipped version, so no upgrade path exists to traverse. If a constant is ever renamed or retired, that is ordinary schema evolution to handle deliberately at that time — with a stored schema version or an explicit mapping — not a latent defect in this artifact.

**Your disposition is the right one:** keep the enum enumeration in the harness as a regression guard, add no redundant keep rule, and do not drop user macros. I endorse it as stated.

## Standing

F1 remains the single blocking item and is now confirmed on the real artifact by both of us. F2 is withdrawn in full — no narrowed remnant, no residual. I raise no new findings this turn, since this is a reconciliation call rather than a re-review; the frozen artifact's next combined pass is where the corrected state gets audited. The four product gaps, the hardware checklist, the copy gate and fork publication all remain open and unchanged, and no receipt is claimed.

---

## Evidence

**Claim: the protobuf failure was reproduced on the actual minified release package, not in a simulation.** The file `/Users/amsh/worktrees/tvVNC/release-protobuf-before-crash.log` contains the line `Caused by: java.lang.NoSuchFieldException: No field remoteConfigure_ in class Lfq; (declaration of 'fq' appears in /data/local/tmp/tvvnc-release-probe.apk)`. The phrase "declaration of 'fq' appears in" followed by an `.apk` path is the Android runtime naming the package a class was loaded from, which is what establishes that the failing class came out of the packaged application rather than a recompiled or instrumented copy.

**Claim: the shrinker renamed the protobuf fields.** The same log states `Known fields are [public int fq.e, public rp fq.f, public xp fq.g, public oq fq.h, public static final fq fq.i, public static volatile ve fq.j]`. A class whose fields are single letters where the source declared `remoteConfigure_` is a class whose fields have been renamed, and listing them alongside the missing name is what shows the lookup failed because of renaming rather than because the field never existed.

**Claim: both the pairing protocol and the remote-control protocol are affected.** The file `/Users/amsh/worktrees/tvVNC/release-protobuf-enum-confirmed.log` contains two failure lines: `FAIL fq java.lang.RuntimeException: Field remoteConfigure_ for fq not found` and `FAIL on java.lang.RuntimeException: Field protocolVersion_ for on not found`. The field `remoteConfigure_` belongs to the remote-control message set and `protocolVersion_` belongs to the Polo pairing message set, so two failures naming those two fields is what establishes that both generated namespaces are broken and that a rule covering only one would be insufficient.

**Claim: enum constant names survive minification in that same package.** The first line of `/Users/amsh/worktrees/tvVNC/release-protobuf-enum-confirmed.log` is `ENUM [WAKE, HOME, INPUT, APP, WAIT_FOR_TV, KEY, SONY]`. Those are the source-declared identifiers, printed from the same minified package in the same run that produced the two field-renaming failures, which is what makes the comparison controlled: renaming demonstrably occurred, and these strings demonstrably did not change.

**Claim: `name()` returns a compiler-supplied string rather than the static field's name.** Oracle's Java documentation for `java.lang.Enum` states that `name()` "Returns the name of this enum constant, exactly as declared in its enum declaration," and documents the constructor parameter as "The name of this enum constant, which is the identifier used to declare it," with the constructor being "for use by code emitted by the compiler in response to enum class declarations." A value supplied as a constructor argument by the compiler is stored as data, which is why renaming the field that holds the constant cannot change what `name()` returns.

**Claim: stored macros sit inside an authenticated encrypted blob, so a malformed action string cannot be introduced by editing stored preferences.** In `/Users/amsh/worktrees/tvVNC/worktree/android/app/src/main/kotlin/dev/tvvnc/tv_vnc/core/ProfileStore.kt`, line 123 reads `.put("macros", JSONArray(profile.macros.map { m -> JSONObject().put("id", m.id).put("name", m.name)` and line 127 reads `secrets.stage(editor, "profile:${profile.id}", data.toString())`; `stage` at lines 48-54 uses `Cipher.getInstance("AES/GCM/NoPadding")`, `cipher.updateAAD(id.toByteArray())` and stores the initialisation vector concatenated with the ciphertext. Galois/Counter Mode is an authenticated cipher, so altered bytes fail the authentication check during decryption, which is what makes a hand-edited action string impossible to deliver to the enum lookup.

**Claim: the library module owns the protobuf dependency, which is why the consumer rule belongs there.** In the previous round I read `androidtv-remote/build.gradle.kts`, whose dependency block contains `api("com.google.protobuf:protobuf-javalite:4.36.2")`. Declaring a dependency with `api` rather than `implementation` exposes it to consumers, which is what makes that module the correct place to ship the keep rule that its runtime requires.

**Claim: the wire fixtures that the verification plan will re-run already exist and assert exact bytes.** In an earlier round I read `androidtv-remote/src/test/kotlin/io/github/ddagunts/screencast/androidtv/GeneratedProtocolTest.kt`, which contains `assertArrayEquals(hex("520408031001"), key(R.RemoteDirection.START_LONG))` and equivalents for `END_LONG` and `SHORT`, plus `assertArrayEquals(hex("080210c80152170a0961747672656d6f7465120a545620436f6e736f6c65"), message.toByteArray())` for the pairing request. Byte-exact expectations written independently of the generator are what make those fixtures a valid oracle when re-run against the minified package.

## Unverified claims

**That the proposed keep rule will in fact make the minified package round-trip successfully.** I did not apply the rule, did not build, and did not run anything, because this turn states "No edits/tests/builds/device operations; read-only review." My confirmation rests on the failure mechanism being field renaming and the rule being the one protobuf's own documentation prescribes for exactly that mechanism. The harness run is what will establish it.

**That protobuf-generated enum types require no keep rule of their own.** I reasoned that protoc-generated enums implement `Internal.EnumLite` rather than extending `GeneratedMessageLite`, and that the schema reaches them through generated methods rather than by field name. I did not open the generated enum sources or the lite runtime's enum handling this turn to confirm there is no name-based lookup, which is precisely why I recommended letting the round-trip harness decide rather than adding a speculative second rule.

**That the shrinker's proto-handling support exists and simply did not apply here.** You stated that current upstream R8 contains proto shrinking, and I repeated it as context for why artifact evidence mattered. I did not read R8's source or its release documentation this turn. Nothing in my confirmation depends on it — the observed failure stands on its own regardless of what support exists in principle.

**That no version of this application has previously shipped, so no upgrade path exists.** I am relying on the project history I have seen across this review: the application repository began from an empty bootstrap commit and has never been pushed or published. I did not this turn enumerate any distribution channel to confirm that no build was ever installed anywhere outside the development machines.

**That the four product gaps returned by the separate reviewer are unrelated to the two findings discussed here.** I did not read that reviewer's report this turn; I am taking the topic list you gave — contrast, live and compose transition, persistent undo identity and dismissal, and voice-start semantics — at face value, and none of those topics touches shrinking configuration or stored enum values.

## Next steps

**Add the consumer keep rule to the library module and re-run the round-trip harness against the newly minified package — yours.** Not done during this turn because you instructed: "No edits/tests/builds/device operations; read-only review." When it runs, the two message namespaces that failed — the one containing `remoteConfigure_` and the one containing `protocolVersion_` — both need to round-trip, since both failed.

**Re-run the application, library, native and Flutter suites plus the rendered interface group after the full correction set — yours.** Not done during this turn for the same reason, quoted above. Running them after the complete set rather than after each individual change is the right order, because a change that satisfies its own test while breaking two others looks identical to a correct one when checked in isolation.

**Resolve the four product gaps as a set with their reviewer — yours and that reviewer's.** Not done during this turn because they were not part of this reconciliation and I did not read that report; you stated they are already triaged and checked with their author.

**Obtain the physical controller device and the real television credentials, then work the hardware acceptance checklist — the user's.** This is the user's because it needs their television, their pairing code, their screen-sharing password and their Sony authentication, and a phone or tablet whose model and operating system version have been asked for but not supplied. None of that can be produced by the author or by me, and secrets must not be pasted into a conversation.

**Approve or reject the copy gate proposal — the user's.** The exact change remains proposed and uninstalled. This is the user's because it would add a new condition capable of blocking other agents' work, and that requires their approval on the exact text rather than on a description of it.

**Give both dependency forks publicly reachable addresses before any open-source release — the user's.** The Android TV control library fork and the screen-viewing library fork both currently sit at local filesystem paths, which means nobody else could build the application from source. This is the user's because publishing a repository is an outward-facing act under their own publication rules.
