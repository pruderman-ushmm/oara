module Ushmm
	module DigitalCollections
		class Asset
			attr_accessor :image_asset_path
			attr_accessor :page_side
			attr_accessor :page_designation
			attr_accessor :matched_on_pattern
			# attr_accessor :components
			# attr_accessor :component_structure

			attr_accessor :component


			def initialize
			    @logger = Logging.logger[self]
			end

			def load_derivative_file_metadata!
				@logger.debug "Preparing to load_derivative_file_metadata"
				@logger.debug self.pretty_inspect


				# Run the external command:
				command = Shellwords.join(["/usr/bin/rdjpgcom", '-v',  fq_derivative_path])+" 2>&1"
				command_output_all = `#{command}`
				command_output = command_output_all.split("\n")[0]

				if (command_output == "Not a JPEG file")
					@derivative_exists = false
					return
				end

				regular_expression_pattern = /^JPEG image is ([0-9]+)w . ([0-9]+)h/
				match_result = regular_expression_pattern.match(command_output)
				if match_result == nil
					error_message = "Unable to interpret output from rdjpgcom.\ncommand: " + command + "\ncommand_output: " + command_output_all + "\nregex: " + regular_expression_pattern.to_s
					# raise RuntimeError.new(error_message)
					@logger.warn(error_message)
				else
					@derivative_width = match_result[1]
					@derivative_height = match_result[2]
					@derivative_exists = true
				end

				@logger.debug "Finishing load_derivative_file_metadata"
				@logger.debug self.pretty_inspect
			end

			def derivative_exists
				Pathname.new(fq_derivative_path).exist?
			end

			## Build derivative images from the originals, for the purpose of displaying in the BookReader.
			def generate_derivative!
				@logger.debug "Preparing to generate_derivative"
				@logger.debug self.pretty_inspect

				## If this is a directory (not a file), skip it:
				unless File.directory?(File.dirname(fq_asset_path))
					raise "This should not happen!"
				end

				## Make all of the intermediate directories to the file.
				unless File.directory?(File.dirname(fq_derivative_path))
					FileUtils.mkdir_p(File.dirname(fq_derivative_path))
				end

				## Does the path exist in the derivative tree?
				if (! derivative_exists)
					puts "create asset derivative #{fq_asset_path}"
#						command = "/usr/bin/convert -verbose #{fq_asset_path} -resize 800x800 #{fq_derivative_path}"
#					command = Shellwords.join(["/usr/bin/convert", '-verbose', fq_asset_path.to_s, '-resize', '800x800', fq_derivative_path.to_s])
					command = Shellwords.join(["/usr/bin/convert", '-verbose', fq_asset_path.to_s, '-resize', '1800x1800', fq_derivative_path.to_s])
					puts command
					command_output = `#{command}`
					exit_value = $?
					puts "output: #{command_output}"
					if (exit_value != 0)
						raise "Thumbnail generation failed: #{command_output}"
					end
				else
					# puts "we have derivative for asset #{this_path}"
				end
				@logger.debug "Finishing generate_derivative"
				@logger.debug self.pretty_inspect

			end

			def derivative_width
				@derivative_width
			end

			def derivative_height
				@derivative_height
			end

			def image_derivative_path
				image_asset_path  ## derivative (relative) path is the same as the asset path
			end

			def fq_asset_path
				File.join(Ushmm::DigitalCollections::Settings::REPOSITORY_ASSETS_ROOT_PATH, image_asset_path)
			end

			def fq_derivative_path
				File.join(Ushmm::DigitalCollections::Settings::REPOSITORY_DERIVATIVES_ROOT_PATH, image_derivative_path)
			end

			def fq_derivative_url
				File.join(Ushmm::DigitalCollections::Settings::REPOSITORY_DERIVATIVES_ROOT_URL, image_derivative_path)
			end

			def to_s
				o = ''
				o += super.to_s
				o += "\n"
				o += "              breadcrumbs: #{component.breadcrumbs}"
				o += "\n"
				o += "                component: #{component}"
				o += "\n"
				o += "         image_asset_path: #{image_asset_path}"
				o += "\n"
				o += "            fq_asset_path: #{fq_asset_path}"
				o += "\n"
				o += "       fq_derivative_path: #{fq_derivative_path}"
				o += "\n"
				o += "        fq_derivative_url: #{fq_derivative_url}"
				o += "\n"
				o += "        derivative_height: #{derivative_height}"
				o += "\n"
				o += "         derivative_width: #{derivative_width}"
				o += "\n"
				o += "         page_designation: #{page_designation}"
				o += "\n"
				o += "                page_side: #{page_side}"
				o += "\n"
				o += "       matched_on_pattern: #{matched_on_pattern}"
				o += "\n"
				# o += "               components: #{components.pretty_inspect}"
				# o += "\n"
				# o += "       component_sequence: #{parent_fonds_collection.component_sequence}"
				# o += "\n"
				# o += "      component_structure: #{component_structure.join (' -> ')}"
				# o += "\n"
				o += "\n"
			end

			def to_json (options = {})
				{
					'image_asset_path'=> image_derivative_path, 
					'fq_image_asset_path'=> fq_derivative_path, 
					'fq_image_asset_url'=> fq_derivative_url, 
					'height' => derivative_height,
					'width' => derivative_width,
					'page_designation' => page_designation,
					'page_side' => page_side
				}.to_json
			end

		end
	end
end