import json
import time
from pathlib import Path

import requests


SOURCE_PATH = Path("lib/l10n/app_en.arb")
L10N_DIR = Path("lib/l10n")
API_URL = "https://libretranslate.de/translate"
DELAY_SECONDS = 0.5


def load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def translate_text(text: str, target_locale: str) -> str | None:
    payload = {
        "q": text,
        "source": "en",
        "target": target_locale,
        "format": "text",
    }
    try:
        response = requests.post(API_URL, json=payload, timeout=30)
        response.raise_for_status()
        translated = response.json().get("translatedText")
        return translated
    except requests.RequestException as exc:
        print(f"[{target_locale}] Translation failed: {exc}")
    except ValueError:
        print(f"[{target_locale}] Invalid response from translation service")
    return None


def translate_locale(
    locale: str,
    target_path: Path,
    english_data: dict,
) -> None:
    print(f"Processing locale '{locale}'")
    target_data = load_json(target_path)
    updated = False
    missing_keys = []

    for key, value in english_data.items():
        if key.startswith("@"):
            continue
        if not isinstance(value, str):
            continue
        target_value = target_data.get(key)
        if target_value is None or (isinstance(target_value, str) and target_value.strip() == ""):
            missing_keys.append((key, value))

    if not missing_keys:
        print(f"  -> No missing entries for {locale}")
        return

    print(f"  -> Translating {len(missing_keys)} entries")
    for key, english_text in missing_keys:
        time.sleep(DELAY_SECONDS)
        translated = translate_text(english_text, locale)
        if translated:
            target_data[key] = translated
            updated = True
        else:
            print(f"  → [{locale}] Keeping English text for {key}")
            target_data[key] = english_text

        metadata_key = f"@{key}"
        if metadata_key not in target_data:
            target_data[metadata_key] = {"description": ""}
            updated = True

    if updated:
        save_json(target_path, target_data)
        print(f"  → Saved translations for {locale}")
    else:
        print(f"  → No updates written for {locale}")


def main() -> None:
    english_data = load_json(SOURCE_PATH)
    if not english_data:
        print("English source not found or empty")
        return

    locales = sorted(L10N_DIR.glob("app_*.arb"))
    for path in locales:
        if path.name == SOURCE_PATH.name:
            continue
        locale = path.name.split("_", 1)[1].split(".")[0]
        translate_locale(locale, path, english_data)


if __name__ == "__main__":
    main()
