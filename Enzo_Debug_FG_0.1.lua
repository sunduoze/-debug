_KeepRet 			= ""
DEV_USBCAN  		= "DEV_USBCAN"
DEV_USBCAN2 		= "DEV_USBCAN2"
SerialPortName 		= {}
Getindex()


gPacKBatterCode     = GetPackCode()		      --全局电池条码
gCellCode 		    = GetCellCode()			  --全局电芯条码/临时条码

local PortName 		= 1
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


function Gpib_Test()
	local addr 			= 2
	local isCard 		= false
	local order  		= "SYST:REM"
	local askVolt  		= "READ?" -- "MEAS:VOLT?"
	local ReadVolt 		= ""
	local ClearError    = "*CLS"
	local endl = ""--"\r\n"

	local x = {}
	Gpib_Init(addr,isCard)
								--初始化卡或者USB2GPIB
	Sleep(100)
	Gpib_SendStr(addr, "*CLS" .. endl)
	-- Sleep(100)
	-- Gpib_SendStr(addr, "SYST:REM" .. endl)	
	Sleep(100)	
	Gpib_SendStr(addr,":CONF:CURR;:SENS:CURR:DC:NPLC MIN;:SAMP:COUN 1" .. endl)
	-- Gpib_SendStr(addr,":CONF:CURR;:SENS:CURR:DC:NPLC MIN;:SAMP:COUN 1")
	Sleep(10)

	LogPush("current test start",true)
	for i=1,100 do
		Gpib_SendStr(addr,":READ?" .. endl)
		get_val = Gpib_RecvidStr(addr)--GPIB读取结果，传地址
		LogPush("current" .. tostring(i) .. ", " .. tostring(get_val))
		-- SetUI("current"..i,tostring(ReadVolt),tostring(true), (0),"pass",tostring(90),tostring(200))
	end
	LogPush("current test end",true)

	if ReadVolt ~= "" then
		ReadVolt = tonumber(ReadVolt)
	end
	-- Gpib_Close()											--关闭GPIB卡
end
Gpib_Test()




SetLuaAllTestResult(true)
	
