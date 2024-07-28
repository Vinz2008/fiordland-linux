import os
import subprocess
from typing import *
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib
import multiprocessing

#from urllib.parse import urlparse
#from os.path import splitext

from urllib.request import urlretrieve

import progressbar
import shutil

import rootfs
import utils

project_folders = ["cross-compiler"]

proc_nb = multiprocessing.cpu_count()

print("processors number :", proc_nb)

# TODO : add a build_package_just_make and a build_package_configure and call these functions in build_package_default that will be a simple wrapper to those functions

def build_package_default(download_path : str, process_env : dict[str, str], build_folder : str, config : dict[str, Any]) -> None :
#	f = open(os.path.join(folder, "build.toml"), "rb")
#	config = tomllib.load(f)
	configure_flags = config.get("configure_options")
	configure_script = "./configure"
	post_run_commands_cmd = "echo"
	additional_commands_cmd = "echo"
	additional_commands_in_build_folder_cmd = "echo"
	src_folder = build_folder
	make_additional_flags = ""
	make_install_additional_flags = ""
	if config.get("build_directory") == True:
		os.makedirs(os.path.join(build_folder, "build"), exist_ok=True)
		print(os.path.join(build_folder, "build"))
		build_folder = os.path.join(build_folder, "build")
		configure_script = "../configure"
	if config.get("make_install_args") != None:
		make_install_args : str = config.get("make_install_args")
		make_install_additional_flags += make_install_args
	if config.get("make_args") != None:
		make_additional_flags += config.get("make_args")
	if config.get("additional_commands") != None:
		additional_commands_cmd_list = config.get("additional_commands")
		additional_commands_cmd = ""
		count = 0
		# additional_commands_cmd = additional_commands_cmd_list[0]
		for cmd in additional_commands_cmd_list:
			if count != 0:
				additional_commands_cmd += " && "
			additional_commands_cmd += cmd
			count += 1
	if config.get("additional_commands_in_build_folder") != None:
		additional_commands_in_build_folder_cmd_list = config.get("additional_commands_in_build_folder")
		additional_commands_in_build_folder_cmd = ""
		count = 0
		# additional_commands_cmd = additional_commands_cmd_list[0]
		for cmd in additional_commands_in_build_folder_cmd_list:
			if count != 0:
				additional_commands_in_build_folder_cmd += " && "
			additional_commands_in_build_folder_cmd += cmd
			count += 1
	patches_to_apply : list[str] = []
	if config.get("patch_urls") != None:
		patch_urls : list[str] = config.get("patch_urls")
		for patch_url in patch_urls:
			patch_path = os.path.join(download_path, utils.get_url_filename(patch_url))
			patches_to_apply.append(patch_path)
	if config.get("post_run_commands") != None:
		post_run_commands_cmd_list = config.get("post_run_commands")
		post_run_commands_cmd = ""
		count = 0
		#post_run_commands_cmd = post_run_commands_cmd_list[0]
		for cmd in post_run_commands_cmd_list:
			if count != 0:
				post_run_commands_cmd += " && "
			post_run_commands_cmd += cmd
			count += 1
	proc_nb_used = proc_nb
	if config.get("parallelism") != None:
		parallelism : bool = config.get("parallelism")
		if not parallelism:
			proc_nb_used = 1
	no_incremental_build = False
	if config.get("no_incremental_build") == True:
		no_incremental_build = True
	utils.verify_retcode(subprocess.run("cd " + src_folder + " && " + additional_commands_cmd, shell=True, env=process_env))
	utils.verify_retcode(subprocess.run("cd " + build_folder + " && " + additional_commands_in_build_folder_cmd, shell=True, env=process_env))
	for patch_path in patches_to_apply:
		#utils.verify_retcode(subprocess.run("cd " + src_folder + " && " + "patch -Np1 -i " + patch_path, shell=True, env=process_env))
		subprocess.run("cd " + src_folder + " && " + "patch -Np1 -i " + patch_path, shell=True, env=process_env)
