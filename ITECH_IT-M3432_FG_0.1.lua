_KeepRet 			= ""
DEV_USBCAN  		= "DEV_USBCAN"
DEV_USBCAN2 		= "DEV_USBCAN2"
SerialPortName 		= {}
Getindex()
gPacKBatterCode     = GetPackCode()		      --全局电池条码
gCellCode 		    = GetCellCode()			  --全局电芯条码/临时条码
-- string(":CONF:VOLT;:SENS:VOLT:DCNPLC 0.02")
-- string(":CONF:CURR;:SENS:CURR:DCNPLC 0.02;SAMP:COUN 1")
local dbg_port_g = 1 --serial port
local ps_port_g = 3--serial port

--该函数
function SetUI(TestItemName,ActMeas,TestRest,Time,ErrInfo,LimitMin,LimitMax)
		
	if LimitMin == nil  then
		LimitMin = ""
	end

	if LimitMax == nil then
		LimitMax = ""
	end

	Setbinding(tostring(TestItemName),tostring(TestRest),tostring(ActMeas),tostring(Time),tostring(ErrInfo),tostring(LimitMin),tostring(LimitMax))
	_KeepRet = _KeepRet .. tostring(TestRest)
end

function serial_init( port_x, baudrate, ...)
	local arg = {...}
	local port_num = arg[1]
	local ret = 1

	if port_num == nil then
		port_num = 2
	end

	SetSerialPortCount(port_num)							--设置串口个数
	SerialPortName = SerialPort_Sacn()						--获取主机连接的全部串口
	print(SerialPortName)

	SerialPortInit(port_x, baudrate, 0, 8, 1)				--初始化串口，除第一个参数串口号其他参数可省略(默认为此参数)

	ret = PortSerialOpen(port_x)							--Open串口(串口号)
	PortClearBuff(port_x)									--ClearBuff
	if ret ~= true then
		print("port open fail !\r\n")
	end
	return ret
end

function serial_send_receive( port_x, data, ...)
	local arg = {...}
	local timeout = arg[1]
	local endl = "\r\n" --arg[1]

	if timeout == nil then
		timeout = 0
	end
	-- ShowMsg("port_x:" .. tostring(port_x) .. "data:" .. tostring(data).. "timeout:".. timeout .."\r\n")
	-- PortClearBuff(port_x)
	PortSendStr(data .. endl, port_x)					    --指令，串口号(不可省略)
	Sleep(timeout)
	local rx_data = PortGetStr(port_x)
	if type(rx_data) == "string" then
		return rx_data
	elseif type(rx_data) == "nil" then
	    return nil
	else
		ShowMsg("serial rx error" .. type(rx_data)) 	
	end
end

function debug( str )
	serial_send_receive(dbg_port_g, "dbg:" .. tostring(str), 100)
