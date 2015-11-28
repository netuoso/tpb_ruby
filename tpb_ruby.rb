#!/usr/bin/env ruby
# This file handles the user interaction with api_base.rb
# This is intended to be used as a console/headless script
# Written by @Netuoso

require './api_base'

require 'optparse'
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'restclient'
require 'torrent-ruby'

class ApiWrapper
  def initialize
    @options = {page: 0, ordering: Constants::ORDERING.default, type: Constants::CATEGORIES.default}
    @base_url = Constants::BASE_URL

    opt_parser = OptionParser.new do |opt|
      opt.banner = "Usage: #{__FILE__} COMMAND [OPTIONS]"
      opt.separator  ""
      opt.separator  "Commands"
      opt.separator  "     recent: List recently uploaded torrents"
      opt.separator  "     search: Search for a specific torrent; returns torrent ID"
      opt.separator  "     download: Download a specific torrent; requires torrent ID"
      opt.separator  "     info: List how many torrents/seeders/leechers are present"
      opt.separator  ""
      opt.separator  "Options"

      opt.on("-t","--type TYPE","Specify media type; all|audio|video|music|porn|other") do |type|
        @options[:type] = type
      end

      opt.on("-o","--ordering ORDER","Specify sorting order (asc)") do |ordering|
        @options[:ordering] = ordering
      end

      opt.on("-p","--pages PAGES","Number of result pages to display at maximum (1)") do |pages|
        @options[:pages] = pages
      end

      opt.on("-v","--version","Display this program's version") do
        puts "Version 1.0.0"
        puts "Written by @Netuoso"
      end

      opt.on("-h","--help","Display this help") do
        puts opt_parser
      end
    end

    opt_parser.parse!

    case ARGV[0]
    when nil
      puts opt_parser
    else
      process(ARGV[0])
    end
  end

  def process(action)
    case action
    when 'recent'
      recent
    when 'top'
      top
    when 'search'
      search(ARGV[1])
    when 'download'
      download(ARGV[1])
    when 'info'
      info
    end
  end

  def recent
    results = {}
    url = URI::encode(@base_url + '/recent')
    page = Nokogiri::HTML(RestClient.get(url))
    torrent_rows = page.css('tr')[1...-1]
    torrent_rows.each_with_index do |result, index|
      results.merge!({"torrent_#{index+1}" => {info: result.text.lstrip.gsub("\t", "").gsub("\n", " "), magnet: ""}})
    end if torrent_rows
    links = page.css("a[title='Download this torrent using magnet']").select { |link| link['title'] = 'Download this torrent using magnet' }
    links[0...torrent_rows.count].each_with_index do |link, index|
      results["torrent_#{index+1}"][:magnet] = link['href']
    end if torrent_rows
    results.each do |result|
      puts result
    end
    p "Listed #{torrent_rows ? torrent_rows.count : 0} recent torrents sorted by seeders (desc)."
  end

  def top(opts=[])
    results = {}
    url = URI::encode(@base_url + "/top/#{@options[:type]}")
    page = Nokogiri::HTML(RestClient.get(url))
    torrent_rows = page.css('tr')[1...-1]
    torrent_rows.each_with_index do |result, index|
      results.merge!({"torrent_#{index+1}" => {info: result.text.lstrip.gsub("\t", "").gsub("\n", " "), magnet: ""}})
    end if torrent_rows
    links = page.css("a[title='Download this torrent using magnet']").select { |link| link['title'] = 'Download this torrent using magnet' }
    links[0...torrent_rows.count].each_with_index do |link, index|
      results["torrent_#{index+1}"][:magnet] = link['href']
    end if torrent_rows
    results.each do |result|
      puts result
    end
    p "Listed #{torrent_rows ? torrent_rows.count : 0} top torrents sorted by seeders (desc)."
  end

  def search(query, opts=[])
    results = {}
    url = URI::encode(@base_url + "/search/#{query}/#{@options[:page]}/#{@options[:ordering]}/#{@options[:type]}")
    page = Nokogiri::HTML(RestClient.get(url))
    torrent_rows = page.css('tr')[1...-1]
    torrent_rows.each_with_index do |result, index|
      results.merge!({"torrent_#{index+1}" => {info: result.text.lstrip.gsub("\t", "").gsub("\n", " "), magnet: ""}})
    end if torrent_rows
    links = page.css("a[title='Download this torrent using magnet']").select { |link| link['title'] = 'Download this torrent using magnet' }
    links[0...torrent_rows.count].each_with_index do |link, index|
      results["torrent_#{index+1}"][:magnet] = link['href']
    end if torrent_rows
    results.each do |result|
      puts result
    end
    p "Listed #{torrent_rows ? torrent_rows.count : 0} related torrents sorted by seeders (desc)."
  end

  def download(torrent_id)
    # TODO: Enable downloading?
    p "Not yet implemented"
  end

  def info
    puts "ThePirateBay Unofficial Ruby API written by @Netuoso"
  end
end

ApiWrapper.new