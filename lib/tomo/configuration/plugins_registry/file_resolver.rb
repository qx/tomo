module Tomo
  class Configuration
    class PluginsRegistry::FileResolver
      def self.resolve(path)
        new(path).plugin_module
      end

      def initialize(path)
        @path = path
      end

      def plugin_module
        # TODO: error handling for file-not-found
        Tomo.logger.debug("Loading plugin from #{path.inspect}")
        script = IO.read(path)
        plugin = define_anonymous_plugin_class
        plugin.class_eval(script, path.to_s, 1)

        plugin
      end

      private

      attr_reader :path

      def define_anonymous_plugin_class
        name = path.to_s
        plugin = Class.new(TaskLibrary)
        plugin.extend(PluginDSL)
        plugin.send(:tasks, plugin)
        plugin.define_singleton_method(:to_s) do
          super().sub(/>$/, "(#{name})>")
        end
        plugin
      end
    end
  end
end
