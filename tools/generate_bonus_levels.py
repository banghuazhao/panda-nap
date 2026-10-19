"""Author three bonus puzzles from the game's existing SpriteKit sprite templates.

Run this from any directory with Python 3. The files are keyed archives, so every
new node imports a private graph of archive references. This is important for
physics bodies and NSValue positions: changing one support must never resize or
move another. The scene physics-body registry is rebuilt and unreachable editor
objects are removed before the binary archive is saved.

The centered load paths deliberately leave a generous vertical chute to the bed.
No new physics rules, assets, or custom classes are needed. The solution manifest
records scene-space taps for an actual SpriteKit simulation / manual playtest.
"""

from __future__ import annotations

import copy
import json
from pathlib import Path
import plistlib
import re


ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = ROOT / "Panda Nap" / "Scene"
UID = plistlib.UID
RECT = re.compile(
    r"^\{\{[-\d.]+, [-\d.]+\}, \{([-\d.]+), ([-\d.]+)\}\}$"
)

# These source nodes provide their existing texture, custom-class metadata,
# collision masks, damping, density, restitution, and editor archive structure.
TEMPLATES = {
    "panda": (1, 238),
    "wood_post": (1, 93),
    "wood_deck": (1, 154),
    "wood_square": (2, 121),
    "stone_post": (10, 152),
    "stone_deck": (10, 180),
}


def point_string(x: float, y: float) -> str:
    return f"{{{x:g}, {y:g}}}"


def load_scene(number: int) -> dict:
    with (SCENE_DIR / f"Level{number}.sks").open("rb") as stream:
        return plistlib.load(stream)


class SceneBuilder:
    def __init__(self) -> None:
        self.archive = load_scene(1)
        self.objects = self.archive["$objects"]
        self.root = self.get(self.archive["$top"]["root"])
        # Keep the authored background and bed, with their existing positioning.
        self.children = self.get(self.root["_children"])["NS.objects"][:2]
        self.authored = []

    def get(self, uid: UID):
        return self.objects[uid.data]

    def append(self, value) -> UID:
        uid = UID(len(self.objects))
        self.objects.append(value)
        return uid

    def import_template(self, template: str) -> UID:
        source_number, source_index = TEMPLATES[template]
        source = load_scene(source_number)["$objects"]
        imported = {0: UID(0)}

        def import_value(value):
            if isinstance(value, UID):
                if value.data not in imported:
                    destination = self.append(None)
                    imported[value.data] = destination
                    self.objects[destination.data] = import_value(source[value.data])
                return imported[value.data]
            if isinstance(value, dict):
                return {key: import_value(item) for key, item in value.items()}
            if isinstance(value, list):
                return [import_value(item) for item in value]
            return copy.deepcopy(value)

        return import_value(UID(source_index))

    def add(self, template: str, name: str, x: float, y: float,
            x_scale: float | None = None, y_scale: float | None = None) -> None:
        node_uid = self.import_template(template)
        node = self.get(node_uid)
        bounds = self.get(node["_bounds"])
        bounds_match = RECT.fullmatch(self.get(bounds["NS.rectval"]))
        if bounds_match is None:
            raise ValueError(f"Unexpected bounds for {template}")
        width, height = map(float, bounds_match.groups())
        original_x_scale = self.get(node["_xScale"])
        original_y_scale = self.get(node["_yScale"])
        x_scale = original_x_scale if x_scale is None else x_scale
        y_scale = original_y_scale if y_scale is None else y_scale

        self.get(node["_position"])["NS.pointval"] = self.append(point_string(x, y))
        bounds["NS.rectval"] = self.append(
            "{" + point_string(x - width / 2, y - height / 2)
            + ", " + point_string(width, height) + "}"
        )
        node["_name"] = self.append(name)
        node["_xScale"] = self.append(x_scale)
        node["_yScale"] = self.append(y_scale)

        body = self.get(node["_PKPhysicsBody"])
        if isinstance(body, dict) and "_size" in body:
            # SpriteKit's editor stores a rectangle body's scaled dimensions.
            # Keep the same convention as the source scene when authoring a size.
            body["_size"] = self.append(point_string(width * x_scale, height * y_scale))
        self.children.append(node_uid)
        self.authored.append({
            "name": name, "template": template, "position": [x, y],
            "frame_size": [width * x_scale, height * y_scale],
        })

    def finish(self, number: int) -> None:
        self.get(self.root["_children"])["NS.objects"] = self.children
        world = self.get(self.root["_physicsWorld"])
        body_uids = [self.root["_scenePinBody"], self.root["_PKPhysicsBody"]]
        for uid in self.children:
            body_uid = self.get(uid)["_PKPhysicsBody"]
            if body_uid.data != 0:
                body_uids.append(body_uid)
        self.get(world["_bodies"])["NS.objects"] = body_uids
        self.archive = compact_archive(self.archive)
        validate_scene(self.archive, number)
        with (SCENE_DIR / f"Level{number}.sks").open("wb") as stream:
            plistlib.dump(self.archive, stream, fmt=plistlib.FMT_BINARY, sort_keys=True)


