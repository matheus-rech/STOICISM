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
    json_path = "project_frameworks.json"

    print("Converting project to JSON...")
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

    print(f"Found Frameworks Phase: {frameworks_phase_id}")

    # 2. Frameworks to add
    frameworks = [
        {
            "name": "HealthKit.framework",
            "path": "System/Library/Frameworks/HealthKit.framework",
        },
        {
            "name": "UserNotifications.framework",
            "path": "System/Library/Frameworks/UserNotifications.framework",
        },
        {
            "name": "SwiftUI.framework",
            "path": "System/Library/Frameworks/SwiftUI.framework",
        },
    ]

    # 3. Add Frameworks
    # We need to find the PBXGroup that holds frameworks usually "Frameworks" group or create one?
    # Usually we add PBXFileReference for the system framework

    # Let's check if there is a "Frameworks" group
    frameworks_group_id = None
    main_group_id = project[
        "rootObject"
    ]  # Project object ID? No, rootObject points to PBXProject
    pbx_project = objects[project["rootObject"]]
    main_group_id = pbx_project["mainGroup"]

    main_group = objects[main_group_id]

    for child_id in main_group["children"]:
        child = objects[child_id]
        if child.get("name") == "Frameworks":
            frameworks_group_id = child_id
            break

    if not frameworks_group_id:
        # Create Frameworks group
        frameworks_group_id = generate_id()
        objects[frameworks_group_id] = {
            "isa": "PBXGroup",
            "children": [],
            "name": "Frameworks",
            "sourceTree": "<group>",
        }
        main_group["children"].append(frameworks_group_id)
        print("Created Frameworks Group")

    frameworks_group = objects[frameworks_group_id]

    for fw in frameworks:
        # Check if already exists? (Skipping check for simplicity, just adding new ones if duplicates it's usually fine or we can check path)

        file_ref_id = generate_id()
        build_file_id = generate_id()

        # PBXFileReference
        objects[file_ref_id] = {
            "isa": "PBXFileReference",
            "lastKnownFileType": "wrapper.framework",
            "name": fw["name"],
            "path": fw["path"],
            "sourceTree": "SDKROOT",
        }

        # Add to Group
        frameworks_group["children"].append(file_ref_id)

        # PBXBuildFile
        objects[build_file_id] = {"isa": "PBXBuildFile", "fileRef": file_ref_id}

        # Add to Phase
        objects[frameworks_phase_id]["files"].append(build_file_id)
        print(f"Added {fw['name']}")

    # Save
    with open(json_path, "w") as f:
        json.dump(project, f)

    print("Converting back to XML...")
    run_command(f"plutil -convert xml1 '{json_path}' -o '{project_path}'")
    print("Done!")


if __name__ == "__main__":
    main()
