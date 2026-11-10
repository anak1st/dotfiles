#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把本机 $HOME 里的 dotfiles 同步回仓库。

方向与 install.py 相反，本质上是一个“回收”动作：把日常使用中改过的配置
收回仓库，方便 commit。只处理 dotfiles.json 里声明的路径，仓库里其他文件
不会被误覆盖。

和 install.py 一样按 app 选择：`python3 sync.py dms` 只回收 DMS 的条目，
不带参数则回收当前平台的全部 app。

所有面向用户的输出与报错都使用英文；代码注释使用中文。
"""

from __future__ import annotations

import argparse
import os
import shutil
import sys
from pathlib import Path

# sync.py 需要复用 install.py 里的清单解析和比较逻辑。把脚本目录插到
# sys.path 最前面，保证无论从哪个工作目录调用 `python3 sync.py`，
# 导入到的都是仓库里这一份，而不是别处的同名模块。
sys.path.insert(0, str(Path(__file__).resolve().parent))

from install import (  # noqa: E402  (import 必须在 sys.path 调整之后)
    IGNORED_NAMES,
    MANIFEST,
    REPO,
    detect_os,
    display,
    load_manifest,
    print_apps,
    same_file,
    select_entries,
)


def walk_files(root: Path) -> list:
    """递归列出 root 下的普通文件，返回 [(绝对路径, 相对路径)]。

    和 install.expand() 的区别：那边从仓库出发，这边从 home 出发。
    过滤规则保持一致（忽略 .DS_Store/.git/__pycache__），符号链接跳过。
    """
    files = []
    for current, dirs, names in os.walk(root):
        # 原地过滤 dirs，os.walk 就不会进入被忽略的目录。
        dirs[:] = sorted(d for d in dirs if d not in IGNORED_NAMES)
        for name in sorted(names):
            if name in IGNORED_NAMES:
                continue
            full = Path(current) / name
            if full.is_symlink() or not full.is_file():
                continue
            files.append((full, full.relative_to(root).as_posix()))
    return files


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Sync dotfiles from $HOME into this repository")
    parser.add_argument(
        "apps",
        nargs="*",
        metavar="APP",
        help="apps to handle (see --list); omit to handle all apps on this platform",
    )
    parser.add_argument("--repo", type=Path, default=REPO, help="dotfiles repository path")
    parser.add_argument(
        "--home", type=Path, default=Path.home(), help="source root directory (default: $HOME)"
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
        "--prune",
        action="store_true",
        help="delete repository files that no longer exist under $HOME",
    )
    args = parser.parse_args(argv)

    repo = args.repo.resolve()
    home = args.home.expanduser().resolve()
    os_name = args.os_name or detect_os()

    manifest = load_manifest(repo)
    if args.list_apps:
        print(f"apps in {repo / MANIFEST}  (os: {os_name})")
        print_apps(manifest, os_name)
        return 0

    # 只处理点名的 app（都没点名就是全部）、且适用于当前平台的条目。
    entries = select_entries(manifest, args.apps, os_name)

    # 注意方向：home 是“源”，仓库是“目标”。
    scope = " ".join(args.apps) if args.apps else "all"
    print(
        f"sync <- {home}  (os: {os_name}, apps: {scope}"
        f"{', dry-run' if args.dry_run else ''})"
    )

    # 统计本轮结果；dry-run 时只累计不落盘，数字即“将会发生什么”。
    counts = {"add": 0, "update": 0, "same": 0, "prune": 0}
    for entry in entries:
        live = home / entry.target
        stored = repo / entry.source

        # 本机没有这个文件/目录：不凭空创建，也不删仓库里的内容，
        # 除非用户显式 --prune（删除是破坏性操作，必须显式要求）。
        if not live.exists():
            print(f"[skip] {display(live, home)} not found")
            continue

        # 清单允许 target 是单个文件，也允许是目录，这里统一成文件列表。
        if live.is_file():
            pairs = [(live, "")]
        else:
            pairs = walk_files(live)

        # expected 记录本机实际存在的文件，--prune 时用来判断仓库里哪些是多余的。
        expected = set()
        for live_file, rel in pairs:
            dest = stored if not rel else stored / rel
            expected.add(rel)

            if same_file(live_file, dest):
                counts["same"] += 1
                continue

            action = "update" if dest.exists() else "add"
            target_label = f"{entry.source}/{rel}" if rel else entry.source
            print(f"[{action}] {display(live_file, home)} -> {target_label}")
            if not args.dry_run:
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(live_file, dest)
            counts[action] += 1

        # 可选清理：仓库里存在、但本机已经删掉的文件。
        if args.prune and stored.is_dir():
            for stored_file, rel in walk_files(stored):
                if rel in expected:
                    continue
                print(f"[prune] {entry.source}/{rel}")
                if not args.dry_run:
                    stored_file.unlink()
                counts["prune"] += 1

            # 删完文件后顺手清掉空目录，避免仓库里留下一堆空壳。
            # topdown=False 保证先处理子目录，再处理父目录。
            if not args.dry_run:
                for current, _dirs, _names in os.walk(stored, topdown=False):
                    if Path(current) != stored:
                        try:
                            os.rmdir(current)
                        except OSError:
                            # 目录非空（还留着别的文件）时 rmdir 会失败，忽略即可。
                            pass

    print(
        "summary: {add} added, {update} updated, {same} unchanged, {prune} pruned".format(**counts),
        flush=True,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
