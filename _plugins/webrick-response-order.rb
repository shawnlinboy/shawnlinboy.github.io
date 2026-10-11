# frozen_string_literal: true

# On macOS with Ruby 3.1, WEBrick's IO.copy_stream can send a file body before
# the buffered HTTP headers. Browsers then reject the response as invalid.
# Keep Jekyll's normal response handling, but write file bodies through the
# socket so that headers and body arrive in order during local previews.
if Jekyll.env == "development" && RUBY_PLATFORM.include?("darwin")
  require "webrick"

  class WEBrickSocketWriter
    def initialize(socket)
      @socket = socket
    end

    def write(data)
      @socket.write(data)
    end
  end

  module WEBrickResponseOrder
    def send_body_io(socket)
      super(WEBrickSocketWriter.new(socket))
    end
  end

  WEBrick::HTTPResponse.prepend(WEBrickResponseOrder)
end
