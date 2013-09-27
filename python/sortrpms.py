#!/usr/bin/env python
# -*- coding: utf-8 -*-
# =========================================== #
# Python script to sort and move RPM packages #
# Author: Alexei Panov                        #
# e-mail: elemc AT atisserv DOT ru            #
# =========================================== #

import os.path
import rpm
from os.path import join as pathjoin
import shutil

EL_DISTR                = 'epel'
FEDORA_DISTR            = 'fedora'
ARCH_FIX                = '$arch'

class RPM:
    def __init__(self, rpm_hdr):
        self._init_lvar()
        if type(rpm_hdr) is rpm.hdr:
            self.name           = rpm_hdr['name']
            if rpm_hdr.isSource():
                self.type       = 1
            else:
                self.type       = 0
            self.arch           = self._replace_arch(rpm_hdr['arch'])
            self.os             = rpm_hdr['os']
            self.version        = rpm_hdr['version']
            self.release        = rpm_hdr['release']
            self.distr, self.distr_ver    = self._get_distr()

    def is_null(self):
        if ( len(self.distr) == 0 ) or ( len(self.distr_ver) == 0 ):
            return True
        return False

    def set_file_name(self, fn):
        self.filename = fn

    def set_dest_path(self, dp):
        self.dest_path = dp

    def is_debuginfo(self):
        if 'debuginfo' in self.name:
            return True
        return False

    def is_srpm(self):
        if self.type == 1:
            return True

    def _replace_arch(self, arch):
        if 'i' in arch and '86' in arch:
            return 'i386'
        return arch

    def _init_lvar(self):
        self.name       = ''
        self.type       = 0 # if 0 - binary, 1 - source
        self.arch       = 'noarch'
        self.os         = ''
        self.version    = ''
        self.release    = ''
        self.distr      = ''
        self.distr_ver  = 0
        self.filename   = ''
        self.dest_path  = ''
        self.dirs_for_updaterepo = []

    def _get_distr(self):
        if len(self.release) == 0:
            return '', ''

        distr = '';
        distr_ver = '';
        r = self.release.split('.')
        for rel_part in r:
            if 'fc' in rel_part:
                distr = FEDORA_DISTR
                distr_ver = rel_part[2:]
            elif 'el' in rel_part:
                distr = EL_DISTR
                distr_ver = rel_part[2:]
        return distr, distr_ver

class SortRPMs:

    sourcedir               = "/srv/web/repos/incoming-pkgs"
    destdir                 = "/srv/web/repos"
    fedoradir_name          = "fedora"
    epeldir_name            = "el"
    debuginfo_dir           = 'debug'
    srpm_dir                = 'SRPMS'
    arch_includes_debuginfo = True
    arches                  = ['i386', 'x86_64']
    create_repo_cmd         = 'createrepo -x debug/* %s > /dev/null'
    remove_source_files     = True

    def __init__(self):
        _new_files = self.get_new_files()
        self.packages = None
        if len(_new_files) > 0:
            self.packages = self.parse_files(_new_files)

    def __del__(self):
        pass

    def is_empty(self):
        if self.packages is None:
            return True
        return False

    def get_new_files(self):
        print("Source dir: %s" % self.sourcedir)
        if (not os.path.exists(self.sourcedir)) or (not os.path.isdir(self.sourcedir)):
            return list()
        
        rpm_list = []
        for _rpm in os.listdir(self.sourcedir):
            if _rpm[-3:].lower() == 'rpm':
                rpm_list.append(_rpm)
        return rpm_list

    def _parse_hdr(self, hdr, filename):
        pkg = RPM(hdr)
        pkg.set_file_name(filename)
        pkg.set_dest_path(self._get_dest_path(pkg))
        if pkg.is_null():
            return None
        return pkg
        
    def parse_files(self, files_list):
        pkg_list = []

        ts = rpm.TransactionSet()
        for _rpm in files_list:
            fn = os.path.join(self.sourcedir, _rpm)
            fdno = os.open(fn, os.O_RDONLY)
            hdr = ts.hdrFromFdno(fdno)
            os.close(fdno)
            pkg = self._parse_hdr(hdr, _rpm)
            if pkg is not None:
                pkg_list.append(pkg)
        return pkg_list

    def show(self):
        for pkg in self.packages:
            print "* /%s/%s/%s/%s" % (pkg.distr, pkg.distr_ver, pkg.arch, pkg.filename);

    def debug(self, msg):
        print("DEBUG: %s" % msg)

    def _get_dest_path(self, pkg):
        dest_path = self.destdir

        # add distr path
        if pkg.distr == FEDORA_DISTR:
            dest_path = pathjoin(dest_path, self.fedoradir_name)
        elif pkg.distr == EL_DISTR:
            dest_path = pathjoin(dest_path, self.epeldir_name)
        else:
            self.debug('Package %s doesn\'t contain information about distributive' % pkg.filename)
            return None
            
        # add distr version path
        if len(pkg.distr_ver) == 0:
            self.debug('Package %s doesn\'t contain information about distributive version' % pkg.filename)
            return None

        dest_path = pathjoin(dest_path, pkg.distr_ver)

        # add arch path
        if pkg.is_debuginfo() and not self.arch_includes_debuginfo:
            dest_path = pathjoin(dest_path, self.debuginfo_dir)
            return dest_path

        if pkg.is_srpm():
            dest_path = pathjoin(dest_path, self.srpm_dir)
        elif pkg.arch == 'noarch':                          # this package need do copy in all archs
            dest_path = pathjoin(dest_path, ARCH_FIX)
        else:
            dest_path = pathjoin(dest_path, pkg.arch)

        if pkg.is_debuginfo():
            dest_path = pathjoin(dest_path, self.debuginfo_dir)

        return dest_path

    def _move_file(self, src_file, dst_path, oper_type = None):
        # check dest dir
        if not os.path.exists(dst_path):
            try:
                os.makedirs(dst_path)
            except OSError:
                self.debug("Directorie(s) don't be a create [%s]" % dest_path)
                return

        if oper_type is None:
            shutil.move(src_file, dst_path)
        else:
            shutil.copy(src_file, dst_path)

        if dst_path not in self.dirs_for_updaterepo:
            self.dirs_for_updaterepo.append(dst_path)

    def move_packages(self):
        if len(self.packages) == 0:
            return
        self.dirs_for_updaterepo = []
        for pkg in self.packages:
            src_file = pathjoin(self.sourcedir, pkg.filename)
            if ARCH_FIX in pkg.dest_path:
                haserror = False
                for a in self.arches:
                    temp_dest = pkg.dest_path.replace(ARCH_FIX, a)
                    try:
                        self._move_file(src_file, temp_dest, 'copy')
                    except:
                        haserror = True
                if not haserror and self.remove_source_files:
                    os.unlink(src_file)
            else:
                try:
                    tocopy = None
                    if not self.remove_source_files:
                        tocopy = 'copy'
                    self._move_file(src_file, pkg.dest_path, tocopy)
                except:
                    self.debug("File %s don't moved" % src_file)
                    continue
                

    def create_repo(self):
        for repo in self.dirs_for_updaterepo:
            exit_status = os.system(self.create_repo_cmd % repo)
            if exit_status != 0:
                self.debug("createrepo on %s failed." % repo)

    def show(self):
        print("============================================================")
        for r in self.dirs_for_updaterepo:
            print("repo to update: %s" % r)
        print("============================================================")

if __name__ == "__main__":
    s = SortRPMs()
    if not s.is_empty():
        s.move_packages()
        s.create_repo()
        s.show()

