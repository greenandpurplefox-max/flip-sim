local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiStyleFix = {}

local function radiusFromSelector(selector: string): number?
	local fromClass = string.match(selector, "RoundedCorner(%d+)")
	if fromClass then
		return tonumber(fromClass)
	end
	return nil
end

local function fixTokenAttributes(instance: Instance)
	for attributeName, attributeValue in instance:GetAttributes() do
		if typeof(attributeValue) ~= "string" then
			continue
		end

		local numeric = string.match(attributeValue, "^%$?(%d+)$")
			or string.match(attributeName, "(%d+)")
		if not numeric then
			continue
		end

		if string.find(attributeName, "Rad", 1, true)
			or string.find(attributeName, "Corner", 1, true)
			or string.find(attributeName, "Radius", 1, true)
		then
			instance:SetAttribute(attributeName, UDim.new(0, tonumber(numeric)))
		end
	end
end

local function fixStyleRule(rule: StyleRule)
	local selector = rule.Selector
	if typeof(selector) ~= "string" or not string.find(selector, "UICorner", 1, true) then
		return
	end

	local radius = radiusFromSelector(selector)
	if radius then
		rule:SetProperty("CornerRadius", UDim.new(0, radius))
	end
end

local function fixStyleSheet(sheet: StyleSheet)
	fixTokenAttributes(sheet)

	for _, descendant in sheet:GetDescendants() do
		if descendant:IsA("StyleRule") then
			fixStyleRule(descendant)
		elseif descendant:IsA("StyleSheet") then
			fixTokenAttributes(descendant)
		end
	end
end

local function scanFolder(folder: Instance)
	for _, child in folder:GetChildren() do
		if child:IsA("StyleSheet") then
			fixStyleSheet(child)
		elseif child:IsA("Folder") then
			scanFolder(child)
		end
	end
end

function UiStyleFix.init()
	scanFolder(ReplicatedStorage)

	ReplicatedStorage.ChildAdded:Connect(function(child)
		if child:IsA("StyleSheet") then
			task.defer(fixStyleSheet, child)
		elseif child:IsA("Folder") and (child.Name == "Design" or child.Name == "Designs") then
			task.defer(function()
				scanFolder(child)
			end)
		end
	end)
end

return UiStyleFix
