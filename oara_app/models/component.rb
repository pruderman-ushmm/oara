module Ushmm
	module DigitalCollections
		class Component
			attr_reader :level_type
			attr_reader :designation

			attr_accessor :title
			attr_accessor :comment

			attr_accessor :parent

			attr_accessor :asset
			attr_accessor :book_title

			## Returns the JSON needed for an Archive BookReader rendering.
			## !!! - This currently only works on the parent component which contains the items.
			def dump_book_json
				superpage_component = self
				incrementing_page_number = 1
				superpage_component.children.each { |this_page_component|
					this_asset = this_page_component.asset

					if this_asset
						@logger.debug "Assigning page numbers to asset:"
						@logger.debug this_asset.pretty_inspect

						this_asset.page_designation = incrementing_page_number
						incrementing_page_number += 1

						this_asset.page_side = this_asset.page_designation % 2 == 0 ? 'L' : 'R'
						@logger.debug this_asset.pretty_inspect
					else
						superpage_component.component_errors << "Trying to read assets from non-terminal components."
						@logger.error "Trying to read assets from non-terminal components."
						raise "Trying to read assets from non-terminal components."
					end
				}


				assets = []
				children.each { |c|
					@logger.debug "doing asset associated with this component: #{c}"
					unless c.asset
						@logger.error "no asset associated with this component: #{c}"
						raise "no asset associated with this component: #{c}"
					end
					c.asset.generate_derivative!
					c.asset.load_derivative_file_metadata!
					assets << c.asset
				}
				return assets.to_json
			end

			def initialize new_level_type, new_designation
				@logger = Logging.logger[self]
				@logger.debug "Initializing new component: level_type => '#{new_level_type}', designation => '#{new_designation}'"

				unless new_designation
					raise ArgumentError, "A component must have a designation.  None supplied."
				end

			    ## If the designation is passed as a number, convert it to a string.
			    if new_designation.class == Fixnum
					@logger.debug "new_designation is a Fixnum (#{new_designation}), converting to string..."
			    	new_designation = new_designation.to_s
					@logger.debug "new_designation is now #{new_designation}"
			    end

			    ## Verify that the supplied designation is (now) a String.
			    unless new_designation.class == String
			    	raise ArgumentError, "Component designation must be a String!  #{new_designation.class} given."
			    end

			    ## Verify that the supplied level_type is a Symbol.
			    unless new_level_type.class == Symbol
			    	raise ArgumentError, "Component level_type must be a Symbol!  #{new_level_type.class} given."
			    end

			    ## Start children off as an empty array.
			    @children = []

			    ## Start component errors as empty array.
			    @component_errors = []

			    ## Set the level and designation passed via the constructor.
			    self._level_type = new_level_type  ## use private method call for value checking
			    @designation = new_designation

			    return self
			end


			## Create a new child component of this component.
			def add_child new_level_type, new_designation
				@logger.debug "Creating child component under #{breadcrumbs}..."
				if self[new_designation]
					@logger.warn "Child already exists: #{[new_designation]}"
					raise IndexError, "Child already exists: #{[new_designation]}"
				end
				new_child = Component.new(new_level_type, new_designation)
				new_child.parent = self
				@children << new_child
				return new_child
			end

			def remove_child search_designation
				new_children = @children.reject { |c|
					c.designation.to_s == search_designation.to_s
				}
				@logger.debug "Before count: " + @children.count.to_s
				@children = new_children
				@logger.debug "After count: " + @children.count.to_s
			end

			def children
				@children.sort { |a,b| a.designation.to_i <=> b.designation.to_i }
			end

			# Find child component by its designation.
			#
			# Returns nil if not found.
			#
			# @see #find_child_by_designation
			#
			# @param search_designation [String] designation of child to return
			# @return [Component] the child component specified by the designation
			def [] search_designation
				@logger.debug "Searching in component #{level_type} #{designation} for #{search_designation}"
				@children.each { |c|
					if c.designation == search_designation
						@logger.debug "Found: #{c}"
						return c
					end
				}
				@logger.debug "Not found: #{search_designation}"
				return nil
			end

			# Find child component by its designation.
			#
			# Raises IndexError if not found.
			#
			# @see #[]
			#
			# @param search_designation [String] designation of child to return
			# @return [Component] the child component specified by the designation
			def find_child_by_designation search_designation
				r = self[search_designation]
				if r == nil
					raise IndexError, "No child component found with designation #{search_designation}."
				end
				r
			end

			def to_s
				to_ss
			end

			# Pretty-print
			# @deprecated
			def to_ss
				"#{level_type} #{designation} \"#{title}\""
			end

			def breadcrumbs_array
				ancestors.map {|x| "#{x.level_type} #{x.designation}"}
			end

			def breadcrumbs
				breadcrumbs_array.join " -> "
			end

			def designation_path
				ancestors.map {|x| x.designation}. join "/"
			end

			def can_have_item_children
				## Right now this is defined as being true if there are no *component* children (except possibly "item" component children).
				## That is, only "terminal" nodes (not counting items) on the component tree can have "items".  (But the items themselves cannot.)

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

			# Returns an Array of each successive parent component, starting with the most distant ancestor at index 0, and proceeding to
			# the immediate parent at the final index postion.
			# @return [Array<Component>]  An Array of successive ancestors.
			def ancestors
				a = []
				pos = self

				a << pos
				while pos = pos.parent
					a.unshift pos
				end
				a
			end

			# Returns an Array of all descendant (children of children of ...) Components.
			# Descendants are returned in depth-first order.
			# @return [Array<Component>]
			def descendants
				descendant_array = []
				children.each { |c|
					descendant_array << c
					descendant_array += c.descendants
				}
				return descendant_array
			end

			def descendant_assets
				asset_array = []
				descendants.each { |d| 
					unless d.asset.nil?
						asset_array << d.asset
					end
				}
				return asset_array
			end

			# An alias for #descendant_assests
			# @see #descendant_assets
			alias :assets :descendant_assets

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

			def component_errors
				@component_errors
			end

			################################
			## These attributes "inherit" or "cascade" from the parent:

			def container
				@container ? @container : parent ? parent.container : nil
			end
			def container= new_container
				unless @container
					@container = []
				end
				@container << new_container
			end
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

			def narrow_path_component
				@narrow_path ? self : parent ? parent.narrow_path_component : nil
			end

			def load_assets
				npc = narrow_path_component
				unless npc
					puts "No assets found."
					return nil
				end
				unless npc == self
					npc.load_assets  ## If we're not the one with narrow_path, call the ancestor that does have it.
				else


					## First gather all descendant components' regex patterns into a hash,
					## indexed by regex, pointing back to the descendant component.
					descendant_file_regex_hash = {}

					## Add for self first (if self can have item children):
					if can_have_item_children
						file_regex_array.each { |file_regex| 
							descendant_file_regex_hash[file_regex] = self
						}
					end

					## Now do descendants:
					descendants.each { |d|
						if d.can_have_item_children
							d.file_regex_array.each { |file_regex|
								descendant_file_regex_hash[file_regex] = d
							}
						end
					}


					base_path_to_scan = File.join(assets_path, '**', '*')  ## The ** indicates recursion.

					@logger.debug "Looking for digital assets in #{base_path_to_scan}"

					unless (file_pattern_array)
						raise "file_pattern_array must be set before calling #find_all_assets!"
					end

					# Get the list of pathnames (as strings)
					x = Dir.glob(base_path_to_scan)

					# Convert the array of strings into Pathname objects, change base path, then convert back to strings.
					z = Pathname.new(Ushmm::DigitalCollections::Settings::REPOSITORY_ASSETS_ROOT_PATH)


					file_list = x.map{ |y| (Pathname.new(y).relative_path_from(z).to_s)}

					## Initialize a progress bar, since this could take a while.
					progress_bar = ProgressBar.create(:title => 'Loading assets...', :total => file_list.length, :format => '%a %B %p%% %t')

					file_list.each { |this_asset_filename|
						unless File.directory? File.join Ushmm::DigitalCollections::Settings::REPOSITORY_ASSETS_ROOT_PATH, this_asset_filename
							@logger.debug "Found asset filename: #{this_asset_filename}"

							number_of_patterns_this_file_matches = 0
							descendant_file_regex_hash.each_pair { |dfr, this_component|
								matches = dfr.match('/'+this_asset_filename)
								# ap this_component.to_ss
								# ap dfr
								if matches
									number_of_patterns_this_file_matches += 1

									# ap matches

									item_number = matches['item'].to_i

									## If there is already a child item with this number, get rid of it:
									if this_component[item_number]
										if this_component[item_number].level_type != :item
											@logger.debug "Trying to create a component that already exists!"
											puts this_component[item_number].detail
											raise "Trying to create a component that already exists!"
										end
										@logger.debug "Removing child by item number: #{item_number}"
										this_component.remove_child(item_number)
									end

									## Create "item" level component:
									item_component = this_component.add_child :item, item_number
									item_component.title = "Component for item #{item_number}"

									if item_component.asset
										raise "Item component already has asset."
									end

									## Create the asset object:
									asset = DigitalCollections::Asset.new
									#asset.component = self
									asset.image_asset_path = this_asset_filename
									# asset.matched_on_pattern = this_asset_pattern_number

									## Link the asset object with its component object:
									asset.component = item_component
									item_component.asset = asset

									@logger.debug "Just created asset: #{asset.inspect}"
									@logger.debug "...connected to component: #{asset.component.inspect}"

									## Now examine the files.
									# asset.generate_derivative!
									# asset.load_derivative_file_metadata!
								end	

							}

							## Check the number of patterns matched, flag an error is not exactly 1.
							if number_of_patterns_this_file_matches != 1
								@logger.warn "Found #{number_of_patterns_this_file_matches} matches for '#{this_asset_filename}'"
								@component_errors << "Matched #{number_of_patterns_this_file_matches} times: #{this_asset_filename}"
							end
						end
					}

				end
				true
			end

			################################



			def assets_path
				(File.join Ushmm::DigitalCollections::Settings::REPOSITORY_ASSETS_ROOT_PATH, narrow_path).to_s
			end

			def derivatives_path
				(File.join Ushmm::DigitalCollections::Settings::REPOSITORY_ASSETS_ROOT_PATH, narrow_path).to_s
			end


			#######################################

			## Return the collections solr record.  (Look it up if needed.)
			# def solr_record
			# 	if @solr_record
			# 		return @solr_record
			# 	end
			# 	if (@rg_number)
			# 		@solr_record = Ushmm::DigitalCollections::SolrGateway.get_solr_record_from_rg_number(@rg_number)
			# 	elsif (@accession_number)
			# 		@solr_record = Ushmm::DigitalCollections::SolrGateway.get_solr_record_from_accession_number(@accession_number)
			# 	else
			# 		raise "Cannot lookup SOLR record without either an rg_number or an accession_number."
			# 	end

			# 	return @solr_record
			# end


			def detail
				o = ''
				o += "     Title: '#{title}.\n"
				o += "Level type: #{level_type}\n"
				o += "\n"
				child_level_types.each_pair { |lt, num|
					o += "Has #{num} children of level type #{lt}\n"
				}
				o += "\n"
				descendant_level_types.each_pair { |lt, num|
					o += "Has #{num} descendants of level type #{lt}\n"
				}
				o += "\n"
				o += "Regex: " + file_regex_array.to_s
				o += "\n"
				o += "Can have item children: " + ( can_have_item_children ? "yes" : "no" )
				o += "\n"
				o += "Component Errors: " + component_errors.count.to_s
				o += "\n"
				o
			end


			def errors
				o = ''
				o += "Component Errors: "
				o += "\n"
				component_errors.each { |e| o += "  #{e}\n" }
				o
			end

			##########################################################

			def file_regex_array
				file_pattern_array.map { |pretty_pattern|
					@logger.debug "Converting '#{pretty_pattern}' to regex..." 
					rest = pretty_pattern
					new_regex_string = ''
					tags_used = []

					while rest.length > 0 do
						if /^\[(?<raw_tag>[^\]]*)\](?<new_rest>.*)$/ =~ rest
							## Extract the "tag" and "tag_length" from the pretty pattern
							@logger.debug "Matched tag: #{raw_tag} (rest: #{new_rest})"

							tag_s, tag_length_s = raw_tag.split '_'
							tag = tag_s.to_sym
							tag_length = tag_length_s.to_i
							@logger.debug tag
							@logger.debug tag_length

							new_regex_string += if tags_used.include?(tag)
								'\k<' + tag.to_s + '>' ## If a tag has already been used, refer back to the previous named capture.
								else
									tags_used << tag
									_generate_regex_for_tag tag, tag_length
								end

						elsif /^(?<literal>[^\[]+)(?<new_rest>.*)$/ =~ rest
							# @logger.debug "Matched literal: #{literal} (rest: #{new_rest})"

							new_regex_string += Regexp.escape(literal)
						else
							raise "regex error: should not happen"
						end
						rest = new_rest
					end
					new_regex = Regexp.new(new_regex_string)
					new_regex
				}
			end

			################################################################################
			private # methods below:
			################################################################################

			def _generate_regex_for_tag tag, tag_length
				'(?<' + tag.to_s + '>' +
					if ancestor_value_hash[tag]
						if tag_length > 0
							"%0#{tag_length}d" % ancestor_value_hash[tag]
						else
							ancestor_value_hash[tag]
						end
					else
							case tag
							when :series
								"[0-9]{#{tag_length}}"
							when :subseries
								"[0-9]{#{tag_length}}"
							when :rg
								"[-RGM0-9.]+"
							when :item
								"[0-9]{#{tag_length}}"
							else
								raise "unrecognized tag: #{tag}"
							end
					end + ')'
			end


			## Sets the level type for this component.  Must be one of the pre-defined levels.
			def _level_type= new_level_type
				unless [:archive, :rg, :subrg, :accession, :subaccession, :series, :subseries, :file, :item].include? new_level_type.to_sym
					raise ArgumentError, "'#{new_level_type}' is not a valid component level_type."
				end
				@level_type = new_level_type.to_sym
			end

		end
	end
end