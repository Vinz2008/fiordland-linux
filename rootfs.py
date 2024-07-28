import subprocess
import utils
import os

def prepare_rootfs() -> None:
    rootfs_path = "./rootfs"
    utils.mkdir_if_not_exists(rootfs_path)
    subprocess.run("mkdir -pv " + rootfs_path + "/{etc,var} " + rootfs_path + "/usr/{bin,lib,sbin}", shell=True)
    for dir in ["bin", "lib", "sbin"]:
        #subprocess.run("ln -sv usr/" + dir + " " + rootfs_path, shell=True)
        utils.ln_if_not_exists(os.path.realpath(os.path.join(os.path.join(rootfs_path, "usr"), dir)), os.path.realpath(os.path.join(rootfs_path, dir)), True)
    print(subprocess.run("uname -m",  capture_output = True, text = True, shell=True).stdout)
    if subprocess.run("uname -m",  capture_output = True, text = True, shell=True).stdout.startswith("x86_64"):
        utils.mkdir_if_not_exists(os.path.join(rootfs_path, "lib64"))
    utils.mkdir_if_not_exists(os.path.join(rootfs_path, "tools"))