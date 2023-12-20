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

    def write_brief(self, out: TextIOWrapper):
        h = "**" if self.is_good else "_"
        anchor = self.name.replace(" ", "-").lower()
        filepath = f"../../blob/master/scripting/rtd/perks/{self.token}.sp"
        out.write(f"{self.index} | {h}[{self.name}](#{anchor}-){h} | {self.brief} | [⧉]({filepath})\n")

    def write_full(self, out: TextIOWrapper):
        sign = "+" if self.is_good else "-"

        run_time = {
            "-1": "Perk is **instant**, no timer is run.",
            "0": "Perk runs for the **default time**.",
        }.get(self.time, f"Perk runs for custom time of **{self.time} seconds**.")

        out.writelines([
            f"# {self.name} [^](#perk-briefs)\n",
            "```diff\n",
            f"{sign} {self.index}. {self.token}\n",
            "```\n",
            "### Description\n",
            self.description.replace(". ", ".\n") + "\n",
            f"### Time\n{run_time}\n",
            self._get_settings(),
            self._get_notes(),
            f"### Tags\n",
            "{`" + self.tags.replace(", ", "`, `") + "`}\n"
        ])

    def _get_settings(self) -> str:
        effective = self.settings

        if len(effective) == 0:
            effective = ["Perk has **no settings**."]

        return "\n".join(["### Settings"] + [*map(str, effective)]) + "\n"

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
            "# Perk Briefs\n",
            "**ID** | **NAME** | **SHORT DESCRIPTION** | **SOURCE**\n",
            "-:|-:|-|:-:\n",
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
