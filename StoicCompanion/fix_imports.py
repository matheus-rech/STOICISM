import os


def add_import_if_needed(file_path, import_statement):
    with open(file_path, "r") as f:
        content = f.read()

    if import_statement in content:
        return False

    lines = content.split("\n")
    last_import_idx = -1
    for i, line in enumerate(lines):
        if line.startswith("import "):
            last_import_idx = i

    if last_import_idx != -1:
        lines.insert(last_import_idx + 1, import_statement)
    else:
        # No imports, add to top (after comments if any)
        # Simple heuristic: find first non-comment line
        insert_idx = 0
        for i, line in enumerate(lines):
            if not line.strip().startswith("//") and line.strip() != "":
                insert_idx = i
                break
        lines.insert(insert_idx, import_statement)

    with open(file_path, "w") as f:
        f.write("\n".join(lines))
    return True


def main():
    watch_app_dir = "Stoic_Companion/Stoic_Companion Watch App"

    files_needing_combine = []
    files_needing_swiftui = []

    for filename in os.listdir(watch_app_dir):
        if not filename.endswith(".swift"):
            continue

        filepath = os.path.join(watch_app_dir, filename)

        with open(filepath, "r") as f:
            content = f.read()

        if "ObservableObject" in content or "@Published" in content:
            files_needing_combine.append(filepath)

        if "View" in content or "Scene" in content:  # Basic check for SwiftUI usage
            files_needing_swiftui.append(filepath)

    print("Adding imports...")

    for f in files_needing_combine:
        if add_import_if_needed(f, "import Combine"):
            print(f"Added Combine to {os.path.basename(f)}")

    for f in files_needing_swiftui:
        if add_import_if_needed(f, "import SwiftUI"):
            print(f"Added SwiftUI to {os.path.basename(f)}")


if __name__ == "__main__":
    main()
