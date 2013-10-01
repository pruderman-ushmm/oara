module Ushmm
	module DigitalCollections
		class CollectionNavPage
			attr_accessor :nav_path
			attr_accessor :collection

			def initialize base_collection, nav_path
				@collection = base_collection
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


