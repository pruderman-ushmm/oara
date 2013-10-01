module Ushmm
	module DigitalCollections
		module Controllers
			@logger = Logging.logger[self]




			## Renders a USHMM page with a book reader embedded in it.
		    def self.book_frame path_info_data
		    	page = Page.new("Home", "#CCCCCC")
				return page.render("index.html.erb")
		    end

		    ## This controller renders the template for the full-screen bookreader.
		  #   def self.book_reader path_info_data
		  #   	page = Page.new("Home", "#CCCCCC")
				# return page.render("full_screen_bookreader.html.erb")
		  #   end


		    def self.book_nav_page path_info_data
				bc = Ushmm::DigitalCollections::DSL.base_component  ## Point the user nav pointer at its root.
				unless bc.children.count > 0
					Ushmm::DigitalCollections::DSL.read_file('root.rb')
				end

				## Set the target collection:
				target_collection = bc
				path_components = path_info_data.split /\//

				## This bit is a little ugly:
				path_components.shift
				if path_components[0] == 'root'
					path_components.shift
				end

				@logger.warn path_components.inspect
				path_components.each { |pc|
					@logger.warn "Target collection: "
					@logger.warn target_collection
					target_collection = target_collection[pc]
					unless target_collection
						raise "Cannot find path component #{pc}!"
					end
				}

				if target_collection.book_title
			    	page = Page.new("Home", path_info_data)
					return page.render("full_screen_bookreader.html.erb")
					# return "This is book: #{target_collection.book_title}"
				else
					return "This is not book"
				end

		    end


		    def self.collection_nav_page path_info_data
				bc = Ushmm::DigitalCollections::DSL.base_component  ## Point the user nav pointer at its root.
				unless bc.children.count > 0
					Ushmm::DigitalCollections::DSL.read_file('root.rb')
				end

				## Set the target collection:
				target_collection = bc
				path_components = path_info_data.split /\//

				## This bit is a little ugly:
				path_components.shift
				if path_components[0] == 'root'
					path_components.shift
				end

				@logger.warn path_components.inspect
				path_components.each { |pc|
					@logger.warn "Target collection: "
					@logger.warn target_collection
					target_collection = target_collection[pc]
					unless target_collection
						raise "Cannot find path component #{pc}!"
					end
				}

				target_collection.load_assets

		    	page = CollectionNavPage.new(target_collection, path_info_data)
				return page.render("collection_nav.html.erb")
		    end

		    def self.container_nav_page path_info_data
				bc = Ushmm::DigitalCollections::DSL.base_container  ## Point the user nav pointer at its root.
				unless bc.children.count > 0
					@logger.debug "Base container is empty, loading root.rb."
					Ushmm::DigitalCollections::DSL.read_file('root.rb')
				end

				## Set the target_container variable:
				target_container = bc
				path_components = path_info_data.split /\//

				## This bit is a little ugly:
				path_components.shift
				if path_components[0] == 'root_container' or path_components[0] == 'archive_container-root_container'
					path_components.shift
				end

				@logger.warn path_components.inspect
				path_components.each { |pc|
					@logger.warn "Target container: "
					@logger.warn target_container
					pc_level, pc_designation = pc.split /[-]/
					target_container = target_container[pc_designation, pc_level]
					unless target_container
						raise "Target container not found: [#{pc_level}] #{pc_designation}"
					end
					unless target_container.class == Ushmm::DigitalCollections::Container
						raise "Incorrect class (in loop): #{target_container.class}"
					end
				}

				unless target_container.class == Ushmm::DigitalCollections::Container
					raise "Incorrect class (after loop): #{target_container.class}"
				end

				# target_container.load_assets

		    	page = ContainerNavPage.new(target_container, path_info_data)
				return page.render("container_nav.html.erb")
		    end

		    def self.book_json path_info_data
				@logger.debug "book_json here, path_info_data: #{path_info_data}"

				# Ushmm::DigitalCollections::DSL.read_file('root.rb')
				# bc = Ushmm::DigitalCollections::DSL.base_component  ## Point the user nav pointer at its root.



				##########################
				bc = Ushmm::DigitalCollections::DSL.base_component  ## Point the user nav pointer at its root.
				unless bc.children.count > 0
					Ushmm::DigitalCollections::DSL.read_file('root.rb')
				end

				## Set the target collection:
				target_collection = bc
				path_components = path_info_data.split /\//

				## This bit is a little ugly:
				path_components.shift
				if path_components[0] == 'root'
					path_components.shift
				end

				@logger.warn path_components.inspect
				path_components.each { |pc|
					@logger.warn "Target collection: "
					@logger.warn target_collection
					target_collection = target_collection[pc]
					unless target_collection
						raise "Cannot find path component #{pc}!"
					end
				}
				##########################
				
#				target_collection = bc['USHMM']['RG-56.001']
#				target_collection = bc['USHMM']['RG-15.118M']['1']

				# target_collection.load_assets
				r = target_collection.dump_book_json
				@logger.debug "JSON:"
				@logger.debug r

				return r
		    end

		    def self.archives
		    	archives = DigitalCollections::Archves
		    	page = Page.new("Achives", "#CCCCCC")
		    	return page.render("archives.html.erb")
		    end
		end

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