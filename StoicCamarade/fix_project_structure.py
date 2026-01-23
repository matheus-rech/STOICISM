import json
import subprocess
import os
import uuid


def generate_id():
    # Xcode IDs are 24 chars hex.
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
    json_path = "project.json"
    watch_app_dir = "Stoic_Companion/Stoic_Companion Watch App"

    # 1. Get list of files
    files = []
    for f in os.listdir(watch_app_dir):
        if f.startswith(".") or f == "Info.plist":
            continue
        full_path = os.path.join(watch_app_dir, f)
        if os.path.isfile(full_path) or f.endswith(".xcassets"):
            files.append(f)

    print(f"Found {len(files)} files to add.")

    # 2. Convert Project
    print("Converting project to JSON...")
    run_command(f"plutil -convert json '{project_path}' -o '{json_path}'")

    with open(json_path, "r") as f:
        project = json.load(f)

    objects = project["objects"]

    # 3. Find targets and groups
    watch_app_target = None
    watch_app_group = None

    for key, obj in objects.items():
        if (
            obj.get("isa") == "PBXNativeTarget"
            and obj.get("name") == "Stoic_Companion Watch App"
        ):
            watch_app_target = obj

        # Check for the group (it might be PBXFileSystemSynchronizedRootGroup or PBXGroup)
        if obj.get("path") == "Stoic_Companion Watch App":
            watch_app_group = obj
            watch_app_group_id = key

    if not watch_app_target:
        print("Error: Target not found")
        return

    print(f"Target found: {watch_app_target['name']}")

    # 4. Convert Group to PBXGroup (if it's synced)
    if watch_app_group["isa"] == "PBXFileSystemSynchronizedRootGroup":
        print("Converting Synced Root Group to standard PBXGroup...")
        watch_app_group["isa"] = "PBXGroup"
        # Remove synced specific keys if any (fileSystemSynchronizedGroups might be on project/target, not group)
        # But we need to initialize 'children'
        watch_app_group["children"] = []
        # 'sourceTree' is likely '<group>'

    # 5. Create File References and Build Files

    # Get Build Phases
    sources_phase_id = None
    resources_phase_id = None

    for phase_id in watch_app_target["buildPhases"]:
        phase = objects[phase_id]
        if phase["isa"] == "PBXSourcesBuildPhase":
            sources_phase_id = phase_id
        elif phase["isa"] == "PBXResourcesBuildPhase":
            resources_phase_id = phase_id

    print(f"Sources Phase: {sources_phase_id}")
    print(f"Resources Phase: {resources_phase_id}")

    # Process files
    for filename in files:
        file_ref_id = generate_id()
        build_file_id = generate_id()

        # Determine file type
        file_type = "text"
        if filename.endswith(".swift"):
            file_type = "sourcecode.swift"
            phase_to_add = sources_phase_id
        elif filename.endswith(".xcassets"):
            file_type = "folder.assetcatalog"
            phase_to_add = resources_phase_id
        elif filename.endswith(".json"):
            file_type = "text.json"
            phase_to_add = resources_phase_id
        else:
            continue  # Skip unknown

        # Create File Reference
        objects[file_ref_id] = {
            "isa": "PBXFileReference",
            "path": filename,
            "sourceTree": "<group>",
            "lastKnownFileType": file_type,
        }

        # Add to Group
        if file_ref_id not in watch_app_group["children"]:
            watch_app_group["children"].append(file_ref_id)

        # Create Build File
        objects[build_file_id] = {"isa": "PBXBuildFile", "fileRef": file_ref_id}

        # Add to Build Phase
        if phase_to_add:
            objects[phase_to_add]["files"].append(build_file_id)
            print(f"Added {filename} to project.")

    # Remove fileSystemSynchronizedGroups from Target if present (cleanup)
    if "fileSystemSynchronizedGroups" in watch_app_target:
        del watch_app_target["fileSystemSynchronizedGroups"]

    # Save
    with open(json_path, "w") as f:
        json.dump(project, f)

    print("Converting back to XML...")
    run_command(f"plutil -convert xml1 '{json_path}' -o '{project_path}'")
    print("Done!")


if __name__ == "__main__":
    main()
