# coding: utf-8
module Splash
  class CommandWrapper
    include Splash::Templates
    include Splash::Config
    include Splash::Helpers
    include Splash::Backends
    include Splash::Exiter


    @@registry = Prometheus::Client.registry
    @@metric_exitcode = Prometheus::Client::Gauge.new(:errorcode, docstring: 'SPLASH metric batch errorcode')
    @@metric_time = Prometheus::Client::Gauge.new(:exectime, docstring: 'SPLASH metric batch execution time')
    @@registry.register(@@metric_exitcode)
    @@registry.register(@@metric_time)

    def initialize(name)
      @config  = get_config
      @url = "http://#{@config.prometheus_pushgateway_host}:#{@config.prometheus_pushgateway_port}"
      @name = name
      unless @config.commands.keys.include? @name.to_sym then
        splash_exit case: :not_found, more: "command #{@name} is not defined in configuration"
      end
    end

    def ack
      puts "Sending ack for command : '#{@name}'"
      notify(0,0)
    end

    def notify(value,time)
      unless verify_service host: @config.prometheus_pushgateway_host ,port: @config.prometheus_pushgateway_port then
        return { :case => :service_dependence_missing, :more => "Prometheus Notification not send."}
      end
      @@metric_exitcode.set(value)
      @@metric_time.set(time)
      hostname = Socket.gethostname
      Prometheus::Client::Push.new(@name, hostname, @url).add(@@registry)
      puts " * Prometheus Gateway notified."
      return { :case => :quiet_exit}
    end


    def call_and_notify(options)
      puts "Executing command : '#{@name}' "
      acase = { :case => :quiet_exit }
      start = Time.now
      start_date = DateTime.now.to_s
      unless options[:trace] then
        puts " * Traceless execution"
        if @config.commands[@name.to_sym][:user] then
          puts " * Execute with user : #{@config.commands[@name.to_sym][:user]}."
          system("sudo -u #{@config.commands[@name.to_sym][:user]} #{@config.commands[@name.to_sym][:command]} > /dev/null 2>&1")
        else
          system("#{@config.commands[@name.to_sym][:command]} > /dev/null 2>&1")
        end
        time = Time.now - start
        exit_code = $?.exitstatus
      else
        puts " * Tracefull execution"
        if @config.commands[@name.to_sym][:user] then
          puts " * Execute with user : #{@config.commands[@name.to_sym][:user]}."
          stdout, stderr, status = Open3.capture3("sudo -u #{@config.commands[@name.to_sym][:user]} #{@config.commands[@name.to_sym][:command]}")
        else
          stdout, stderr, status = Open3.capture3(@config.commands[@name.to_sym][:command])
        end
        time = Time.now - start
        tp = Template::new(
            list_token: @config.execution_template_tokens,
            template_file: @config.execution_template_path)
        data = Hash::new
        data[:start_date] = start_date
        data[:end_date] = DateTime.now.to_s
        data[:cmd_name] = @name
        data[:cmd_line] = @config.commands[@name.to_sym][:command]
        data[:desc] = @config.commands[@name.to_sym][:desc]
        data[:status] = status.to_s
        data[:stdout] = stdout
        data[:stderr] = stderr
        data[:exec_time] = time.to_s
        backend = get_backend :execution_trace
        key = @name
        backend.put key: key, value: data.to_yaml
        exit_code = status.exitstatus
      end

      puts "  => exitcode #{exit_code}"
      if options[:notify] then
        acase = notify(exit_code,time.to_i)
      else
        puts " * Without Prometheus notification"
      end
      if options[:callback] then
        on_failure = (@config.commands[@name.to_sym][:on_failure])? @config.commands[@name.to_sym][:on_failure] : false
        on_success = (@config.commands[@name.to_sym][:on_success])? @config.commands[@name.to_sym][:on_success] : false

        if on_failure and exit_code > 0 then
          puts " * On failure callback : #{on_failure}"
          if @config.commands.keys.include?  on_failure then
            @name = on_failure.to_s
            call_and_notify options
          else
            acase = { :case => :configuration_error , :more => "on_failure call error : #{on_failure} command inexistant."}
          end
        end
        if on_success and exit_code == 0 then
          puts " * On success callback : #{on_success}"
          if @config.commands.keys.include?  on_success then
            @name = on_success.to_s
            call_and_notify options
          else
            $stderr.puts "on_success call error : configuration mistake : #{on_success} command inexistant."
          end
        end
      else
        puts " * Without callbacks sequences"
      end
      return acase
    end
  end
end
