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

## Notes / Observations
- Intentionally built as an interactive TUI to limit easy automation/abuse.
- Threat names are XOR-obfuscated in the binary.
- Most functionality works in user mode; only Trace Session management requires elevation.
- Useful both for purple-team testing and understanding ETW resilience of modern EDRs.

---

**Source**: Conversation research on olafhartong/BamboozlEDR (Black Hat USA 2025 related work)  
**Date**: 2026-09-23