def compact_archive(archive: dict) -> dict:
    """Retain all and only objects reachable from the keyed archive's top values."""
    source = archive["$objects"]
    objects = ["$null"]
    imported = {0: UID(0)}

    def move(value):
        if isinstance(value, UID):
            if value.data not in imported:
                uid = UID(len(objects))
                imported[value.data] = uid
                objects.append(None)
                objects[uid.data] = move(source[value.data])
            return imported[value.data]
        if isinstance(value, dict):
            return {key: move(item) for key, item in value.items()}
        if isinstance(value, list):
            return [move(item) for item in value]
        return copy.deepcopy(value)

    top = move(archive["$top"])
    return {**archive, "$objects": objects, "$top": top}


def validate_scene(archive: dict, number: int) -> None:
    objects = archive["$objects"]
    get = lambda uid: objects[uid.data]
    root = get(archive["$top"]["root"])
    children = get(root["_children"])["NS.objects"]
    names = [get(get(uid)["_name"]) for uid in children]
    assert len(names) == len(set(names)), (number, names)
    assert names.count("panda") == names.count("bed") == 1
    position_ids = [get(uid)["_position"].data for uid in children]
    assert len(position_ids) == len(set(position_ids)), "Shared node positions"
    bodies = [get(uid)["_PKPhysicsBody"] for uid in children
              if get(uid)["_PKPhysicsBody"].data != 0]
    assert len({uid.data for uid in bodies}) == len(bodies), "Shared physics bodies"
    size_ids = [get(uid)["_size"].data for uid in bodies]
    assert len(size_ids) == len(set(size_ids)), "Shared physics-body size values"
    registry = get(get(root["_physicsWorld"])["_bodies"])["NS.objects"]
    assert {uid.data for uid in registry} == {
        uid.data for uid in [root["_scenePinBody"], root["_PKPhysicsBody"], *bodies]
    }, "Physics world contains stale bodies"
    for value in objects:
        def check_refs(item):
            if isinstance(item, UID):
                assert 0 <= item.data < len(objects), (number, item)
            elif isinstance(item, dict):
                for nested in item.values():
                    check_refs(nested)
            elif isinstance(item, list):
                for nested in item:
                    check_refs(nested)
        check_refs(value)


