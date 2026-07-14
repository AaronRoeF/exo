#!/usr/bin/env python3
# exo-trace-audit.py
# PostToolUse hook - writes a signed, tamper-evident TRACE record for each
# tool call the agent makes, into a local append-only chain.
#
# This is an opt-in governance surface. It does NOT block or change any action
# (that is a PreToolUse concern); it produces evidence after the fact: a signed
# receipt of what ran, under which policy, touching which data class, calling
# which tool - in a form a third party can verify without trusting this machine.
#
# It uses the upstream TRACE library (agentrust-trace) for the record format and
# Ed25519 signing rather than a home-grown receipt scheme, so records are
# schema-valid TRACE v0.1 and verify with any TRACE-conformant tooling.
#
#   pip install agentrust-trace
#
# Wire in ~/.claude/settings.json under "PostToolUse". Recommended matcher scopes
# it to the actions that carry risk:
#
#   {
#     "hooks": {
#       "PostToolUse": [
#         { "matcher": "Bash|Edit|Write|NotebookEdit|WebFetch|mcp__.*",
#           "hooks": [ { "type": "command",
#                        "command": "python3 ~/.claude/hooks/exo-trace-audit.py" } ] }
#       ]
#     }
#   }
#
# Records:  $KB_ROOT/trace/records.jsonl   (KB_ROOT defaults to ~/Exo)
# Key:      ~/.config/exo/trace/signing-key.pem   (0600, generated on first run)
# Pub key:  ~/.config/exo/trace/public-key.jwk.json   (pin this in verifiers)
#
# Verify the whole chain:  python3 exo-trace-audit.py --verify
#
# Hardware honesty: a laptop has no silicon root of trust, so records are written
# with runtime.platform = "software-only". The TRACE schema keeps that value
# distinct from any hardware platform, so a consumer can never mistake a
# laptop-signed record for hardware-backed evidence. The same record format rides
# a cMCP gateway or an attested runtime unchanged when you need that stronger
# guarantee - only the platform and measurement change.
#
# Design fit: local-first (writes local files only, no network, no telemetry),
# opt-in (nothing runs unless you wire it), and it never blocks a tool call.

import argparse
import hashlib
import json
import os
import sys
import time
from pathlib import Path

EAT_PROFILE = "tag:agentrust.io,2026:trace-v0.1"
GENESIS = "urn:exo:trace:chain:genesis"


def kb_root() -> Path:
    return Path(os.environ.get("KB_ROOT", str(Path.home() / "Exo")))


def records_path() -> Path:
    return kb_root() / "trace" / "records.jsonl"


def config_dir() -> Path:
    return Path(os.environ.get("EXO_TRACE_CONFIG", str(Path.home() / ".config" / "exo" / "trace")))


def key_file() -> Path:
    return Path(os.environ.get("EXO_TRACE_KEY_FILE", str(config_dir() / "signing-key.pem")))


def pubkey_file() -> Path:
    return config_dir() / "public-key.jwk.json"


def _sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _digest(data: bytes) -> str:
    return "sha256:" + _sha256_hex(data)


def _stable(obj) -> bytes:
    return json.dumps(obj, sort_keys=True, separators=(",", ":")).encode("utf-8")


def load_or_create_key():
    """Return a persistent Ed25519 signing key so records stay verifiable.

    Precedence: TRACE_PRIVATE_KEY_PEM env, then the on-disk key file, then a
    freshly generated key written to that file at 0600. A persistent key is what
    lets --verify re-check historical records after the agent process exits.
    """
    from agentrust_trace import load_key, generate_key, key_to_jwk
    from cryptography.hazmat.primitives import serialization

    pem_env = os.environ.get("TRACE_PRIVATE_KEY_PEM")
    if pem_env:
        return load_key(pem_env)

    kf = key_file()
    if kf.exists():
        return load_key(kf.read_text())

    key = generate_key()
    cfg = config_dir()
    cfg.mkdir(parents=True, exist_ok=True)
    try:
        os.chmod(cfg, 0o700)
    except OSError:
        pass
    pem = key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    ).decode()
    kf.write_text(pem)
    try:
        os.chmod(kf, 0o600)
    except OSError:
        pass
    # Publish the public JWK so verifiers can pin a trusted key.
    pubkey_file().write_text(json.dumps(key_to_jwk(key), indent=2))
    return key


def prev_chain_link() -> str:
    """Return the transparency link binding this record to the previous one.

    The value is the SHA-256 of the exact previous JSONL line, folded into the
    signed payload. Because the signature covers it, editing or dropping any
    earlier record breaks every later link - the same tamper-evidence a hand
    -rolled hash chain gives, but inside a signed, standard record.
    """
    rp = records_path()
    if not rp.exists():
        return GENESIS
    last = None
    with rp.open("rb") as fh:
        for line in fh:
            line = line.strip()
            if line:
                last = line
    if last is None:
        return GENESIS
    return "urn:exo:trace:chain:sha256:" + _sha256_hex(last)


