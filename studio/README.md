# Factory Studio

Runs this Factory in [Mastra Studio](https://mastra.ai): a browser UI where people operate the Factory agents, the delivery board and the approval gates without an IDE.

It reads the kit directly. Agents come from [`.github/agents`](../.github/agents), so editing a profile changes the Studio agent. Board lanes follow [super-board](https://github.com/EricTechPro/super-board) (MIT): Backlog, Ready, Build, QA, Review, Done.

- [Quick start for technical users](#quick-start-for-technical-users)
- [Step-by-step guide for everyone else](#step-by-step-guide-for-everyone-else)
- [Using the Studio](#using-the-studio)
- [Troubleshooting](#troubleshooting)
- [Limits](#limits)

## Before you start

You need three things, whichever guide you follow:

| What | Why | Where to get it |
|---|---|---|
| Node.js 22 or later | Runs the Studio on your computer | [nodejs.org](https://nodejs.org) (LTS download) |
| Git | Downloads this repository | [git-scm.com](https://git-scm.com/downloads), already installed on most Macs |
| A model API key | Lets the agents reply | The provider your organization approved, for example the [Anthropic Console](https://console.anthropic.com) |

`FACTORY_MODEL` picks the model for every agent. Use a provider your organization has approved, as [the repository instructions](../.github/copilot-instructions.md) require.

## Quick start for technical users

```bash
git clone https://github.com/juliopessan/agent-factory.git
cd agent-factory/studio
cp .env.example .env    # set FACTORY_MODEL and the matching API key
npm install
npm run dev             # http://localhost:4111
```

Already cloned? Run `git pull` in the repository root, then `npm install` in `studio/`.

Configuration lives in `studio/.env`:

| Variable | Example | Purpose |
|---|---|---|
| `FACTORY_MODEL` | `anthropic/claude-sonnet-5-5` | Mastra model router id used by every agent |
| `ANTHROPIC_API_KEY` | (your key) | Key for the provider in `FACTORY_MODEL`; use that provider's variable when you switch |
| `FACTORY_ROOT` | `/path/to/agent-factory` | Optional. Kit root, when Studio runs outside the repository |

Code layout: agents in `src/mastra/agents`, board tools in `src/mastra/tools/board.ts`, workflow in `src/mastra/workflows/delivery.ts`.

## Step-by-step guide for everyone else

No coding needed. You will copy a few commands into the Terminal, one at a time. Each step says what you should see.

### 1. Open the Terminal

- **Mac:** press `Cmd + Space`, type `Terminal` and press Enter.
- **Windows:** press the Windows key, type `PowerShell` and press Enter.

### 2. Check that Node.js is installed

Type this and press Enter:

```bash
node --version
```

You should see a number like `v22.12.0`. If the first number is below 22, or you see "command not found", install the LTS version from [nodejs.org](https://nodejs.org), close the Terminal, open it again and repeat this step.

### 3. Download the Factory

```bash
git clone https://github.com/juliopessan/agent-factory.git
```

This creates a folder called `agent-factory` in your home folder. If you see "already exists", you downloaded it before: go to step 4 and then run `git pull` to get the latest version.

### 4. Go into the Studio folder

```bash
cd agent-factory/studio
```

The Terminal does not print anything when this works.

### 5. Add your API key

Create your settings file:

```bash
cp .env.example .env
```

Open it:

- **Mac:** `open -e .env`
- **Windows:** `notepad .env`

Paste your key after `ANTHROPIC_API_KEY=` with no spaces, save and close the file. The key stays on your computer and is never uploaded to GitHub.

### 6. Install

```bash
npm install
```

This takes one or two minutes and prints a lot of text. Warnings are normal. It is done when you see `added ... packages`.

### 7. Start the Studio

```bash
npm run dev
```

When you see `Studio: http://localhost:4111`, open [http://localhost:4111](http://localhost:4111) in your browser.

Keep the Terminal window open while you use the Studio. To stop it, click the Terminal and press `Ctrl + C`.

### Next time

You only repeat steps 1, 4 and 7: open the Terminal, `cd agent-factory/studio`, `npm run dev`.

## Using the Studio

| Studio area | What you do there |
|---|---|
| Agents | Chat with the eight Factory profiles. Start with **chief-of-staff**: it owns the board and delegates to the specialists. |
| Workflows → `factory-delivery` | Turn a request into delivered work: triage, specification, your approval (`beforeImplementation`), build, QA + security + docs in parallel, your merge decision (`beforeMerge`). Any FAIL sends the card back to Build. |
| Board | Stored in `studio/factory-board.json`. Every lane move an agent proposes asks for your approval. |

To run your first delivery:

1. Open **Workflows**, pick `factory-delivery` and fill in `title` and `request`, for example "Login page" and "Users need to sign in with email and password".
2. The run pauses after the specification. Read it, then resume with `approved: true` (or `false` and a `comment`).
3. It pauses again after the reviews. Resume with `merge: true` to move the card to Done.

## Troubleshooting

| You see | What to do |
|---|---|
| `command not found: node` or `npm` | Install Node.js 22+ from [nodejs.org](https://nodejs.org), then open a new Terminal. |
| `command not found: git` | Install Git from [git-scm.com](https://git-scm.com/downloads). On a Mac, accept the prompt to install developer tools. |
| `no such file or directory: agent-factory` | You are in another folder. Run `cd ~` and try again, or repeat step 3. |
| Agents do not reply, or you see `invalid x-api-key` | Check the key in `.env`, save the file, stop the Studio with `Ctrl + C` and run `npm run dev` again. |
| `port 4111 is already in use` | The Studio is already running in another window. Use that one, or close it first. |

## Limits

- Agents plan and write in chat. They do not edit files, run commands or open pull requests.
- Approvals in Studio are recorded on the card, not in GitHub. They do not replace the merge and release gates in [REVIEW.md](../REVIEW.md).
- The board and run history are local files, one per machine.
