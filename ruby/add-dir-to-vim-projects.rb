#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# -*-      Ruby     -*-
# ----------------------------------------------- #
# Ruby source single (add-dir-to-vim-projects.rb) #
# Author: Alexei Panov <me@elemc.name>            #
# ----------------------------------------------- #
# Description: This script generate .vimprojects 
# content for given directories

VIMPROJECTS_FILE    = File.join( Dir.home, ".vimprojects" )
INDENT              = "    "
SKIP_DIR_ENTRIES    = [ '.',
                        '..',
                        '.git',
                        '.gitkeep',
                        'tmp',
                      ]
SKIP_EXT_ENTRIES    = [ '.pyc',
                        '.pyo',
                        '.swp',
                      ]

class AddDirToVimProjects < Object
    def initialize( folders )
        if folders.kind_of? Array
            @folders = folders
        else
            @folders = [ folders ]
        end
        check_folders
        check_vimprojects
    end

    def is_ok?; @ok; end

    def proceed
        return nil unless @ok
        @records = []
        @folders.each do |folder|
            path_to, name = File.split( folder )
            path_to
            record = []
            record << "#{name}=#{folder} CD=. {" # top-level project record
            scan_folder( folder, record )
            record << "}" # finalize record
            @records << record.join( "\n" )
        end

        @records
    end

    def write
        return nil if @records.size == 0
        File.open( VIMPROJECTS_FILE, 'a' ) do |f|
            f.puts("\n")
            @records.each { |rec| f.puts( rec ) }
        end
    rescue
        puts "Error per open file #{VIMPROJECTS_FILE}"
        return nil
    else
        return true
    end

    private

    def add_entry?( entry )
        return false if SKIP_DIR_ENTRIES.include? entry

        # skip .pyc and .pyo files
        return false if SKIP_EXT_ENTRIES.include? File.extname( entry )

        true
    end

    def scan_folder( folder, record, indent = INDENT )
        files = []
        Dir.open( folder ).sort.each do |entry|
            full_path = File.join( folder, entry )
            next unless add_entry? entry

            
            if File.directory? full_path
                record << "#{indent}#{entry}=#{entry}/ {" # open directory
                scan_folder( full_path, record, indent+INDENT )
                record << "#{indent}}" # close directory
            else
                files << "#{indent}#{entry}"
            end
        end
        record << files
    end

    def check_folders
        @ok = true
        @folders.each { |dir| @ok &= Dir.exists? dir }
    end

    def check_vimprojects
        @ok &= File.exists? VIMPROJECTS_FILE
    end
end

if __FILE__ == $0
    puts ARGV
    exit 1 if ARGV.size == 0
    c = AddDirToVimProjects.new( ARGV )
    c.proceed   # generate list
    c.write     # write to file
end

