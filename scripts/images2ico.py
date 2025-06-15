#!/usr/bin/env python3
"""Pack multiple images into a single .ico file.

The script expects images up to 256x256 in 32-bit RGBA format. Requires
Pillow (``pip3 install Pillow``).
"""

import argparse
import os
import struct
from typing import Iterable

from PIL import Image  # https://python-pillow.org/


def pack(output: str, images: Iterable[str]) -> None:
    """Create an .ico file from multiple images."""
    count = len(list(images))

    with open(output, "wb") as f:
        f.write(struct.pack("HHH", 0, 1, count))
        offset = struct.calcsize("HHH") + struct.calcsize("BBBBHHII") * count

        for img_path in images:
            size = os.stat(img_path).st_size
            img = Image.open(img_path)
            width = 0 if img.width == 256 else img.width
            height = 0 if img.height == 256 else img.height
            f.write(struct.pack("BBBBHHII", width, height, 0, 0, 1, 32, size, offset))
            offset += size

        for img_path in images:
            with open(img_path, "rb") as img_file:
                f.write(img_file.read())


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="pack multiple images into ico file")
    parser.add_argument("-o", "--out", required=True, help="output file")
    parser.add_argument("input", nargs="+", help="input images")
    args = parser.parse_args()
    pack(args.out, args.input)
