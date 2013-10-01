#!/usr/bin/ruby

require "rubygems"

# Load the json gem:
require 'json'
#gem "json"

# Load the rsolr gem:
require "rsolr"
#gem "rsolr"

[
  'erb',
  'pathname',
  'nokogiri',
  'readline',
  'readline/history/restore',
  'fileutils',
  'shellwords',
  'pp',
  'logging',
  'ruby-progressbar',
  'awesome_print',

  # "./lib/solr_gateway.rb",
  # "./lib/ead.rb",
  "./settings.rb",


  "./oara_app/dsl/dsl.rb",
  "./oara_app/models/component.rb",
  "./oara_app/models/container.rb",
  "./oara_app/models/asset.rb",
  "./oara_app/controllers/controllers.rb",
  "./oara_app/viewmodels/page.rb",
  "./oara_app/viewmodels/collection_nav_page.rb",
  "./oara_app/viewmodels/container_nav_page.rb",

  ].each { |l| puts "Loading #{l}..."; require l }

