"""Build the three mirrored late-game puzzles from their authored SpriteKit scenes.

The source puzzles provide the support geometry and physics bodies. Mirroring
positions around the scene center gives the panda a new route to the bed while
preserving the source node types and dimensions.
"""

from pathlib import Path
import plistlib
import re


SCENE_DIR = Path(__file__).resolve().parents[1] / "Panda Nap" / "Scene"
REMIXES = {11: 6, 12: 7, 13: 9}
SCENE_WIDTH = 2048
POINT = re.compile(r"^\{(-?\d+(?:\.\d+)?), (-?\d+(?:\.\d+)?)\}$")


def make_remix(number: int, source: int) -> None:
    with (SCENE_DIR / f"Level{source}.sks").open("rb") as scene_file:
        archive = plistlib.load(scene_file)

    objects = archive["$objects"]

    def item(uid):
        return objects[uid.data]

    root = item(archive["$top"]["root"])
    sprites = item(root["_children"])["NS.objects"]
    mirrored = 0
    for sprite_uid in sprites:
        sprite = item(sprite_uid)
        if item(sprite["_name"]) in ("background", "bed"):
            continue
        point = item(sprite["_position"])
        point_uid = point["NS.pointval"]
        match = POINT.fullmatch(item(point_uid))
        if match is None:
            raise ValueError(f"Unexpected position in Level{source}: {item(point_uid)}")
        x, y = map(float, match.groups())
        objects[point_uid.data] = f"{{{SCENE_WIDTH - x}, {y}}}"
        mirrored += 1

    if mirrored < 4:
        raise ValueError(f"Level{source} has too few puzzle nodes")
    with (SCENE_DIR / f"Level{number}.sks").open("wb") as scene_file:
        plistlib.dump(archive, scene_file, fmt=plistlib.FMT_BINARY)


if __name__ == "__main__":
    for number, source in REMIXES.items():
        make_remix(number, source)