end
----------------------------------------------------------------------------------------------------------------------------------
-- function psu_test( ... )
	serial_init(dbg_port_g, 115200)
	serial_init(ps_port_g, 115200)
	psu_dev = {
	-------------------------------------------------------------------------------------------------
	 -- power supply unit with 2-quadrant const voltage & const current function
		name = "IT_M3432", com_port = 1, mode = "cvcc_cc",    quadrant = 2, endl_str = "\r\n",

		init = function(self, str)
		 	local str = serial_send_receive(self.com_port, str, 1000)
		 	debug(str)
		 end,
		 print = function(self, para)
		    -- ShowMsg(tostring(para))
		 	debug(para)
		 end,
		 set_vi = function(self, ...) --v, i, mode, delay, v_max, v_min, i_max, i_min 
	 		 local para = {...}
	 		 local v = para[1]
	 		 local i = para[2]
	 		 local mode = para[3]
	 		 local delay = para[4]
	 		 local v_max = para[5]
	 		 local v_min = para[6]
	 		 local i_max = para[7]
	 		 local i_min = para[8]
	 		 local ret_val = ""

	 		 if mode == "all_cc" then
	 		 	ret_val = serial_send_receive(self.com_port, "VOLT:LIM ".. v, 100)
	 		 	ret_val = serial_send_receive(self.com_port, "VOLT:LIM?", 100)
	 		 	ret_val = serial_send_receive(self.com_port, "CURR " .. i .. ";CURR?", 100)
	 		 elseif mode == "v_cc" then
	 		 	ret_val = serial_send_receive(self.com_port, "VOLT:LIM ".. v, 100)
	 		 	ret_val = serial_send_receive(self.com_port, "VOLT:LIM?", 100)
	 		 elseif mode == "i_cc" then
	 		 	ret_val = serial_send_receive(self.com_port, "CURR ".. i .. ";CURR?", 100)
 	 		 elseif mode == "all_cv" then -- cv 模式优先的情况下，电流需要配置为CURR:LIM:POS or CURR:LIM:NEG
 	 		 	if(i >= 0) then
 	 		 		ret_val = serial_send_receive(self.com_port, "VOLT ".. v .. ";CURR:LIM:POS " .. i, 10)
	 		 		ret_val = serial_send_receive(self.com_port, "VOLT?;CURR:LIM:POS?", 100)
	 		 	else
 	 		 		ret_val = serial_send_receive(self.com_port, "VOLT ".. v .. ";CURR:LIM:NEG " .. i, 10)
	 		 		ret_val = serial_send_receive(self.com_port, "VOLT?;CURR:LIM:NEG?", 100)
	 		 	end
	 		 elseif mode == "v_cv" then
 		 		ret_val = serial_send_receive(self.com_port, "VOLT ".. v .. ";VOLT?", 100)
	 		 elseif mode == "i_cv" then
	 		 	if(i >= 0) then
	 		 		ret_val = serial_send_receive(self.com_port, "CURR:LIM:POS ".. i, 10)
	 		 		ret_val = serial_send_receive(self.com_port, "VOLT?;CURR:LIM:POS?", 100)
	 		 	else
	 		 		ret_val = serial_send_receive(self.com_port, "CURR:LIM:NEG ".. i, 10)
	 		 		ret_val = serial_send_receive(self.com_port, "VOLT?;CURR:LIM:NEG?", 100)
	 		 	end
	 		 else
	 		 	ShowMsg("para[mode] input error")
	 		 end
	 		 -- self.print(self, ret_val)
	 		 -- SetUI("set_vi",tostring(ret_val),tostring(true), (0),"error info",tostring(90),tostring(200))
	 		 return ret_val
		 end,
		 get_vi = function(self, ...) 
	 		 local para = {...}
	 		 local mode = para[1]
	 		 local ret_val = ""

	 		 if mode == "all" then
	 		 	ret_val = serial_send_receive(self.com_port, "FETC:VOLT?;CURR?", 100)
	 		 elseif mode == "v" then
	 		 	ret_val = serial_send_receive(self.com_port, "FETC:VOLT?", 100)
	 		 elseif mode == "i" then
	 		 	ret_val = serial_send_receive(self.com_port, "FETC:CURR?", 100)
	 		 elseif mode == "all_slow" then
	 		 	ret_val = serial_send_receive(self.com_port, "MEAS:VOLT?;CURR?", 500)
	 		 elseif mode == "v_slow" then
	 		 	ret_val = serial_send_receive(self.com_port, "MEAS:VOLT?", 500)
	 		 elseif mode == "i_slow" then
	 		 	ret_val = serial_send_receive(self.com_port, "MEAS:CURR?", 500)
	 		 else
	 		 	ShowMsg("para[mode] input error")
	 		 end
	 		 -- self.print(self, ret_val)
	 		 -- SetUI("get_vi",tostring(ret_val),tostring(true), (0),"error info",tostring(90),tostring(200))
	 		 return ret_val
		 end,
	 	 out = function(self, ...) 
	 		 local para = {...}
	 		 local mode = para[1]
	 		 local ret_val = ""

	 		 if mode == "on" then
	 		 	ret_val = serial_send_receive(self.com_port, "OUTP ON;OUTP?", 100)
	 		 elseif mode == "off" then
	 		 	ret_val = serial_send_receive(self.com_port, "OUTP OFF;OUTP?", 100)
	 		 else
	 		 	ShowMsg("para[mode] input error")
	 		 end
	 		 -- self.print(self, ret_val)
	 		 -- SetUI("out",tostring(ret_val),tostring(true), (0),"error info",tostring(90),tostring(200))
	 		 return ret_val
		 end,
		 reset = function(self, ... )
		 	-- body
		 end,
		 curr_slope = function(self, rise, fall)
		 	-- body
		 end,
		 set_para_check = function(self, ... )
		 	-- body
		 end,
	}

	psu_dev.__index = psu_dev
	function psu_dev:new( name, com_port, mode, quadrant, endl_str)
		local dev = {}
		dev.mode = name
		dev.com_port = com_port
		dev.mode = mode
		dev.quadrant = quadrant
		dev.endl_str = endl_str
		setmetatable(dev, psu_dev)--setmetatable(dev, {__index = psu_dev})
		return dev
	end
	setmetatable(psu_dev, {__call = function(self, name, com_port, mode, quadrant, endl_str)
	    return self:new( name, com_port, mode, quadrant, endl_str)
	end
	})

	local psu_dev1 = psu_dev("IT-M3432", ps_port_g, "cv", 2, "\r\n")

	psu_dev1:print(psu_dev1:init("*IDN?;SYST:REM"))
	psu_dev1:print(psu_dev1:init("PROT:CLE"))
	psu_dev1:print(psu_dev1:init("OUTP:PONS RST")) 

	psu_dev1:print(psu_dev1:init("SOUR:FUNC CC"))          -- 配置环路优先模式  <CV|CC|VOLTage|CURRent>
	psu_dev1:print(psu_dev1:init("OFF:VOLT ZERO"))         --ZERO 是表示仪器电压快速降到 0V，当设置为 CONSt 时，电压下降速度为正常速度
	psu_dev1:print(psu_dev1:init("CURR:SLEW:POS 100")) --0.001 to 999.999

	psu_dev1:print(psu_dev1:init("OUTP:DEL 0")) 
	psu_dev1:print(psu_dev1:init("OUTP:DEL:FALL 0")) 


