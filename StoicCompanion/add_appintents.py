import json
import subprocess
import os
import uuid


def generate_id():
    return uuid.uuid4().hex[:24].upper()


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
    json_path = "project_frameworks_update.json"

    run_command(f"plutil -convert json '{project_path}' -o '{json_path}'")

    with open(json_path, "r") as f:
        project = json.load(f)

    objects = project["objects"]

    # 1. Find Watch App Target and Frameworks Phase
    watch_app_target = None
    frameworks_phase_id = None

    for key, obj in objects.items():
        if (
            obj.get("isa") == "PBXNativeTarget"
            and obj.get("name") == "Stoic_Companion Watch App"
        ):
            watch_app_target = obj
            for phase_id in obj["buildPhases"]:
                if objects[phase_id]["isa"] == "PBXFrameworksBuildPhase":
                    frameworks_phase_id = phase_id
                    break

    if not frameworks_phase_id:
        print("Error: Frameworks Build Phase not found")
        return

    # 2. Add AppIntents
    framework_name = "AppIntents.framework"
    framework_path = "System/Library/Frameworks/AppIntents.framework"

    # Check if exists in Frameworks group
    frameworks_group_id = None
    pbx_project = objects[project["rootObject"]]
    main_group = objects[pbx_project["mainGroup"]]

    for child_id in main_group["children"]:
        child = objects[child_id]
        if child.get("name") == "Frameworks":
            frameworks_group_id = child_id
            break

    if not frameworks_group_id:
        print("Frameworks group not found (should exist)")
        return

    frameworks_group = objects[frameworks_group_id]

    # Create File Reference
    file_ref_id = generate_id()
    objects[file_ref_id] = {
        "isa": "PBXFileReference",
        "lastKnownFileType": "wrapper.framework",
        "name": framework_name,
        "path": framework_path,
        "sourceTree": "SDKROOT",
    }

    frameworks_group["children"].append(file_ref_id)

    # Create Build File
    build_file_id = generate_id()
    objects[build_file_id] = {"isa": "PBXBuildFile", "fileRef": file_ref_id}

    # Add to Phase
    objects[frameworks_phase_id]["files"].append(build_file_id)
    print(f"Added {framework_name}")

    # Save
    with open(json_path, "w") as f:
        json.dump(project, f)

    run_command(f"plutil -convert xml1 '{json_path}' -o '{project_path}'")
    print("Done!")


if __name__ == "__main__":
    main()
