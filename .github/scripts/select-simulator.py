"""Select an installed iPhone simulator for the pinned Xcode 27 test job."""

import json
import subprocess

devices = json.loads(subprocess.check_output(
    ["xcrun", "simctl", "list", "devices", "available", "--json"], text=True
))["devices"]
candidates = [device for runtime, entries in devices.items()
              if runtime.startswith("com.apple.CoreSimulator.SimRuntime.iOS-27-")
              for device in entries if device["name"].startswith("iPhone")]
if not candidates:
    raise SystemExit("No installed iOS 27 iPhone simulator; check the runner image.")
candidates.sort(key=lambda device: (device["name"] != "iPhone 18 Pro", device["name"]))
print(candidates[0]["udid"])
