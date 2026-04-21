import subprocess
import os
import sys

def run_swift_automator():
    """
    Runner shim to launch the Swift Automator from the root directory.
    This allows running the project via standard IDE 'Run' buttons.
    """
    current_dir = os.path.dirname(os.path.abspath(__file__))
    package_dir = os.path.join(current_dir, "SolitaireAutomator")
    
    if not os.path.exists(package_dir):
        print(f"❌ Error: Could not find SolitaireAutomator directory at {package_dir}")
        sys.exit(1)

    print("🚀 [IphoneSolitaire] Building and Starting Native Automator...")
    print("Press Ctrl+C to stop.")
    
    try:
        # Using swift run to build and execute the project
        subprocess.run(["swift", "run"], cwd=package_dir, check=True)
    except KeyboardInterrupt:
        print("\n\n👋 iPhone Solitaire Automator stopped.")
    except subprocess.CalledProcessError as e:
        print(f"\n❌ Build or Execution failed: {e}")
    except Exception as e:
        print(f"\n❌ An unexpected error occurred: {e}")

if __name__ == "__main__":
    run_swift_automator()
