module Tomo
  module Commands
    class Deploy
      extend CLI::Command
      include CLI::DeployOptions
      include CLI::ProjectOptions
      include CLI::CommonOptions

      def summary
        "Deploy the current project to remote host(s)"
      end

      def banner
        <<~BANNER
          Usage: #{green('tomo deploy')} #{yellow('[--dry-run] [options]')}

          Sequentially run the "deploy" list of tasks specified in .tomo/project.rb to
          deploy the project to a remote host. Use the #{blue('--dry-run')} option to quickly
          simulate the entire deploy without actually connecting to the host.

          For a .tomo/project.rb that specifies distinct environments (e.g. staging,
          production), you must specify the target environment using the #{blue('-e')} option. If
          you omit this option, tomo will automatically prompt for it.

          Tomo will use the settings specified in .tomo/project.rb to configure the
          deploy. You may override these on the command line using #{blue('-s')}. E.g.:

            #{blue('tomo deploy -e staging -s git_branch=develop')}

          Or use environment variables with the special #{blue('TOMO_')} prefix:

            #{blue('TOMO_GIT_BRANCH=develop tomo deploy -e staging')}

          Bash completions are provided for tomo’s options. For example, you could type
          #{blue('tomo deploy -s <TAB>')} to see a list of all settings, or #{blue('tomo deploy -e pr<TAB>')}
          to expand #{blue('pr')} to #{blue('production')}. For bash completion installation instructions,
          run #{blue('tomo completion-script')}.

          More documentation and examples can be found here:

            #{blue('https://tomo-deploy.com/commands/deploy')}
        BANNER
      end

      def call(options)
        Tomo.logger.info "tomo deploy v#{Tomo::VERSION}"

        runtime = configure_runtime(options)
        plan = runtime.deploy!

        log_completion(plan)
      end

      private

      def log_completion(plan)
        app = plan.settings[:application]
        target = "#{app} to #{plan.applicable_hosts_sentence}"

        if Tomo.dry_run?
          Tomo.logger.info(green("* Simulated deploy of #{target} (dry run)"))
        else
          Tomo.logger.info(green("✔ Deployed #{target}"))
        end
      end
    end
  end
end