# TODO : maybe verify with a file named "build_finished" that would be deleted automatically when there is a reforce build or manually if we want to recompile some packages
	makefile_path = os.path.join(build_folder, "Makefile")
	#if config.get("build_directory") == True:
	#	makefile_path = os.path.join(build_folder, os.path.join("build", "Makefile"))
	if no_incremental_build:
		if os.path.exists(makefile_path):
			os.remove(makefile_path)
	if not os.path.exists(makefile_path) or no_incremental_build:
		utils.verify_retcode(subprocess.run("cd " + build_folder + " && " + configure_script + " " + configure_flags, shell=True, env=process_env))
	utils.verify_retcode(subprocess.run("cd " + build_folder + " && " + " make " + make_additional_flags + " -j" + str(proc_nb_used) + " && make " + make_install_additional_flags + " install && " + post_run_commands_cmd, shell=True, env=process_env))

def build_package_custom(package_name : str, folder : str, process_env : dict[str, str]) -> None:
	print("custom script for package " + package_name + " in folder " + folder)
	utils.verify_retcode(subprocess.run("cd " + folder + " && " + "./custom.sh", shell=True, env=process_env))

def get_install_prefix(project_name : str) -> str:
    if project_name == "cross-compiler":
        return os.path.realpath(os.path.join("./rootfs", "tools"))
    return os.path.realpath("./rootfs/usr")

# is a second pass (folder ends with _pass2)
def is_second_pass(folder_name : str) -> bool:
	return folder_name.endswith("_pass2")

def remove_second_pass_postfix(folder_name : str) -> str:
	return folder_name[:-6] # the length of "_pass2" is 6 


# TODO : add a way to build a package specifically by giving its path through the cli 
def build_package(package_name : str, folder : str, staging_folder : str, rootfs_path : str, download_path : str, project_name : str) -> None:
	print(folder)
