import requests
from typing import Any
from collections import OrderedDict, defaultdict
from pathlib import Path
from csv import reader as CsvReader 
from io import BytesIO, TextIOWrapper
from zipfile import ZipFile, Path as ZipPath
from crowdin_api import CrowdinClient
from time import sleep

def to_sm_code(lang: str) -> str:
    return {
        "en": "en", # English
        "format": "#format", # SM format string
        "da": "da", # Danish
        "de": "de", # German
        "es-es": "es", # Spanish
        "fi": "fi", # Finnish
        "fr": "fr", # French
        "pl": "pl", # Polish
        "pt-br": "pt", # Brazilian Portuguese
        "ru": "ru", # Russian
        "sv-se": "sv", # Swedish
        "zh-cn": "chi", # Chinese (Simplified)
    }[lang.lower()]

class RTDCrowdin(CrowdinClient):
    PROJECT_ID = 631116

class FormatOrderedDict(OrderedDict):
    def __setitem__(self, __key: Any, __value: Any) -> None:
        super().__setitem__(__key, __value)

        # `#format` specifiers must be at the beginning
        if isinstance(__key, str) and __key.startswith("#"):
            self.move_to_end(__key, last=False)

def main(token: str):
    client = RTDCrowdin(token=token)

    # region Get last build ID and/or attempt to trigger a build
    response = client.translations.build_project_translation({"exportApprovedOnly": True})
    build_id = int(response["data"]["id"])
    print(f"Build ID: {build_id}", flush=True)
    # endregion

    # region Wait for build in case a new one needed to be triggered
    checks = 15
    while checks > 0:
        response = client.translations.check_project_build_status(build_id)

        if response["data"]["status"] == "finished":
            datetime = response["data"]["finishedAt"]
            print(f"Build finished on {datetime}", flush=True)
            break

        checks -= 1
        print(f"Waiting on build... ({checks} retries left)", flush=True)

        sleep(1)
    # endregion

    # region Download the built translation files
    response = client.translations.download_project_translations(build_id)
    download_url = response["data"]["url"]
    print(f"Download URL: {download_url}", flush=True)

    response = requests.get(download_url)
    zipped = ZipFile(BytesIO(response.content))

    files = map(lambda name: ZipPath(root=zipped, at=name), zipped.namelist())
    files = filter(ZipPath.is_file, files)
    # endregion

    # region Iterate all strings and convert them to SM-friendly structure
    out = defaultdict(lambda: defaultdict(lambda: FormatOrderedDict()))

    for zipf in files:
        code = to_sm_code(zipf.parent.stem)
        with zipped.open(zipf.at) as f:
            f_textwrapped = TextIOWrapper(f, encoding="utf-8")
            for key, string in CsvReader(f_textwrapped, escapechar="\\"):
                out[zipf.stem][key][code] = string.replace('"', '\\\"')
    # endregion

    # region Write parsed translationas in SM format
    dest_dir = Path.cwd() / "translations"
    dest_dir.mkdir(exist_ok=True)

    for stem, keys in out.items():
        filename = str(dest_dir / stem) + ".txt"
        print(f"Writing to {filename}...", flush=True)

        with open(filename, "w", encoding="utf-8") as f:
            f.write('"Phrases"\n{\n')

            for key, codes in keys.items():
                print(">", key, flush=True)
                f.write(f'\t"{key}"\n\t{{\n')

                for code, string in codes.items():
                    if len(string) > 0: # format may be empty with no vars
                        f.write(f'\t\t"{code}" "{string}"\n')

                f.write('\t}\n')

            f.write('}\n')
    # endregion

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        main(sys.argv[1])
