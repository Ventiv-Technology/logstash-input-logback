require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/util/socket_peer"
require "socket"
require "timeout"

# Read events over a TCP socket from Logback SocketAppender.
#
# Can either accept connections from clients or connect to a server,
# depending on `mode`. Depending on mode, you need a matching SocketAppender or SocketHubAppender on the remote side
class LogStash::Inputs::Logback < LogStash::Inputs::Base

  config_name "logback"
  plugin_status 0

  # When mode is `server`, the address to listen on.
  # When mode is `client`, the address to connect to.
  config :host, :validate => :string, :default => "0.0.0.0"

  # When mode is `server`, the port to listen on.
  # When mode is `client`, the port to connect to.
  config :port, :validate => :number, :required => true

  # Read timeout in seconds. If a particular tcp connection is
  # idle for more than this timeout period, we will assume
  # it is dead and close it.
  # If you never want to timeout, use -1.
  config :data_timeout, :validate => :number, :default => 5

  # Mode to operate in. `server` listens for client connections,
  # `client` connects to a server.
  config :mode, :validate => ["server", "client"], :default => "server"

  # Location of the jar files for deserialization.  The following are required:
  # - logback-classic
  # - logback-core
  # - slf4j-api
  config :jar_location, :validate => :string, :required => true

  # Version of logback to look for
  config :logback_version, :validate => :string, :default => "1.1.3"

  # Version of slfj4 to look for
  config :slf4j_version, :validate => :string, :default => "1.7.14"

  def initialize(*args)
    super(*args)
  end # def initialize

  public
  def register
    require "java"
    require "jruby/serialization"
    require "#{@jar_location}/logback-classic-#{@logback_version}.jar"
    require "#{@jar_location}/logback-core-#{@logback_version}.jar"
    require "#{@jar_location}/slf4j-api-#{@slf4j_version}.jar"

    if server?
      @logger.info("Starting Logback input listener", :address => "#{@host}:#{@port}")
      @server_socket = TCPServer.new(@host, @port)
    end
    @logger.info("Logback input")
  end # def register

  private
  def handle_socket(socket, output_queue, event_source)
    begin
      # JRubyObjectInputStream uses JRuby class path to find the class to de-serialize to
      ois = JRubyObjectInputStream.new(java.io.BufferedInputStream.new(socket.to_inputstream))
      loop do
        # NOTE: event_raw is ch.qos.logback.classic.spi.ILoggingEvent
        event_obj = ois.readObject()
        e = LogStash::Event.new("message" => event_obj.getFormattedMessage())
        decorate(e)
        e["host"] = socket.peer
        e["path"] = event_obj.getLoggerName()
        e["priority"] = event_obj.getLevel().toString()
        e["logger_name"] = event_obj.getLoggerName()
        e["thread"] = event_obj.getThreadName()
        e["log_timestamp"] = event_obj.getTimeStamp()

        # Add callerData to '@fields'
        if event_obj.hasCallerData()
          if event_obj.getCallerData().length > 0
            callerData = event_obj.getCallerData[0]
            e["file"] = callerData.getFileName() + ":" + callerData.getLineNumber().to_s
            e["class"] = callerData.getClassName()
            e["method"] = callerData.getMethodName()
          end
        end

        # Add the MDC context properties to '@fields'
        if event_obj.getMDCPropertyMap()
          event_obj.getMDCPropertyMap().keySet().each do |key|
            e[key] = event_obj.getMDCPropertyMap().get(key)
          end
        end

        # Add the stackTrace to '@fields'
        if event_obj.getThrowableProxy()
          tp = event_obj.getThrowableProxy()
          st = tp.getClassName() + ": " + tp.getMessage()
          if tp.getStackTraceElementProxyArray()
            tp.getStackTraceElementProxyArray().each do |ste|
              st = st + "\n" + ste.getSTEAsString()
            end
          end

          e["stack_trace"] = st
        end

        if e
          output_queue << e
        end
      end # loop do
    rescue => e
      @logger.debug("Closing connection", :client => socket.peer,
                    :exception => e, :backtrace => e.backtrace)
    rescue Timeout::Error
      @logger.debug("Closing connection after read timeout",
                    :client => socket.peer)
    end # begin

    begin
      socket.close
    rescue IOError
      pass
    end # begin
  end

  private
  def server?
    @mode == "server"
  end # def server?

  private
  def readline(socket)
    line = socket.readline
  end # def readline

  public
  def run(output_queue)
    if server?
      loop do
        # Start a new thread for each connection.
        Thread.start(@server_socket.accept) do |s|
          # TODO(sissel): put this block in its own method.

          # monkeypatch a 'peer' method onto the socket.
          s.instance_eval { class << self; include ::LogStash::Util::SocketPeer end }
          @logger.debug("Accepted connection", :client => s.peer,
                        :server => "#{@host}:#{@port}")
          handle_socket(s, output_queue, "tcp://#{@host}:#{@port}/client/#{s.peer}")
        end # Thread.start
      end # loop
    else
      loop do
        client_socket = TCPSocket.new(@host, @port)
        client_socket.instance_eval { class << self; include ::LogStash::Util::SocketPeer end }
        @logger.debug("Opened connection", :client => "#{client_socket.peer}")
        handle_socket(client_socket, output_queue, "tcp://#{client_socket.peer}/server")
      end # loop
    end
  end # def run
end # class LogStash::Inputs::Logback
