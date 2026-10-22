# Factory Diagrams

These source-backed Archify diagrams explain the Factory operating model and delivery lifecycle; they are documentation, not execution or acceptance evidence for a product.

Owner: Chief of Staff. Generated on 2026-10-22 using [juliopessan/archify](https://github.com/juliopessan/archify) version 3.1.0 at revision `68be1e0971208ef0b1550ec3b29f3d4d177f3cd6`. The renderer ran from a temporary directory; no global skill, Factory dependency, client profile or CI integration was installed.

## Artifacts

| Diagram | Interactive HTML | Editable Source | Static Image |
| --- | --- | --- | --- |
| Factory coordination | [factory-overview.html](factory-overview.html) | [factory-overview.workflow.json](factory-overview.workflow.json) | [factory-overview.png](../assets/factory-overview.png) |
| Governed delivery | [delivery-lifecycle.html](delivery-lifecycle.html) | [delivery-lifecycle.workflow.json](delivery-lifecycle.workflow.json) | [delivery-lifecycle.png](../assets/delivery-lifecycle.png) |

Open either standalone HTML locally; no server or hosted service is required. The diagram PNGs above are Archify native Chrome screenshots at 2048 x 1320 in the light theme, with viewer controls visible. The root README hero instead uses the [original illustration](../assets/copilot-agent-factory.png), subsequently supplied by the repository owner and copied without modification. Its conceptual delivery outcomes are not evidence of executed tests or acceptance; parallel work remains conditional on client capabilities and disjoint ownership. The text table in the root README remains an accessible alternative to the lifecycle graphic.

## Evidence Boundary

Both candidates cite committed Factory documentation and agent profiles at revision `409597a71ce7605b3a392500af5125363aa01f90`. The current README and SDLC review had pre-existing uncommitted edits; those edits are not represented as committed source evidence. The diagrams do not imply automatic parallel execution, filesystem enforcement, completed client pilots or production readiness.

| Check | Observed Result |
| --- | --- |
| Archify finalize: both workflows | PASS: validate, deliver, strict check and browser-check; zero final diagnostics |
| Integrated browser: desktop | No document-level horizontal overflow at 1440 x 1000 |
| Integrated browser: mobile | No document-level horizontal overflow at 390 x 844; dense diagrams still require zooming for detail |
| Overview interaction | Chief of Staff keyboard focus and pinned source link verified |
| Archify native Chrome screenshots | PASS: containment, readability, viewer chrome, theme states and captures at 1440 x 900 and 2048 x 1320; screenshots inspected visually |

An initial overview browser run failed in the Chrome DevTools pipe handshake. A complete retry against unchanged candidate and HTML bytes passed all four gates. The lifecycle's initial release-arrow label collision was corrected with the renderer-recommended label segment, then all four gates passed. A Playwright click on the SVG group was intercepted; keyboard focus was verified instead. This is not a claim that every pointer interaction was tested. Integrated-browser PNG captures were rejected after a resize produced clipping. The final README images are exact copies of Archify's native Chrome light-theme screenshots; the delivered HTML was not modified.

Raw delivery/browser receipts are generated alongside each HTML. The successful final summaries, browser receipts and visual-check receipts identify the exact artifact hashes. Original receipt paths into the temporary tool checkout are retained as provenance; those temporary paths and the unsuccessful initial run are not portable evidence links. Do not interpret a diagram's quality check as the separate Factory extension acceptance gate. Real VS Code/CLI interrupted-session pilots remain NOT RUN, the runtime-state exception remains OPEN, and Phase 2 remains unauthorized. See the [authoritative extension board](../factory/TASK_BOARD.md).

## Reproduce

Obtain the Archify source at the pinned revision above and set the CLI path to that local checkout. From the Factory root:

```powershell
$archifyCli = 'C:/Tools/archify/archify/bin/archify.mjs'
node $archifyCli finalize workflow docs/diagrams/factory-overview.workflow.json docs/diagrams/factory-overview.html --repo-root . --quality showcase --out-dir docs/diagrams/overview-review --json
node $archifyCli finalize workflow docs/diagrams/delivery-lifecycle.workflow.json docs/diagrams/delivery-lifecycle.html --repo-root . --quality showcase --out-dir docs/diagrams/lifecycle-review --json
node $archifyCli visual-check docs/diagrams/factory-overview.html --out-dir docs/diagrams/overview-review --summary --require-provenance
node $archifyCli visual-check docs/diagrams/delivery-lifecycle.html --out-dir docs/diagrams/lifecycle-review --summary --require-provenance
npm run test:structure
```

Treat every nonzero exit as failure. Use a fresh evidence directory for a subsequent browser-reviewed revision. Inspect the native screenshots and copy the corresponding `*.visual-check.2048x1320.light.png` into each README image path to refresh it. Archify reported version 3.2.0 as available; generation deliberately retained the user-specified fork's version 3.1.0, with no automatic update.

## Renderer License

The generated standalone HTML contains Archify renderer code. Its MIT notice is retained below. The embedded JetBrains Mono font carries its SIL Open Font License 1.1 notice in the generated font CSS. No third-party brand marks were requested for these diagrams.

```text
MIT License

Copyright (c) 2026 tt-a1i (Archify)
Copyright (c) 2025 Cocoon AI

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Next Steps

1. Review the rendered diagrams and preserve source evidence when changing responsibilities or approval paths.
2. Preserve the supplied hero illustration separately from generated Archify screenshots when refreshing the diagrams.
3. Complete the separate real-client pilots and human acceptance decisions before proposing Phase 2.