# data example
# http://danbooru.donmai.us/post/index.xml/?limit=10&page=1&tags=konpaku_youmu
# api here
# http://danbooru.donmai.us/help/api

# version 0.1-dev

require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'fileutils'

class Danbooru

  def initialize(tags)
    @num = 1
    @page = 1
    @tag = tags.gsub(" ","_")
    FileUtils.mkdir_p @tag
    path = File.join(@tag,"files.bbs")
    @bbs = File.new(path,"a+")
    @old_file = @bbs.read
    get_data(@page)
    @count = @doc.root["count"]
    @pages = @count.to_i/100 + 1
  end

  def download_all
    while have_elements do
      download
      next_page
    end
    puts "Thats all"
  end

  private

  def have_elements
    @posts.size > 0
  end

  def next_page
    @page += 1
    puts "Switching to page #{@page} of #{@pages}"
    get_data(@page)
  end

  def get_data(page_num)
    data = ""
    while data.empty?
      begin
        data = open("http://danbooru.donmai.us/post/index.xml?limit=100&page=#{page_num}&tags=#{@tag}").read
      rescue => ex
        puts "Error reading data — #{ex}"
      end
    end
    @doc = Nokogiri::XML(data)
    @posts = @doc.xpath("//posts/post")
  end

  def write_tags(filename,tags)
    @bbs.puts "#{filename} - #{tags}"
  end

  def download
    @posts.each do |post|
      url = post["file_url"]
      filename = File.join(@tag,url.gsub("http://s3.amazonaws.com/danbooru/","").gsub("http://danbooru.donmai.us/data/",""))
      tags = post["tags"]
      if File.exist?(filename) && !File.zero?(filename)
        puts "File exist - #{filename} (#{@num}/#{@count})"
      else
        puts "saving #{filename}... (#{@num}/#{@count})"
        open(filename,"wb").write(open(url).read)
        puts "saved!"
      end
      write_tags(filename,tags) if !@old_file.include?(filename)
      @num += 1
    end
  end

end

#if ARGV.length == 0
#  puts "Usage: danbooru.rb tags=\"bla bla\" limit=100 offset=10"
#  exit 0
#end

#@params = {}
#  ARGV.each { |arg| @params.merge!(Hash[*arg.split('=')])}
#pp @params

if ARGV.length == 0 || ARGV[0].empty?
  puts "Usage: danbooru.rb \"tags\""
else
  puts "tags are #{ARGV[0]}"
  d = Danbooru.new(ARGV[0])
  d.download_all
end
