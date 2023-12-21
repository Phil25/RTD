from operator import attrgetter
import vdf
from io import TextIOWrapper
from itertools import starmap
from typing import Mapping, NamedTuple
from pathlib import Path

class PerkDocs(NamedTuple):
    class _Setting(NamedTuple):
        name: str
        value: str
        default: str
        description: str

        def __str__(self) -> str:
            if self.value.startswith("<"):
                suffix = f" _(default: `{self.default}`)_"

            else:
                suffix = " _(default)_" if self.value == self.default else ""

            return f'* `"{self.name}" "{self.value}"` — {self.description}{suffix}'

    index: int
    is_good: bool
    name: str
    token: str
    brief: str
    description: str
    time: str
    tags: str
    settings: list[_Setting]
    notes: list[str]

    @property
    def circle(self):
        return "🟢" if self.is_good else "🟣"

    @property
    def square(self):
        return "🟩" if self.is_good else "🟪"

    @property
    def filepath(self):
        return f"../../blob/master/scripting/rtd/perks/{self.token}.sp"

    @property
    def header(self):
        return f"# {self.square} {self.name} [^](#perk-briefs)"

    @property
    def anchor(self):
        escaped = self.name.replace(" ", "-").lower()
        return f"#-{escaped}-"

    def write_brief(self, out: TextIOWrapper):
        out.write(f'{self.index} | **[{self.name}]({self.anchor} "Navigate to {self.name}")** | {self.circle} | {self.brief}\n')

    def write_full(self, out: TextIOWrapper):
        run_time = {
            "-1": "Perk is **instant**, no timer is run.",
            "0": "Perk runs for the **default time**.",
        }.get(self.time, f"Perk runs for custom time of **{self.time} seconds**.")

        settings_brief = "_none_"
        if len(self.settings) > 0:
            settings_brief = "{`" + "`, `".join(set(map(attrgetter("name"), self.settings))) + "`}"

        tags = "{`" + self.tags.replace(", ", "`, `") + "`}"

        out.writelines([
            f"{self.header}\n",
            "**ID** | **TOKEN** | **SETTINGS** | **TAGS** | **SOURCE**\n-:|:-:|:-:|:-:|:-:\n",
            f'{self.index} | `{self.token}` | {settings_brief} | {tags} | [{self.token}.sp]({self.filepath} "View source code of {self.name}")\n',
            "### Description\n",
            self.description.replace(". ", ".\n") + "\n",
            f"### Time\n{run_time}\n",
            self._get_settings(),
            self._get_notes(),
        ])

    def _get_settings(self) -> str:
        if len(self.settings) == 0:
            return ""

        return "\n".join(["### Settings"] + [*map(str, self.settings)]) + "\n"

    def _get_notes(self) -> str:
        if len(self.notes) == 0:
            return ""

        return "### Additional notes\n* " + "\n* ".join(self.notes) + "\n"

    @classmethod
    def from_config(cls, index: int, perk: Mapping):
        docs = perk["docs"]

        settings = []
        if "settings" in docs:
            for name, values in docs["settings"].items():
                for value, description in values.items():
                    default = perk["settings"][name]
                    settings.append(cls._Setting(name, value, default, description))

        extra_notes = []

        if perk.get("no_medieval", "0") != "0":
            extra_notes.append("Perk is disabled in Medieval Mode.")

        if (limit_team := perk.get("limit_team", "0")) != "0":
            plural = "use" if limit_team == "1" else "uses"
            extra_notes.append(f"Perk is limited to {limit_team} active {plural} per team.")

        if (limit_global := perk.get("limit_global", "0")) != "0":
            plural = "use" if limit_global == "1" else "uses"
            extra_notes.append(f"Perk is limited to {limit_global} active {plural}.")

        return cls(
            index,
            perk["good"] == "1",
            perk["name"],
            perk["token"],
            docs["brief"],
            docs["description"],
            perk["time"],
            perk["tags"],
            settings,
            extra_notes + docs["notes"].split(";") if "notes" in docs else []
        )

def main(output: Path):
    with open(Path.cwd() / "configs" / "rtd2_perks.default.cfg", encoding="utf-8") as f:
        perk_ids = vdf.load(f)["Effects"]

    perks_docs = list(starmap(PerkDocs.from_config, perk_ids.items()))

    with open(output, "w", encoding="utf-8") as out:
        out.writelines([
            "> Automatically generated from [rtd2_perks.default.cfg](../../blob/master/configs/rtd2_perks.default.cfg). Please edit that file for any updates.\n",
            "# Perk Briefs\n",
            "**ID** | **NAME** | | **SHORT DESCRIPTION**\n",
            "-:|-:|-|-\n",
        ])

        for doc in perks_docs:
            doc.write_brief(out)

        out.write("\n***\n")

        for doc in perks_docs:
            out.write("***\n\n")
            doc.write_full(out)
            out.write("\n")

    print(f"Written to \"{output}\"", flush=True)

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        main((Path.cwd() / sys.argv[1]).with_suffix(".md"))
