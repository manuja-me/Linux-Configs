---
name: sast-security-auditor
description: Systematic security review and Static Application Security Testing (SAST). Use when performing code security audits, identifying OWASP Top 10 vulnerabilities, finding leaked secrets, analyzing insecure dependencies, or reviewing PRs for security risks.
---

# SAST Security Auditor Skill

A rigorous, evidence-based methodology for identifying, validating, and remediating software security vulnerabilities across codebases.

---

## 1. Audit Principles & Standards

Every reported finding MUST adhere to the following standards:
1. **Evidence-Based**: No speculative vulnerabilities. You must point to the exact file, line number, and tainted data flow.
2. **CWE / OWASP Alignment**: Map each finding to an established classification (e.g., CWE-89: SQL Injection, CWE-79: XSS, CWE-918: SSRF).
3. **Severity Calibration**:
   - **CRITICAL**: Remote Code Execution (RCE), Authentication Bypass, exposed live credentials with admin privileges, SQL Injection with direct exploitation path.
   - **HIGH**: Stored XSS, Insecure Direct Object Reference (IDOR), Server-Side Request Forgery (SSRF) without egress filtering, sensitive data leakage in logs.
   - **MEDIUM**: Reflected XSS requiring user interaction, missing CSRF protection on state-changing endpoints, weak password hashing algorithms (MD5/SHA1).
   - **LOW / INFORMATIONAL**: Missing security headers (HSTS, CSP), verbose server banner disclosures, deprecated dependency without active exploit.

---

## 2. Security Audit Checklist

### A. Input Handling & Injection Flaws
- [ ] **SQL / NoSQL Injection (CWE-89 / CWE-943)**:
  - Check for dynamic string interpolation in database queries (`f"SELECT * FROM users WHERE id = {user_id}"`).
  - Enforce parameterized queries, ORM prepared statements, or query builders.
- [ ] **Command Injection (CWE-78)**:
  - Identify calls to `subprocess.Popen(..., shell=True)`, `os.system()`, `exec()`, `eval()`, or `child_process.exec()`.
  - Replace with array-based arguments (`shell=False`) and strict input whitelisting.
- [ ] **Cross-Site Scripting (XSS - CWE-79)**:
  - Look for unescaped HTML injection (`dangerouslySetInnerHTML`, `v-html`, template filters like `| safe`).
- [ ] **Path Traversal (CWE-22)**:
  - Check user-controlled file paths passed to `fs.readFile` or `open()`. Verify sanitization using `os.path.abspath()` checks or path containment.

### B. Authentication, Session & Access Control
- [ ] **Broken Access Control & IDOR (CWE-639)**:
  - Ensure every data access endpoint validates that the authenticated user owns or is authorized to access the requested resource ID.
- [ ] **Hardcoded Secrets & Sensitive Credentials (CWE-798)**:
  - Scan for private keys, AWS/GCP tokens, database passwords, and JWT signing keys in code or commit history.
  - Require environment variables via `.env` or secret managers.
- [ ] **Cryptographic Weaknesses (CWE-327 / CWE-328)**:
  - Check for weak hashing (MD5, SHA1) used for passwords or security tokens. Enforce bcrypt, argon2id, or scrypt.

### C. Dependency & Software Supply Chain (SCA)
- [ ] Verify lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `poetry.lock`, `go.sum`).
- [ ] Run automated vulnerability checks:
  ```bash
  # Node.js
  npm audit --audit-level=high
  # Python
  pip-audit
  # Go
  govulncheck ./...
  # Rust
  cargo audit
  ```

---

## 3. Reporting Template

When documenting findings, use this structured format:

```markdown
### [VULN-01] <Vulnerability Title>
- **Severity**: Critical | High | Medium | Low
- **CWE**: CWE-XXX (<CWE Name>)
- **Location**: `path/to/file.ext` (Line XX-YY)

#### Description & Impact
Explain the vulnerability, the untrusted input source, and what an attacker could achieve.

#### Proof of Concept / Tainted Flow
```text
Source: req.query.url -> Variable: targetUrl -> Sink: fetch(targetUrl) (SSRF)
```

#### Remediation Diff
```diff
- const response = await fetch(req.query.url);
+ const allowedDomains = ['api.example.com'];
+ const targetUrl = new URL(req.query.url);
+ if (!allowedDomains.includes(targetUrl.hostname)) {
+     throw new Error('Forbidden destination host');
+ }
+ const response = await fetch(targetUrl.toString());
```
```
