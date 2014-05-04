#!/usr/bin/env ruby

# A script for counting actual lines of code in a file.
#
# Works for both line- and block-comments.
#
# Nested comments are not implemented.
#
# Assumes comments aren't placed haphazardly:
# Lines containing a block comment start or end character are counted as
# comment lines.
# example:
# printf("Hello World!\n") /* comment comment comment
#  * comment */ printf("Hello World!\n");
# is counted as 2 comment lines.

if ARGV.length < 1
    puts "USAGE:\n    sloc [FILE] ...\nWhere FILE is a valid path/filename."
    exit
end

filetypes = Array.new
comment_map = Hash.new
block_comment_map = Hash.new

# A file containing a mapping between extension name and comment character
# on the form of "FILE_EXTENSION ...
#                 LINE_COMMENT ...
#                 BLOCK_COMMENT_START BLOCK_COMMENT_END ..."
#
# Lines starting with "#sloc#" are ignored
# 2 lines are expected after a file extension line, if the language in question
# does not have block comments, for example, the a blank line is required.
#
# examples:
# #sloc# Python
# py
# #
# """ """
#
# #sloc# C
# c h
# //
# /* */
#
# #sloc# x86 Assembly
# s
# #
#
#
mapping_filename = File.dirname(File.realpath(__FILE__)) + "/extension_to_comment_map"

extension = nil
handle_lines = 0
File.open(mapping_filename, "r").each_line do |line|
    line.chomp!

    if handle_lines == 2
        extension.each do |ext|
            comment_map[ext] = line.split(/\s+/)
        end
        handle_lines -= 1
        next
    elsif handle_lines == 1
        extension.each do |ext|
            block_comment_map[ext] = line.split(/\s+/)
        end
        handle_lines -= 1
        next
    end

    if /#sloc#/ =~ line or /^\s*$/ =~ line
        next
    end

    extension = line.split(' ')
    filetypes << extension
    handle_lines = 2
end
filetypes.flatten!

def put_delimiter
        puts "####################"
end

ARGV.each do |arg|
    if arg == ARGV.first
        put_delimiter
    end

    filetype = /(?<=\.)[^\s\.]+$/.match(arg).to_s

    if !filetypes.include? filetype
        puts "\"." + filetype + "\" is not a supported file extension!\n\"" + arg + "\""
        put_delimiter
        next
    end

    num_loc = 0
    num_empty_lines = 0
    num_comment_lines = 0
    inside_comment_block = false
    comment_block_end = nil

    open(arg).each_line do |line|
        if inside_comment_block
            num_comment_lines += 1
            if /#{Regexp.quote(comment_block_end)}\s*$/ =~ line
                inside_comment_block = false
                comment_block_end = nil
            end
            next
        end

        catch :continue do
            line.chomp!

            if /^\s*$/ =~ line
                num_empty_lines += 1
                next
            end

            if comment_map.has_key? filetype
                comment_map[filetype].each do |comment|
                    if /^\s*#{Regexp.quote(comment)}/ =~ line
                        num_comment_lines += 1
                        throw :continue
                    end
                end
            end

            if block_comment_map.has_key? filetype
                block_comment_map[filetype].each_slice(2) do |block_start, block_end|
                    if /^\s*#{Regexp.quote(block_start)}/ =~ line
                        num_comment_lines += 1
                        if !(/#{Regexp.quote(block_end)}\s*$/ =~ line)
                            inside_comment_block = true
                            comment_block_end = block_end
                        end
                        throw :continue
                    end
                end
            end

            num_loc += 1
        end
    end

    puts "Stats for \"" + arg + "\":"
    puts "    Total lines: " + (num_loc + num_empty_lines + num_comment_lines).to_s
    puts "  Lines of code: " + num_loc.to_s
    puts "    Empty lines: " + num_empty_lines.to_s
    puts "Commented lines: " + num_comment_lines.to_s
    put_delimiter
end
