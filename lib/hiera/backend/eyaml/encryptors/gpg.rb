require 'ruby_gpg'
require 'base64'
require 'pathname'
require 'hiera/backend/eyaml/encryptor'
require 'hiera/backend/eyaml/utils'
require 'hiera/backend/eyaml/options'

class Hiera
  module Backend
    module Eyaml
      module Encryptors

        class Gpg < Encryptor

          self.tag = "GPG"

          self.options = {
            :gnupghome => { :desc => "Location of your GNUPGHOME directory",
                            :type => :string,
                            :default => "#{ENV[["HOME", "HOMEPATH"].detect { |h| ENV[h] != nil }]}/.gnupg" },
            :always_trust => { :desc => "Assume that used keys are fully trusted",
                               :type => :boolean,
                               :default => false },
            :recipients => { :desc => "List of recipients (comma separated)",
                             :type => :string },
            :recipients_file => { :desc => "File containing a list of recipients (one on each line)",
                             :type => :string }
          }

          @@passphrase_cache = Hash.new

          def self.passfunc(hook, uid_hint, passphrase_info, prev_was_bad, fd)
            begin
                system('stty -echo')

                unless @@passphrase_cache.has_key?(uid_hint)
                  @@passphrase_cache[uid_hint] = ask("Enter passphrase for #{uid_hint}: ") { |q| q.echo = '' }
                  $stderr.puts
                end
                passphrase = @@passphrase_cache[uid_hint]

                io = IO.for_fd(fd, 'w')
                io.puts(passphrase)
                io.flush
              ensure
                (0 ... $_.length).each do |i| $_[i] = ?0 end if $_
                  system('stty echo')
              end
          end

          def self.find_recipients
            recipient_option = self.option :recipients
            recipients = if !recipient_option.nil?
              debug("Using --recipients option")
              recipient_option.split(",")
            else
              recipient_file_option = self.option :recipients_file
              recipient_file = if !recipient_file_option.nil?
                debug("Using --recipients-file option")
                Pathname.new(recipient_file_option)
              else
                debug("Searching for any hiera-eyaml-gpg.recipients files in path")
                # if we are editing a file, look for a hiera-eyaml-gpg.recipients file
                filename = case Eyaml::Options[:source]
                when :file
                  Eyaml::Options[:file]
                when :eyaml
                  Eyaml::Options[:eyaml]
                else
                  nil
                end

                if filename.nil?
                  nil
                else
                  path = Pathname.new(filename).realpath.dirname
                  selected_file = nil
                  path.descend{|path| path
                    potential_file = path.join('hiera-eyaml-gpg.recipients')
                    selected_file = potential_file if potential_file.exist? 
                  }
                  debug("Using file at #{selected_file}")
                  selected_file
                end
              end

              unless recipient_file.nil?
                recipient_file.readlines.map{ |line| line.strip } 
              else
                []
              end
            end
          end

          def self.encrypt plaintext
            gnupghome = self.option :gnupghome
            debug("GNUPGHOME is #{gnupghome}")
            RubyGpg.config.homedir = gnupghome

            recipients = self.find_recipients
            debug("Recipents are #{recipients}")

            raise RecoverableError, 'No recipients provided, don\'t know who to encrypt to' if recipients.empty?

            # TODO: check that keys are trusted

            RubyGpg.encrypt_string(plaintext, recipients)
          end

          def self.decrypt ciphertext
            gnupghome = self.option :gnupghome
            debug("GNUPGHOME is #{gnupghome}")
            RubyGpg.config.homedir = gnupghome

            RubyGpg.decrypt_string(ciphertext)
          end

          def self.create_keys
            STDERR.puts "The GPG encryptor does not support creation of keys, use the GPG command lines tools instead"
          end

        end

      end
    end
  end
end