local PS_LIMIT_CURR=30.0
local PS_LIMIT_VOLT=20 --58.0
local PS_LIMIT_PWR =800.0

function chg_dsg(mode, curr, timeout, chg_volt, hi_res ) --测试时间小于500ms，电流测量是不准的，maybe 用 fech指令
	local ret = 0
	--- charge or discharge ---------
	if(mode == "discharge")then
		chg_volt = 4.0
	end
	if(chg_volt > PS_LIMIT_VOLT or chg_volt < 0) then
		return false
	elseif (chg_volt * curr > PS_LIMIT_PWR)then
		return false
	end
	psu_dev1:set_vi( chg_volt, curr, "all_cc")
	psu_dev1:out("on")
	Sleep(timeout)
	if (hi_res == "hi_res") then
		ret = psu_dev1:get_vi("all_slow")
	else
		ret = psu_dev1:get_vi("all")
	end
	psu_dev1:out("off")

	if(mode == "discharge")then
		SetUI("discharge",tostring(ret),tostring(true), (0),"pass",tostring(90),tostring(200))
	else
		SetUI("charge",tostring(ret),tostring(true), (0),"pass",tostring(90),tostring(200))
	end
	
	return ret
end


--------all cc 
function occp_ocdp(mode, curr_down_limit, curr_up_limit, timeout, chg_volt, curr_r, timeout_r, judge_curr_threshould)
	local ret = 0.0
	--- charge or discharge ---------
	if(chg_volt > PS_LIMIT_VOLT or chg_volt < 0) then -- over chg volt limit
		return false
	elseif (chg_volt * math.abs(curr_down_limit) > PS_LIMIT_PWR) then -- over power limit (curr_down_limit) 
		return false
	elseif (chg_volt * math.abs(curr_up_limit) > PS_LIMIT_PWR) then -- over power limit (curr_up_limit) 
		return false
	end

	if(mode == "discharge") then
		-- down limit
		psu_dev1:set_vi( 0.0, curr_down_limit, "all_cc")
		psu_dev1:out("on")
		Sleep(timeout)
		ret = psu_dev1:get_vi("i_slow")
		psu_dev1:out("off")

		LogPush("occp_ocdp, discharge, " .. tostring(0.0) .. ", " .. tostring(curr_down_limit) .. ", " .. tostring(ret))

		if(math.abs(ret) > math.abs(curr_down_limit) * 1.005 or math.abs(ret) < math.abs(curr_down_limit) * 0.995) then
			if(math.abs(ret) > math.abs(curr_down_limit) * 1.1 or math.abs(ret) < math.abs(curr_down_limit) * 0.9) then
				ShowMsg("error:down limit protect!")
			else
				ShowMsg("psu accuracy low ")
			end
			return false
		end
		-- up limit
		psu_dev1:set_vi( 0.0, curr_up_limit, "all_cc")
		psu_dev1:out("on")
		Sleep(timeout)
		ret = psu_dev1:get_vi("i_slow") -- ret = psu_dev1:get_vi("i")
		psu_dev1:out("off")
		-- ShowMsg("up limit after curr:" .. ret)
		LogPush("occp_ocdp, discharge, " .. tostring(0.0) .. ", " .. tostring(curr_up_limit) .. ", " .. tostring(ret))

		if(math.abs(ret) > math.abs(judge_curr_threshould)) then
			ShowMsg("occp_ocdp, protect FAIL")
			-- return false
		end

		psu_dev1:set_vi( chg_volt, curr_r, "all_cc")
		psu_dev1:out("on")
		Sleep(timeout_r)
		ret = psu_dev1:get_vi("i_slow")
		psu_dev1:out("off")

		if(tonumber(ret) > tonumber(curr_r) * 1.005 or tonumber(ret) < tonumber(curr_r) * 0.995) then
			if(tonumber(ret) > tonumber(curr_r) * 1.1 or tonumber(ret) < tonumber(curr_r) * 0.9) then
				ShowMsg("error: protect release fail!" .. "curr:" .. tostring(ret))
			else
				ShowMsg("[release]psu accuracy low ")
			end
			return false
		end
		if(mode == "discharge")then
			SetUI("discharge",tostring(ret),tostring(true), (0),"pass",tostring(90),tostring(200))
		else
			SetUI("charge",tostring(ret),tostring(true), (0),"pass",tostring(90),tostring(200))
		end
		return true


	elseif (mode == "charge") then
		-- down limit
		psu_dev1:set_vi( chg_volt, curr_down_limit, "all_cc")
		psu_dev1:out("on")
		Sleep(timeout)
		ret = psu_dev1:get_vi("i_slow")
		psu_dev1:out("off")

		LogPush("occp_ocdp, charge, " .. tostring(chg_volt) .. ", " .. tostring(curr_down_limit) .. ", " .. tostring(ret))

		if(math.abs(ret) > math.abs(curr_down_limit) * 1.005 or math.abs(ret) < math.abs(curr_down_limit) * 0.995) then
			if(math.abs(ret) > math.abs(curr_down_limit) * 1.1 or math.abs(ret) < math.abs(curr_down_limit) * 0.9) then
				ShowMsg("error:down limit protect!")
			else
				ShowMsg("psu accuracy low ")
			end
			return false
		end
		-- up limit
		psu_dev1:set_vi( chg_volt, curr_up_limit, "all_cc")
		psu_dev1:out("on")
		Sleep(timeout)
		ret = psu_dev1:get_vi("i_slow")
		psu_dev1:out("off")

		LogPush("occp_ocdp, charge, " .. tostring(chg_volt) .. ", " .. tostring(curr_up_limit) .. ", " .. tostring(ret))
		
		if(math.abs(ret) > math.abs(judge_curr_threshould)) then
			ShowMsg("occp_ocdp, protect FAIL")
			-- return false
		end

		if(curr_up_limit > 20.0) then -- issue_pic0006
			psu_dev1:print(psu_dev1:init("PROT:CLE"))
			Sleep(5000)
			psu_dev1:set_vi( 0.0, curr_r, "all_cc")
			psu_dev1:out("on")
			Sleep(timeout_r)
			ret = psu_dev1:get_vi("i_slow")
			psu_dev1:out("off")
		end

		if(tonumber(ret) < tonumber(curr_r) * 1.005 or tonumber(ret) > tonumber(curr_r) * 0.995) then
			if(tonumber(ret) < tonumber(curr_r) * 1.1 or tonumber(ret) > tonumber(curr_r) * 0.9) then
				ShowMsg("error: protect release fail! " .. "curr:" .. tostring(ret))
			else
				ShowMsg("[release]psu accuracy low ")
			end
			return false
		end
		if(mode == "discharge")then
			SetUI("discharge",tostring(ret),tostring(true), (0),"pass",tostring(90),tostring(200))
		else
			SetUI("charge",tostring(ret),tostring(true), (0),"pass",tostring(90),tostring(200))
		end
		return true

	else
		ShowMsg("mode set error:".. mode)
	end
