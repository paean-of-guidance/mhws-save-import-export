import os
import sys
from pathlib import Path
from dotenv import load_dotenv


def create_links(src_dir, dst_dir):
    if not os.path.isdir(src_dir):
        print(f"Source directory '{src_dir}' does not exist.")
        return
    if not os.path.isdir(dst_dir):
        os.makedirs(dst_dir, exist_ok=True)

    for filename in os.listdir(src_dir):
        src_file = os.path.join(src_dir, filename)
        dst_file = os.path.join(dst_dir, filename)
        if os.path.isdir(src_file):
            # Recursively create subdirectory and links
            if not os.path.exists(dst_file):
                os.makedirs(dst_file, exist_ok=True)
            create_links(src_file, dst_file)
            continue
        if os.path.isfile(src_file):
            if os.path.exists(dst_file):
                print(f"Target file '{dst_file}' already exists. Skipping.")
                continue
            try:
                os.link(src_file, dst_file)
                print(f"Created link: {dst_file} -> {src_file}")
            except Exception as e:
                print(f"Failed to create link for '{src_file}': {e}")


if __name__ == "__main__":
    # set workdir
    os.chdir(Path(__file__).parent.parent)

    src = "reframework/autorun"
    load_dotenv()
    dst = os.getenv("MKLINK_DST")
    if not dst:
        print("Destination directory not specified in environment variables.")
        sys.exit(1)

    create_links(src, dst)
