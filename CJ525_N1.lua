if PLANE_ICAO == "C525" then
	if not SUPPORTS_FLOATING_WINDOWS then
		-- to make sure the script doesn't stop old FlyWithLua versions
		logMsg("imgui not supported by your FlyWithLua version")
		return
	end

-- initialise window settings
	n1calc_wnd = float_wnd_create(300, 160, 1, true)
	float_wnd_set_position(n1calc_wnd, 30, SCREEN_HIGHT-300)
	float_wnd_set_title(n1calc_wnd, "CJ525 Engine Perf. Calculator")
	float_wnd_set_imgui_builder(n1calc_wnd, "n1calc_on_build")
	float_wnd_set_onclose(n1calc_wnd, "closed_n1calc")
	
-- see if the file exists and open if it does
	function file_exists(filename)
	  local f = io.open(filename, "rb")
	  if f then f:close() end
	  return f ~= nil
	end

	function readCSVIntoIndexedArray(file)
--get file
	  if not file_exists(file) then return {} end
	  local array = {}
	  local rowIndexArray = {}
	  local columnIndexArray = {}
	  local linecount = 0
-- loop through lines in csv
	  for line in io.lines(file) do 

			local columnCount = 0		
			linecount = linecount + 1

-- loop though comma separated values in csv
	  	for value in line:gmatch("[^,]+") do
		   	columnCount = columnCount+1

-- if first line and NOT first column then include value in column index 
 				if linecount == 1 and columnCount > 1 then
					columnIndexArray[columnCount] = value
				else
					if columnCount == 1 then
-- if NOT line and first column then include value in row index and prepare sub-table for data values
						if linecount > 1 then
		   				rowIndex = value
			   			array[rowIndex]={}
							rowIndexArray[linecount]=rowIndex
						end
					else		   
-- if NOT line and NOT first column then this is a data value to be stored in data array referenced to row and column index values
		    		array[rowIndex][columnIndexArray[columnCount]]=value
			   	end
			  end
	  	end
	  end
-- pass out data array, row index array and column index array
	  return array,rowIndexArray,columnIndexArray
	end

	function GetValueFromIndexTable(index, min, max, val)
		returnVal = -99
		if val ~= nil then
-- check if vfal is outside the specified max and min			
			if val <= min then
				returnVal = min
			elseif val >= max then
				returnVal = max
			else
-- Loop through values in index
				for i,v in pairs(index) do
-- set returnVal to current value this ensures the last value in loop is returned if we complete loop without hitting either of the break conditions
					returnVal = v
-- if the value we are checking is positive then look for the first index value that is less than value we are checking and set returnval to value of the PREVIOUS element and stop looping
					if val >= 0 then
						if val < tonumber(v) then
							returnVal=index[i-1]
							break
						end
					else
-- if the value we are checking is negative  then look for the first index value that is less than value we are checking stop looping - we've already set the return value to the current index value
						if val <= tonumber(v) then
							break
						end
					end			
				end
			end
		end
		return returnVal
	end

-- function to correctly truncate decimal places from both positive and negative numbers
	function truncate (inputNum)
		return inputNum - math.fmod(inputNum,1)
	end
	
-- set directory for csv files using built-ins for FWL Script Location and OS Specific Directopry Separato r
	local dataDirectory = SCRIPT_DIRECTORY..DIRECTORY_SEPARATOR.."CJ5252_Data"..DIRECTORY_SEPARATOR

-- get data, row index and column index arrays for data csv files	
	local N1TOTable,N1TOAltIndex,N1TOTempIndex = readCSVIntoIndexedArray(dataDirectory.."N1TOTable.csv")
	local N1GATable,N1GAAltIndex,N1GATempIndex = readCSVIntoIndexedArray(dataDirectory.."N1GATable.csv")
	local N1ClimbTable,N1ClimbTempIndex,N1ClimbAltIndex = readCSVIntoIndexedArray(dataDirectory.."N1ClimbTable.csv")
	local N1CruiseTable,N1CruiseTempIndex,N1CruiseAltIndex = readCSVIntoIndexedArray(dataDirectory.."N1CruiseTable.csv")
-- we don't need either of the index tables for the Speed table so only store the data table
	local SpeedTable = readCSVIntoIndexedArray(dataDirectory.."SpeedTable.csv")

-- initialise variables used for Listbox and Checkboxes
	local mode = 1
	local antiIcingOn = false
	local setMem = true
	local setBug = true

-- get X-Plane datarefs
	dataref("PressureAlt_dr", "sim/flightmodel2/position/pressure_altitude")
	dataref("RealAirTemp_dr", "sim/weather/temperature_le_c")
--	local antiIcingTable_df = dataref_table("sim/cockpit/switches/anti_ice_inlet_heat_per_engine")

	dataref("mem_device_1_dr", "afm/cj/center_panel/mem_device_1", "writable")
	dataref("mem_device_2_dr", "afm/cj/center_panel/mem_device_2", "writable")
	dataref("mem_device_3_dr", "afm/cj/center_panel/mem_device_3", "writable")
	
	dataref("asi_bug_dr", "afm/cj/f/pilot_panel/asi_bug_knob", "writable")


	function n1calc_on_build(n1calc_wnd, x, y)  


	-- Code to set anti-icing automatically		
	--		if antiIcingTable_df[0]==1 or antiIcingTable_df[1]==1 then
	--			antiIcingOn = true
	--  	else
	--			antiIcingOn = false
	--  	end 

