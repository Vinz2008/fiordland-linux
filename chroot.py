import os
import sys
from typing import *

import utils


from dotenv import load_dotenv

load_dotenv()


vfs_dirs = ["dev", "proc", "sys", "run"]

def is_path_a_mountpoint(path : str) -> bool:
	completed_process = utils.run_command("mountpoint -q " + path)
	return completed_process.returncode == 0


def mount_if_not_mounted(mount_path : str, mount_device_path : Optional[str] = None, is_bind : bool = False, fs_type : Optional[str] = None, additional_args : Optional[str] = None) -> None:
	assert (mount_device_path == None and fs_type != None) or (mount_device_path != None and fs_type == None)
	if is_path_a_mountpoint(mount_path):
		return
	cmd = "mount -v "
	if is_bind:
		cmd += "--bind "
	if fs_type != None:
		cmd += "-t " + fs_type + " " + fs_type + " "
	else: 
		cmd += mount_device_path + " "
	if additional_args != None:
		cmd += additional_args + " "
	cmd += " " + mount_path
	utils.verify_retcode(utils.run_command_as_sudo(cmd, password=os.getenv("sudo_password")))


def umount_if_mounted(mount_path : str, lazy_mount : bool = False) -> None:
	if not is_path_a_mountpoint(mount_path):
		print("path ", mount_path, "not a mountpoint")
		return
	cmd = "umount "
	if lazy_mount:
		cmd += "-l "
	cmd +=  mount_path
	utils.verify_retcode(utils.run_command_as_sudo(cmd, password=os.getenv("sudo_password")))

def is_shm_a_symlink() -> bool:
	shm_path = "/dev/shm"
	return os.path.exists(shm_path) and os.path.islink(shm_path)

def prepare_chroot(rootfs_path : str):
	# TODO : chown rootfs to root (is needed according to lfs, but it would complicate everything, and need to chown to the user when rebuilding)
	for dir in vfs_dirs:
		utils.mkdir_if_not_exists(os.path.join(rootfs_path, dir))
	mount_if_not_mounted(os.path.join(rootfs_path, "dev"), "/dev", True)
	mount_if_not_mounted(os.path.join(rootfs_path, "dev/pts"), None, False, "devpts", "-o gid=5,mode=0620")
	mount_if_not_mounted(os.path.join(rootfs_path, "proc"), None, False, "proc")
	mount_if_not_mounted(os.path.join(rootfs_path, "sys"), None, False, "sysfs")
	mount_if_not_mounted(os.path.join(rootfs_path, "run"), None, False, "tmpfs")

	if is_shm_a_symlink():
		utils.verify_retcode(utils.run_command("install -v -d -m 1777 " + rootfs_path + "$(realpath /dev/shm)"))
	else:
		mount_if_not_mounted(os.path.join(rootfs_path, "dev/shm"), None, False, "tmpfs", "-o nosuid,nodev")


def umount_chroot_fs(rootfs_path : str) -> None:
	fs_to_umount = ["dev/pts", "proc", "sys", "run"]
	for fs in fs_to_umount:
		print("umount", os.path.join(rootfs_path, fs))
		umount_if_mounted(os.path.join(rootfs_path, fs))
	if not is_shm_a_symlink():
		umount_if_mounted(os.path.join(rootfs_path, "dev/shm"))
	umount_if_mounted(os.path.join(rootfs_path, "dev"), True)

def chown_user_rootfs(user : str, rootfs_path : str) -> None:
	umount_chroot_fs(rootfs_path)
	cmd = "chown " + user + ":"  +  user + " " + rootfs_path + " -R "
	print(cmd)
	utils.verify_retcode(utils.run_command_as_sudo(cmd, password=os.getenv("sudo_password")))

def main():
	first_arg = sys.argv[1]
	rootfs_path = "./rootfs"
	if first_arg == "prepare-chroot":
		prepare_chroot(rootfs_path)
	elif first_arg == "umount":
		umount_chroot_fs(rootfs_path)
	elif first_arg == "chown_user":
		chown_user_rootfs(os.getlogin(), rootfs_path)
	elif first_arg == "chown_root":
		chown_user_rootfs("root", rootfs_path)

if __name__ == "__main__":
	main()