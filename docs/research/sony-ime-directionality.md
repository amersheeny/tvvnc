# Sony IME correction — observed 2026-09-22

Device: Sony KD-55AF8, Android TV Remote Service 7.00.956317615.
Actual payload-free trace: input identity 115, content version 88; incoming
tag 21 contained 1/1; two outgoing edits incorrectly used 1/1 and were ignored.

The exact service APK was inspected outside the repositories, not installed
or incorporated into the application. Package/version match the television.
Its signer is Google `atv_remote_service`, SHA-256
`456edbc33222d20ff158d42e9fab0252dbe0514d6e1c39588d6b1982cc189137`.

Protocol facts confirmed from the service's receiver and sender:

- Server tag 20 supplies input identity in AppInfo field 1 and the initial
  content version in TextFieldStatus field 1.
- Server tag 21 is keyboard visibility (boolean field 1, flags field 2).
  It is NOT a counter acknowledgement. Public schemas reuse a bidirectional
  message name incorrectly for this direction.
- Server tag 22 supplies updated text/content version, with a self-edit flag.
- Client tag 21 carries input identity, content version, and repeated edits.
  The service rejects an input-identity mismatch and, when acquiring editing
  ownership, a content-version mismatch.
- Replacement is edit field 2, containing UTF-16 start/end and replacement
  text. The service sets the composing region then commits that replacement.
  There is no tag-1 integer "insert" operation in this oneof; tag 1 is instead
  a selection message. The unused integer is no longer emitted.
- The service changes content versions after edits; those are not new field
  identities. A changed input identity still invalidates old field revisions.

Read-only analysis evidence:
/Users/amsh/worktrees/tvVNC/remote-service-analysis/sources/defpackage/bsi.java
(edit receiver), bsj.java (state sender), bzr.java/bzu.java/bzy.java/bzz.java
(field mappings), bsg.java (InputConnection operations).
The download is from the matching APKMirror release, with the verified signer
also matching the independently listed APKPure signer SHA-1.

No TV text, passwords, keys or pairing material are in the diagnostic report.
Actual on-phone typing/backspace proof remains required after installation.
