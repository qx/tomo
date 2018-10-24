require "fileutils"
require "securerandom"
require "tmpdir"

module Jam
  module SSH
    class Connection
      attr_reader :host

      def initialize(host)
        @host = host
      end

      # TODO: rename to ssh_exec
      def attach(command)
        ssh_args = build_ssh_command(command, pty: true)
        Process.exec(*ssh_args)
      end

      # TODO: rename to ssh_subprocess
      def run(command, silent: false, pty: false, raise_on_error: true)
        ssh_args = build_ssh_command(command, pty: pty)
        result = ChildProcess.execute(*ssh_args, io: silent ? nil : $stdout)
        if result.failure? && raise_on_error
          $stdout << result.stdout if silent
          $stdout << result.stderr if silent
          raise_run_error(command, ssh_args.join(" "), result)
        end

        result
      end

      # TODO: remove
      def run?(command, silent: false, pty: false)
        run(command, silent: silent, pty: pty, raise_on_error: false).success?
      end

      # TODO: remove
      def capture(command, silent: true, pty: false, raise_on_error: true)
        result = run(
          command,
          silent: silent,
          pty: pty,
          raise_on_error: raise_on_error
        )
        result.stdout
      end

      def close
        FileUtils.rm_f(control_path)
      end

      private

      def build_ssh_command(command, pty:)
        args = [*ssh_options]
        args << "-tt" if pty
        args << host
        args << "--"

        ["ssh", args, command].flatten
      end

      def ssh_options
        [
          "-A",
          %w[-o ControlMaster=auto],
          ["-o", "ControlPath=#{control_path}"],
          %w[-o ControlPersist=30s],
          %w[-o LogLevel=ERROR]
        ]
      end

      def control_path
        @control_path ||= begin
          token = SecureRandom.hex(8)
          File.join(Dir.tmpdir, "jam_ssh_#{token}")
        end
      end

      def raise_run_error(remote_command, ssh_command, result)
        RemoteExecutionError.raise_with(
          "Failed with status #{result.exit_status}: #{ssh_command}",
          host: host,
          remote_command: remote_command,
          ssh_command: ssh_command,
          result: result
        )
      end
    end
  end
end
