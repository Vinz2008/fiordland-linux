import os
import subprocess
import re
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib


folders = ["cross-compiler"]


def build_package_default(folder, staging, tar_name):
	f = open(os.path.join(folder, "build.toml"), "rb")
	config = tomllib.load(f)
	build_folder_name = os.path.splitext(os.path.splitext(tar_name)[0])[0]
	build_folder = os.path.join(staging, build_folder_name)
	configure_flags = config.get("configure_options")
	configure_script = "./configure"
	post_run_commands_cmd = "echo"
	additional_commands_cmd = "echo"
	if (config.get("build_directory")):
		os.makedirs(os.path.join(build_folder, "build"), exist_ok=True)
		print(os.path.join(build_folder, "build"))
		build_folder = os.path.join(build_folder, "build")
		configure_script = "../configure"
	if (config.get("additional_commands")):
		additional_commands_cmd_list = config.get("additional_commands")
		additional_commands_cmd = ""
		count = 0
		additional_commands_cmd = additional_commands_cmd_list[0]
		#for i in additional_commands_cmd_list:
		#	if count != 1:
		#		additional_commands_cmd += " && "
		#	additional_commands_cmd += i
		#	count += 1
	if (config.get("post_run_commands")):
		post_run_commands_cmd_list = config.get("post_run_commands")
		post_run_commands_cmd = ""
		count = 0
		post_run_commands_cmd = post_run_commands_cmd_list[0]
		#for i in post_run_commands_cmd_list:
		#	if count != 1:
		#		post_run_commands_cmd += " && "
		#	post_run_commands_cmd += i
		#	count += 1
	subprocess.run("cd " + build_folder + " && " + additional_commands_cmd + " && "+ configure_script + " " + configure_flags + " && make -j12 && make install && " + post_run_commands_cmd, shell=True)

def build_package_custom(package_name, folder, staging, tar_name):
	print("custom script for package " + package_name + " in folder " + folder)
	build_folder_name = os.path.splitext(os.path.splitext(tar_name)[0])[0]
	build_folder = os.path.join(staging, build_folder_name)
	print("build_folder : " + build_folder)
	subprocess.run("cd " + folder + " && " + "./custom.sh " + os.path.realpath(build_folder), shell=True)

def build_package(package_name, folder, staging, packages):
	print(folder)
	print(staging)
	for subdir, dirs, files in os.walk(packages):
		for file in files:
			if file.startswith(package_name):
				tar_name = file
	subprocess.run("tar -xvf " + os.path.join(packages, tar_name) + " -C " + staging ,stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
	if os.path.exists(os.path.join(folder, "build.toml")):
		build_package_default(folder, staging, tar_name)
	elif os.path.exists(os.path.join(folder, "custom.sh")):
		build_package_custom(package_name, folder, staging, tar_name)
	else:
		print("Couldn't find file build.toml or custom.sh in folder " + folder)
		exit(1)
#	if config.get("build_directory"):
		


def build_project(folder):
	packages = os.path.realpath(os.path.join(os.path.join(folder, ".."), "downloads"))
	staging = os.path.join(folder, "staging")
	if not os.path.exists(staging):
		os.mkdir(staging)
	staging = os.path.join(folder, "staging")
	for subdir, dirs, files in os.walk(folder):
		for dir in dirs:
			if dir != "staging" and dir != "cross-tools":
				package_name = dir
				build_package(package_name, os.path.join(subdir, dir), staging, packages)
		break
	

for folder in folders:
	build_project(folder)

