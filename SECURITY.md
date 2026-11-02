# Security Policy

## Supported Versions

Only the latest commit on `main` and the most recent tagged release receive security fixes.

| Version | Supported |
| --- | --- |
| `main` | Yes |
| `v0.1.0` | Yes |
| Older commits | No |

## Reporting A Vulnerability

Report vulnerabilities privately through GitHub: open the repository's **Security** tab and choose **Report a vulnerability**. If that option is not shown, private vulnerability reporting is not enabled yet; contact the owner through the GitHub profile linked in [LICENSE](LICENSE) and ask for a private channel. Do not open a public issue, pull request or discussion for a suspected vulnerability.

Include the affected file or script, the commit or tag, reproduction steps, the impact you observed, and whether the issue is already public. Do not include real secrets, tokens or client data; describe them instead.

You can expect an acknowledgement within 5 business days and an assessment within 15 business days. Timelines for a fix depend on severity and are agreed with the reporter.

## Scope

In scope:

- Scripts under `scripts/` and `setup-local.ps1`: path handling, link and reparse-point containment, untrusted JSON parsing, evidence integrity and secret handling.
- Workflows under `.github/workflows/` and `.github/workflow-templates/`: permissions, pinned actions, injection through untrusted input, and gate bypasses.
- `tools/factory-console.html`: script injection or data exfiltration from loaded files.
- Agent profiles and instructions where the text itself would lead an agent to disclose secrets, bypass a recorded approval gate or execute untrusted content.

Out of scope:

- The fact that Factory rules are behavioral instructions rather than technical enforcement. This is a documented design limit; see [repository instructions](.github/copilot-instructions.md).
- Vulnerabilities in GitHub Copilot, other AI clients, GitHub Actions runners or third-party packages. Report those to their maintainers.
- Products built with the Factory. Their security belongs to their own owners and pipelines.

## Handling

Confirmed issues are fixed on a private branch or a draft security advisory, verified with the relevant kit checks, and disclosed in [CHANGELOG.md](CHANGELOG.md) after the fix is released. Credit is given to reporters who want it.
