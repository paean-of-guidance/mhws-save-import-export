import os
import json


def main():
    with open("save_export_old.json", "r", encoding="utf-8") as f:
        data_old = json.load(f)
    with open("save_export_5.28.json", "r", encoding="utf-8") as f:
        data_new = json.load(f)

    # keys diff
    def find_key_diff(d1, d2, path=""):
        if isinstance(d1, dict) and isinstance(d2, dict):
            keys1 = set(d1.keys())
            keys2 = set(d2.keys())
            for key in keys1 - keys2:
                print(f"缺失于新文件: {path + '.' if path else ''}{key}")
            for key in keys2 - keys1:
                print(f"新增于新文件: {path + '.' if path else ''}{key}")
            for key in keys1 & keys2:
                find_key_diff(d1[key], d2[key], path + "." + key if path else key)
        # Optionally handle lists of dicts, but skip for now

    find_key_diff(data_old, data_new)


main()
