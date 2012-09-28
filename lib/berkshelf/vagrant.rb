require 'vagrant'
require 'berkshelf'

module Berkshelf
  # @author Jamie Winsor <jamie@vialstudios.com>
  # @author Andrew Garson <andrew.garson@gmail.com>
  module Vagrant
    module Action
      autoload :Install, 'berkshelf/vagrant/action/install'
      autoload :Upload, 'berkshelf/vagrant/action/upload'
      autoload :Clean, 'berkshelf/vagrant/action/clean'
      autoload :SetUI, 'berkshelf/vagrant/action/set_ui'
      autoload :Validate, 'berkshelf/vagrant/action/validate'
    end

    autoload :Config, 'berkshelf/vagrant/config'
    autoload :Middleware, 'berkshelf/vagrant/middleware'

    class << self
      # @param [Vagrant::Action::Environment] env
      def shelf_for(env)
        name = env[:vm].config.vm.name
        return nil unless name

        File.join(Berkshelf.berkshelf_path, "vagrant", name.to_s)
      end

      # @param [Symbol] shortcut
      # @param [Vagrant::Config::Top] config
      #
      # @return [Array]
      def provisioners(shortcut, config)
        config.vm.provisioners.select { |prov| prov.shortcut == shortcut }
      end

      # Determine if the given instance of Vagrant::Config::Top contains a
      # chef_solo provisioner
      #
      # @param [Vagrant::Config::Top] config
      #
      # @return [Boolean]
      def chef_solo?(config)
        !provisioners(:chef_solo, config).empty?
      end

      # Determine if the given instance of Vagrant::Config::Top contains a
      # chef_client provisioner
      #
      # @param [Vagrant::Config::Top] config
      #
      # @return [Boolean]
      def chef_client?(config)
        !provisioners(:chef_client, config).empty?
      end

      # Initialize the Berkshelf Vagrant middleware stack
      def init!
        ::Vagrant.config_keys.register(:berkshelf) { Berkshelf::Vagrant::Config }

        [ :provision, :start ].each do |action|
          ::Vagrant.actions[action].insert(::Vagrant::Action::General::Validate, Berkshelf::Vagrant::Action::Validate)
          ::Vagrant.actions[action].insert(::Vagrant::Action::VM::Provision, Berkshelf::Vagrant::Middleware.install)
          ::Vagrant.actions[action].insert(::Vagrant::Action::VM::Provision, Berkshelf::Vagrant::Middleware.upload)
        end

        ::Vagrant.actions[:destroy].insert(::Vagrant::Action::VM::CleanMachineFolder, Berkshelf::Vagrant::Middleware.clean)
      end
    end
  end
end

Berkshelf::Vagrant.init!