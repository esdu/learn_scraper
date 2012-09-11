require_relative 'lib/ssl_fix'
require 'yaml'
require 'mechanize'
require 'fileutils'
require 'colorize'

class Page
  @@agent = Mechanize.new
  @@checkmark = "\u2713".green
  @@skip = "\u2605".yellow

  def self.legend
    puts "Legend:"
    puts "  #{@@checkmark} => a file is downloaded"
    puts "  #{@@skip} => a file is skipped because it already exists"
  end

  def regex_link(page, regex)
    page.links.find { |l| l.text =~ /#{regex}/ }
  end
end

class LoginPage < Page
  def login(u, p)
    puts "Logging in"
    page = @@agent.get('https://learn.uwaterloo.ca/')
    form = page.forms.first
    form.username = u
    form.password = p
    @@agent.submit form, form.button('submit')
  end
end

class HomePage < Page
  def initialize(page)
    @page = page
  end

  def find_class_link(class_name)
    regex_link(@page, class_name)
  end
end

class ClassPage < Page
  def initialize(link, class_name, output_dir)
    @page = link.click
    @class_name = class_name
    @output_dir = output_dir
  end

  def get_class_id_from_page(page)
    r = CGI::parse(page.uri.query)
    r['ou'][0]
  end

  def get_item_id_from_link(link)
    onclick = link.node.attribute("onclick").value
    r = /^PreviewTopic\((.*), true\);$/.match(onclick)
    if r
      r[1]
    else
      nil
    end
  end

  def download_url(item_id, class_id)
    "https://learn.uwaterloo.ca/d2l/lms/content/preview.d2l?tId=#{item_id}&ou=#{class_id}"
  end

  def clean_filename(filename)
    # diagonalization_practice.pdf__&d2lSessionVal=Ykl3yClGpy6aCR2VBzb4QbJtl&d2l_body_type=3 ---> diagonalization_practice.pdf
    r = /^(.*)__&.*$/.match filename
    if r
      r[1]
    else
      filename
    end
  end

  # This downloads through a preview link from download_url, which goes through an iframe...
  def download(url, name)
    page = @@agent.get(url)
    iframe = page.iframes.first
    file = iframe.click

    # Class names like "AFM 131 / ARBUS 101" -> "AFM 131 - ARBUS 101"
    folder = "#{@output_dir}/#{@class_name.gsub('/', ' - ')}"
    FileUtils.mkdir_p folder
    filename = clean_filename(file.filename)
    path = "#{folder}/#{filename}"

    if FileTest.exists? path
      puts "#{@@skip} #{path}"
    else
      file.save_as path
      puts "#{@@checkmark} #{path}"
    end
  end

  def work
    puts "Fetching files for #{@class_name}"
    content_page = regex_link(@page, 'Content').click
    download_page = regex_link(content_page, 'Print/Download').click

    class_id = get_class_id_from_page(download_page)

    download_page.links_with(:dom_class => 'D2LLink').each do |l|
      item_id = get_item_id_from_link l
      if item_id
        download download_url(item_id, class_id), l.text
      end
    end
  end
end

class LearnScraper
  def initialize()
    @config = read_config
  end

  def read_config
    raw = YAML.load_file("config.yml")
    {
      username:         raw['username'],
      password:         raw['password'],
      classes:          raw['classes'],
      dropbox_location: raw['dropbox_location']
    }
  end

  def work
    current_dir = File.expand_path(File.dirname(__FILE__))
    output_dir = @config[:dropbox_location] || "#{current_dir}/downloads"

    home_page =
      HomePage.new(LoginPage.new.login(@config[:username], @config[:password]))

    @config[:classes].each do |class_name|
      link = home_page.find_class_link class_name
      ClassPage.new(link, class_name, output_dir).work
    end
  end
end

puts "Starting Scraper"
puts Page.legend

beginning = Time.now

LearnScraper.new.work

puts "Done!"
puts "Time elapsed #{Time.now - beginning} seconds"