-- Create options for Mode combobox
		local modes = {"Take Off", "Climb", "Cruise","Go-Around"}
		local n1Value
		local tableAlt
		local tableTemp 

		imgui.TextUnformatted("Mode: ")
		imgui.SameLine()                                   


-- Display Mode combobox
		if imgui.BeginCombo("", modes[mode]) then
			for i = 1, #modes do
				if imgui.Selectable(modes[i], mode == i) then
					mode = i
				end
			end
			imgui.EndCombo()
		end


-- Display Anti-Icing checkbox
		changed, newVal = imgui.Checkbox(" Anti-Icing", antiIcingOn)
		if changed then
			antiIcingOn = newVal
		end
		
--		imgui.SameLine()
--		imgui.TextUnformatted("    ")
--		imgui.SameLine()
				
-- Display Memo Display checkbox
		changed, newVal = imgui.Checkbox(" Set Memo Display",setMem)
		if changed then
			setMem = newVal
		end

-- If in Climb mode display ASI Bug checkbox
		if mode == 2 then

			imgui.SameLine()
			imgui.TextUnformatted("  ")
			imgui.SameLine()

	-- Display ASI Bug checkbox
			changed, newVal = imgui.Checkbox(" Set ASI Bug",setBug)
			if changed then
				setBug = newVal
			end
		end


-- Look up index values for temp, alt from index tables and corresponding data value from arrays for that mode
-- Take-Off
		if mode == 1 then
			tableAlt 	= tostring(GetValueFromIndexTable(N1TOAltIndex, 0, 7, truncate(PressureAlt_dr/1000)))
			tableTemp 	= tostring(GetValueFromIndexTable(N1TOTempIndex, -25, 40, truncate(RealAirTemp_dr)))
			n1Value 		= N1TOTable[tableAlt][(antiIcingOn and tableTemp.."A" or tableTemp)]
-- Climb
		elseif mode == 2 then
			tableAlt 	= tostring(GetValueFromIndexTable(N1ClimbAltIndex, 0, 41, truncate(PressureAlt_dr/1000)))
			tableTemp 	= tostring(GetValueFromIndexTable(N1ClimbTempIndex, -45, 45, truncate(RealAirTemp_dr)))
			n1Value = N1ClimbTable[tableTemp][(antiIcingOn and tableAlt.."A" or tableAlt)]
--Cruise
		elseif mode == 3 then
			tableAlt 	= tostring(GetValueFromIndexTable(N1CruiseAltIndex, 0, 41, truncate(PressureAlt_dr/1000)))
			tableTemp 	= tostring(GetValueFromIndexTable(N1CruiseTempIndex, -45, 45, truncate(RealAirTemp_dr)))
			n1Value = N1CruiseTable[tableTemp][(antiIcingOn and tableAlt.."A" or tableAlt)]
-- Go-Around
		else
			tableAlt 	= tostring(GetValueFromIndexTable(N1GAAltIndex, 0, 7, truncate(PressureAlt_dr/1000)))
			tableTemp 	= tostring(GetValueFromIndexTable(N1GATempIndex, -25, 40, truncate(RealAirTemp_dr)))
			n1Value 		= N1TOTable[tableAlt][(antiIcingOn and tableTemp.."A" or tableTemp)]
		end
	
-- Display results calculated about - set N1 Value text to red if Anti-Ice is on
		imgui.TextUnformatted(string.format("Settings for %sC %sft\n\n", tableTemp, (tableAlt)*1000))
		imgui.TextUnformatted("Maximum N1:")
		if antiIcingOn then
			imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF0000FF)
		end
		imgui.SameLine()
		imgui.TextUnformatted(n1Value)
		if antiIcingOn then
			imgui.PopStyleColor()
		end

-- Add check that there is a valid N1 value
		if setMem and n1Value~="-" then

-- If N1 value is an integer the add ".0" to the end
			if not string.find(n1Value, ".") then
				n1Value = n1Value .. ".0"
			end
			
			mem_device_1_dr = math.abs(string.sub(n1Value,-4,-4)-9)
			mem_device_2_dr = math.abs(string.sub(n1Value,-3,-3)-9)
			mem_device_3_dr = math.abs(string.sub(n1Value,-1,-1)-9)
		end

-- If in Climb mode display Climb speed
		if mode == 2 then
-- Display Cruise Climb checkbox (Climb type is MAX if this is unset)			
			imgui.TextUnformatted(string.format("Climb Speed: %s   ",climbSpeed))
			imgui.SameLine()
			changed, newVal = imgui.Checkbox("Cruise Climb", cruiseClimb)
			if changed then
				cruiseClimb = newVal
			end
	
			if cruiseClimb then
				climbType="CRUISE"
			else
				climbType="MAX"
			end
-- Look up climb speed from data table. We've set the row index value according to the Cruise Climb checkbox value and we have the column index value from the temp value calculated earlier so we can go directly to the data table
			tableAlt 	= tostring(GetValueFromIndexTable(N1ClimbAltIndex, 0, 40, PressureAlt_dr/1000))
			climbSpeed = SpeedTable[climbType][tableAlt]
			
			if setBug and tonumber(climbSpeed) then
				asi_bug_dr = tonumber(climbSpeed)
			end
		end
	
	end

	function closed_n1calc(wnd)
		ocal_ = wnd
	end
end