end

for i=1,20 do
	chg_dsg("discharge", -1.0, 1000, 0, "hi_res")
	chg_dsg("charge", 1.0, 1000, 5.0, "hi_res")
	Sleep(100)
	occp_ocdp("discharge", -20.0, -21.5, 1000, 5.2, 1.0, 500, 0.5)
	Sleep(1000)
	occp_ocdp("charge", 20.0, 21.5, 1000, 5.5, -1.0, 500, 0.5)
	SetUI("loop " .. i, "",tostring(true), (0),"-------------",tostring(0),tostring(0))
end



SetLuaAllTestResult(true)


--backup--20210507----------------------------------------------------------------------------------------------

-- -- //https://blog.csdn.net/klm123698745/article/details/104129915  第四部分 继承


-- psu_dev_list = {
-- -------------------------------------------------------------------------------------------------
-- 	Captain = {
-- 		mode = "cvcc", quadrant = 2, endl_str = "\r\n",
-- 		set = {v = "",  i = ""},
-- 		get = {v = "",  i = ""},
-- 		out = {on = "", off = ""},
-- 		init = function(self, ... )
-- 			-- body
-- 		end,
-- 		reset = function(self, ... )
-- 			-- body
-- 		end,
-- 		curr_slope = function(self, rise, fall)
-- 			-- body
-- 		end,
-- 		set_para_check = function(self, ... )
-- 			-- body
-- 		end,
-- 		},
--  -------------------------------------------------------------------------------------------------
--  -- power supply unit with 2-quadrant const voltage & const current function
-- 	 IT_M3432 = {        
-- 		 mode = "cvcc",    quadrant = 2, endl_str = "\r\n",
-- 		 set = {v = "VOLT v",      i = "CURR i",     all = "VOLT v;CURR i"},
-- 		 get = {v = "FETC:VOLT?",  i = "FETC:CURR?", all = "FETC:VOLT?;FETC:CURR?"},
-- 		 out = {on = "OUTP ON",    off = "OUTP OFF"},
-- 		 init = function(self, str)
-- 		 	debug("init " .. str)
-- 		 	-- body
-- 		 end,
-- 		 reset = function(self, ... )
-- 		 	-- body
-- 		 end,
-- 		 curr_slope = function(self, rise, fall)
-- 		 	-- body
-- 		 end,
-- 		 set_para_check = function(self, ... )
-- 		 	-- body
-- 		 end,
-- 		 print_mode = function(self)
-- 		 	debug(self.mode)
-- 		 end
-- 		},
--  -------------------------------------------------------------------------------------------------
-- }


