module Ushmm
	module DigitalCollections
		module DSL
			@logger = Logging.logger[self]

			def self.base_component= new_base_component
				@base_component = new_base_component
			end

			def self.base_component
				unless @base_component
					@base_component = Ushmm::DigitalCollections::Component.new :archive, 'root'
				end
				return @base_component
			end
			def self.base_container
				unless @base_container
					@base_container = Ushmm::DigitalCollections::Container.new :archive_container, 'root_container'
				end
				return @base_container
			end

			def self.read_file filename
				complete_path = Pathname.new(Ushmm::DigitalCollections::Settings::COLLECTION_PATH).join Pathname.new(filename)
				@logger.debug "Opening #{complete_path}"
				self.module_eval(File.open( complete_path ).read)
			end

			def self.component level_type, designation, filename=nil, &block
				unless @component_ptr
					@component_ptr = self.base_component
				end

				@logger.debug "Pointer is at " + @component_ptr.breadcrumbs

				old_component_ptr = @component_ptr

				## Add this component (or reopen it if it exists.)
				if @component_ptr[designation]
					@component_ptr = @component_ptr[designation]
					## Should check to make sure correct type here !!!
				else
					@component_ptr = @component_ptr.add_child level_type, designation
				end
				new_component = @component_ptr

				## Now evaluate the block for this component, adding children.
				if block
					module_eval(&block)
				end
				if filename
					read_file filename
				end

				## Now that we've evaluated the block, reset the component pointer the previous value.
				@component_ptr = old_component_ptr

				return new_component
			end

			def self.container level_type, designation, filename=nil, &block
				@logger.debug "Processing container [#{level_type.to_s}] #{designation}'"
				@logger.debug "@container_ptr is #{@container_ptr.inspect}"
				@logger.debug "@component_ptr is #{@component_ptr}"
	
				if @component_ptr.class == Array
					raise "Component pointer is array.  This is bad."
				end
				# if @container_ptr
				# 	@logger.debug "cp is TRUE!"
				# else
				# 	@logger.debug "cp is FALSE!"
				# end

				if level_type.class != Symbol
					raise "level_type should be a symbol!"
				end
				if designation.class == Range
					designation = designation.to_a
				end
				if designation.class == Array
					if block_given?
						raise "Blocks and ranges cannot be used together."
					end
					@logger.debug "******** Container range specified! ********"
					@logger.debug "@container_ptr is #{@container_ptr.inspect}"

					designation.each { |d|
						self.container level_type, d, filename
						@logger.debug "@container_ptr is #{@container_ptr.inspect}"
						@container_ptr = @container_ptr.parent
					}
					@logger.debug "******** Done doing range. ********"
					return true
				end

				if designation.class == Fixnum
					@logger.debug "Converting designation #{designation} to string."
					designation = designation.to_s
				end


				if @container_ptr == 'inherit'
					@logger.debug "There is no container ptr.  Setting it from component_ptr.parent" + @component_ptr.breadcrumbs


					z = @component_ptr.parent.container  # this returns an array!!!  ## Do this from parent so we don't inherit from self!!
					if z.class == Array
						@logger.debug "Container pointer is array.  This is expected.  Count: #{z.count}"
						if z.count == 1
							@container_ptr = z[0]
						else
							@logger.error "Cannot specify child component when parent is a range."
							@logger.error @component_ptr
							@logger.error z.inspect
							raise "Cannot specify child component when parent is a range."
						end
					else
						raise "Component.container returns value that is of class #{z.class}.  Expecting array."
					end


					@logger.debug "@container_ptr is #{@container_ptr}"
					@logger.debug "@component_ptr is #{@component_ptr}"
				else
					@logger.debug "not inheriting."
				end




				unless @container_ptr
					@logger.debug "Could not get container from component #{@container_ptr}, using base_container instead."
