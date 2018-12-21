-- Sylvain Ellenstein, DGSE, Ministère des Armées, Balard, Paris
-- 2018-12-19
-- tshark -q -i eth0 -X lua_script:dump.lua
-- Sources :
-- Wireshark wiki, packet counter script :
-- https://wiki.wireshark.org/Lua/Examples
-- Wireshark extension to dump MPEG2 transport stream packets :
-- https://wiki.wireshark.org/mpeg_dump.lua
do
  local udp_src_f = Field.new("udp.srcport")
  local udp_dst_f = Field.new("udp.dstport")

  local ip_src_f = Field.new("ip.src")
  local ip_dst_f = Field.new("ip.dst")

  local rtp_payload_f = Field.new("rtp.payload")
  local flows = {}
  local files = {}

  local function init_listener()
    -- Alcatel 4018 use UDP port 6000 (both source and destination)
    local tap = Listener.new("frame", "udp.port == 6000")

    -- If tshark misses the SIP/SDP negociation,
    -- it does not decode UDP data as RTP automatically
    local rtpdis = Dissector.get("rtp")
    local udptab = DissectorTable.get("udp.port")
    udptab:add(6000, rtpdis)

    function tap.reset()

    end

    function tap.packet(pinfo, tvb, ip)
      local ip_src, ip_dst = tostring(ip_src_f()), tostring(ip_dst_f())

      local udp_src, udp_dst = udp_src_f(), udp_dst_f()

      -- A flow is defined by : source IP, source port, dest IP, dest port
      local flow = ip_src .. ":" .. tostring(udp_src) .. "-" .. ip_dst .. ":" .. tostring(udp_dst)

      if not flows[flow] then
        flows[flow] = 1
        files[flow] = io.open(flow, "wb")
      else
        flows[flow] = flows[flow] + 1
      end

      -- Get G.711 PCMU payload
      local payload = rtp_payload_f()

      -- We want to write raw data. Convert payload (userdata) to string
      -- then back to binary (Ugly)
      files[flow]:write(tobinary(tostring(payload)))
      end

    -- List flows at the end of the capture
    function tap.draw()
      print("VoIP flows:")

      for flow, count in pairs(flows) do
        print(flow .. " : " .. tostring(count))
      end
    end
  end

  -- convert an ascii char code to an integer value "0" => 0, "1" => 1, etc
  local function hex(ascii_code)
  	if not ascii_code then
      return 0
  	elseif ascii_code < 58 then
  		return ascii_code - 48
  	elseif ascii_code < 91 then
  		return ascii_code - 65 + 10
  	else
  		return ascii_code - 97 + 10
  	end
  end

  -- this function converts a hex-string to raw bytes
  tobinary = function (hexbytes)
    local binary = {}
    local sz = 1

    -- hexbytes has the following format : ab:cd:ef:gh:...
    -- Thus the step of 3 in the for loop
    for i=1, string.len(hexbytes), 3 do
      binary[sz] = string.char( 16 * hex( string.byte(hexbytes,i) ) + hex( string.byte(hexbytes,i+1) ) )
      sz = sz + 1
    end

    return table.concat(binary)
  end

  init_listener()
end