-- -- psu_dev_list.IT_M3432:init("hello world")
-- -- debug(psu_dev_list.IT_M3432.mode)
-- -- debug(psu_dev_list.IT_M3432.set.v)
-- -- debug(psu_dev_list.IT_M3432.out.on)

-- -- psu = {}
-- -- setmetatable(psu, {__index = psu_dev_list})

-- -- psu.IT_M3432:init("hello world")
-- -- debug(psu.IT_M3432.set.v)
-- debug(psu_dev_list.IT_M3432.mode)
-- debug(psu.IT_M3432.mode)
-- psu.IT_M3432.mode = "cc"
-- debug(psu_dev_list.IT_M3432.mode)
-- debug(psu.IT_M3432.mode)
-- -- psu_dev_list.IT_M3432:print_mode()
-- -- psu.IT_M3432:print_mode()


--backup--20210508----------------------------------------------------------------------------------------------

-- dev1_set = {v = "VOLT v",      i = "CURR i",     all = "VOLT v;CURR i"}
-- dev1_get = {v = "FETC:VOLT?",  i = "FETC:CURR?", all = "FETC:VOLT?;FETC:CURR?"}
-- dev1_out = {on = "OUTP ON",    off = "OUTP OFF"}
-- psu_dev1 = psu_dev:new("IT_Mxxxx", "cv", 1, "\r\n", dev1_set, dev1_get, dev1_out)
-- psu_dev1:init("test lua class")
-- psu_dev1:print_mode()
-- psu_dev1:print(psu_dev1.get.all)