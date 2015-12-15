$:.unshift File.dirname(__FILE__)
require 'expect4r'
require 'netdev'

ifname = "GigabitEthernet1"

router = NetDevice.new
router.connect(host: "192.168.56.254",
   user: "router", pwd: "router", enable: "router")

puts "-"*10
router.interface(ifname).ipAddr("1.2.3.4 255.255.255.0").descr("1st")
p router.interface(ifname, :refresh).inspect

puts "-"*10
router.interface(ifname).ipAddr("5.6.7.8 255.255.255.0").descr("2nd")
p router.interface(ifname, :refresh).inspect

