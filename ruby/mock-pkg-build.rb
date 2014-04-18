#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# -*-      Ruby     -*-
# -------------------------------------- #
# Ruby source single (mock-pkg-build.rb) #
# Author: Alexei Panov <me@elemc.name>   #
# -------------------------------------- #
# Description: 

require 'tmpdir'
require 'fileutils'

MOUNT_POINT                 = "/mnt/repos"
INCOMING_PKGS               = "#{MOUNT_POINT}/incoming-pkgs"
SSHFS_CMD                   = "/usr/bin/sshfs root@elemc.name:/srv/web/repos #{MOUNT_POINT} -o allow_other,uid=1000,gid=990"
UMOUNT_CMD                  = "/usr/bin/fusermount -u #{MOUNT_POINT}"
UPDATE_REPOS_CMD            = "ssh root@elemc.name 'python /usr/local/bin/sortrpms.py'"
SUPPORTED_ARCHS             = [ "i386", "x86_64" ]
SUPPORTED_FEDORA_VERSIONS   = [ "19", "20", "rawhide" ]
SUPPORTED_EPEL_VERSIONS     = [ "6" ]

class MockPkgBuild < Object

    def initialize( dist, source_package )
        @not_installed_pkg      = []
        @error_msgs_list        = []
        @check_hash = {
            "mock"              => "/usr/bin/mock",
            "fuse-sshfs"        => "/usr/bin/sshfs",
            "fuse"              => "/usr/bin/fusermount",
            "openssh-clients"   => "/usr/bin/ssh",
        }

        @dist = dist
        @source_package = source_package

        # checks
        @is_ok = true
        @is_ok &= external_tools_presents?
        @is_ok &= check_make_dir?( MOUNT_POINT )
    end

    def is_ok?; @is_ok; end
    def not_installed_pkg; @not_installed_pkg end

    def print_error_messages
        @error_msgs_list.each { |msg| log msg }
    end

    def run
        return false unless @is_ok
        return false unless mount?
        return false unless check_make_dir? INCOMING_PKGS

        log "Build..."
        build_prefix = "elemc-#{@dist}"
        versions     = if @dist.include? "fedora"
                        SUPPORTED_FEDORA_VERSIONS
                       else
                        SUPPORTED_EPEL_VERSIONS
                       end
        @build_result= true
        unless @dist.include? "-"
            versions.each { |ver| build( "#{build_prefix}-#{ver}" ) }
        else
            build( build_prefix )
        end

        return false unless umount?

        if @build_result
            log "Update repositories"
            `#{UPDATE_REPOS_CMD}`
        end

        log "Final"
    end

    def self.setup
        # TODO: make setup
    end

    def self.log ( log_msg )
        puts "\033[35m#{log_msg}\033[0m"
    end

    def log ( log_msg )
        self.class.log ( log_msg )
    end

private

    def error( error_msg )
        @error_msgs_list << error_msg
    end

    def binary_exists?( path, pkg )
        if not File.exists? path
            @not_installed_pkg << pkg
            return false
        end
        true
    end

    def external_tools_presents?
        result = true
        @check_hash.each_pair { |key, value| result &= binary_exists?( value, key ) }
        error "Please install packages: #{@not_installed_pkg.join(" ")}" unless result
        result
    end

    def check_make_dir?( dir )
        Dir.mkdir( dir ) unless Dir.exists? dir
    rescue SystemCallError
        error "Directory \"#{dir}\" doesn't exist and don't be a create. Check permissions."
        return false
    else
        true
    end

    def build( build_prefix )
        SUPPORTED_ARCHS.each do |arch| 
            build_config = "#{build_prefix}-#{arch}"
            @build_result &= run_mock( build_config )
        end
    end

    def command_for_mount?( cmd )
        `#{cmd}`
        mount_points = `mount`
        mount_points.include? MOUNT_POINT
    end        

    def mount?
        result = command_for_mount?(SSHFS_CMD)
        error "Error in command: #{SSHFS_CMD}" unless result
        result
    end        

    def umount?
        result = command_for_mount?(UMOUNT_CMD)
        error "Error in command: #{UMOUNT_CMD}" if result
        !result
    end

    def run_mock( build_config )
        result_dir = Dir.mktmpdir build_config
        log "Build for #{build_config} in resultdir: #{result_dir}"
        mock_cmd = "/usr/bin/mock -r #{build_config} --rebuild #{@source_package} --resultdir #{result_dir}"
        output = `#{mock_cmd}`
    rescue
        error "Error in command: #{mock_cmd}"
        return false
    else
        # copy packages
        listfiles = []
        Dir.new( result_dir ).each do |file|
            listfiles << File.join(result_dir, file) if File.extname(file) == ".rpm"
        end

        begin
            FileUtils.cp( listfiles, INCOMING_PKGS )
        rescue
            error "Error in copy files"
            return false
        end
        FileUtils.rm_rf( result_dir )
        true
    end

end

if __FILE__ == $0

    if ARGV.size == 1 and ARGV[0] == "setup"
        MockPkgBuild.setup
        exit 0
    end

    if ARGV.size < 2
        MockPkgBuild::log ("Please use this script as '#{$0} [distributive] [/path/to/src.rpm]'")
        MockPkgBuild::log ("\t distributive is a 'fedora' or 'epel'")
        exit 1
    end

    dist_name      = ARGV[0]
    source_path    = ARGV[1]

    mock = MockPkgBuild.new( dist_name, source_path )
    unless mock.is_ok?
        mock.print_error_messages
        exit 1
    end
    unless mock.run
        mock.print_error_messages
        exit 1
    end
end

