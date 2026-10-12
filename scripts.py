"""Read the supplied files, write a report, print it, and exit."""

import re
import socket
from collections import Counter
from pathlib import Path


DATA_DIR = Path("/home/data")
INPUT_FILES = ("IF.txt", "AlwaysRememberUsThisWay.txt")


def words(text, expand_contractions=False):
    """Ignore punctuation/case; optionally expand common English contractions."""
    text = text.lower().replace("\u2019", "'").replace("\u2018", "'")
    if expand_contractions:
        for contraction, expansion in {"can't": "can not", "won't": "will not", "shan't": "shall not"}.items():
            text = re.sub(r"\b" + re.escape(contraction) + r"\b", expansion, text)
        for ending, expansion in (
            ("n't", " not"), ("'m", " am"), ("'re", " are"),
            ("'ve", " have"), ("'ll", " will"), ("'d", " would"), ("'s", " is"),
        ):
            text = re.sub(re.escape(ending) + r"\b", expansion, text)
    return re.findall(r"[a-z]+(?:'[a-z]+)*", text)


def top_three(tokens):
    # Alphabetical tie-breaking makes the report reproducible.
    return sorted(Counter(tokens).items(), key=lambda item: (-item[1], item[0]))[:3]


def create_report(data_dir=DATA_DIR):
    texts = {name: (data_dir / name).read_text(encoding="utf-8-sig") for name in INPUT_FILES}
    # Whitespace totals include titles and count a contraction once.
    counts = {name: len(text.split()) for name, text in texts.items()}
    lines = ["PROJECT 3: DOCKER", "", "Total words (whitespace-separated, including titles):"]
    lines.extend(f"{name}: {count}" for name, count in counts.items())
    lines.append(f"Grand total: {sum(counts.values())}")
    for name in INPUT_FILES:
        expand = name == "AlwaysRememberUsThisWay.txt"
        tokens = words(texts[name], expand_contractions=expand)
        label = " (contractions expanded)" if expand else ""
        lines.extend(["", f"Top 3 most frequent words in {name}{label}:"])
        lines.extend(f"{word}: {count}" for word, count in top_three(tokens))
        if expand:
            lines.append(f"Words after contraction expansion and punctuation removal: {len(tokens)}")
    lines.extend(["", f"IP address (container): {socket.gethostbyname(socket.gethostname())}"])
    try:
        host_ip = socket.gethostbyname("host.docker.internal")
    except socket.gaierror:
        host_ip = "unavailable on this runtime"
    lines.append(f"Docker host gateway IP (host.docker.internal): {host_ip}")
    return "\n".join(lines) + "\n"


def main():
    report = create_report()
    output_path = DATA_DIR / "output" / "result.txt"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(report, encoding="utf-8")
    print(output_path.read_text(encoding="utf-8"), end="", flush=True)


if __name__ == "__main__":
    main()
