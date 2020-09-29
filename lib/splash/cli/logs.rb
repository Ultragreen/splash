# coding: utf-8

# module for all Thor subcommands
module CLISplash

  # Thor inherited class for documentation management
  class Logs < Thor
    include Splash::Config
    include Splash::Exiter
    include Splash::Logs

    # Thor method : running Splash configured logs monitors analyse
    desc "analyse", "analyze logs defined in Splash config"
    def analyse
      log  = get_logger
      results = LogScanner::new
      res = results.analyse
      log.info "SPlash Configured log monitors :"
      full_status = true
      results.output.each do |result|
        if result[:status] == :clean then
          log.ok "Log : #{result[:log]} with label : #{result[:label]} : no errors"
          log.item "Detected pattern : #{result[:pattern]}"
          log.item "Nb lines = #{result[:lines]}"
        elsif result[:status] == :missing then
          log.ko "Log : #{result[:log]} with label : #{result[:label]} : missing !"
          log.item "Detected pattern : #{result[:pattern]}"
        else
          log.ko "Log : #{result[:log]} with label : #{result[:label]} : #{result[:count]} errors"
          log.item "Detected pattern : #{result[:pattern]}"
          log.item "Nb lines = #{result[:lines]}"
        end

        full_status = false unless result[:status] == :clean
      end

      if full_status then
        log.ok "Global status : no error found"
      else
        log.error "Global status : some error found"
      end
      splash_exit case: :quiet_exit
    end


    # Thor method : running Splash configured logs monitors analyse and sending to Prometheus Pushgateway
    desc "monitor", "monitor logs defined in Splash config"
    def monitor
      log = get_logger
      log.level = :fatal if options[:quiet]
      result = LogScanner::new
      result.analyse
      splash_exit result.notify

    end

    # Thor method : display a specific Splash configured log monitor
    desc "show LOG", "show Splash configured log monitoring for LOG"
    def show(logrecord)
      log = get_logger
      log_record_set = get_config.logs.select{|item| item[:log] == logrecord or item[:label] == logrecord.to_sym}
      unless log_record_set.empty? then
        record = log_record_set.first
        log.info "Splash log monitor : #{record[:log]}"
        log.item "pattern : /#{record[:pattern]}/"
        log.item "label : #{record[:label]}"
        splash_exit case: :quiet_exit
      else
        splash_exit case: :not_found, :more => "log not configured"
      end
    end

    # Thor method : display the full list of Splash configured log monitors
    desc "list", "List all Splash configured logs monitoring"
    long_desc <<-LONGDESC
    Show configured logs monitoring\n
    with --detail, show logs monitor details
    LONGDESC
    option :detail, :type => :boolean,  :aliases => "-D"
    def list
      log = get_logger
      log.info "Splash configured log monitoring :"
      log_record_set = get_config.logs
      log.ko 'No configured commands found' if log_record_set.empty?
      log_record_set.each do |record|
        log.item "log monitor : #{record[:log]} label : #{record[:label]}"
        if options[:detail] then
          log.arrow "pattern : /#{record[:pattern]}/"
        end
      end
      splash_exit case: :quiet_exit
    end

  end

end