#					@container_ptr = @component_ptr.container
					@container_ptr = self.base_container
				else
					@logger.debug "not using base."
				end

				@logger.debug "Container pointer is at " + @container_ptr.to_s

				old_container_ptr = @container_ptr

				## Add this container (or reopen it if it exists.)
				# if @container_ptr[designation, level_type]
				if @container_ptr.find_child_by_designation_and_level_type designation, level_type
					@logger.debug "x3"

					@logger.debug "Container #{designation} already exists, reopening."
					@container_ptr = @container_ptr[designation, level_type]
					@logger.debug "@container_ptr is #{@container_ptr}"
					## Should check to make sure correct type here !!!
				else
					@logger.debug "x4"
					@container_ptr = @container_ptr.add_child level_type, designation
				end
				@logger.debug "x5"

				new_container = @container_ptr  ## for returning, below


				if !block and !filename
					## Only add this to the collection if no more specific containers are nested inside.

					@component_ptr.container = @container_ptr  ## This is really a push!
					@container_ptr.contained_component = @component_ptr

					## If we're not doing a block, we want to return component_ptr as nil.
					## This way, sub components will check their parents for nesting.
					#@container_ptr = 'inherit'
				end

				## Now evaluate the block for this container, adding children.
				if block
					module_eval(&block)
					## Now that we've evaluated the block, reset the container pointer the previous value.
					@container_ptr = old_container_ptr
				end
				if filename
					read_file filename
					## Now that we've evaluated the block, reset the container pointer the previous value.
					@container_ptr = old_container_ptr
				end

				@logger.debug "Finishing DSL#container and container_ptr is now #{@container_ptr}"
				return new_container
			end


			def self.component_alias level_type, designation
			end

			def self.file_patterns pattern_array
				@component_ptr.file_pattern_array = pattern_array
			end

			def self.archive *args, &block
				# @logger.debug "Doing archive"
				# if block_given?
					self.component :archive, *args, &block
				# else
				# 	self.component :archive, *args
				# end					
			end
			def self.rg designation, filename=nil, &block
				self.component :rg, designation, filename, &block
				# component = self.component :rg, designation, filename, &block
				# component.container = Ushmm::DigitalCollections::Container.new :collection_container, designation
			end
			def self.accession designation, filename=nil, &block
				self.component :accession, designation, filename, &block
				# component = self.component :accession, designation, filename, &block
				# component.container = Ushmm::DigitalCollections::Container.new :collection_container, designation
			end
			def self.series *args, &block
				self.component :series, *args, &block
			end
			def self.subseries *args, &block
				self.component :subseries, *args, &block
			end
			def self.file *args, &block
				self.component :file, *args, &block
			end


			def self.collection_container *args, &block
				self.container :collection_container, *args, &block
			end

			def self.box *args, &block
				self.container :box, *args, &block
			end

			def self.folder *args, &block
				self.container :folder, *args, &block
			end

			# Currently only works for level immediately above "item" level.
			def self.book title
				superpage_component = @component_ptr
				superpage_component.book_title = title

				incrementing_page_number = 1

				# superpage_component.children.each { |this_page_component|
				# 	this_asset = this_page_component.asset

				# 	if this_asset
				# 		@logger.debug "Assigning page numbers to asset:"
				# 		@logger.debug this_asset.pretty_inspect

				# 		this_asset.page_designation = incrementing_page_number
				# 		incrementing_page_number += 1

				# 		this_asset.page_side = this_asset.page_designation % 2 == 0 ? 'L' : 'R'
				# 		@logger.debug this_asset.pretty_inspect
				# 	else
				# 		@component_ptr.component_errors << "Trying to read assets from non-terminal components."
				# 		@logger.error "Trying to read assets from non-terminal components."
				# 		raise "Trying to read assets from non-terminal components."
				# 	end
				# }
			end

			def self.title the_title
				@component_ptr.title = the_title
			end

			def self.comment the_comment
				@component_ptr.comment = the_comment
			end

			def self.finding_aid finding_aid
				@component_ptr.finding_aid = finding_aid
			end

			def self.narrow_path path
				@component_ptr.narrow_path = path
			end
		end
	end
end
