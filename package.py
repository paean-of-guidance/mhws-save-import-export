import os
import shutil
from dotenv import load_dotenv


def zip_package(source_dir="reframework", output_filename=None):
    load_dotenv()
    version = os.getenv("VERSION", "0.0.0")
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


if __name__ == "__main__":
    zip_package()
