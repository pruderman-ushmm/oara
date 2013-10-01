module Ushmm
	module DigitalCollections
		class Page
#			attr_accessor :binding
			attr_accessor :path_info_data

			def initialize title, path_info_data_s
				@title = title
				# @color = '#cccccc'
				# @path_info_data = path_info_data
				@path_info_data = path_info_data_s
			end


			def render path
				content = File.read(File.expand_path(File.join(Ushmm::DigitalCollections::Settings::TEMPLATES_PATH, path)))
				t = ERB.new(content)
				t.result(binding)
				#	p(binding())
			end
		end
	end
end


