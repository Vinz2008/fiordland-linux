import requests
import subprocess
from os.path import exists


if not exists("wget.list"):
    subprocess.run("./update-wget-list.sh")
subprocess.run("wget --input-file=wget.list --continue --directory-prefix=../../downloads", shell=True)
