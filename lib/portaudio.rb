require 'ffi'

module PortAudio
  module C
    extend FFI::Library
    
    case RUBY_PLATFORM
    when /darwin/i
      ffi_lib '/System/Library/Frameworks/AudioUnit.framework/AudioUnit'
      ffi_lib '/System/Library/Frameworks/CoreAudio.framework/CoreAudio'
      ffi_lib '/System/Library/Frameworks/AudioToolbox.framework/AudioToolbox'
      ffi_lib '/System/Library/Frameworks/CoreServices.framework/CoreServices'
    end
    
    ffi_lib 'portaudio'
    
    PA_ERROR = :int
    PA_NO_ERROR = 0
    
    PA_DEVICE_INDEX = :int
    PA_NO_DEVICE = (2 ** FFI::Platform::LONG_SIZE) - 1
    
    PA_HOST_API_TYPE_ID = :int
    
    PA_HOST_API_INDEX = :int
    
    class PaHostApiInfo < FFI::Struct
      layout :struct_version, :int,
             :type, PA_HOST_API_TYPE_ID,
             :name, :string,
             :device_count, :int,
             :default_input_device, PA_DEVICE_INDEX,
             :default_output_device, PA_DEVICE_INDEX
    end
    
    class PaHostErrorInfo < FFI::Struct
      layout :host_api_type, PA_HOST_API_TYPE_ID,
             :error_code, :long,
             :error_text, :string
    end
    
    PA_TIME = :double
    
    PA_SAMPLE_FORMAT = :ulong
    PA_SAMPLE_FORMAT_MAP = {
      :float32 => 0x00000001,
      :int32   => 0x00000002,
      :int24   => 0x00000004,
      :int16   => 0x00000008,
      :int8    => 0x00000010,
      :uint8   => 0x00000020,
      :custom  => 0x00010000
    }
    
    PA_NON_INTERLEAVED = 0x80000000
    
    class PaDeviceInfo < FFI::Struct
      layout :struct_version, :int,
             :name, :string,
             :host_api, PA_HOST_API_INDEX,
             :max_input_channels, :int,
             :max_output_channels, :int,
             :default_low_input_latency, PA_TIME,
             :default_low_output_latency, PA_TIME,
             :default_high_input_latency, PA_TIME,
             :default_high_output_latency, PA_TIME,
             :default_sample_rate, :double
    end
    
    class PaStreamParameters < FFI::Struct
      layout :device, PA_DEVICE_INDEX,
             :channel_count, :int,
             :sample_format, PA_SAMPLE_FORMAT,
             :suggested_latency, PA_TIME,
             :host_specific_stream_info, :pointer
      
      def self.from_options(options)
        params = C::PaStreamParameters.new
        params[:device] = case options[:device]
          when Integer then options[:device]
          when Device  then options[:device].index
        end
        params[:channel_count] = options[:channels]
        params[:sample_format] = C::PA_SAMPLE_FORMAT_MAP[options[:sample_format]]
        params
      end
    end
    
    PA_FORMAT_IS_SUPPORTED = 0
    
    PA_FRAMES_PER_BUFFER_UNSPECIFIED = 0
    
    PA_STREAM_FLAGS = :ulong
    PA_NO_FLAG                 = 0
    PA_CLIP_OFF                = 0x00000001
    PA_DITHER_OFF              = 0x00000002
    PA_NEVER_DROP_INPUT        = 0x00000004
    PA_PRIME_OUTPUT_BUFFERS_USING_STREAM_CALLBACK =
                                 0x00000008
    PA_PLATFORM_SPECIFIC_FLAGS = 0xFFFF0000
    
    PA_STREAM_CALLBACK_FLAGS = :ulong
    PA_INPUT_UNDERFLOW  = 0x00000001
    PA_INPUT_OVERFLOW   = 0x00000002
    PA_OUTPUT_UNDERFLOW = 0x00000004
    PA_OUTPUT_OVERFLOW  = 0x00000008
    PA_PRIMING_OUTPUT   = 0x00000010
    
    PA_STREAM_CALLBACK_RESULT = :int
    PA_CONTINUE = 0
    PA_COMPLETE = 1
    PA_ABORT    = 2
    
    PA_STREAM_CALLBACK = :pointer
    
    PA_STREAM_FINISHED_CALLBACK = :pointer
    
    class PaStreamInfo < FFI::Struct
      layout :struct_version, :int,
             :input_latency, PA_TIME,
             :output_latency, PA_TIME,
             :sample_rate, :double
    end
    
    attach_function :Pa_GetVersion, [], :int
    attach_function :Pa_GetVersionText, [], :string
    attach_function :Pa_GetErrorText, [PA_ERROR], :string
    attach_function :Pa_Initialize, [], PA_ERROR
    attach_function :Pa_Terminate, [], PA_ERROR
    attach_function :Pa_GetHostApiCount, [], PA_DEVICE_INDEX
    attach_function :Pa_GetDefaultHostApi, [], PA_DEVICE_INDEX
    attach_function :Pa_GetHostApiInfo, [:int], :pointer
    attach_function :Pa_HostApiTypeIdToHostApiIndex, [PA_HOST_API_TYPE_ID], PA_HOST_API_INDEX
    attach_function :Pa_HostApiDeviceIndexToDeviceIndex, [PA_HOST_API_INDEX, :int], PA_DEVICE_INDEX
    attach_function :Pa_GetLastHostErrorInfo, [], PaHostErrorInfo
    attach_function :Pa_GetDeviceCount, [], PA_DEVICE_INDEX
    attach_function :Pa_GetDefaultInputDevice, [], PA_DEVICE_INDEX
    attach_function :Pa_GetDefaultOutputDevice, [], PA_DEVICE_INDEX
    attach_function :Pa_GetDeviceInfo, [PA_DEVICE_INDEX], :pointer
    attach_function :Pa_IsFormatSupported, [:pointer, :pointer, :double], PA_ERROR
    attach_function :Pa_OpenStream, [:pointer, :pointer, :pointer, :double, :ulong, PA_STREAM_FLAGS, PA_STREAM_CALLBACK, :pointer], PA_ERROR
    attach_function :Pa_OpenDefaultStream, [:pointer, :int, :int, PA_SAMPLE_FORMAT, :double, :ulong, PA_STREAM_CALLBACK, :pointer], PA_ERROR
    attach_function :Pa_CloseStream, [:pointer], PA_ERROR
    attach_function :Pa_SetStreamFinishedCallback, [:pointer, :pointer], PA_ERROR
    attach_function :Pa_StartStream, [:pointer], PA_ERROR
    attach_function :Pa_StopStream, [:pointer], PA_ERROR
    attach_function :Pa_AbortStream, [:pointer], PA_ERROR
    attach_function :Pa_IsStreamStopped, [:pointer], PA_ERROR
    attach_function :Pa_IsStreamActive, [:pointer], PA_ERROR
    attach_function :Pa_GetStreamInfo, [:pointer], :pointer
    attach_function :Pa_GetStreamTime, [:pointer], PA_TIME
    attach_function :Pa_GetStreamCpuLoad, [:pointer], :double
    attach_function :Pa_ReadStream, [:pointer, :pointer, :ulong], PA_ERROR
    attach_function :Pa_WriteStream, [:pointer, :pointer, :ulong], PA_ERROR
    attach_function :Pa_GetStreamReadAvailable, [:pointer], :long
    attach_function :Pa_GetStreamWriteAvailable, [:pointer], :long
    attach_function :Pa_GetSampleSize, [:ulong], PA_ERROR
    attach_function :Pa_Sleep, [:long], :void
  end
  
  def version_number
    C.Pa_GetVersion()
  end
  module_function :version_number
  
  def version_text
    C.Pa_GetVersionText()
  end
  module_function :version_text
  
  def error_text(pa_err)
    C.Pa_GetErrorText(pa_err)
  end
  module_function :error_text
  
  def init
    C.Pa_Initialize()
  end
  module_function :init
  
  def terminate
    C.Pa_Terminate()
  end
  module_function :terminate
  
  def sleep(msec)
    C.Pa_Sleep(msec)
  end
  module_function :sleep
  
  def invoke
    status = yield
    if status != C::PA_NO_ERROR
      raise RuntimeError, PortAudio.error_text(status)
    end
  end
  module_function :invoke
  
  def sample_size(format)
    status = C.Pa_GetSampleSize(C::PA_SAMPLE_FORMAT_MAP[format])
    if status >= 0 then status
    else
      raise RuntimeError, PortAudio.error_text(status)
    end
  end
  module_function :sample_size
  
  class Host
    def self.count
      C.Pa_GetHostApiCount()
    end
    
    def self.default
      new(C.Pa_GetDefaultHostApi())
    end
    
    class << self
      private :new
    end
    
    def initialize(index)
      @index = index
      infop = C.Pa_GetHostApiInfo(@index)
      if infop.null?
        err = C::PaHostErrorInfo.new(C.Pa_GetLastHostErrorInfo())
        raise RuntimeError, err[:error_text]
      end
      @info = C::PaHostApiInfo.new(infop) unless infop.null?
    end
    
    def name
      @info[:name]
    end
    
    def devices
      @devices ||= DeviceCollection.new(@index, @info)
    end
    
    class DeviceCollection
      include Enumerable
      
      def initialize(host_index, host_info)
        @host_index, @host_info = host_index, host_info
      end
      
      def count
        @host_info[:device_count]
      end
      alias_method :size, :count
      
      def [](index)
        case index
        when (0 ... count)
          Device.new(C.Pa_HostApiDeviceIndexToDeviceIndex(@host_index, index))
        end
      end
      
      def each
        0.upto(count) { |i| yield self[i] }
      end
      
      def default_input
        index = @host_info[:default_input_device]
        self[index] unless C::PA_NO_DEVICE == index
      end
      
      def default_output
        index = @host_info[:default_output_device]
        self[index] unless C::PA_NO_DEVICE == index
      end
    end
  end
  
  class Device
    def self.count
      C.Pa_GetDeviceCount()
    end
    
    def self.default_input
      index = C.Pa_GetDefaultInputDevice()
      new(index) unless C::PA_NO_DEVICE == index
    end
    
    def self.default_output
      index = C.Pa_GetDefaultOutputDevice()
      new(index) unless C::PA_NO_DEVICE == index
    end
    
    def initialize(index)
      @index = index
      infop = C.Pa_GetDeviceInfo(@index)
      raise RuntimeError, "Device not found" if infop.null?
      @info = C::PaDeviceInfo.new(infop)
    end
    
    attr_reader :index
    
    def name
      @info[:name]
    end
    
    def max_input_channels
      @info[:max_input_channels]
    end
    
    def max_output_channels
      @info[:max_output_channels]
    end
    
    def default_low_input_latency
      @info[:default_low_input_latency]
    end
    
    def default_low_output_latency
      @info[:default_low_output_latency]
    end
    
    def default_high_input_latency
      @info[:default_high_input_latency]
    end
    
    def default_high_output_latency
      @info[:default_high_output_latency]
    end
    
    def default_sample_rate
      @info[:default_sample_rate]
    end
  end
  
  class Stream
    def self.format_supported?(options)
      if options[:input]
        in_params = C::PaStreamParameters.from_options(options[:input])
      end
      
      if options[:output]
        out_params = C::PaStreamParameters.from_options(options[:output])
      end
      
      sample_rate = options[:sample_rate]
      err = C.Pa_IsFormatSupported(in_params, out_params, sample_rate)
      
      case err
        when C::PA_FORMAT_IS_SUPPORTED then true
        else false
      end
    end
    
    def self.open(options)
      if options[:input]
        in_params = C::PaStreamParameters.from_options(options[:input])
      end
      
      if options[:output]
        out_params = C::PaStreamParameters.from_options(options[:output])
      end
      
      sample_rate = options[:sample_rate]
      frames    = options[:frames]    || C::PA_FRAMES_PER_BUFFER_UNSPECIFIED
      flags     = options[:flags]     || C::PA_NO_FLAG
      callbackp = options[:callback]  || FFI::Pointer.new(0) # default: blocking mode
      user_data = options[:user_data] || FFI::Pointer.new(0)
      FFI::MemoryPointer.new(:pointer) do |streamp|
        PortAudio.invoke {
          C.Pa_OpenStream(streamp,
            in_params, out_params,
            sample_rate, frames, flags,
            callbackp, user_data)
        }
        
        return new(streamp.read_pointer)
      end
    end
    
    class << self
      private :new
    end
    
    def initialize(pointer)
      @stream = pointer
      infop = C.Pa_GetStreamInfo(@stream)
      raise RuntimeError, "Invalid stream" if infop.null?
      @info = C::PaStreamInfo.new(infop)
    end
    
    def close
      PortAudio.invoke { C.Pa_CloseStream(@stream) }
    end
    
    def start
      PortAudio.invoke { C.Pa_StartStream(@stream) }
    end
    
    def stop
      PortAudio.invoke { C.Pa_StopStream(@stream) }
    end
    
    def abort
      PortAudio.invoke { C.Pa_AbortStream(@stream) }
    end
    
    def stopped?
      status = C.Pa_IsStreamStopped(@stream)
      case status
        when 1 then true
        when 0 then false
        else
          raise RuntimeError, PortAudio.error_text(status)
      end
    end
    
    def active?
      status = C.Pa_IsStreamActive(@stream)
      case status
        when 1 then true
        when 0 then false
        else
          raise RuntimeError, PortAudio.error_text(status)
      end
    end
    
    def time
      C.Pa_GetStreamTime(@stream)
    end
    
    def cpu_load
      C.Pa_GetStreamCpuLoad(@stream)
    end
    
    def read
      raise NotImplementedError, "Stream#read is not implemented" # TODO ;)
    end
    
    def write(buffer)
      C.Pa_WriteStream(@stream, buffer.to_ptr, buffer.frames)
    end
    alias_method :<<, :write
  end
  
  # A memory buffer for interleaved PCM data
  class SampleBuffer
    attr_reader :channels, :format, :frames, :size
    
    def initialize(options = {})
      @channels, @format, @frames = options.values_at(:channels, :format, :frames)
      @sample_size = PortAudio.sample_size(@format)
      @size = @sample_size * @channels * @frames
      @buffer = FFI::MemoryPointer.new(@size)
    end
    
    def dispose
      @buffer.free
      nil
    end
    
    def to_ptr
      @buffer
    end
    
    def [](index, channel = 0)
      offset = (index + channel) * @sample_size
      case @format
      when :float32
        @buffer.get_float32(offset)
      else
        raise NotImplementedError, "Unsupported sample format #@format"
      end
    end
    
    def []=(index, channel = 0, sample)
      offset = (index + channel) * @sample_size
      case @format
      when :float32
        @buffer.put_float32(offset, sample)
      else
        raise NotImplementedError, "Unsupported sample format #@format"
      end
    end
  end
end

if __FILE__ == $0
  PortAudio.init
  
  block_size = 512
  sr   = 44100
  step = 1.0/sr
  time = 0.0
  
  stream = PortAudio::Stream.open(
             :sample_rate => 44100,
             :frames => block_size,
             :output => {
               :device => PortAudio::Device.default_output,
               :channels => 1,
               :sample_format => :float32
              })
  
  buffer = PortAudio::SampleBuffer.new(
             :format   => :float32,
             :channels => 1,
             :frames   => block_size)
  
  playing = true
  Signal.trap('INT') { playing = false }
  puts "Ctrl-C to exit"
  
  stream.start
  
  loop do
    (0...512).each do |i|
      buffer[i] = Math.cos(time * 2 * Math::PI * 440.0) * Math.cos(time * 2 * Math::PI)
      time += step
    end
    stream << buffer
    break unless playing
  end
  
  stream.stop
end
