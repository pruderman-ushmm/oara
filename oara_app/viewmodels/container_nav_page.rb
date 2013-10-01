module Ushmm
	module DigitalCollections
		class ContainerNavPage
			attr_accessor :nav_path
			attr_accessor :container

			def initialize base_container, nav_path
				@container = base_container
				@nav_path = nav_path
			end

			def render path
				content = File.read(File.expand_path(File.join(Ushmm::DigitalCollections::Settings::TEMPLATES_PATH, path)))
				t = ERB.new(content)
				t.result(binding)
			end
		end
	end
end


