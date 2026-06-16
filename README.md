# home-soc-lab-build-Project-1
Designed and deployed a multi-VM Active Directory home SOC lab on VMware Workstation, including a Windows Server 2022 domain controller, Windows 11 client, Ubuntu server, pfSense firewall, and Kali attacker — instrumented with Sysmon, PowerShell script block logging for learning

# Home SOC Lab — Active Directory with Centralized Logging

A home lab with 5 virtual machines behind a pfSense firewall. Set up with Sysmon, PowerShell logging, and Windows audit policies so it produces the kind of logs a real SOC team would monitor.

---

## Project Overview

This is **Project 1** of my SOC analyst portfolio.

The goal was simple: build a safe environment where I can run attacks and see them in the logs. That way I can practice detection, threat hunting, and incident response on real data instead of just reading about it.

**What I used**: VMware Workstation Pro, pfSense, Windows Server 2022, Windows 11 Enterprise, Ubuntu Server 22.04, Kali Linux

**Result**: 5 VMs in a private network, all sending good logs from Sysmon, PowerShell, Windows Security, and the firewall. Ready to feed into a SIEM in Project 2 (Wazuh) and Project 3 (Microsoft Sentinel).


## What I Built

### 1. A private network with pfSense as the gateway

I used the `172.16.50.0/24` subnet (more on why later). pfSense controls everything:

- Static IPs for the important servers
- DHCP for anything else
- Firewall blocks by default, allows what I need
- DNS resolver is on
- Ready to send syslog to a SIEM (Project 2)

### 2. Active Directory domain (`corp.local`)

A working AD setup with:

- DC01 (Windows Server 2022) running AD and DNS
- WIN10-1 (Windows 11) joined to the domain
- 4 test users — normal, admin, service account
- OUs for Users / Workstations / Servers / ServiceAccounts
- DNS works end-to-end: DC01 → pfSense → public DNS

### 3. Better logging on every Windows machine

The default Windows logs are not enough for detection. I added these:

| **Sysmon** (SwiftOnSecurity config) | Logs every process, network connection, LSASS access, DNS query |
| **PowerShell Module Logging** | Event ID 4103 — shows which modules ran |
| **PowerShell Script Block Logging** | Event ID 4104 — captures the actual code that ran |
| **Command-Line Auditing** | Event ID 4688 now shows full command lines |
| **Advanced Audit Policy** | More detail on logons, processes, Kerberos, credentials |

### 4. Attacker machine

Kali Linux on the same lab-net network. I can use it to safely simulate attacks against the AD environment — brute force, credential dumping, lateral movement.

### 5. Ready for a SIEM

UB-SRV (Ubuntu) is built and waiting. pfSense is already set up to send syslog to it. Once I install Wazuh in Project 2, the Windows agents and firewall logs will start flowing right away.


## What I Learned

These are things I figured out while doing the project — not stuff I read in a book.

### Lesson 1: Pick the right subnet from the start

I started with `192.168.1.0/24` because every tutorial uses it. Then I tried to open the pfSense admin page at `https://192.168.1.1` and got my home router instead. They were on the same IP.

I moved everything to `172.16.50.0/24`. No more collision.

**Takeaway**: check your subnet against your real network before you build anything. 

### Lesson 2: Windows says "No Internet" even when you have internet

After I built pfSense, Windows kept showing the yellow "No Internet" warning. But `ping 8.8.8.8` worked fine.

It turns out Windows checks internet by trying to load `www.msftncsi.com`. If DNS can't resolve that name, Windows says "No Internet" even though your IP routing works fine. The real fix was setting up DNS forwarders on DC01.

**Takeaway**: don't trust the Windows UI. Use `ping`, `nslookup`, and `Invoke-WebRequest` to test each layer separately. This is exactly how you diagnose user "internet broken" tickets in a SOC.

### Lesson 3: DNS has more layers than you think

A domain controller runs DNS for the AD domain. But it doesn't know external names like `google.com` on its own. It needs forwarders set up. The full path is:

```
App → DC01 DNS (127.0.0.1) → pfSense DNS Resolver → Public DNS
```

Each step is configured separately. If any one breaks, name resolution fails.

**Takeaway**: when you see "DNS resolution failed" alerts in a SOC, the broken step could be anywhere in this chain. Knowing the layers helps you find the problem faster.

### Lesson 4: One NIC per VM is the right call

I was tempted to give each VM a second NIC on VMware NAT as a backup. That way, if pfSense was off, the VMs still had internet.

But this would have broken the whole lab. Windows would have used the backup NIC sometimes and skipped pfSense, so my firewall logs would have missed traffic.

**Takeaway**: in real corporate networks, regular workstations don't have multiple ways to reach the internet. They go through one firewall. That's what makes the firewall useful — every packet has to pass through it.

### Lesson 5: Sysmon is the most useful logging tool to deploy

Default Windows logs are basic. With Sysmon plus the SwiftOnSecurity config, I now log:

- Every process that starts, with the full command line and the parent process
- Every outbound network connection, with which process made it
- Every DNS query
- Every time something touches LSASS (this is how you catch credential dumping)
- Every CreateRemoteThread call (this catches process injection)

**Takeaway**: if a Windows machine doesn't have Sysmon, you're half-blind. It's the first thing I'd install on any endpoint that doesn't already have a real EDR.

### Lesson 6: "It works" is not the same as "I tested it works"

I checked every layer with actual commands

- `ping 172.16.50.1` — gateway works
- `ping 8.8.8.8` — internet routing works
- `nslookup google.com` — DNS works
- `Get-Service Sysmon64` — Sysmon is running
- `Get-WinEvent` on the Sysmon log — events are flowing

**Takeaway**: in a real SOC, when you say "the agent is working on that host," you need proof. Taking screenshots while you build is not extra work — it's part of the job.

---

## Verification Evidence attached


### Network


| `ping 172.16.50.1` (pfSense) | 0% loss |
| `ping 8.8.8.8` (Internet) | 0% loss, TTL=127 |
| `nslookup -type=A google.com` | Worked, returned an IP |
| HTTPS test | 200 OK |

### Telemetry


| `Get-Service Sysmon64` |  Running |
| Sysmon Operational log |  Events flowing |
| `EnableModuleLogging` registry value |  Set to 1 |
| `EnableScriptBlockLogging` registry value | Set to 1 |
| Event ID 4104 captured |  Confirmed |

---


## What's Next

**Project 2 — Wazuh SIEM** — install Wazuh on UB-SRV, add agents on the Windows machines, pull in pfSense syslog, and write 10 custom detection rules mapped to MITRE ATT&CK.

After that: Microsoft Sentinel (Project 3), phishing analysis (Project 4), and a full incident response project that simulates an attack from start to finish (Project 8).

---



**Built by**: [Faisal Khan] · [LinkedIn](https://www.linkedin.com/in/mohammedfaisalkhan/) · [GitHub](https://github.com/samfaiz)
