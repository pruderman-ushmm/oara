#!/usr/bin/ruby

require "./dependencies.rb"

module Ushmm
  module DigitalCollections
    module Main
      @logger = Logging.logger[self]

Logging.logger.root.level = :info


Logging.color_scheme( 'bright',
    :levels => {
      :debug => [:cyan, :bold],
      :info  => :green,
      :warn  => :yellow,
      :error => :red,
      :fatal => [:white, :on_red]
    },
    :date => [:bold, :blue],
    :logger => :cyan,
    :message => :white
  )

  Logging.appenders.stdout(
    'stdout',
    :layout => Logging.layouts.pattern(
      :pattern => '[%d] %-5l %c: %m\n',
      :color_scheme => 'bright'
    )
  )
Logging.logger.root.appenders = 'stdout'
Logging.logger.root.appenders = ['stdout', Logging.appenders.file(Ushmm::DigitalCollections::Settings::LOG_PATH)]


# Logging.logger['Ushmm::DigitalCollections::Collection'].level = :debug
Logging.logger['Ushmm::DigitalCollections::Main'].level = :debug
Logging.logger['Ushmm::DigitalCollections::Controllers'].level = :debug
Logging.logger['Ushmm::DigitalCollections::Component'].level = :warn
Logging.logger['Ushmm::DigitalCollections::Asset'].level = :debug
Logging.logger['Ushmm::DigitalCollections::Container'].level = :warn
Logging.logger['Ushmm::DigitalCollections::DSL'].level = :warn
# Logging.logger['Ushmm::DigitalCollections::Component'].level = :debug


  foo = Logging.logger['main']
    # foo.appenders = Logging.appenders.stdout

  foo.info "Welcome!"

      # Dispatch routing table to map URLs to controller methods
      DISPATCH_TABLE = {
        "/nav" => :collection_nav_page,
        "/container" => :container_nav_page,
        "/book_nav" => :book_nav_page,

        "/book_frame" => :book_frame,
        "/book_reader" => :book_reader,
        "/book_json" => :book_json,
        "/book_" => :book_no_method,
        "/testing" => :testing,
        "/archives" => :archives
      }

      # Define mainline controller to handle incoming HTTP requests
      def self.respond(env)
        http_request = Rack::Request.new(env)
        http_response_content = ""
        begin
          http_response_content += self.dispatch(http_request.path_info)
          http_response_status = 200
        rescue StandardError
          http_response_content += $!.message
          http_response_status = 500
        ensure
          return [
            http_response_status,
            { 'Content-Type' => 'text/html' },
            [ http_response_content ]
          ]        
        end
      end

      ## Dispatch HTTP requests according to the dispatch table.
      def self.dispatch(path_info)
        # return('x')
        DISPATCH_TABLE.each { |x, y|
          if path_info =~ /^#{Regexp.quote(x)}(.*)$/
            if Controllers.respond_to? y
              begin
                @logger.debug "Dispatching to #{y}"
                result = Controllers.send(y, $1)
              rescue Exception => ex
                @logger.error "Exception caught: #{ex.message}"
                @logger.error "Backtrace:\n" + ex.backtrace.join("\n")
              end
              return result.to_s
            else
              raise "No controller method found for #{path_info}!"
            end
          end
        }
        raise "No route for #{path_info}!"
      end


      def self.dispatch_command(command_input)
        command_parts = command_input.split /[ \t]+/
        if command_parts[0]  ## only if there is actually a command to try to perform
          if ConsoleControllers.respond_to? command_parts[0].to_sym
            args = command_parts[1, command_parts.size]
            result = ConsoleControllers.send(command_parts[0].to_sym, *args)
            puts result.to_s
          else
            puts "ConsoleControllers does not respond_to #{command_parts[0]}."
          end
        end
      end


      ## Interpret and dispatch CLI commands.
      def self.do_command(command_input)
        if true or ConsoleControllers.respond_to? command_input
#          pp ConsoleControllers.instance_eval(command_input)
          begin
            result = $archives.instance_eval(command_input)
            if (result)
            #   if result.respond_to? (:length)
            #     @logger.info "\n" + result.pretty_inspect
            #   else
            #     @logger.info result
            #   end
            puts result

            else
              @logger.info "(no result)"
            end
          rescue Exception => ex
            @logger.error "Exception caught: #{ex.message}"
            @logger.error "Backtrace:\n" + ex.backtrace.join("\n")
          end
        end
      end

      def self.cli()
        # unless $archives
        #   $archives = Archives.new  # Set up a global singleton.
        # end

        ## Store a command-line history file in the user's homedir.
        Readline::History::Restore.new(File.expand_path '~/.oara_cli_history')

        while command_input = Readline.readline(( ConsoleControllers.get_pointer ? ConsoleControllers.get_pointer.breadcrumbs : '(none)') + " > ", true)
          if (['quit', 'bye', 'exit'].include? command_input)
            self.exit_cli
          end
          dispatch_command(command_input)
        end
        self.exit_cli  ## Do not return.  Exit process instead.
      end

      def self.exit_cli
        puts "Bye!"
        exit
      end
    end
  end
end





