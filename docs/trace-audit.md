# TRACE audit hook

> **WIFM:** Every risky thing your agent does gets a signed receipt you (or an auditor) can verify later, without trusting Anthropic, this machine, or Exo.

This is an opt-in power surface. Off by default. It does not block or change any action, and it sends nothing anywhere. It writes a local, tamper-evident log of what your agent did.

## What it is

`hooks/exo-trace-audit.py` fires after a tool call and writes one signed record per action into an append-only chain. Each record answers: what ran, under which policy, on which data class, calling which tool. Records use the open [TRACE v0.1](https://trace.agentrust-io.com) format and the upstream `agentrust-trace` library for the record schema and Ed25519 signing, so they are standard TRACE, not a bespoke format, and verify with any TRACE-conformant tooling.

Two properties make the log evidence rather than a diary:

- **Signed.** Each record carries an Ed25519 signature over its canonical form. Change any field and the signature no longer verifies.
- **Chained.** Each record binds the hash of the previous one into its own signed payload. Remove or edit any earlier record and every later link visibly breaks.

## Why it uses the library instead of rolling its own

Hand-writing a receipt scheme means owning the format, the canonicalization, the signing, and the verifier forever, and the result verifies only with your own code. The `agentrust-trace` library already ships all of that, tested against the TRACE conformance suite. The hook is thin on purpose: it assembles a record and hands it to the library.

## The hardware honesty

A laptop has no silicon root of trust, so records are written with `runtime.platform = "software-only"`. TRACE keeps that value distinct from every hardware platform, so no consumer can mistake a laptop-signed record for hardware-backed evidence. A software signature proves the log was not altered after the fact; it does not prove which physical machine produced it.

The same record format rides a gateway or a hardware-attested runtime unchanged when you need that stronger guarantee. Only `runtime.platform` and `runtime.measurement` change. The rule you wrote, and the receipt you read, stay the same.

## Install

```bash
pip install agentrust-trace
```

Wire it in `~/.claude/settings.json`. The matcher scopes it to the actions worth recording:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash|Edit|Write|NotebookEdit|WebFetch|mcp__.*",
        "hooks": [
          { "type": "command", "command": "python3 ~/.claude/hooks/exo-trace-audit.py" }
        ]
      }
    ]
  }
}
```

On first run it generates a persistent signing key at `~/.config/exo/trace/signing-key.pem` (mode `0600`) and publishes the public key at `~/.config/exo/trace/public-key.jwk.json`. Pin that public key in whatever verifies the log.

## Verify the chain

```bash
python3 ~/.claude/hooks/exo-trace-audit.py --verify
```

This checks every record's signature against the pinned public key and confirms every chain link. Exit code `0` means the log is intact; `1` means at least one record was altered or dropped.

## Where things live

| Thing | Path | Notes |
|---|---|---|
| Records | `$KB_ROOT/trace/records.jsonl` | `KB_ROOT` defaults to `~/Exo`. Append-only. |
| Signing key | `~/.config/exo/trace/signing-key.pem` | `0600`. Back it up; without it you cannot sign new records under the same identity. |
| Public key | `~/.config/exo/trace/public-key.jwk.json` | Safe to share. Verifiers pin this. |

## Configuration

All optional, set as environment variables.

| Variable | Default | Purpose |
|---|---|---|
| `EXO_TRACE_SUBJECT` | `spiffe://exo.local/agent/exo` | Agent identity in the record. |
| `EXO_TRACE_DATA_CLASS` | `personal` | Data classification for the action. |
| `EXO_TRACE_ENFORCEMENT` | `advisory` | `enforce`, `advisory`, or `silent`. Exo's product hooks are advisory. |
| `EXO_TRACE_POLICY_BUNDLE` | (none) | Path to a policy bundle file; its hash is recorded so a record cites the exact policy in force. |
| `EXO_TRACE_MODEL_ID` | `claude-code` | Model id recorded in the record. |
| `TRACE_PRIVATE_KEY_PEM` | (none) | Use this key instead of the on-disk file. |

## What this is not

- **Not enforcement.** It records after the fact; it never holds or blocks an action. Blocking is a PreToolUse concern (see `hooks/exo-focus-gate.sh` for that shape).
- **Not hardware attestation.** See the honesty note above.
- **Not telemetry.** Records are local files. Nothing is transmitted.
