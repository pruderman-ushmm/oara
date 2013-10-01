module Ushmm
	module DigitalCollections
		class Container
			attr_reader :level_type
			attr_accessor :designation

			attr_accessor :parent

			attr_accessor :contained_component


			def initialize new_level_type, new_designation
				@logger = Logging.logger[self]
				@logger.debug "Initializing new container: level_type => '#{new_level_type}', designation => '#{new_designation}'"

				unless new_designation
					raise "A container must have a designation.  None supplied."
				end

			    ## If the designation is passed as a number, convert it to a string.
			    if new_designation.class == Fixnum
			    	new_designation = new_designation.to_s
			    end

			    ## Verify that the supplied designation is (now) a String.
			    unless new_designation.class == String
			    	raise "Container designation must be a string!  #{new_designation.class} given."
			    end

			    ## Start children off as an empty array.
			    @children = []


			    ## Set the level and designation passed via the constructor.
			    self.level_type = new_level_type
			    self.designation = new_designation
			end

			## Sets the level type for this container.  Must be one of the pre-defined levels.
			def level_type= new_level_type
				unless [:archive_container, :collection_container, :box, :folder].include? new_level_type.to_sym
					raise "'#{new_level_type}' is not a valid container level_type."
				end
				@level_type = new_level_type.to_sym
			end


			## Create a new child container of this container.
			def add_child new_level_type, new_designation, &block
				@logger.debug "Creating child container under #{breadcrumbs}..."
				if self[new_designation, new_level_type]
					@logger.warn "Child already exists: [#new_level_type] #{new_designation}"
					raise
				end
				new_child = Container.new(new_level_type, new_designation, &block)
				new_child.parent = self
				@children << new_child
				return new_child
			end

			def remove_child search_designation
				@children = @children.reject { |c|
					c.designation = search_designation
				}
			end

			def children= new_children_array
				@children = new_children_array
			end

			def children
				@children.sort { |a,b| a.designation.to_i <=> b.designation.to_i }
			end

			## Find child container by its designation.
			def find_child_by_designation search_designation
				raise 'deprecated'

				@logger.debug "Searching in container [#{level_type}] #{designation} for #{search_designation} (any level type)"
				@children.each { |c|
					# @logger.debug "Comparing: #{c.designation} == #{search_designation} ?"
					# @logger.debug "Comparing: #{c.designation.class} == #{search_designation.class} ?"
					if c.designation == search_designation
						@logger.debug "Found: #{c.detail}"
						return c
					end
				}
				@logger.debug "Not Found."
				return nil
			end

			## Find child container by its designation and level_type.
			def find_child_by_designation_and_level_type search_designation, search_level_type
				@logger.debug "Searching in container [#{level_type}] #{designation} for [#{search_level_type}] #{search_designation}"
				@children.each { |c|
					# @logger.debug "Comparing: #{c.designation} == #{search_designation} ?"
					# @logger.debug "Comparing: #{c.level_type.to_s} == #{search_level_type.to_s} ?"
					# @logger.debug "Comparing: #{c.designation.class} == #{search_designation.class} ?"
					if c.designation == search_designation and c.level_type == search_level_type
						@logger.debug "Found: #{c.detail}"
						return c
					end
				}
				@logger.debug "Not Found."
				return nil
			end

			## This method is an alias for #find_child_by_designation.
			def [] search_designation, search_level_type=nil
				@logger.debug "ooo"
				if search_level_type
					r = find_child_by_designation_and_level_type search_designation.to_s, search_level_type.to_sym
				else
					r = find_child_by_designation search_designation.to_s
				end
				return r
			end

			## Pretty-print
			def to_ss
				"#{level_type} #{designation}"
			end

			def to_s
#				to_ss
				breadcrumbs
			end

			def breadcrumbs_array
				ancestors.map {|x| "#{x.level_type} #{x.designation}"}
			end

			def breadcrumbs
				breadcrumbs_array.join " -> "
			end

			def designation_path
				ancestors.map {|x| x.level_type.to_s + '-' + x.designation.to_s}. join "/"
			end

			def can_have_item_children
				## Right now this is defined as being true if there are no *container* children (except possibly "item" container children).
				## That is, only "terminal" nodes (not counting items) on the container tree can have "items".  (But the items themselves cannot.)

				if level_type == :item
					return false
				end

				children.each{ |c|
					if c.level_type != :item
						return false
					end
				}
				return true
			end

			def ancestors
				a = []
				pos = self

				a << pos
				while pos = pos.parent
					a.unshift pos
				end
				a
			end

			def descendants
				descendant_array = []
				children.each { |c|
					descendant_array << c
					descendant_array += c.descendants
				}
				return descendant_array
			end

			def assets
				asset_array = []
				descendants.each { |d| 
					unless d.asset.nil?
						asset_array << d.asset
					end
				}
				return asset_array
			end

			def child_level_types
				child_type_hash = {}
				children.each { |c| 
					dlt = c.level_type
					if child_type_hash[dlt]
						child_type_hash[dlt] += 1
					else
						child_type_hash[dlt] = 1
					end
				}
				return child_type_hash
			end

			def descendant_level_types
				descendant_type_hash = {}
				descendants.each { |d| 
					dlt = d.level_type
					if descendant_type_hash[dlt]
						descendant_type_hash[dlt] += 1
					else
						descendant_type_hash[dlt] = 1
					end
				}
				return descendant_type_hash
			end

			def ancestor_value_hash
				the_hash = {}
				ancestors.each { |c|
					the_hash[c.level_type] = c.designation
				}
				the_hash
			end

			################################
			## These attributes "inherit" or "cascade" from the parent:

			def narrow_path
				@narrow_path ? @narrow_path : parent ? parent.narrow_path : nil
			end
			def narrow_path= new_value
				@narrow_path = new_value
			end
			def finding_aid
				@finding_aid ? @finding_aid : parent ? parent.finding_aid : nil
			end
			def finding_aid= new_value
				@finding_aid = new_value
			end
			def file_pattern_array
				@file_pattern_array ? @file_pattern_array : parent ? parent.file_pattern_array : []
			end
			def file_pattern_array= new_value
				@file_pattern_array = new_value
			end

			################################
			## This one calls itself up the hierarchy, until it finds a parent with narrow_path set on in explicitly (not inherited).

			def narrow_path_container
				@narrow_path ? self : parent ? parent.narrow_path_container : nil
			end


			################################


			def detail
				o = ''
				o += " Level type: #{level_type}\n"
				o += "Designation: '#{designation}.\n"
				o += "\n"
				child_level_types.each_pair { |lt, num|
					o += "Has #{num} children of level type #{lt}.\n"
				}
				o += "\n"
				descendant_level_types.each_pair { |lt, num|
					o += "Has #{num} descendants of level type #{lt}.\n"
				}
				o += "\n"

				o
			end

		end
	end
end