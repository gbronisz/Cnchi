#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  installation_thread.py
#  
#  Copyright 2013 Cinnarch
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  
#  Cinnarch Team:
#   Alex Filgueira (faidoc) <alexfilgueira.cinnarch.com>
#   Raúl Granados (pollitux) <raulgranados.cinnarch.com>
#   Gustau Castells (karasu) <karasu.cinnarch.com>
#   Kirill Omelchenko (omelcheck) <omelchek.cinnarch.com>
#   Marc Miralles (arcnexus) <arcnexus.cinnarch.com>
#   Alex Skinner (skinner) <skinner.cinnarch.com>

import threading
import subprocess
import os
import sys

from config import installer_settings

# Insert the src/pacman directory at the front of the path.
base_dir = os.path.dirname(__file__) or '.'
parted_dir = os.path.join(base_dir, 'pacman')
sys.path.insert(0, parted_dir)

import misc
import transaction

_autopartition_script = 'auto_partition.sh'

class InstallationThread(threading.Thread):
    def __init__(self, method, mount_devices):
        threading.Thread.__init__(self)

        self.method = method
        self.mount_devices = mount_devices
        
        print(mount_devices)
        
        self.root = mount_devices["/"]
        print("Root device : %s" % self.root)

        self.running = True
        self.error = False
        
        self.auto_partition_script_path = \
            os.path.join(installer_settings["CNCHI_DIR"], "scripts", _autopartition_script)
    
    @misc.raise_privileges    
    def run(self):
        ## Create and format partitions if we're in automatic mode
        if method == "automatic":
            try:
                if os.path.exists(self.script_path):
                       subprocess.Popen(["/bin/bash", self.script_path, self.root])
            except subprocess.FileNotFoundError as e:
                self.error = True
                print (_("Can't execute the auto partition script"))
            except subprocess.CalledProcessError as e:
                self.error = True
                print (_("subprocess CalledProcessError.output = %s") % e.output)

        ## Do real installation here
        
        # Extracted from /arch/setup script
        
        dest_dir = "/INSTALL"
        kernel_pkg = "linux"
        vmlinuz = "vmlinuz-%s" % kernel_pkg
        initramfs = "initramfs-%s" % kernel_pkg       
        pacman = "powerpill --root %s --config /tmp/pacman.conf --noconfirm --noprogressbar" % dest_dir
        
        
        
        
        
        self.chroot_mount(dest_dir)
        

        self.running = False
    
    def chroot_mount(self, dest_dir):
        dirs = [ "/sys", "/proc", "/dev" ]
        for d in dirs:
            mydir = os.path.join(dest_dir, d)
            if not os.path.exists(mydir):
                os.makedirs(mydir)

        mydir = os.path.join(dest_dir, "/sys")
        subprocess.Popen(["mount", "-t", "sysfs", "sysfs", mydir])
        subprocess.Popen(["chmod", "555", mydir])

        mydir = os.path.join(dest_dir, "/proc")
        subprocess.Popen(["mount", "-t", "proc", "proc", mydir])
        subprocess.Popen(["chmod", "555", mydir])

        mydir = os.path.join(dest_dir, "/dev")
        subprocess.Popen(["mount", "-o", "bind", "/dev", mydir])

        

    def is_running(self):
        return self.running

    def is_ok(self):
        return not self.error