#	print(staging_folder)
	tar_name = None
	f = None
	config = None
	has_tar = True
	if os.path.exists(os.path.join(folder, "build_finished")):
		return
	if os.path.exists(os.path.join(folder, "build.toml")):
		f = open(os.path.join(folder, "build.toml"), "rb")
		config = tomllib.load(f)
		if config.get("has_tar") == False:
			has_tar = False
	if is_second_pass(package_name):
		package_name = remove_second_pass_postfix(package_name)

	for subdir, dirs, files in os.walk(download_path):
		for file in files:
			if file.startswith(package_name):
				tar_name = file
	if tar_name == None and has_tar:
		print("Couldn't find tar file for package :", package_name)
		exit(1)

	#build_folder_name = os.path.splitext(os.path.splitext(tar_name)[0])[0]
	build_folder = ""
	if tar_name != None:
		build_folder_name = utils.get_folder_name_from_tar(tar_name)
		build_folder = os.path.realpath(os.path.join(staging_folder, build_folder_name))
	if is_second_pass(folder):
		shutil.rmtree(build_folder)
	if not os.path.exists(build_folder) and has_tar:
		subprocess.run("tar -xvf " + os.path.join(download_path, tar_name) + " -C " + staging_folder ,stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
	install_prefix = get_install_prefix(project_name)
	process_env = os.environ.copy()
	process_env["INSTALL_PREFIX"] = install_prefix 
	process_env["ROOTFS"] = rootfs_path
	process_env["DOWNLOADS"] = download_path
	process_env["BUILD_FOLDER"] = build_folder
	process_env["PATH"] = os.path.join(rootfs_path, "tools/bin") + ":" + process_env["PATH"]
	process_env["CONFIG_SITE"] = os.path.join(rootfs_path, "usr/share/config.site")


	if os.path.exists(os.path.join(folder, "custom.sh")):
		build_package_custom(package_name, folder, process_env)
	elif os.path.exists(os.path.join(folder, "build.toml")):
		#f = open(os.path.join(folder, "build.toml"), "rb")
		#config = tomllib.load(f)
		build_package_default(download_path, process_env, build_folder, config)
		f.close()
	else:
		print("Couldn't find file build.toml or custom.sh in folder " + folder)
		exit(1)
	open(os.path.join(folder, "build_finished"), 'w').close()
#	if config.get("build_directory"):
		

def build_project(folder : str, project_name : str) -> None:
	packages = os.path.realpath(os.path.join(os.path.join(folder, ".."), "downloads"))
	rootfs_path = os.path.realpath(os.path.join(os.path.join(folder, ".."), "rootfs"))
	staging = os.path.join(folder, "staging")
	if not os.path.exists(staging):
		os.mkdir(staging)
	staging = os.path.join(folder, "staging")
	f = None
	config : dict[str, Any] | None = None
	build_order_found : bool = False
	if os.path.exists(os.path.join(folder, "build.toml")):
		f = open(os.path.join(folder, "build.toml"), "rb")
		config = tomllib.load(f)
		if config.get("build_order") != None:
			build_order_found = True

	if build_order_found:
		build_order : list[str] = config.get("build_order")
		print("build order :", build_order)
		for dir in build_order:
			package_name = dir
			build_package(package_name, os.path.join(folder, dir), staging, rootfs_path, packages, project_name)
	else:
		for subdir, dirs, files in os.walk(folder):
			for dir in dirs:
				if dir != "staging":
					package_name = dir
					build_package(package_name, os.path.join(subdir, dir), staging, rootfs_path, packages, project_name)
			break
	
	if f != None:
		f.close()
# TODO : after having build the project, create a tar with the rootfs content in a special folder



progress_bar = None

def show_progress_urlretrieve(block_num, block_size, total_size):
    global progress_bar
    if progress_bar is None:
        progress_bar = progressbar.ProgressBar(maxval=total_size)
        progress_bar.start()

    downloaded = block_num * block_size
    if downloaded < total_size:
        progress_bar.update(downloaded)
    else:
        progress_bar.finish()
        progress_bar = None

# TODO : move all the downloads function in a downloader file

def download_url(url : str, folder : str, url_filename : str) -> None:
	#parsed_url = urlparse(url)
	print("downloading ", url)
	urlretrieve(url, os.path.join(folder, url_filename), show_progress_urlretrieve)


def download_url_package(folder : str) -> None:
	print(folder)
	if os.path.exists(os.path.join(folder, "build.toml")):
		f = open(os.path.join(folder, "build.toml"), "rb")
		config = tomllib.load(f)
		if config.get("download_urls") == None:
			return
		download_urls_package : list[str] = config.get("download_urls")
		downloads_folder = "./downloads"
		for download_url_package in download_urls_package:
			# parsed_url = urlparse(download_url_package)
			# url_filename = os.path.basename(parsed_url.path)
			url_filename = utils.get_url_filename(download_url_package)
			if not os.path.exists(os.path.join(downloads_folder, url_filename)):
				download_url(download_url_package, downloads_folder, url_filename)
		if config.get("patch_urls") != None:
			patch_urls_package : list[str] = config.get("patch_urls")
			for patch_url_package in patch_urls_package:
				patch_url_filename = utils.get_url_filename(patch_url_package)
				if not os.path.exists(os.path.join(downloads_folder, patch_url_filename)):
					download_url(patch_url_package, downloads_folder, patch_url_filename)

		f.close()

def download_project(project_folder) -> None:
	for subdir, dirs, files in os.walk(project_folder):
		for dir in dirs:
			if dir != "staging" and dir != "cross-tools" and not is_second_pass(dir):
				download_url_package(os.path.join(subdir, dir))
		break

def download_all_projects() -> None:
	utils.mkdir_if_not_exists("./downloads")
	for project_folder in project_folders:
 		download_project(project_folder)

rootfs.prepare_rootfs()

download_all_projects()

for project_folder in project_folders:
    build_project(project_folder, project_folder)

