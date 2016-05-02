# frozen_string_literal: true
Dir.glob("lib/tasks/*.rake").each { |file| load file }
require "rubygems/tasks"
Gem::Tasks.new

task default: %w[spec rubocop]
