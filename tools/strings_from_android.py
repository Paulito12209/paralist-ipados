# Zusammenhang: Paralist/Resources/Localizable.xcstrings, tools/strings_ios.json, paralist-android app/src/main/res/values*/strings.xml
import json, re, sys, xml.etree.ElementTree as ET
from pathlib import Path

res = Path(sys.argv[1])
out = Path(sys.argv[2])
langs = {"values": "de", "values-en": "en", "values-es": "es", "values-fr": "fr", "values-zh": "zh-Hans", "values-hi": "hi", "values-ar": "ar", "values-bn": "bn"}

def text_of(el):
    raw = "".join(el.itertext())
    raw = raw.strip()
    if len(raw) >= 2 and raw[0] == '"' and raw[-1] == '"':
        raw = raw[1:-1]
    raw = raw.replace("\\n", "\n").replace("\\'", "'").replace('\\"', '"').replace("\\@", "@").replace("\\?", "?")
    raw = re.sub(r"%(\d+\$)?s", lambda m: "%" + (m.group(1) or "") + "@", raw)
    raw = re.sub(r"%(\d+\$)?d", lambda m: "%" + (m.group(1) or "") + "lld", raw)
    return raw

catalog = {"sourceLanguage": "de", "version": "1.0", "strings": {}}
for folder, lang in langs.items():
    tree = ET.parse(res / folder / "strings.xml")
    for el in tree.getroot():
        name = el.get("name")
        if el.get("translatable") == "false" and lang != "de":
            continue
        entry = catalog["strings"].setdefault(name, {"extractionState": "manual", "localizations": {}})
        if el.tag == "string":
            entry["localizations"][lang] = {"stringUnit": {"state": "translated", "value": text_of(el)}}
        elif el.tag == "plurals":
            variants = {}
            for item in el.findall("item"):
                variants[item.get("quantity")] = {"stringUnit": {"state": "translated", "value": text_of(item)}}
            entry["localizations"][lang] = {"variations": {"plural": variants}}
extra = json.loads((Path(__file__).parent / "strings_ios.json").read_text(encoding="utf-8"))
for name, values in extra.items():
    unit = lambda v: {"stringUnit": {"state": "translated", "value": v}}
    catalog["strings"][name] = {"extractionState": "manual", "localizations": {lang: {"variations": {"plural": {q: unit(v) for q, v in value.items()}}} if isinstance(value, dict) else unit(value) for lang, value in values.items()}}
out.write_text(json.dumps(catalog, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(len(catalog["strings"]), "keys")
