module Splash
  module Constants
    VERSION = "0.0.2"
    CONFIG_FILE = "/etc/splash.yml"
    DAEMON_USER = "root"
    DAEMON_GROUP = "wheel"
    PID_PATH="/var/run"
    TRACE_PATH="/var/run/splash"
    PID_FILE="splash.pid"
    STDOUT_TRACE="stdout.txt"
    STDERR_TRACE="stderr.txt"
    DAEMON_PROCESS_NAME="Splash : Prometheus logs monitoring."
    AUTHOR="Romain GEORGES"
    EMAIL = "gems@ultragreen.net"
    COPYRIGHT="Ultragreen (c) 2020"
    LICENSE="BSD-2-Clause"
    PROMETHEUS_PUSHGATEWAY_HOST = "localhost"
    PROMETHEUS_PUSHGATEWAY_PORT = "9091"
    EXECUTION_TEMPLATE="/etc/splash_execution_report.tpl"
    TOKENS_LIST = [:date,:cmd_name,:cmd_line,:stdout,:stderr,:desc,:status]
  end
end
