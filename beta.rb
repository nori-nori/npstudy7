require 'expect4r'
require 'pp'

def ifStatus v
  return {ifOper: v[2].to_s, ifAdmin: v[3].to_s}
end

def ifPhy v
  return {ifPyh: v[1].to_s, mac: v[2].to_s}
end

def ipAddr v
  return {ipAddr: v[1].to_s}
end

def descr v
  return {descr: v[1].to_s}
end

def ifMtu_bw v
  return {mtu: v[1].to_s, bw: v[2].to_s}
end

  ShowInterfaceMessageFormatTable = [
    [/^(\w+) is (\w+), line protocol is (\w+)\s*/, :ifStatus],
    [/^  Hardware is (.+), address is ([^\s]+) /, :ifPhy],
    [/^  Description: (.+)/, :descr],
    [/^  Internet address is (.+)/, :ipAddr],
    [/^  MTU (\d+) bytes, BW (\d+) Kbit\/sec/, :ifMtu_bw],
    [/^    reliability (\d+)\/(\d+), txload (\d+)\/(\d+), rxload (\d+)\/(\d+)/, nil],
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

def interfaceMsgAnalyzer msg
  def pickupVal line, fmtTable, ret
    fmtTable.each do |tbl|
      if (m = tbl[0].match(line))
        ret.merge!(self.send(tbl[1], m)) if tbl[1] != nil
        return true
      end
    end
    false
  end

  ret = {}
  msg.each do |line|
    next if pickupVal(line.chomp, ShowInterfaceMessageFormatTable, ret)
    STDERR.puts "not match message => #{line}"
    exit
  end
  return ret

end


#
# main
#

ios = Expect4r::Ios.new(:telnet, host: "192.168.56.254",
      user: "router", pwd: "router", enable: "router")
ios.login

# ip address set
ios.config %{
  interface GigabitEthernet 1
    ip address 1.1.1.1 255.255.255.0
}

msg = (ios.show_interface_GigabitEthernet1[0])[1..-2]
pp interfaceMsgAnalyzer(msg)

puts "-"*10
# ip address set ,2nd
ios.config %{
  interface GigabitEthernet 1
    ip address 5.6.7.8 255.255.255.0
}

msg = (ios.show_interface_GigabitEthernet1[0])[1..-2]
pp interfaceMsgAnalyzer(msg)

