require "./main.rb"


class UshmmBookReaderRackApplication
	def call(env)
		return Ushmm::DigitalCollections::Main.respond(env)
	end
end

run UshmmBookReaderRackApplication.new

