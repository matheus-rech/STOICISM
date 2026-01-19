import json
import subprocess


def run_command(command):
    try:
        subprocess.run(
            command,
            check=True,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {command}")
        print(e.stderr.decode())
        raise


def main():
    project_path = "Stoic_Companion/Stoic_Companion.xcodeproj/project.pbxproj"
    json_path = "project_bundle_id.json"

    run_command(f"plutil -convert json '{project_path}' -o '{json_path}'")

    with open(json_path, "r") as f:
        project = json.load(f)

    objects = project["objects"]

    for key, obj in objects.items():
        if obj.get("isa") == "XCBuildConfiguration":
            bs = obj.get("buildSettings", {})
            if "PRODUCT_BUNDLE_IDENTIFIER" in bs:
                print(
                    f"Config: {obj.get('name')} - BundleID: {bs['PRODUCT_BUNDLE_IDENTIFIER']}"
                )


if __name__ == "__main__":
    main()
