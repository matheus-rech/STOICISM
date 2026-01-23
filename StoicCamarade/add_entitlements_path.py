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
    json_path = "project_entitlements.json"

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

    # Update Build Configuration
    build_config_list = objects[watch_app_target["buildConfigurationList"]]
    for config_id in build_config_list["buildConfigurations"]:
        config = objects[config_id]
        print(f"Updating Entitlements for {config['name']}")
        config["buildSettings"]["CODE_SIGN_ENTITLEMENTS"] = (
            "Stoic_Companion Watch App/Stoic_Companion.entitlements"
        )
        config["buildSettings"]["ENABLE_PREVIEWS"] = "YES"

    # Save
    with open(json_path, "w") as f:
        json.dump(project, f)

    run_command(f"plutil -convert xml1 '{json_path}' -o '{project_path}'")
    print("Updated Project Settings.")


if __name__ == "__main__":
    main()
