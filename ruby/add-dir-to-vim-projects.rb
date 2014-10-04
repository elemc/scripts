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
                        '.gitignore',
                        '.keep',
                        'Gemfile.lock',
                        'schema.rb',
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

        if @ok
            @buf_file = IO.readlines( VIMPROJECTS_FILE )
        else
            @buf_file = nil
        end
    end

    def is_ok?; @ok; end

    def proceed
        return nil unless @ok
        @records = []
        @folders.each do |raw_folder|
            folder = raw_folder
            if raw_folder[-1] == "/"
                folder = raw_folder[0..-2]
            end
            path_to, name = File.split( folder )
            path_to
            record = []
            tilda_folder = folder.sub( Dir.home, "~" )
            root_level_record = "#{name}=#{tilda_folder} CD=. {"
           
            new_file = []
            project_begin_index = @buf_file.index( root_level_record + "\n" )
            project_end_index = @buf_file.size + 1 
            unless project_begin_index.nil?
                new_file += @buf_file[0...project_begin_index]
                counter = 0
                pos = project_begin_index
                @buf_file[project_begin_index..@buf_file.size].each do |s|
                    pos += 1
                    counter += 1 if s.include? "{"
                    counter -= 1 if s.include? "}"
                    break if counter == 0
                end
                project_end_index = pos
            else
                new_file += @buf_file
            end

            puts "Begin: #{project_begin_index}. End: #{project_end_index}. Size: #{@buf_file.size}"

            record << root_level_record # top-level project record
            scan_folder( folder, record )
            record << "}" # finalize record

            new_file += record
            new_file += @buf_file[project_end_index..@buf_file.size] if project_end_index <= @buf_file.size

            @buf_file = new_file
        end
    end

    def write
        return nil if @buf_file.size == 0
        File.open( VIMPROJECTS_FILE, 'w' ) do |f|
            @buf_file.each do |rec|
                next if rec == "\n"
                f.puts( rec )
            end
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

