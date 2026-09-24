# BamboozlEDR – Jira Research / Test Notes

**Tool**: [olafhartong/BamboozlEDR](https://github.com/olafhartong/BamboozlEDR)  
**Type**: Proof-of-Concept ETW event generation tool  
**Purpose**: Testing & research of EDR detection capabilities, telemetry quality, and resilience to noise / event flooding.

---

## Summary (Jira Summary Field)
Research and document BamboozlEDR – an ETW event emitter that can generate realistic security telemetry and potentially blind or confuse EDRs by flooding providers and competing for Trace Sessions.

---

## Description (Jira Description Field)

### What is BamboozlEDR?
BamboozlEDR is a TUI-based tool that generates (injects) realistic Event Tracing for Windows (ETW) events across many security-relevant providers.  
It is primarily used for:
- Blue-team detection testing (safe generation of attack-like telemetry)
- Red-team / research into EDR blinding and false-positive generation
- Understanding how EDRs consume ETW data

### Core ETW Concepts & How the Tool Interacts

| Component       | What it is                                      | What BamboozlEDR does |
|-----------------|-------------------------------------------------|-----------------------|
| **Provider**    | Component that *writes* events (e.g. Antimalware, LDAP-Client, PowerShell) | Acts as a fake emitter – constructs and writes correctly formatted events as if they came from the real provider |
| **Trace Session** | The “pipe” that carries events from providers to consumers. Has limited buffers. | Writes into existing sessions used by EDRs. Can also create a competing session (admin) or start a session without a consumer, causing system-wide event loss |
| **Consumer**    | Anything that *reads* events (EDR agents, Event Log, custom collectors) | Does not act as a normal consumer. Instead floods the sessions that real consumers (EDRs) are watching, causing dropped events, rate-limit hits, or noise |

### High-level Flow
```
Real Provider ──► Trace Session ──► Real Consumer (EDR)
       ▲                 ▲
       │                 │
BamboozlEDR writes   BamboozlEDR can create
fake events here     competing / empty sessions
                     → events get dropped for EDR
```

### Key Modes
- **Single / Batch events** – Generate individual or multiple realistic events (malware detections, SharpHound-style LDAP, PowerShell, WMI, etc.)
- **BamboozlEDR mode** – Fire multiple event types simultaneously to create noise
- **Buffer Overflow** – High-volume continuous flooding of multiple providers to overwhelm buffers or hit EDR capping
- **Admin feature** – Create/manage an external Trace Session using the same providers MDE relies on ("NotMDE ETW Trace Monitor")

### Supported Providers (examples)
- Microsoft-Windows-Antimalware / RTP
- Microsoft-Windows-AMSI
- Microsoft-Windows-Defender
- Microsoft-Windows-PowerShell
- Microsoft-Windows-WMI-Activity
- Microsoft-Windows-LDAP-Client
- Microsoft-Windows-TCPIP
- Microsoft-Windows-AppLocker
- Microsoft-Windows-CodeIntegrity
- Microsoft-Windows-NTLM
- Microsoft-Windows-RPC
- Microsoft-Windows-DotNETRuntime
- Microsoft-Windows-Crypto-DPAPI-Events

---

## Acceptance Criteria / Test Ideas (for a Jira ticket)
- [ ] Confirm tool can emit events for at least 5 major providers without admin rights
- [ ] Verify generated events appear in a real EDR console / SIEM (or are dropped)
- [ ] Test Buffer Overflow mode and measure event loss / rate limiting on target EDR
- [ ] Test admin Trace Session feature and observe impact on real EDR consumer
- [ ] Document any detectable artifacts (process name, binary strings, behavior)
- [ ] Create detection rules or hunting queries for the tool itself

---

## Installation Notes (Windows 11)

### Prerequisites
- Go 1.23+ (installed via Chocolatey: `choco install golang -y`)
- Git

### Build Steps
```cmd
cd %USERPROFILE%\Documents\ETW_research
git clone https://github.com/olafhartong/BamboozlEDR.git
cd BamboozlEDR
```

### Network / Proxy Issue Fix (Lab Environment)
Default Go module proxy (`proxy.golang.org`) was blocked / connections forcibly closed on the research lab network.

**Working solution:**
```cmd
go env -w GOPROXY=https://goproxy.io,direct
go clean -modcache
go build -o BamboozlEDR.exe .
```

Alternative (if needed):
```cmd
go env -w GOPROXY=direct
go env -w GOSUMDB=off
go clean -modcache
go build -o BamboozlEDR.exe .
```

### Run
```cmd
.\BamboozlEDR.exe
```
(Run as Administrator for full features – especially Trace Session management)

---

## Notes / Observations
- Intentionally built as an interactive TUI to limit easy automation/abuse.
- Threat names are XOR-obfuscated in the binary.
- Most functionality works in user mode; only Trace Session management requires elevation.
- Useful both for purple-team testing and understanding ETW resilience of modern EDRs.
- On restricted lab networks, `goproxy.io` works better than the official `proxy.golang.org`.

---

## CrowdStrike Falcon Internals (DbgMan Article)

Found an excellent deep reverse-engineering write-up by DbgMan that dissects how CrowdStrike Falcon actually works under the hood (kernel callbacks, WFP, minifilter, user-mode service, and cloud content).  
Article: https://0xdbgman.github.io/posts/inside-the-falcon-how-crowdstrike-catches-you/

### Point-by-point takeaways (especially ETW vs MDE / FalconForce)

1. **ETW is dual-role here**  
   Kernel side (`csagent.sys`) produces ETW via `EtwRegister` / `EtwWriteTransfer` that feeds `CSFalconService.exe`. User-mode side has a dedicated `EtwConsumer@ETW` actor that actively consumes OS ETW providers (`OpenTraceW` + `ProcessTrace`) purely for telemetry enrichment. This is not the primary detection path.

2. **Primary visibility is still the classic six kernel callbacks + WFP + minifilter**  
   Process / Thread / Image / Object / Registry / File (FltRegisterFilter). ETW consumption is secondary enrichment, not the core “see everything” surface the way ETW-TI is for some MDE scenarios.

3. **Cloud content delivery is the real brain**  
   Detection rules live in channel files pulled by `ODSChannelFileActor` / `ChannelFileUpdated` over WinHTTP (NGDP). The driver is mostly a generic event collector + dispatcher; the actual matcher is a runtime-loaded object installed via `CS_SetDetectionEngine` (cmd 1021/2000). Same channel-file mechanism that caused the July 2024 issues.

4. **Implication for testing vs MDE**  
   Blinding techniques that target user-mode ETW providers or AMSI will hit Falcon’s enrichment layer and script visibility, but the process/thread/image/object callbacks and WFP callouts remain live. Falcon’s process-block path (negative NTSTATUS written back to `CreateInfo->CreationStatus`) is independent of the ETW consumer.

5. **Practical takeaway for comparative testing**  
   When moving from FalconForce/MDE work to CrowdStrike, the ETW surface is narrower and more of a supporting actor. The higher-value targets remain the six kernel notification sources, the two WFP engines, the minifilter altitude, and the channel-file update path.

---

**Source**: Conversation research on olafhartong/BamboozlEDR (Black Hat USA 2025 related work) + DbgMan CrowdStrike teardown  
**Date**: 2026-09-23  
**Updated**: 2026-09-24 – Added DbgMan Falcon reverse-engineering notes (ETW consumption section + architecture comparison)
