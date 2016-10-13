module Kitchen
  class Logger
    alias_method :old_stdout_logger, :stdout_logger
    def stdout_logger(*args)
      logger = old_stdout_logger(*args)
      old_formatter = logger.formatter
      if ENV['LOG_TIMESTAMPS']
        logger.formatter = proc do |_severity, _datetime, _progname, msg|
          "[#{_datetime}] #{old_formatter.call(_severity, _datetime, _progname, msg)}"
        end
      end
      logger
    end
  end
end
