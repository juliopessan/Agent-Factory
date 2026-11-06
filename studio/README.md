# Factory Studio

Runs this Factory in [Mastra Studio](https://mastra.ai): a browser UI where people operate the Factory agents, the delivery board and the approval gates without an IDE.

It reads the kit directly. Agents come from [`.github/agents`](../.github/agents), so editing a profile changes the Studio agent. Board lanes follow [super-board](https://github.com/EricTechPro/super-board) (MIT): Backlog, Ready, Build, QA, Review, Done.

## Run it

Needs Node 22 or later.

```bash
cd studio
cp .env.example .env   # set FACTORY_MODEL and the matching API key
npm install
npm run dev            # opens http://localhost:4111
```

`FACTORY_MODEL` picks the model for every agent. Use a provider your organization has approved, as [the repository instructions](../.github/copilot-instructions.md) require.

## What you get

| Studio area | Content |
|---|---|
| Agents | The eight Factory profiles. Chief of Staff owns the board and delegates to the specialists. |
| Workflow `factory-delivery` | triage, specification, human approval (`beforeImplementation`), build, QA + security + docs in parallel, human merge decision (`beforeMerge`). Any FAIL sends the card back to Build. |
| Board | Stored in `studio/factory-board.json`. Every lane move an agent proposes asks for approval in Studio. |

## Limits

- Agents plan and write in chat. They do not edit files, run commands or open pull requests.
- Approvals in Studio are recorded on the card, not in GitHub. They do not replace the merge and release gates in [REVIEW.md](../REVIEW.md).
- The board and run history are local files, one per machine.
