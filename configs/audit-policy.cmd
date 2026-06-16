@echo off
REM ============================================================================
REM  Windows Advanced Audit Policy Configuration for SOC Lab
REM ============================================================================
REM  Purpose:
REM    Enables the Windows audit subcategories needed for SOC detection.
REM    Native Windows logging is minimal by default. This script turns on
REM    the events that matter for credential attacks, lateral movement,
REM    persistence detection, and brute-force monitoring.
REM
REM  How to run:
REM    1. Open Command Prompt or PowerShell as Administrator
REM    2. Run this file:   audit-policy.cmd
REM
REM  Where to run:
REM    On every Windows host you want monitored (DC01, WIN10-1, future servers)
REM
REM  Verification after running:
REM    auditpol /get /category:*
REM ============================================================================

echo.
echo [+] Configuring Windows Advanced Audit Policies...
echo.

REM --- Logon / Logoff Events --------------------------------------------------
REM  4624 (success), 4625 (failure), 4634 (logoff), 4647 (user-initiated logoff)
REM  Critical for: brute force detection, account abuse, anomalous sign-ins
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Logoff" /success:enable
auditpol /set /subcategory:"Account Lockout" /success:enable /failure:enable
auditpol /set /subcategory:"Special Logon" /success:enable
echo [OK] Logon/Logoff auditing enabled

REM --- Process Tracking -------------------------------------------------------
REM  4688 (process create), 4689 (process exit)
REM  This is the SINGLE most useful detection event when command-line auditing
REM  is also enabled via Group Policy (separate step).
auditpol /set /subcategory:"Process Creation" /success:enable
auditpol /set /subcategory:"Process Termination" /success:enable
echo [OK] Process tracking enabled

REM --- Kerberos Auditing (Domain Controllers) ---------------------------------
REM  4768 (TGT requested), 4769 (service ticket requested), 4771 (pre-auth fail)
REM  Critical for: Kerberoasting, AS-REP roasting, Golden Ticket detection
auditpol /set /subcategory:"Kerberos Authentication Service" /success:enable /failure:enable
auditpol /set /subcategory:"Kerberos Service Ticket Operations" /success:enable /failure:enable
echo [OK] Kerberos auditing enabled

REM --- Credential Validation --------------------------------------------------
REM  4776 (NTLM credential validation)
REM  Critical for: NTLM relay detection, password spray attempts
auditpol /set /subcategory:"Credential Validation" /success:enable /failure:enable
echo [OK] Credential validation auditing enabled

REM --- Account Management -----------------------------------------------------
REM  4720 (user created), 4722 (enabled), 4724 (password reset), 4738 (changed)
REM  4728/4732/4756 (added to security group)
REM  Critical for: persistence detection, privilege escalation
auditpol /set /subcategory:"User Account Management" /success:enable /failure:enable
auditpol /set /subcategory:"Security Group Management" /success:enable /failure:enable
auditpol /set /subcategory:"Computer Account Management" /success:enable /failure:enable
echo [OK] Account management auditing enabled

REM --- Directory Service Changes (Domain Controllers) -------------------------
REM  5136, 5137, 5138, 5139, 5141 (object created, modified, moved, undeleted, deleted)
REM  Critical for: AD attack detection (AdminSDHolder modification, DCSync, etc.)
auditpol /set /subcategory:"Directory Service Changes" /success:enable /failure:enable
auditpol /set /subcategory:"Directory Service Access" /success:enable /failure:enable
echo [OK] Directory service auditing enabled

REM --- Object Access (File Shares) --------------------------------------------
REM  5140 (network share accessed), 5145 (detailed share access)
REM  Critical for: lateral movement, sensitive file access tracking
auditpol /set /subcategory:"File Share" /success:enable /failure:enable
auditpol /set /subcategory:"Detailed File Share" /success:enable /failure:enable
echo [OK] File share auditing enabled

REM --- System Integrity -------------------------------------------------------
REM  Critical for: detection of tampering, security log clearing
auditpol /set /subcategory:"Security State Change" /success:enable /failure:enable
auditpol /set /subcategory:"Security System Extension" /success:enable /failure:enable
auditpol /set /subcategory:"System Integrity" /success:enable /failure:enable
echo [OK] System integrity auditing enabled

REM --- Policy Change ----------------------------------------------------------
REM  4719 (audit policy changed) — DON'T let attackers turn off our logging
REM  silently. This is the audit-the-audit safeguard.
auditpol /set /subcategory:"Audit Policy Change" /success:enable /failure:enable
auditpol /set /subcategory:"Authentication Policy Change" /success:enable /failure:enable
auditpol /set /subcategory:"Authorization Policy Change" /success:enable /failure:enable
echo [OK] Policy change auditing enabled

REM --- Sensitive Privilege Use ------------------------------------------------
REM  4673, 4674 (privileged operations performed)
REM  Critical for: detecting use of debug/backup privileges by attackers
auditpol /set /subcategory:"Sensitive Privilege Use" /success:enable /failure:enable
echo [OK] Sensitive privilege use auditing enabled

echo.
echo ============================================================================
echo  All audit policies configured.
echo ============================================================================
echo.
echo  To verify: auditpol /get /category:*
echo.
echo  Recommended next step:
echo    Enable command-line in Event 4688 via Group Policy:
echo      Computer Configuration
echo        -^> Administrative Templates
echo          -^> System
echo            -^> Audit Process Creation
echo              -^> "Include command line in process creation events" = ENABLED
echo.
echo  Then run:  gpupdate /force
echo.

pause
