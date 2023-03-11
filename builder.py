import os
import subprocess
import re
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib


folders = ["cross-compiler"]


def build_package(package_name, folder, staging, packages):
	print(folder)
	print(staging)
	f = open(os.path.join(folder, "build.toml"), "rb")
	config = tomllib.load(f)
	for subdir, dirs, files in os.walk(packages):
		for file in files:
			if file.startswith(package_name):
				tar_name = file
	subprocess.run("tar -xvf " + os.path.join(packages, tar_name) + " -C " + staging ,stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
	build_folder_name = os.path.splitext(os.path.splitext(tar_name)[0])[0]
	build_folder = os.path.join(staging, build_folder_name)
	configure_flags = config.get("configure_options")
	subprocess.run("cd " + build_folder + " && ./configure " + configure_flags + " && make -j12 && make install", shell=True)
#	if config.get("build_directory"):
		


def build_project(folder):
	packages = os.path.realpath(os.path.join(os.path.join(folder, ".."), "downloads"))
	staging = os.path.join(folder, "staging")
	if not os.path.exists(staging):
		os.mkdir(staging)
	staging = os.path.join(folder, "staging")
	for subdir, dirs, files in os.walk(folder):
		for dir in dirs:
			if dir != "staging":
				package_name = dir
				build_package(package_name, os.path.join(subdir, dir), staging, packages)
		break
	

for folder in folders:
	build_project(folder)

