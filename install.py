#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把仓库里的 dotfiles 安装到 $HOME。

dotfiles.json 是唯一的事实来源：每条 entry 把仓库内的路径映射到相对 $HOME
的路径，并可限定适用平台。清单之外的文件一律不复制，所以像本脚本这样的
工具文件可以放心放在仓库根目录，而不会跟着装进 home。

每条 entry 还带一个 app 字段（fish、nvim 之类），命令行可以只装其中几个：
`python3 install.py fish nvim`；不带参数时安装当前平台的全部 app。

所有面向用户的输出与报错都使用英文；代码注释使用中文。
"""

from __future__ import annotations

import argparse
import filecmp
import json
import os
import platform
import re
import shutil
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

# 仓库根目录 = 脚本所在目录。之所以用 resolve()，是为了在通过符号链接或
# 从其他工作目录调用脚本时，仍然能得到真实的仓库位置。
REPO = Path(__file__).resolve().parent

# 清单文件名。放在仓库根目录，和脚本平级，方便 `python3 install.py` 直接跑。
MANIFEST = "dotfiles.json"

# 遍历目录时统一忽略的名字：
#   .DS_Store   macOS 的目录元数据，没有任何同步价值；
#   .git        git 内部目录，绝不能被当成 dotfile；
#   __pycache__ sync.py 导入 install.py 时 Python 可能生成的字节码缓存。
IGNORED_NAMES = {".DS_Store", ".git", "__pycache__"}

# 清单里 os 字段缺省时视为两个平台都适用。
DEFAULT_OS = ["macos", "linux"]

# app 名字要能直接当命令行参数用，所以限制成不含空白和路径分隔符的短标识符。
APP_NAME_RE = re.compile(r"^[A-Za-z0-9_.-]+$")


@dataclass
class Entry:
    """一条清单项。

    app: 所属软件名（fish、nvim 等），命令行按它选择要安装/同步哪几个；
    source: 仓库内路径，可以是单个文件，也可以是目录；
    target: 相对 $HOME 的目标路径，同样可以是文件或目录；
    os_list: 该条目适用的平台列表，例如 ["macos"]。
    """

    app: str
    source: str
    target: str
    os_list: list


def detect_os() -> str:
    """把 platform.system() 映射成清单里使用的平台名。

    只接受 Darwin / Linux；其他系统（Windows 等）没有对应的清单约定，
    直接报错让用户显式传 --os，避免脚本猜错平台后写坏 home。
    """
    system = platform.system()
    if system == "Darwin":
        return "macos"
    if system == "Linux":
        return "linux"
    raise SystemExit(f"Cannot detect OS ({system!r}); pass --os macos|linux")


def load_manifest(repo: Path) -> list:
    """读取并校验 dotfiles.json，返回 Entry 列表。

    校验点：
      1. 清单文件必须存在；
      2. 每条 entry 必须同时有 app、source 和 target；
      3. app 必须是简短的标识符（能直接当命令行参数传）；
      4. source/target 必须是相对路径，且不能包含 ".."，否则可能逃出仓库或 home；
      5. os 缺省时使用 DEFAULT_OS。
    """
    path = repo / MANIFEST
    if not path.is_file():
        raise SystemExit(f"Manifest not found: {path}")

    data = json.loads(path.read_text(encoding="utf-8"))

    entries = []
    for index, raw in enumerate(data.get("entries", [])):
        try:
            app = str(raw["app"])
            source = str(raw["source"])
            target = str(raw["target"])
        except KeyError as exc:
            raise SystemExit(f"Entry #{index + 1} is missing field: {exc}")

        # app 会出现在命令行里，脏字符只会换来难懂的报错，不如在读取时就拒绝。
        if not APP_NAME_RE.match(app):
            raise SystemExit(
                f"Entry #{index + 1}: app must match {APP_NAME_RE.pattern}, got {app!r}"
            )

        # 只允许相对路径：绝对路径会让 "source" 直接指向仓库外的文件，
        # ".." 则可能让 target 写到 $HOME 之外，都属于危险输入。
        for name, value in (("source", source), ("target", target)):
            candidate = Path(value)
            if candidate.is_absolute() or ".." in candidate.parts:
                raise SystemExit(
                    f"Entry #{index + 1}: {name} must be a relative path, got {value!r}"
                )

        entries.append(
            Entry(
                app=app,
                source=source,
                target=target,
                os_list=raw.get("os") or list(DEFAULT_OS),
            )
        )
    return entries


def app_names(entries: list) -> list:
    """返回清单里出现过的 app 名，按字母序排序。"""
    return sorted({entry.app for entry in entries})


def select_entries(entries: list, apps: list, os_name: str) -> list:
    """按 app 和平台筛选清单条目。

    apps 为空表示全选。未知 app 直接报错并列出可用名字，避免手滑打错后
    静默什么都没装；显式点名、但在当前平台没有条目的 app 同样报错，
    否则 `install.py ghostty` 在 Linux 上会看起来“成功”却什么也没做。
    """
    known = app_names(entries)
    unknown = [name for name in apps if name not in known]
    if unknown:
        raise SystemExit(
            "Unknown app(s): {unknown}; known apps: {known}".format(
                unknown=", ".join(unknown), known=", ".join(known)
            )
        )

    wanted = [entry for entry in entries if not apps or entry.app in apps]
    selected = [entry for entry in wanted if os_name in entry.os_list]

    unavailable = [
        name
        for name in apps
        if not any(entry.app == name and os_name in entry.os_list for entry in wanted)
    ]
    if unavailable:
        raise SystemExit(
            "App(s) not available on {os_name}: {apps}".format(
                os_name=os_name, apps=", ".join(unavailable)
            )
        )
    if not selected:
        raise SystemExit(f"No manifest entries for platform {os_name!r}")
    return selected


def print_apps(entries: list, os_name: str) -> None:
    """打印清单里的 app 一览，供 `--list` 使用。

    计数只算当前平台适用的条目，所以能一眼看出某个 app 在这台机器上
    到底会装几个文件；括号里是它声明支持的全部平台。
    """
    for name in app_names(entries):
        own = [entry for entry in entries if entry.app == name]
        on_platform = [entry for entry in own if os_name in entry.os_list]
        platforms = sorted({platform_name for entry in own for platform_name in entry.os_list})
        note = "" if on_platform else "  (not on this platform)"
        print(f"{name:<10} {len(on_platform):>2} file(s)  [{','.join(platforms)}]{note}")


def expand(entry: Entry, repo: Path) -> list:
    """把一条 entry 展开成 [(源文件, 相对 entry.target 的路径)]。

    文件条目：rel 为空串，表示目标就是 entry.target 本身；
    目录条目：递归展开，rel 是文件相对目录根的路径，用于拼出目标路径。
    符号链接会被跳过（本仓库目前不存放链接，跳过比跟随更安全）。
    """
    src = repo / entry.source
    if src.is_file():
        return [(src, "")]

    if not src.is_dir():
        raise SystemExit(f"Source does not exist: {src}")

    files = []
    for root, dirs, names in os.walk(src):
        # 原地过滤 dirs，os.walk 就不会再进入被忽略的目录。
        dirs[:] = sorted(d for d in dirs if d not in IGNORED_NAMES)
        for name in sorted(names):
            if name in IGNORED_NAMES:
                continue
            full = Path(root) / name
            if full.is_symlink() or not full.is_file():
                continue
            files.append((full, full.relative_to(src).as_posix()))
    return files


def same_file(a: Path, b: Path) -> bool:
    """内容相同才算“无需处理”。

    用 shallow=False 做逐字节比较，而不是比 mtime/size：复制、git checkout
    都会改变 mtime，却不代表内容真的变了；比内容可以避免无谓的覆盖和备份。
    """
    return b.is_file() and filecmp.cmp(a, b, shallow=False)


def display(path: Path, home: Path) -> str:
    """把绝对路径格式化成 ~/... 形式，输出更短也更好认。"""
    try:
        rel = path.relative_to(home)
    except ValueError:
        return str(path)
    return "~/" + rel.as_posix()


def backup_path(target: Path, home: Path, backup_root: Path, stamp: str) -> Path:
    """计算备份路径，保留相对 home 的目录结构，避免同名文件互相覆盖。"""
    try:
        rel = target.relative_to(home)
    except ValueError:
        rel = Path(target.name)
    return backup_root / stamp / rel


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Install dotfiles into $HOME")
    parser.add_argument(
        "apps",
        nargs="*",
        metavar="APP",
        help="apps to handle (see --list); omit to handle all apps on this platform",
    )
    parser.add_argument("--repo", type=Path, default=REPO, help="dotfiles repository path")
    parser.add_argument(
        "--home", type=Path, default=Path.home(), help="target root directory (default: $HOME)"
    )
    parser.add_argument(
        "--os",
        "--target",
        dest="os_name",
        choices=["macos", "linux"],
        help="force platform instead of auto-detecting it",
    )
    parser.add_argument("--dry-run", action="store_true", help="print the plan without writing")
    parser.add_argument(
        "--list",
        dest="list_apps",
        action="store_true",
        help="list apps in the manifest and exit",
    )
    parser.add_argument(
        "--no-backup", action="store_true", help="overwrite files without backing them up first"
    )
    parser.add_argument(
        "--backup-dir",
        type=Path,
        default=None,
        help="backup directory (default: <home>/.dotfiles-backup)",
    )
    args = parser.parse_args(argv)

    # resolve() 统一相对路径和符号链接，后面做目录包含判断时更可靠。
    repo = args.repo.resolve()
    home = args.home.expanduser().resolve()
    os_name = args.os_name or detect_os()

    # 先解析清单：--list 不需要写任何东西，也不该因为 home 里缺文件而报错。
    manifest = load_manifest(repo)
    if args.list_apps:
        print(f"apps in {repo / MANIFEST}  (os: {os_name})")
        print_apps(manifest, os_name)
        return 0

    # 一次运行只用一个时间戳，同批备份都落在同一个目录里，方便回滚。
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_root = args.backup_dir or (home / ".dotfiles-backup")

    # 按 app 和平台过滤，然后逐条展开。这里不做“合并”之类的操作，保持方向单一：
    # 永远只从仓库流向 home。
    entries = select_entries(manifest, args.apps, os_name)
    scope = " ".join(args.apps) if args.apps else "all"
    print(
        f"install -> {home}  (os: {os_name}, apps: {scope}"
        f"{', dry-run' if args.dry_run else ''})"
    )

    # 统计各类结果，最后一行汇总；dry-run 时数字代表“如果真跑会怎样”。
    counts = {"new": 0, "update": 0, "same": 0, "backup": 0}
    for entry in entries:
        for src_file, rel in expand(entry, repo):
            dest = home / entry.target
            if rel:
                dest = dest / rel

            # 内容相同：完全不动，避免刷新 mtime、触发备份。
            if same_file(src_file, dest):
                counts["same"] += 1
                continue

            action = "update" if dest.exists() else "new"

            # 先备份再覆盖。备份失败会直接抛错终止，宁可中断也不静默丢数据。
            if dest.exists() and not args.no_backup:
                saved = backup_path(dest, home, backup_root, stamp)
                print(f"[backup] {display(dest, home)} -> {saved}")
                if not args.dry_run:
                    saved.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(dest, saved)
                counts["backup"] += 1

            print(f"[{action}] {display(dest, home)}")
            if not args.dry_run:
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src_file, dest)
            counts[action] += 1

    print(
        "summary: {new} new, {update} updated, {same} unchanged, {backup} backed up".format(**counts),
        flush=True,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
