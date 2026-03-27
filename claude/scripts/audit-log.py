#!/usr/bin/env python3
# ~/.claude/hooks/audit-log.py
"""Bashコマンドの実行履歴を記録するhook。"""
import json
import sys
from datetime import datetime, timezone
from pathlib import Path


def main() -> None:
    """stdinからコマンドを読み取り、ログファイルに追記する。

    Returns:
        なし。常にexit 0で通過。
    """
    data = json.load(sys.stdin)
    command = data.get("tool_input", {}).get("command", "")

    log_path = Path.home() / ".claude" / "audit.log"
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    with open(log_path, "a") as f:
        f.write(f"{timestamp} CMD: {command}\n")

    sys.exit(0)


if __name__ == "__main__":
    main()