import os
import re
from pathlib import Path
import shutil
import zipfile


def zip_package(source_dir="reframework", output_filename=None):
    # 从modinfo.ini中读取版本号
    modinfo_path = "modinfo.ini"
    with open(modinfo_path, "r") as f:
        content = f.read()
    version = re.search(r"version=(\d+\.\d+\.\d+)*", content).group(1)
    
    if output_filename is None:
        output_filename = f"save_import_export-{version}.zip"
    if not os.path.isdir(source_dir):
        raise FileNotFoundError(f"Directory '{source_dir}' does not exist.")

    dist_dir = "dist"
    if not os.path.exists(dist_dir):
        os.makedirs(dist_dir)
    output_path = os.path.join(dist_dir, output_filename)

    shutil.make_archive(
        base_name=output_path[:-4], format="zip", root_dir=".", base_dir=source_dir
    )

    if os.path.isfile(modinfo_path):
        with zipfile.ZipFile(output_path, "a") as zipf:
            zipf.write(modinfo_path, arcname="modinfo.ini")


if __name__ == "__main__":
    # set workdir
    os.chdir(Path(__file__).parent.parent)

    zip_package()
