import shutil
import os
import sys

rootfs_path = "./rootfs"

def clean_rootfs(clean_tools : bool) -> None:
	tools_folder = os.path.join(rootfs_path, "tools")

	if not clean_tools:
		shutil.move(tools_folder, "./tools") 
	shutil.rmtree(rootfs_path)
	os.mkdir(rootfs_path)
	if not clean_tools:
		shutil.move("./tools", tools_folder)

def clean_tools_staging() -> None:
	staging_path = os.path.join("cross-compiler", "staging")
	if os.path.exists(staging_path):
		shutil.rmtree(staging_path)

def clean_build_finished(folder : str) -> None:
	build_finished_path = os.path.join(folder, "build_finished")
	if os.path.exists(build_finished_path):
		os.remove(build_finished_path)

def clean_build_finished_project(project_folder : str):
	for subdir, dirs, files in os.walk(project_folder):
			for dir in dirs:
				if dir != "staging":
					clean_build_finished(os.path.join(project_folder, dir))
			break

def clean_tools() -> None:
	clean_tools_staging()
	clean_build_finished_project("cross-compiler")
	tools_folder = os.path.join(rootfs_path, "tools")
	shutil.rmtree(tools_folder)
	os.mkdir(tools_folder)
	
# TODO : add a way to clean a single package

def main():
	first_arg = sys.argv[1]
	if first_arg == "clean-all":
		clean_rootfs(True)
	elif first_arg == "clean-rootfs":
		clean_rootfs(False)
	elif first_arg == "clean-tools":
		clean_tools()


if __name__ == "__main__":
	main()