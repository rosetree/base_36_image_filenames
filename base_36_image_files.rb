#!/usr/bin/env ruby
# Description:
#   This script generates nearly unique image filenames. It uses the images
#   exposure date and time, converts some stuff to base 36 and appends an
#   acronym of the photographers name.

# Installation:
#   $ sudo apt-get install libexif-dev
#   $ gem install exif
#
# See more:
#   https://github.com/tonytonyjan/exif
require 'exif'

# We use FileUtils::copy
require 'fileutils'

def base_36_time(datetime)
  return nil unless datetime

  # This is shorter, than using base 36 versions of each.
  time = "#{datetime.hour}#{datetime.min}#{datetime.sec}".to_i
  time.to_s(36).rjust(4, '0')
end

def base_36_date(date)
  return nil unless date

  # Assuming all images got created after year 2000. (Saves a character.)
  year = (date.year - 2000)

  # Create unique identifier with base 36
  unique =                year.to_s(36).rjust(2, "0")
  unique = unique + date.month.to_s(36)
  unique = unique +             '-'
  unique = unique +   date.day.to_s

  return unique
end

def base_36_datetime(date)
  return nil unless date
  return base_36_date(date) + '-' + base_36_time(date)
end

class String
  def acronymify
    gsub(/\B\w+\s?/, '')
  end
end


# TODO: Add option --use-folders
use_folders = if ARGV[0] == 'use_folders'
                true
              else
                false
              end

tmp_dir = "base_36_images_of_#{base_36_datetime(Time.new)}"
puts "Note: Find renamed images in #{tmp_dir}"
Dir.mkdir(tmp_dir)

# TODO: Don’t use a hard coded file extension list.
images = Dir['*.jpg', '*.JPG']

images.each do |original_image|
  begin
    data = Exif::Data.new(original_image)
  rescue RuntimeError
    puts "ERROR: #{original_image} isn’t readable or doesn’t contain exif data"
    puts "Note: I will ignore #{original_image}"
    next
  end

  # TODO: Error? Or use file modification date?
  next if !data.date_time.is_a?(Time)

  folder = File.join(Dir.getwd, tmp_dir, base_36_date(data.date_time))

  date_id = base_36_datetime data.date_time

  # TODO: Without author. (Add option --skip-author.)
  artist_acronym = if data.artist.is_a?(String)
                     data.artist.acronymify.downcase
                   else
                     'xx'
                   end

  # TODO: Don’t use hard coded file extension.
  image_name = "#{date_id}-#{artist_acronym}.jpg"

  file_name = if use_folders
                File.join(folder, image_name)
              else
                File.join(Dir.getwd, tmp_dir, image_name)
              end

  # Make sure the destination folder exists.
  Dir.mkdir(folder) if use_folders && !File.directory?(folder)

  if File.exist?(file_name)
    puts "Error: File #{file_name} exists"
    # TODO: Don’t skip if file exists. Instead use a different name.
    next
  end

  FileUtils.copy original_image, file_name
end
