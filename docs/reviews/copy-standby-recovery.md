REVIEW-ID: c8f66c15-698e-4231-a95f-972eddee6ad9
DATE: 2026-09-24
REVIEWER: content-strategist (Claude, cross-model)
ARTIFACT: /Users/amsh/worktrees/tvVNC/worktree/docs/reviews/copy-standby-recovery.md
DESCRIPTOR: none — derived from current rendered Diagnostics and Remote

STRING: standbyIntent
KEYS: standbyIntent
ENGLISH: "Automatic reconnection resumes when this TV reports that it is on. You can use Power on the Remote screen to wake it."
VERDICT: REWORD
REWRITE: "Automatic reconnect resumes once the app sees this TV is on, however it was turned on. To turn it on from here, try Power on the Remote screen."
REASONING: The draft is accurate, but four small changes make it clearer for someone helping a relative. First, the banner directly above says "Automatic reconnect paused". Using "reconnection" here would give the same thing a second name, so the rewrite uses "Automatic reconnect". Second, "reports that it is on" describes how the software works internally. "Once the app sees this TV is on" says the same thing: the pause ends when the app observes that the TV is on. It also keeps the idea that recovery depends on what the app can detect, not on any promise. Third, the old text said reconnecting only resumed if the TV was turned on from this app. That is no longer true, and the draft only implies the correction. "However it was turned on" states it outright. That matters because the relative may well use the TV's own remote. Fourth, the Remote screen shows only a Power icon, not a separate "Turn on" button, and whether Power works depends on the TV. "Try Power" sets a realistic expectation where "use Power" suggests it will always work. "Turn it on" also matches the "Standby" and "turn the TV on" wording elsewhere on the screen better than "wake it". "Remote" matches the navigation drawer's name exactly. The word "resumes" promises only that the app starts trying again, not that every connection will succeed.
RISKS: The Remote screen marks Power with an icon but no text label, so a reader may have to connect the word "Power" to the power symbol. That symbol is widely recognised, so the risk is small. The rewrite is a little longer than the draft, but no length limit was given.
COPY REVIEW COMPLETE: 1 strings (0 approved, 1 reworded)
