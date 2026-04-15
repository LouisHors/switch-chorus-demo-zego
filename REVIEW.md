# Review Instructions

Focus on high-signal review findings for this repository:

- Treat this as an iOS UIKit app with real-time chorus / media playback behavior.
- Prioritize bugs, regressions, race conditions, state machine mistakes, and missing tests.
- Be skeptical of changes touching `ChorusSEISync`, `TeamChorusViewController`, player state, mute logic, or Zego SDK calls.
- Flag API guesses against the Zego SDK. New calls should be verified against headers instead of inferred.
- Ignore cosmetic issues unless they hide a behavioral problem.
- When no issue is found, say so briefly and mention any validation gaps.
