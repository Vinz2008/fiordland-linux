import os
import subprocess
from urllib.parse import urlparse
from typing import *

def mkdir_if_not_exists(folder : str) -> None:
	if not os.path.exists(folder):
		os.mkdir(folder)


def ln_if_not_exists(src : str, dest : str, target_is_directory : bool) -> None:
	if not os.path.exists(dest):
		os.symlink(src, dest, target_is_directory)

def verify_retcode(completed_process : subprocess.CompletedProcess[bytes]) -> None | NoReturn:
	if completed_process.returncode != 0:
		print("process" , completed_process.args, " exited with return code :", completed_process.returncode)
		exit(1)

# foo.tar.xz -> foo
def get_folder_name_from_tar(tar_name : str) -> str:
	return os.path.splitext(os.path.splitext(tar_name)[0])[0]

def get_url_filename(url : str) -> str:
	parsed_url = urlparse(url)
	return os.path.basename(parsed_url.path)

def run_command_as_sudo(cmd : str, process_env : dict[str, str] = None, password : Optional[str] = None) -> subprocess.CompletedProcess[bytes]:
	cmd = "echo " + password + " | sudo -S " + cmd
	return subprocess.run(cmd, env=process_env, shell=True)

def run_command(cmd : str, is_in_chroot : bool = False, process_env : dict[str, str] = None, rootfs : Optional[str] = None, sudo_password : Optional[str] = None) -> subprocess.CompletedProcess[bytes]:
	if is_in_chroot:
		cmd = "chroot" + rootfs + " /usr/bin/env -i HOME=/root PATH=/usr/bin:/usr/sbin" + cmd
		return run_command_as_sudo(cmd, process_env, sudo_password)
	else:
		return subprocess.run(cmd, env=process_env, shell=True)