def build_record(payload: dict) -> dict:
    """Assemble an unsigned TRACE Trust Record dict from a PostToolUse payload."""
    tool_name = payload.get("tool_name", "unknown")
    transcript = {
        "tool_name": tool_name,
        "tool_input": payload.get("tool_input"),
        "tool_response": payload.get("tool_response"),
    }
    self_bytes = Path(__file__).read_bytes()

    bundle = os.environ.get("EXO_TRACE_POLICY_BUNDLE")
    if bundle and Path(bundle).exists():
        bundle_hash = _digest(Path(bundle).read_bytes())
    else:
        bundle_hash = _digest(b"exo:no-policy-bundle")

    return {
        "eat_profile": EAT_PROFILE,
        "iat": int(time.time()),
        "subject": os.environ.get("EXO_TRACE_SUBJECT", "spiffe://exo.local/agent/exo"),
        "model": {
            "provider": os.environ.get("EXO_TRACE_MODEL_PROVIDER", "anthropic"),
            "model_id": os.environ.get("EXO_TRACE_MODEL_ID", "claude-code"),
        },
        "runtime": {
            "platform": "software-only",
            "measurement": _digest(self_bytes),
        },
        "policy": {
            "bundle_hash": bundle_hash,
            "enforcement_mode": os.environ.get("EXO_TRACE_ENFORCEMENT", "advisory"),
        },
        "data_class": os.environ.get("EXO_TRACE_DATA_CLASS", "personal"),
        "tool_transcript": {
            "hash": _digest(_stable(transcript)),
            "call_count": 1,
        },
        "build_provenance": {
            "slsa_level": 0,
            "builder": "exo-trace-audit",
            "digest": _digest(self_bytes),
        },
        "appraisal": {
            "status": "none",
            "verifier": "urn:exo:trace-audit",
        },
        "transparency": prev_chain_link(),
    }


def record_action(payload: dict) -> None:
    from agentrust_trace import sign_record, validate_json, TrustRecord

    key = load_or_create_key()
    signed = sign_record(build_record(payload), key)

    # Fail loud, not silent: a record that will not validate is worse than none.
    TrustRecord.model_validate(signed)
    validate_json(signed)

    rp = records_path()
    rp.parent.mkdir(parents=True, exist_ok=True)
    with rp.open("ab") as fh:
        fh.write(_stable(signed) + b"\n")


def verify_chain() -> int:
    """Verify every record's signature and the chain links. Returns process code."""
    from agentrust_trace import verify_record

    rp = records_path()
    if not rp.exists():
        print(f"no records at {rp}")
        return 0

    pf = pubkey_file()
    if os.environ.get("TRACE_PUBLIC_JWK"):
        jwk = json.loads(os.environ["TRACE_PUBLIC_JWK"])
    elif pf.exists():
        jwk = json.loads(pf.read_text())
    else:
        print(f"no trusted key: expected {pf} or TRACE_PUBLIC_JWK", file=sys.stderr)
        return 2

    ok = 0
    bad = 0
    prev_link = GENESIS
    with rp.open("rb") as fh:
        lines = [ln.strip() for ln in fh if ln.strip()]

    for i, line in enumerate(lines):
        rec = json.loads(line)
        errs = []
        try:
            # Historical audit: disable the freshness window, pin the trusted key.
            verify_record(rec, jwk, max_age_seconds=None)
        except Exception as exc:  # signature / structural failure
            errs.append(f"signature: {type(exc).__name__}: {exc}".rstrip(": "))
        if rec.get("transparency") != prev_link:
            errs.append(
                f"chain: expected {prev_link!r} got {rec.get('transparency')!r}"
            )
        if errs:
            bad += 1
            print(f"  record {i}: FAIL - " + "; ".join(errs))
        else:
            ok += 1
        prev_link = "urn:exo:trace:chain:sha256:" + _sha256_hex(line)

    print(f"verified {ok} record(s), {bad} failure(s)")
    return 1 if bad else 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Exo TRACE audit hook")
    parser.add_argument("--verify", action="store_true", help="verify the record chain and exit")
    args = parser.parse_args()

    if args.verify:
        return verify_chain()

    # Hook mode: read the PostToolUse payload from stdin, record, never block.
    try:
        raw = sys.stdin.read()
        payload = json.loads(raw) if raw.strip() else {}
    except Exception:
        payload = {}

    try:
        record_action(payload)
    except ModuleNotFoundError:
        print(
            "exo-trace-audit: agentrust-trace not installed - run 'pip install agentrust-trace'",
            file=sys.stderr,
        )
    except Exception as exc:
        # An audit failure must never break the agent's turn; surface, don't block.
        print(f"exo-trace-audit: could not write record: {exc}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
