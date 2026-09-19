# TestFlight 111 Sentry triage — 2026-09-19

## Scope

Release `com.opencapture.openpocketcine@0.1.0+111`, environment `testflight`,
14-day query refreshed during the September 19 review (through 17:08 UTC). This is the latest release
observed in Sentry; App Store Connect availability is not independently verified.
Source revision: `3a3f858`. Issue counts below are release-filtered event counts,
not the lifetime totals shown on issue groups. All event pages were read; 61
typed incident attachments were sampled across camera family and outcome. Raw
events and attachments remain in ignored local storage.

The snapshot contains 786 feed incidents, nine native crashes/termination
reports, nine native hang reports and 567 informational session summaries.
There are no warning-level issues or separate Sentry logs for this release.
These counts describe opted-in reports, not unique operators or confirmed
independent failures. Recovery outcomes are 461 recovered, 158 interrupted,
151 suppressed and 16 exhausted.

## Coverage

All issue IDs below have the prefix `OPENPOCKETCINE-IOS-`.

| Issue | Events in 111 | Reported family | Disposition |
| --- | --- | --- | --- |
| [W](https://opencapture.sentry.io/issues/147424400/) | 567 | Session summaries | Informational exposure data |
| [N](https://opencapture.sentry.io/issues/147317662/) | 219 | unexpectedDisconnect / packet / none | Trace reviewed; initiating fault not reproduced |
| [Q](https://opencapture.sentry.io/issues/147400866/) | 80 | decoderError / decodedOutput / nativeDecoder | Trace reviewed; initiating fault not reproduced |
| [M](https://opencapture.sentry.io/issues/147315395/) | 67 | transportStall / decodedOutput / none | Trace reviewed; initiating fault not reproduced |
| [P](https://opencapture.sentry.io/issues/147317671/) | 71 | unexpectedDisconnect / assistOutput / none | Trace reviewed; initiating fault not reproduced |
| [G](https://opencapture.sentry.io/issues/147195916/) | 66 | unexpectedDisconnect / assistOutput / nativeDecoder | Trace reviewed; initiating fault not reproduced |
| [E](https://opencapture.sentry.io/issues/147186544/) | 95 | freshInputStaleOutput / decodedOutput / none | Trace reviewed; initiating fault not reproduced |
| [F](https://opencapture.sentry.io/issues/147195912/) | 136 | transportStall / assistOutput / none | Trace reviewed; initiating fault not reproduced |
| [R](https://opencapture.sentry.io/issues/147404310/) | 17 | decoderError / assistOutput / nativeDecoder | Trace reviewed; initiating fault not reproduced |
| [1F](https://opencapture.sentry.io/issues/148059969/) | 1 | presentStalled / assistOutput / none | Trace reviewed; initiating fault not reproduced |
| [T](https://opencapture.sentry.io/issues/147419172/) | 2 | freshInputStaleOutput / decodeAccept / none | Trace reviewed; initiating fault not reproduced |
| [V](https://opencapture.sentry.io/issues/147419191/) | 2 | App Hang Fully Blocked | Main-thread native model preparation reproduced at rendering boundary |
| [1C](https://opencapture.sentry.io/issues/148006668/) | 3 | freshInputStaleOutput / assistOutput / nativeDecoder | Trace reviewed; initiating fault not reproduced |
| [1D](https://opencapture.sentry.io/issues/148042590/) | 2 | SIGABRT | Keyboard-layout AttributeGraph abort; iPadOS reproduction needed |
| [1E](https://opencapture.sentry.io/issues/148042702/) | 1 | SIGABRT | Same keyboard-layout stack as 1D |
| [16](https://opencapture.sentry.io/issues/147632945/) | 3 | decoderError / decodeAccept / nativeDecoder | Trace reviewed; initiating fault not reproduced |
| [K](https://opencapture.sentry.io/issues/147315390/) | 10 | presentStalled / presentation / none | Trace reviewed; initiating fault not reproduced |
| [1B](https://opencapture.sentry.io/issues/148006266/) | 1 | App Hang Fully Blocked | Data-release hang: symbols and reproduction needed |
| [19](https://opencapture.sentry.io/issues/147796349/) | 4 | unexpectedDisconnect / presentation / none | Trace reviewed; initiating fault not reproduced |
| [11](https://opencapture.sentry.io/issues/147606503/) | 1 | assistStalled / assistOutput / nativeDecoder | Inactive-assist classification regression reproduced; live outage still separate |
| [2](https://opencapture.sentry.io/issues/147029799/) | 1 | WatchdogTermination | SDK-inferred prior termination; no stack identifying a cause |
| [10](https://opencapture.sentry.io/issues/147589961/) | 5 | App Hang Non Fully Blocked | Off-main cache snapshot and storage scan implemented; physical attribution pending |
| [Y](https://opencapture.sentry.io/issues/147548771/) | 3 | EXC_BREAKPOINT | Two app traps plus one Core Location trap: symbols and reproduction needed |
| [17](https://opencapture.sentry.io/issues/147696754/) | 1 | unexpectedDisconnect / packet / nativeDecoder | Trace reviewed; initiating fault not reproduced |
| [Z](https://opencapture.sentry.io/issues/147574572/) | 2 | NSInvalidArgumentException | Nonnumeric playback-seek regression reproduced |
| [J](https://opencapture.sentry.io/issues/147302199/) | 7 | freshInputStaleOutput / assistOutput / none | Trace reviewed; initiating fault not reproduced |
| [12](https://opencapture.sentry.io/issues/147608154/) | 2 | transportStall / assistOutput / nativeDecoder | Trace reviewed; initiating fault not reproduced |
| [14](https://opencapture.sentry.io/issues/147623998/) | 1 | assistStalled / decodedOutput / nativeDecoder | Inactive-assist classification regression reproduced; live outage still separate |
| [13](https://opencapture.sentry.io/issues/147619356/) | 1 | App Hang Fully Blocked | Main-thread recursive deletion reproduced and moved to utility task |

## Highest-priority remaining live reproduction

A final refresh added one Pocket 4 Pro event to E. Its attachment shows roughly
24–26 complete AUs/s and 40 ACKs/s for 28 seconds, with no native submissions or
output. The new native decoder retained an IRAP-wait state without decodable
references; an enable request was blocked as `decoderNotReady`, and the watchdog
stayed idle. This narrows the next reproduction to assist activation / native
decoder handoff and shell repair-readiness gates. The attachment does not capture
all those gates, so it does not establish which gate remained closed. Changing
watchdog thresholds or sending extra enables from this evidence would be speculative.

## Symbol and reproduction limits

Seventeen native events report the missing app dSYM UUID
`3661BEC8-DC2B-35ED-BD21-C44019BAEEAD`. The remaining native event is a
stackless SDK-inferred watchdog termination. Matching symbols were not found in
local archives, the Spotlight dSYM index or Sentry’s project debug-file store. Both available App Store Connect
browser sessions require sign-in. A new build cannot replace these historical
symbols; retrieve the original Xcode Cloud build 111 artifact.

No physical iPhone/iPad is currently available to this checkout. The iPad
keyboard abort occurs in an OS version absent from the installed simulators.
No claim is made that the app traps, Core Location trap, Data-release hang,
watchdog termination or live-camera outages have been fixed. Sentry issue
statuses remain unchanged.

## Changes and evidence

- Playback: a production-path regression reproduced seeks with invalid/indefinite
  positions. Readiness, item identity and numeric-time guards now prevent them;
  a ready parked clip still performs its first-frame seek. The unresolved app
  frames mean this is a supported mechanism for Z, not definitive attribution
  of both historical events.
- Rendering: an injected slow encode/model-preparation boundary reproduced a
  blocked main actor. Preparation now uses the serial drawable worker. One
  in-flight reservation spans preparation/GPU completion; invalidation and resize
  during preparation reject the old frame and allow the replacement to present.
- Media: recursive deletion was reproduced on MainActor. A retired directory is
  removed off-main while new downloads use the live directory. Catalog and color
  metadata survive; failed prepared-tree removal stays counted and retryable. Unfinished metadata
  preservation is protected from deletion sweeps, including after failed rollback. View rows use
  asynchronous cache snapshots, and size scans reject obsolete camera/revision
  results. These remove concrete filesystem work observed in the hang families;
  missing app symbols prevent exact attribution of every sampled stack.
- Diagnostics: compressed-layer feeds no longer classify retired assist clocks as
  active stalls. Independent review also reproduced a continuing active assist
  stall being recorded as recovered; recovery now requires that failure to clear.
  This changes accounting and does not establish a fix for real feed freezes.
- The pre-existing iOS empty-capability shutter test was updated to the fallback
  ladder already introduced on main by #357. Production shutter behavior is unchanged.

## Verification

- `just check`: passed, including 995 core tests and repository hygiene/docs checks.
- `just native-check`: passed, including 675 iOS tests (one skipped), relay tests,
  and iOS/Watch simulator builds.
- `just handbook-build`: passed (21 pages).
- Strict Swift formatting lint on changed files and `git diff --check`: passed.
- Independent read-only review found and verified fixes for recovery accounting,
  valid playback seeks, invalidation during encode, stale cache results,
  deletion retries and protecting unfinished metadata preservation.

The existing D-Log2 scope-distribution test was skipped because `OPV_SIM_FEED_CLIP`
was not supplied. The suite still requires device qualification. Android's Kotlin classifier remains a documented
parity exception to this iOS-only triage; its shell was not changed or tested.

Physical follow-up must cover cold AI upscaler activation, resize/recovery during
preparation, unready/parked clip assists, a populated Media library offline and
online, cache clear/retry, foreground/background transitions, and live-rate and
thermal measurements. The iPad keyboard abort additionally needs its reported
OS/device combination. No Sentry groups have been resolved or suppressed.
