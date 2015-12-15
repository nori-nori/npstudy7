class Interface
  attr_reader :name, :descr, :ifOper, :ifAdmin, :mtu, :bw, :ifPhy, :mac, :ipAddr
  def initialize var
    @name = var[:ifName] if var.has_key?(:ifName)
    @descr = var[:descr] if var.has_key?(:descr)
    @ifOper = var[:ifOper] if var.has_key?(:ifOper)
    @ifAdmin = var[:fAdmin] if var.has_key?(:ifAdmin)
    @mtu = var[:mtu] if var.has_key?(:mtu)
    @bw = var[:bw] if var.has_key?(:bw)
    @ifPhy = var[:ifPhy] if var.has_key?(:ifPhy)
    @mac = var[:mac] if var.has_key?(:mac)
    @ipAddr = var[:ipAddr] if var.has_key?(:ipAddr)
  end

  def adapter val
    @adapter = val
  end

  def  inspect
    "name: #{@name}, descr: #{@descr}, ipAddr:#{@ipAddr}, ifOper:#{@ifOper}, ifAdmin:#{@ifAdmin}"
  end

  def ipAddr val=nil
    return @ipAddr if val == nil
    cmd = "
      interface #{@name}
      ip address #{val}
    "
    @adapter.config cmd
    self
  end

  def ipAddr= val=nil
    ipAddr val 
  end

  def descr val=nil
    return @descr if val == nil
    cmd = "
      interface #{@name}
      description #{val}
    "
    @adapter.config cmd
    self
  end

  def descr= val=nil
    descr val 
  end

  
end


module MessageAnalyzer
  module Interface 
    ShowInterfaceMessageFormatTable = [
      [/^(\w+) is (\w+), line protocol is (\w+)\s*/, :ifStatus],
      [/^  Hardware is (.+), address is ([^\s]+) /, :ifPhy],
      [/^  Description: (.+)/, :descr],
      [/^  Internet address is (.+)/, :ipAddr],
      [/^  MTU (\d+) bytes, BW (\d+) Kbit\/sec/, :ifMtu_bw],
      [/^    reliability/, nil],
      [/^  Encapsulation ARPA/, nil],
      [/^  Keepalive/, nil],
      [/^  .*media type/, nil],
      [/^  output flow-control/, nil],
      [/^  ARP type/, nil],
      [/^  Last/, nil],
      [/^  Input/, nil],
      [/^  Queueing strategy/, nil],
      [/^  Output queue/, nil],
      [/^  5 minute/,nil],
      [/^\s{4}/, nil]
    ]

    def self.ifStatus v
      return {ifName: v[1].to_s, ifOper: v[2].to_s, ifAdmin: v[3].to_s}
    end

    def self.ifPhy v
    return {ifPyh: v[1].to_s, mac: v[2].to_s}
    end

    def self.ipAddr v
      return {ipAddr: v[1].to_s}
    end

    def self.descr v
      return {descr: v[1].to_s}
    end

    def self.ifMtu_bw v
      return {mtu: v[1].to_s, bw: v[2].to_s}
    end

    def self.ipAddr v
      return {ipAddr: v[1].to_s}
    end

    def self.analyze msg
      ret = {}
      msg.each do |line|
        next if pickupVal(line.chomp, ShowInterfaceMessageFormatTable, ret)
        STDERR.puts "not match message => #{line}"
        exit
      end
      return ret
    end
    def self.pickupVal line, fmtTable, ret
      fmtTable.each do |tbl|
        if (m = tbl[0].match(line))
          ret.merge!(self.send(tbl[1], m)) if tbl[1] != nil
          return true
        end
      end
      false
    end
  end
end


class NetDevice
  def initialize
    @interfaces = {}
    @device = nil
  end

  def connect var
    return @device if @device != nil
    @device = adapter var
    @device.login
  end

  def interface name, refresh = nil
    return @interfaces[name] if @interfaces.has_key?(name) and refresh == nil
    msg = @device.send("show_interface_#{name}")
    @interfaces[name] = 
      Interface.new MessageAnalyzer::Interface::analyze((msg[0])[1..-2])
    @interfaces[name].adapter @device
    @interfaces[name]
  end

private
  def adapter var
    Expect4r::Ios.new(:telnet, var)
  end
end

class NetDevice::SSH < NetDevice
  def adapter var
    Expect4r::Ios.new(:ssh, var)
  end
end
