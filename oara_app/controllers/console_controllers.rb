module Ushmm
	module DigitalCollections
		module ConsoleControllers
			def self.help
				"There is no help for you."
			end


			## This command allows navigation between parent and child components.
			def self.cd path
				unless @pointer
					puts "No components loaded.  Try 'open'."
					return nil
				end

				subcomponents = path.split /\//
				while subcomponents.length > 1
					if ! self.cd subcomponents.shift
						return false
					end
				end

				subcomponent = subcomponents[0]

				if subcomponent == '..'
					new_pointer_value = @pointer.parent
				else
					new_pointer_value = @pointer[subcomponent]
				end

				if new_pointer_value
					@pointer = new_pointer_value
					return true
				else
					print "not found!"
					return nil
				end
			end

			def self.ls
				self.list_children
			end

			def self.desc
				@pointer.descendants.each { |d|
					puts d.to_ss
				}
				nil
			end

			def self.list_children
				unless @pointer
					puts "(none)"
					return
				end
				@pointer.children.each { |c|
					puts c.to_ss
				}
				nil
			end

			def self.open
				Ushmm::DigitalCollections::DSL.read_file('root.rb')
				@pointer = Ushmm::DigitalCollections::DSL.base_component  ## Point the user nav pointer at its root.
			end

			## Return the component object currently being referenced by the pointer.
			def self.get_pointer
				@pointer
			end

			def self.detail
				puts @pointer.detail
			end

			def self.errors
				puts @pointer.errors
			end

			def self.pc
				ap @pointer.ancestor_value_hash
				nil
			end

			def self.la
				ap @pointer.load_assets
			end
		end
	end
end