def make_levels() -> dict:
    levels = {}

    # Quiet Arch: remove the obstacle in the chute before releasing the cap.
    scene = SceneBuilder()
    scene.add("wood_post", "arch_left_post", 864, 439)
    scene.add("wood_post", "arch_right_post", 1184, 439)
    scene.add("wood_deck", "arch_top_plank", 1024, 639)
    scene.add("wood_square", "arch_center_block", 1024, 393)
    scene.add("panda", "panda", 1000, 850.84)
    scene.finish(14)
    levels["14"] = {
        "title": "Quiet Arch",
        "hint": "Clear the wooden block above the bed, then remove the top plank.",
        "nodes": scene.authored,
        "removals": [
            {"at_seconds": 0.6, "node": "arch_center_block", "point": [1024, 393]},
            {"at_seconds": 1.2, "node": "arch_top_plank", "point": [1024, 639]},
        ],
        "expected": "The panda drops straight through the arch onto the bed.",
    }

    # Double Decker: each symmetrical pair of supports leaves a 240-point chute.
    # The lower deck catches the panda after the first deliberate short drop.
    scene = SceneBuilder()
    for side, x in (("left", 814), ("right", 1234)):
        scene.add("wood_square", f"tower_{side}_base", x, 393)
        scene.add("wood_square", f"tower_{side}_upper", x, 701)
    scene.add("wood_deck", "tower_lower_plank", 1024, 547, x_scale=1)
    scene.add("wood_deck", "tower_upper_plank", 1024, 855, x_scale=1)
    scene.add("wood_square", "tower_center_block", 1024, 393)
    scene.add("panda", "panda", 1000, 1066.84)
    scene.finish(15)
    levels["15"] = {
        "title": "Double Decker",
        "hint": ("Clear the center block, then remove the upper plank. Let the "
                 "panda settle before removing the lower plank."),
        "nodes": scene.authored,
        "removals": [
            {"at_seconds": 0.6, "node": "tower_center_block", "point": [1024, 393]},
            {"at_seconds": 1.2, "node": "tower_upper_plank", "point": [1024, 855]},
            {"at_seconds": 3.5, "node": "tower_lower_plank", "point": [1024, 547]},
        ],
        "expected": "The panda settles on the lower plank, then drops onto the bed.",
    }

    # Stone Shelter: three authored sprites become the existing single StoneNode
    # compound. All wood below the bridge is independent and remains tappable.
    scene = SceneBuilder()
    for side, x in (("left", 804), ("right", 1244)):
        scene.add("wood_square", f"shelter_{side}_base", x, 393)
        scene.add("stone_post", f"shelter_{side}_stone", x, 622.2,
                  x_scale=0.8, y_scale=0.58)
    scene.add("stone_deck", "shelter_stone_bridge", 1024, 801.4, x_scale=0.9, y_scale=1)
    scene.add("wood_square", "shelter_center_base", 1024, 393)
    scene.add("wood_square", "shelter_center_top", 1024, 573)
    scene.add("panda", "panda", 1000, 989.24)
    scene.finish(16)
    levels["16"] = {
        "title": "Stone Shelter",
        "hint": "Clear both wooden blocks above the bed, then tap the stone bridge.",
        "nodes": scene.authored,
        "removals": [
            {"at_seconds": 0.6, "node": "shelter_center_top", "point": [1024, 573]},
            {"at_seconds": 1.0, "node": "shelter_center_base", "point": [1024, 393]},
            {"at_seconds": 1.6, "node": "shelter_stone_bridge", "point": [1024, 801.4],
             "target": "ancestor StoneNode compound with physics body"},
        ],
        "expected": "The entire stone bridge disappears and the panda drops onto the bed.",
    }
    return {
        "scene_size": [2048, 1536],
        "bed_position": [1024, 400],
        "playable_floor_y": 302.54545454545456,
        "initial_panda_rotation": 0,
        "seconds_after_last_removal_to_check": 4,
        "validation": "Run the live SpriteKit physics with the normal GameScene rules.",
        "levels": levels,
    }


if __name__ == "__main__":
    manifest = make_levels()
    manifest_path = Path(__file__).with_name("bonus_level_solutions.json")
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print("Generated and archive-validated Level14.sks, Level15.sks, Level16.sks")
