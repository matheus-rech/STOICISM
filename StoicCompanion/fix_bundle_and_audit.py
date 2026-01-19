import json
import subprocess
import os


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
    json_path = "project_audit.json"

    run_command(f"plutil -convert json '{project_path}' -o '{json_path}'")

    with open(json_path, "r") as f:
        project = json.load(f)

    objects = project["objects"]

    # Find Watch App Target
    watch_app_target = None
    for key, obj in objects.items():
        if (
            obj.get("isa") == "PBXNativeTarget"
            and obj.get("name") == "Stoic_Companion Watch App"
        ):
            watch_app_target = obj
            break

    if not watch_app_target:
        print("Target not found")
        return

    # Update Bundle ID in Build Configuration
    build_config_list = objects[watch_app_target["buildConfigurationList"]]
    for config_id in build_config_list["buildConfigurations"]:
        config = objects[config_id]
        print(f"Updating Bundle ID for {config['name']}")
        config["buildSettings"]["PRODUCT_BUNDLE_IDENTIFIER"] = (
            "com.stoic.companion.watchkitapp"
        )
        config["buildSettings"]["DEVELOPMENT_TEAM"] = (
            ""  # Clear if needed or set if known
        )

    # List Source Files
    print("\n--- Source Files ---")
    sources_phase_id = None
    for phase_id in watch_app_target["buildPhases"]:
        if objects[phase_id]["isa"] == "PBXSourcesBuildPhase":
            sources_phase_id = phase_id
            break

    if sources_phase_id:
        for build_file_id in objects[sources_phase_id]["files"]:
            file_ref_id = objects[build_file_id]["fileRef"]
            file_ref = objects[file_ref_id]
            print(f" - {file_ref.get('path')}")

    # Save
    with open(json_path, "w") as f:
        json.dump(project, f)

    run_command(f"plutil -convert xml1 '{json_path}' -o '{project_path}'")
    print("\nUpdated Project Settings.")


if __name__ == "__main__":
    main()
