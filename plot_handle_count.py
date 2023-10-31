from collections import Counter
from pathlib import Path
from typing import NamedTuple

class Entry(NamedTuple):
    timestamp: str
    counter: Counter

    @classmethod
    def from_file(cls, path: Path):
        counter = Counter()

        with open(path, "r") as f:
            for line in f.readlines():
                parts = line.split()
                if len(parts) > 2 and parts[1] == "rtd.smx":
                    counter[parts[2]] += 1

        return cls(path.stem, counter)


def main(dump_dir: Path):
    if not dump_dir.is_absolute():
        dump_dir = Path.cwd() /  dump_dir

    assert dump_dir.is_dir()

    entries = map(Entry.from_file, dump_dir.iterdir())
    for e in entries:
        print(e.timestamp, "->", e.counter);

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        main(Path(sys.argv[1]))
