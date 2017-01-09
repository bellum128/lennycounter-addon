LennyCounter = {}

LennyCounter.LENNY_DATA_FOLDER = "lennycounter"
LennyCounter.LENNY_COUNT_FILE = LennyCounter.LENNY_DATA_FOLDER .. "/lennycount.txt"
LennyCounter.OLD_DAY_FILE = LennyCounter.LENNY_DATA_FOLDER .. "/oldDay.txt"

LennyCounter.openings = { '(', '[', '{'}
LennyCounter.closings = { ')', ']', '}'}

LennyCounter.POST_URL = CreateConVar("lennycounter_post_url", "http://localhost/processlenny.php", {FCVAR_ARCHIVE}, "Full URL of processlenny.php file."):GetString()
cvars.AddChangeCallback("lennycounter_post_url", function()
	LennyCounter.POST_URL = GetConVarString("lennycounter_post_url")
	print("Setting post url convar")
	end)

function LennyCounter.GetDay()
	return os.date("%d" , os.time())
end

LennyCounter.oldDay = LennyCounter.GetDay()

function LennyCounter.Initialize()
	print("======================================================")
	print("LennyCounter by bellum128 Productions has started.")
	print("======================================================")

	file.CreateDir(LennyCounter.LENNY_DATA_FOLDER)

	timer.Create("CheckReset", 5, 0, LennyCounter.CheckReset)
end
hook.Add("Initialize","LennyInit", LennyCounter.Initialize)

function LennyCounter.PlayerSay(ply, text, team )

	local textLeftTrim = string.TrimLeft(text)
	local cmdText = string.sub(textLeftTrim, 1, 6)

	if(string.lower(cmdText) == "!lenny" && (textLeftTrim == cmdText)) then
		LennyCounter.NotifyLennyCount(HUD_PRINTTALK, ply)
		return ""
	end

	if(LennyCounter.IsLenny(text)) then
		local newCount = LennyCounter.GetLennyCount()

		newCount = newCount + 1

		if(math.mod(newCount, 100) == 0) then
			LennyCounter.NotifyLennyCount(HUD_PRINTCENTER)
		end

		LennyCounter.SaveLennyCount(newCount)
	end
end
hook.Add("PlayerSay", "LennyPlayerSay", LennyCounter.PlayerSay)

function LennyCounter.NotifyLennyCount(type, ply)
	timer.Simple(0.01, function()
		if(ply == nil) then
			PrintMessage(type, "Lenny Face has been used " .. tostring(LennyCounter.GetLennyCount()) .. " times today!")
		else
			ply:PrintMessage(type, "Lenny Face has been used " .. tostring(LennyCounter.GetLennyCount()) .. " times today!")
		end
	end)
end

function LennyCounter.GetLennyCount()
	local count

	if(file.Exists(LennyCounter.LENNY_COUNT_FILE, "DATA")) then
		count = tonumber(file.Read(LennyCounter.LENNY_COUNT_FILE))
	else
		count = 0
	end

	if(count == nil) then
		count = 0
	end

	return count
end

function LennyCounter.SaveLennyCount(count)
	file.Write(LennyCounter.LENNY_COUNT_FILE, tostring(count))
	http.Post(LennyCounter.POST_URL, {count = tostring(count)}, nil, function() print("LennyCounter - Message send to " .. LennyCounter.POST_URL .. " failed!") end)
end

concommand.Add("lennycounter_setcount", function(ply, cmd, args, argStr)
	local count = tonumber(argStr)
	if(count) then
		LennyCounter.SaveLennyCount(count)
		print("Lenny Count set to " .. argStr)
	else
		print("Invalid number entered " .. argStr)
	end
end)

function LennyCounter.CheckReset()
	if(file.Exists(LennyCounter.OLD_DAY_FILE, "DATA")) then
		if(LennyCounter.GetDay() != file.Read(LennyCounter.OLD_DAY_FILE)) then
			LennyCounter.ResetCount()
		end
	else
		LennyCounter.ResetCount()
	end

	file.Write(LennyCounter.OLD_DAY_FILE, LennyCounter.GetDay())
end

function LennyCounter.ResetCount()
		file.Write(LennyCounter.LENNY_COUNT_FILE, "0")
		http.Post(LennyCounter.POST_URL, {count = tostring(0)}, nil, function() print("LennyCounter - Message send failed!") end)
		LennyCounter.NotifyLennyCount(HUD_PRINTTALK)
		print("Resetting Lenny Count!")
end

function LennyCounter.IsLenny(text)
	local result = false

	for i = 1, #LennyCounter.openings do
		if(CheckLennyWithDeliminators(text, LennyCounter.openings[i], LennyCounter.closings[i])) then
			result = true
			break
		end
	end

	return result
end

function CheckLennyWithDeliminators(text, opening, closing)
	local result = false

	if(string.contains(text, opening)) then
		textAfterFirstDel = string.sub(text, string.find(text, opening, 1, true) + 1)
		if(string.contains(textAfterFirstDel, closing)) then
			if(string.len(textAfterFirstDel) < 20) then
				result = true
			end
		end
	else
		result = false
	end

	return result
end

function string.contains(haystack, needle)
	return string.find(haystack, needle, 1, true)
end
