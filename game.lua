-- modded version of pepsi club by pander.lua
local LoadingTime = tick();
print("loaing time")
------------------------------------ LIBRARY CODEE ------------------------------------
local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local CoreGui = game:GetService('CoreGui');
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);
print("protec guikl")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.Parent = CoreGui;

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

local Library = {
    Registry = {};
    RegistryMap = {};

    HudRegistry = {};

    FontColor = Color3.fromRGB(255, 255, 255);
    MainColor = Color3.fromRGB(28, 28, 28);
    BackgroundColor = Color3.fromRGB(20, 20, 20);
    AccentColor = Color3.fromRGB(0, 85, 255);
    OutlineColor = Color3.fromRGB(50, 50, 50);
    RiskColor = Color3.fromRGB(255, 50, 50),

    Black = Color3.new(0, 0, 0);
    Font = Enum.Font.Code,

    OpenedFrames = {};
    DependencyBoxes = {};

    Signals = {};
    ScreenGui = ScreenGui;
};

local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta

    if RainbowStep >= (1 / 60) then
        RainbowStep = 0

        Hue = Hue + (1 / 400);

        if Hue > 1 then
            Hue = 0;
        end;

        Library.CurrentRainbowHue = Hue;
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers();

    for i = 1, #PlayerList do
        PlayerList[i] = PlayerList[i].Name;
    end;

    table.sort(PlayerList, function(str1, str2) return str1 < str2 end);

    return PlayerList;
end;

local function GetTeamsString()
    local TeamList = Teams:GetTeams();

    for i = 1, #TeamList do
        TeamList[i] = TeamList[i].Name;
    end;

    table.sort(TeamList, function(str1, str2) return str1 < str2 end);
    
    return TeamList;
end;

function Library:SafeCallback(f, ...)
    if (not f) then
        return;
    end;

    if not Library.NotifyOnError then
        return f(...);
    end;

    local success, event = pcall(f, ...);

    if not success then
        local _, i = event:find(":%d+: ");

        if not i then
            return Library:Notify(event);
        end;

        return Library:Notify(event:sub(i + 1), 3);
    end;
end;

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save();
    end;
end;

function Library:Create(Class, Properties)
    local _Instance = Class;

    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;

    for Property, Value in next, Properties do
        _Instance[Property] = Value;
    end;

    return _Instance;
end;

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1;

    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0);
        Thickness = 1;
        LineJoinMode = Enum.LineJoinMode.Miter;
        Parent = Inst;
    });
end;

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Library.FontColor;
        TextSize = 16;
        TextStrokeTransparency = 0;
    });

    Library:ApplyTextStroke(_Instance);

    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor';
    }, IsHud);

    return Library:Create(_Instance, Properties);
end;

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true;

    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ObjPos = Vector2.new(
                Mouse.X - Instance.AbsolutePosition.X,
                Mouse.Y - Instance.AbsolutePosition.Y
            );

            if ObjPos.Y > (Cutoff or 40) then
                return;
            end;

            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                Instance.Position = UDim2.new(
                    0,
                    Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
                    0,
                    Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
                );

                RenderStepped:Wait();
            end;
        end;
    end)
end;

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 14);
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,

        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,

        Visible = false,
    })

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y);
        TextSize = 14;
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Tooltip.ZIndex + 1,

        Parent = Tooltip;
    });

    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    Library:AddToRegistry(Label, {
        TextColor3 = 'FontColor',
    });

    local IsHovering = false

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            return
        end

        IsHovering = true

        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true

        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)

    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)
end;

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

            return true;
        end;
    end;
end;

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

    if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

        return true;
    end;
end;

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update();
    end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end;

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 1.5);
end;
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1;
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    };

    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;

    if IsHud then
        table.insert(Library.HudRegistry, Data);
    end;
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];

    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx);
            end;
        end;

        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx);
            end;
        end;

        Library.RegistryMap[Instance] = nil;
    end;
end;

function Library:UpdateColorsUsingRegistry()
    -- TODO: Could have an 'active' list of objects
    -- where the active list only contains Visible objects.

    -- IMPL: Could setup .Changed events on the AddToRegistry function
    -- that listens for the 'Visible' propert being changed.
    -- Visible: true => Add to active list, and call UpdateColors function
    -- Visible: false => Remove from active list.

    -- The above would be especially efficient for a rainbow menu color or live color-changing.

    for Idx, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx) == 'string' then
                Object.Instance[Property] = Library[ColorIdx];
            elseif type(ColorIdx) == 'function' then
                Object.Instance[Property] = ColorIdx()
            end
        end;
    end;
end;

function Library:GiveSignal(Signal)
    -- Only used for signals not attached to library instances, as those should be cleaned up on object destruction by Roblox
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    -- Unload all of the signals
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        Connection:Disconnect()
    end

     -- Call our unload callback, maybe to undo some hooks etc
    if Library.OnUnload then
        Library.OnUnload()
    end

    ScreenGui:Destroy()
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance);
    end;
end))

local BaseAddons = {};

do
    local Funcs = {};

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;
        -- local Container = self.Container;

        assert(Info.Default, 'AddColorPicker: Missing default value.');

        local ColorPicker = {
            Value = Info.Default;
            Transparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end;
        };

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);

            ColorPicker.Hue = H;
            ColorPicker.Sat = S;
            ColorPicker.Vib = V;
        end;

        ColorPicker:SetHSVFromRGB(ColorPicker.Value);

        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(0, 28, 0, 14);
            ZIndex = 6;
            Parent = ToggleLabel;
        });

        -- Transparency image taken from https://github.com/matas3535/SplixPrivateDrawingLibrary/blob/main/Library.lua cus i'm lazy
        local CheckerFrame = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(0, 27, 0, 13);
            ZIndex = 5;
            Image = 'http://www.roblox.com/asset/?id=12977615774';
            Visible = not not Info.Transparency;
            Parent = DisplayFrame;
        });

        -- 1/16/23
        -- Rewrote this to be placed inside the Library ScreenGui
        -- There was some issue which caused RelativeOffset to be way off
        -- Thus the color picker would never show

        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
            Visible = false;
            ZIndex = 15;
            Parent = ScreenGui,
        });

        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18);
        end)

        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        });

        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 25);
            Size = UDim2.new(0, 200, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibMapOuter;
        });

        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapInner;
        });

        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = SatVibMap;
        });

        local CursorInner = Library:Create('ImageLabel', {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
            Position = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ZIndex = 20;
            Parent = CursorOuter;
        })

        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 208, 0, 25);
            Size = UDim2.new(0, 15, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorOuter;
        });

        local HueCursor = Library:Create('Frame', { 
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0, 0.5);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, 0, 0, 1);
            ZIndex = 18;
            Parent = HueSelectorInner;
        });

        local HueBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner;
        });

        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18,
            Parent = HueBoxOuter;
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = HueBoxInner;
        });

        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = 'Hex color',
            Text = '#FFFFFF',
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 20,
            Parent = HueBoxInner;
        });

        Library:ApplyTextStroke(HueBox);

        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner
        });

        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox'), {
            Text = '255, 255, 255',
            PlaceholderText = 'RGB color',
            TextColor3 = Library.FontColor
        });

        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor;
        
        if Info.Transparency then 
            TransparencyBoxOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.fromOffset(4, 251);
                Size = UDim2.new(1, -8, 0, 15);
                ZIndex = 19;
                Parent = PickerFrameInner;
            });

            TransparencyBoxInner = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 19;
                Parent = TransparencyBoxOuter;
            });

            Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' });

            Library:Create('ImageLabel', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Image = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex = 20;
                Parent = TransparencyBoxInner;
            });

            TransparencyCursor = Library:Create('Frame', { 
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint = Vector2.new(0.5, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(0, 1, 1, 0);
                ZIndex = 21;
                Parent = TransparencyBoxInner;
            });
        end;

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14);
            Position = UDim2.fromOffset(5, 5);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = 14;
            Text = ColorPicker.Title,--Info.Default;
            TextWrapped = false;
            ZIndex = 16;
            Parent = PickerFrameInner;
        });


        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create('Frame', {
                BorderColor3 = Color3.new(),
                ZIndex = 14,

                Visible = false,
                Parent = ScreenGui
            })

            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.fromScale(1, 1);
                ZIndex = 15;
                Parent = ContextMenu.Container;
            });

            Library:Create('UIListLayout', {
                Name = 'Layout',
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = ContextMenu.Inner;
            });

            Library:Create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            });

            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end

            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end

                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end

            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)

            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)

            Library:AddToRegistry(ContextMenu.Inner, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            function ContextMenu:Show()
                self.Container.Visible = true
            end

            function ContextMenu:Hide()
                self.Container.Visible = false
            end

            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then
                    Callback = function() end
                end

                local Button = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, 0, 0, 15);
                    TextSize = 13;
                    Text = Str;
                    ZIndex = 16;
                    Parent = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left,
                });

                Library:OnHighlight(Button, Button, 
                    { TextColor3 = 'AccentColor' },
                    { TextColor3 = 'FontColor' }
                );

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                        return
                    end

                    Callback()
                end)
            end

            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Copied color!', 2)
            end)

            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then
                    return Library:Notify('You have not copied a color!', 2)
                end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)


            ContextMenu:AddOption('Copy HEX', function()
                pcall(setclipboard, ColorPicker.Value:ToHex())
                Library:Notify('Copied hex code to clipboard!', 2)
            end)

            ContextMenu:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', '))
                Library:Notify('Copied RGB values to clipboard!', 2)
            end)

        end

        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor'; });
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });

        Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBox, { TextColor3 = 'FontColor', });
        Library:AddToRegistry(HueBox, { TextColor3 = 'FontColor', });

        local SequenceTable = {};

        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)));
        end;

        local HueSelectorGradient = Library:Create('UIGradient', {
            Color = ColorSequence.new(SequenceTable);
            Rotation = 90;
            Parent = HueSelectorInner;
        });

        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end

            ColorPicker:Display()
        end)

        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r and g and b then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end

            ColorPicker:Display()
        end)

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);

            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value;
                BackgroundTransparency = ColorPicker.Transparency;
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            });

            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value;
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0);
            end;

            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0);
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0);

            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value);
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value);
        end;

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func;
            Func(ColorPicker.Value)
        end;

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false;
                    Library.OpenedFrames[Frame] = nil;
                end;
            end;

            PickerFrameOuter.Visible = true;
            Library.OpenedFrames[PickerFrameOuter] = true;
        end;

        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false;
            Library.OpenedFrames[PickerFrameOuter] = nil;
        end;

        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3]);

            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinX = SatVibMap.AbsolutePosition.X;
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X;
                    local MouseX = math.clamp(Mouse.X, MinX, MaxX);

                    local MinY = SatVibMap.AbsolutePosition.Y;
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y;
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY);

                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX);
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinY = HueSelectorInner.AbsolutePosition.Y;
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y;
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY);

                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        DisplayFrame.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide()
                else
                    ContextMenu:Hide()
                    ColorPicker:Show()
                end;
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show()
                ColorPicker:Hide()
            end
        end);

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        local MinX = TransparencyBoxInner.AbsolutePosition.X;
                        local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X;
                        local MouseX = math.clamp(Mouse.X, MinX, MaxX);

                        ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX));

                        ColorPicker:Display();

                        RenderStepped:Wait();
                    end;

                    Library:AttemptSave();
                end;
            end);
        end;

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    ColorPicker:Hide();
                end;

                if not Library:IsMouseOverFrame(ContextMenu.Container) then
                    ContextMenu:Hide()
                end
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))

        ColorPicker:Display();
        ColorPicker.DisplayFrame = DisplayFrame

        Options[Idx] = ColorPicker;

        return self;
    end;

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self;
        local ToggleLabel = self.TextLabel;
        local Container = self.Container;

        assert(Info.Default, 'AddKeyPicker: Missing default value.');

        local KeyPicker = {
            Value = Info.Default;
            Toggled = false;
            Mode = Info.Mode or 'Toggle'; -- Always, Toggle, Hold
            Type = 'KeyPicker';
            Callback = Info.Callback or function(Value) end;
            ChangedCallback = Info.ChangedCallback or function(New) end;

            SyncToggleState = Info.SyncToggleState or false;
        };

        if KeyPicker.SyncToggleState then
            Info.Modes = { 'Toggle' }
            Info.Mode = 'Toggle'
        end

        local PickOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = 6;
            Parent = ToggleLabel;
        });

        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 7;
            Parent = PickOuter;
        });

        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 13;
            Text = Info.Default;
            TextWrapped = true;
            ZIndex = 8;
            Parent = PickInner;
        });

        local ModeSelectOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
            Size = UDim2.new(0, 60, 0, 45 + 2);
            Visible = false;
            ZIndex = 14;
            Parent = ScreenGui;
        });

        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
        end);

        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 15;
            Parent = ModeSelectOuter;
        });

        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ModeSelectInner;
        });

        local ContainerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left;
            Size = UDim2.new(1, 0, 0, 18);
            TextSize = 13;
            Visible = false;
            ZIndex = 110;
            Parent = Library.KeybindContainer;
        },  true);

        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' };
        local ModeButtons = {};

        for Idx, Mode in next, Modes do
            local ModeButton = {};

            local Label = Library:CreateLabel({
                Active = false;
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = 13;
                Text = Mode;
                ZIndex = 16;
                Parent = ModeSelectInner;
            });

            function ModeButton:Select()
                for _, Button in next, ModeButtons do
                    Button:Deselect();
                end;

                KeyPicker.Mode = Mode;

                Label.TextColor3 = Library.AccentColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor';

                ModeSelectOuter.Visible = false;
            end;

            function ModeButton:Deselect()
                KeyPicker.Mode = nil;

                Label.TextColor3 = Library.FontColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor';
            end;

            Label.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    ModeButton:Select();
                    Library:AttemptSave();
                end;
            end);

            if Mode == KeyPicker.Mode then
                ModeButton:Select();
            end;

            ModeButtons[Mode] = ModeButton;
        end;

        function KeyPicker:Update()
            if Info.NoUI then
                return;
            end;

            local State = KeyPicker:GetState();

            ContainerLabel.Text = string.format('[%s] %s (%s)', KeyPicker.Value, Info.Text, KeyPicker.Mode);

            ContainerLabel.Visible = true;
            ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor;

            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor';

            local YSize = 0
            local XSize = 0

            for _, Label in next, Library.KeybindContainer:GetChildren() do
                if Label:IsA('TextLabel') and Label.Visible then
                    YSize = YSize + 18;
                    if (Label.TextBounds.X > XSize) then
                        XSize = Label.TextBounds.X
                    end
                end;
            end;

            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10, 210), 0, YSize + 23)
        end;

        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then
                return true;
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' then
                    return false;
                end

                local Key = KeyPicker.Value;

                if Key == 'MB1' or Key == 'MB2' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2);
                else
                    return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value]);
                end;
            else
                return KeyPicker.Toggled;
            end;
        end;

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2];
            DisplayLabel.Text = Key;
            KeyPicker.Value = Key;
            ModeButtons[Mode]:Select();
            KeyPicker:Update();
        end;

        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end

        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback
            Callback(KeyPicker.Value)
        end

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        function KeyPicker:DoClick()
            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
        end

        local Picking = false;

        PickOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Picking = true;

                DisplayLabel.Text = '';

                local Break;
                local Text = '';

                task.spawn(function()
                    while (not Break) do
                        if Text == '...' then
                            Text = '';
                        end;

                        Text = Text .. '.';
                        DisplayLabel.Text = Text;

                        wait(0.4);
                    end;
                end);

                wait(0.2);

                local Event;
                Event = InputService.InputBegan:Connect(function(Input)
                    local Key;

                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode.Name;
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Key = 'MB1';
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Key = 'MB2';
                    end;

                    Break = true;
                    Picking = false;

                    DisplayLabel.Text = Key;
                    KeyPicker.Value = Key;

                    Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
                    Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType)

                    Library:AttemptSave();

                    Event:Disconnect();
                end);
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ModeSelectOuter.Visible = true;
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (not Picking) then
                if KeyPicker.Mode == 'Toggle' then
                    local Key = KeyPicker.Value;

                    if Key == 'MB1' or Key == 'MB2' then
                        if Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1
                        or Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2 then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end;
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            KeyPicker.Toggled = not KeyPicker.Toggled;
                            KeyPicker:DoClick()
                        end;
                    end;
                end;

                KeyPicker:Update();
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    ModeSelectOuter.Visible = false;
                end;
            end;
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if (not Picking) then
                KeyPicker:Update();
            end;
        end))

        KeyPicker:Update();

        Options[Idx] = KeyPicker;

        return self;
    end;

    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

local BaseGroupbox = {};

do
    local Funcs = {};

    function Funcs:AddBlank(Size)
        local Groupbox = self;
        local Container = Groupbox.Container;

        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            ZIndex = 1;
            Parent = Container;
        });
    end;

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {};

        local Groupbox = self;
        local Container = Groupbox.Container;

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15);
            TextSize = 14;
            Text = Text;
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            });
        end

        Label.TextLabel = TextLabel;
        Label.Container = Container;

        function Label:SetText(Text)
            TextLabel.Text = Text

            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end

            Groupbox:Resize();
        end

        if (not DoesWrap) then
            setmetatable(Label, BaseAddons);
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Label;
    end;

    function Funcs:AddButton(...)
        -- TODO: Eventually redo this
        local Button = {};
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end

            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.');
        end

        ProcessButtonParams('Button', Button, ...)

        local Groupbox = self;
        local Container = Groupbox.Container;

        local function CreateBaseButton(Button)
            local Outer = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -4, 0, 20);
                ZIndex = 5;
            });

            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = Outer;
            });

            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = 14;
                Text = Button.Text;
                ZIndex = 6;
                Parent = Inner;
            });

            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
                });
                Rotation = 90;
                Parent = Inner;
            });

            Library:AddToRegistry(Outer, {
                BorderColor3 = 'Black';
            });

            Library:AddToRegistry(Inner, {
                BackgroundColor3 = 'MainColor';
                BorderColor3 = 'OutlineColor';
            });

            Library:OnHighlight(Outer, Outer,
                { BorderColor3 = 'AccentColor' },
                { BorderColor3 = 'Black' }
            );

            return Outer, Inner, Label
        end

        local function InitEvents(Button)
            local function WaitForEvent(event, timeout, validator)
                local bindable = Instance.new('BindableEvent')
                local connection = event:Once(function(...)

                    if type(validator) == 'function' and validator(...) then
                        bindable:Fire(true)
                    else
                        bindable:Fire(false)
                    end
                end)
                task.delay(timeout, function()
                    connection:disconnect()
                    bindable:Fire(false)
                end)
                return bindable.Event:Wait()
            end

            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame() then
                    return false
                end

                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                    return false
                end

                return true
            end

            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) then return end
                if Button.Locked then return end

                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'AccentColor' })

                    Button.Label.TextColor3 = Library.AccentColor
                    Button.Label.Text = 'Are you sure?'
                    Button.Locked = true

                    local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)

                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' })

                    Button.Label.TextColor3 = Library.FontColor
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, 'Locked', false)

                    if clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    return
                end

                Library:SafeCallback(Button.Func);
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container

        InitEvents(Button)

        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then
                Library:AddToolTip(tooltip, self.Outer)
            end
            return self
        end


        function Button:AddButton(...)
            local SubButton = {}

            ProcessButtonParams('SubButton', SubButton, ...)

            self.Outer.Size = UDim2.new(0.5, -2, 0, 20)

            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)

            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
            SubButton.Outer.Parent = self.Outer

            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == 'string' then
                    Library:AddToolTip(tooltip, self.Outer)
                end
                return SubButton
            end

            if type(SubButton.Tooltip) == 'string' then
                SubButton:AddTooltip(SubButton.Tooltip)
            end

            InitEvents(SubButton)
            return SubButton
        end

        if type(Button.Tooltip) == 'string' then
            Button:AddTooltip(Button.Tooltip)
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Button;
    end;

    function Funcs:AddDivider()
        local Groupbox = self;
        local Container = self.Container

        local Divider = {
            Type = 'Divider',
        }

        Groupbox:AddBlank(2);
        local DividerOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 5);
            ZIndex = 5;
            Parent = Container;
        });

        local DividerInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DividerOuter;
        });

        Library:AddToRegistry(DividerOuter, {
            BorderColor3 = 'Black';
        });

        Library:AddToRegistry(DividerInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Groupbox:AddBlank(9);
        Groupbox:Resize();
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Textbox = {
            Value = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type = 'Input';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        Groupbox:AddBlank(1);

        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });

        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = TextBoxOuter;
        });

        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, TextBoxOuter)
        end

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = TextBoxInner;
        });

        local Container = Library:Create('Frame', {
            BackgroundTransparency = 1;
            ClipsDescendants = true;

            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);

            ZIndex = 7;
            Parent = TextBoxInner;
        })

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;

            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),

            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = Info.Placeholder or '';

            Text = Info.Default or '';
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;

            ZIndex = 7;
            Parent = Container;
        });

        Library:ApplyTextStroke(Box);

        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength);
            end;

            if Textbox.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then
                    Text = Textbox.Value
                end
            end

            Textbox.Value = Text;
            Box.Text = Text;

            Library:SafeCallback(Textbox.Callback, Textbox.Value);
            Library:SafeCallback(Textbox.Changed, Textbox.Value);
        end;

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end

                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end);
        end

        -- https://devforum.roblox.com/t/how-to-make-textboxes-follow-current-cursor-position/1368429/6
        -- thank you nicemike40 :)

        local function Update()
            local PADDING = 2
            local reveal = Container.AbsoluteSize.X

            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                -- we aren't focused, or we fit so be normal
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                -- we are focused and don't fit, so adjust position
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    -- calculate pixel width of text from start to cursor
                    local subtext = string.sub(Box.Text, 1, cursor-1)
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X

                    -- check if we're inside the box with the cursor
                    local currentCursorPos = Box.Position.X.Offset + width

                    -- adjust if necessary
                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING-width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
                    end
                end
            end
        end

        task.spawn(Update)

        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)

        Library:AddToRegistry(Box, {
            TextColor3 = 'FontColor';
        });

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func;
            Func(Textbox.Value);
        end;

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        Options[Idx] = Textbox;

        return Textbox;
    end;

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';

            Callback = Info.Callback or function(Value) end;
            Addons = {},
            Risky = Info.Risky,
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = 'Black';
        });

        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter;
        });

        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0);
            Position = UDim2.new(1, 6, 0, 0);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleInner;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        });

        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 170, 1, 0);
            ZIndex = 8;
            Parent = ToggleOuter;
        });

        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        function Toggle:UpdateColors()
            Toggle:Display();
        end;

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, ToggleRegion)
        end

        function Toggle:Display()
            ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor;
            ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;

            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor';
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';
        end;

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func;
            Func(Toggle.Value);
        end;

        function Toggle:SetValue(Bool)
            Bool = (not not Bool);

            Toggle.Value = Bool;
            Toggle:Display();

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed, Toggle.Value);
            Library:UpdateDependencyBoxes();
        end;

        ToggleRegion.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Toggle:SetValue(not Toggle.Value) -- Why was it not like this from the start?
                Library:AttemptSave();
            end;
        end);

        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
        end

        Toggle:Display();
        Groupbox:AddBlank(Info.BlankSize or 5 + 2);
        Groupbox:Resize();

        Toggle.TextLabel = ToggleLabel;
        Toggle.Container = Container;
        setmetatable(Toggle, BaseAddons);

        Toggles[Idx] = Toggle;

        Library:UpdateDependencyBoxes();

        return Toggle;
    end;

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default, 'AddSlider: Missing default value.');
        assert(Info.Text, 'AddSlider: Missing slider text.');
        assert(Info.Min, 'AddSlider: Missing minimum value.');
        assert(Info.Max, 'AddSlider: Missing maximum value.');
        assert(Info.Rounding, 'AddSlider: Missing rounding value.');

        local Slider = {
            Value = Info.Default;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            MaxSize = 232;
            Type = 'Slider';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });

            Groupbox:AddBlank(3);
        end

        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(SliderOuter, {
            BorderColor3 = 'Black';
        });

        local SliderInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = SliderOuter;
        });

        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderColor3 = Library.AccentColorDark;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderInner;
        });

        Library:AddToRegistry(Fill, {
            BackgroundColor3 = 'AccentColor';
            BorderColor3 = 'AccentColorDark';
        });

        local HideBorderRight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, 1, 1, 0);
            ZIndex = 8;
            Parent = Fill;
        });

        Library:AddToRegistry(HideBorderRight, {
            BackgroundColor3 = 'AccentColor';
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 14;
            Text = 'Infinite';
            ZIndex = 9;
            Parent = SliderInner;
        });

        Library:OnHighlight(SliderOuter, SliderOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, SliderOuter)
        end

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor;
            Fill.BorderColor3 = Library.AccentColorDark;
        end;

        function Slider:Display()
            local Suffix = Info.Suffix or '';

            if Info.Compact then
                DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix
            elseif Info.HideMax then
                DisplayLabel.Text = string.format('%s', Slider.Value .. Suffix)
            else
                DisplayLabel.Text = string.format('%s/%s', Slider.Value .. Suffix, Slider.Max .. Suffix);
            end

            local X = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize));
            Fill.Size = UDim2.new(0, X, 1, 0);

            HideBorderRight.Visible = not (X == Slider.MaxSize or X == 0);
        end;

        function Slider:OnChanged(Func)
            Slider.Changed = Func;
            Func(Slider.Value);
        end;

        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value);
            end;


            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
        end;

        function Slider:GetValueFromXOffset(X)
            return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max));
        end;

        function Slider:SetValue(Str)
            local Num = tonumber(Str);

            if (not Num) then
                return;
            end;

            Num = math.clamp(Num, Slider.Min, Slider.Max);

            Slider.Value = Num;
            Slider:Display();

            Library:SafeCallback(Slider.Callback, Slider.Value);
            Library:SafeCallback(Slider.Changed, Slider.Value);
        end;

        SliderInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                local mPos = Mouse.X;
                local gPos = Fill.Size.X.Offset;
                local Diff = mPos - (Fill.AbsolutePosition.X + gPos);

                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local nMPos = Mouse.X;
                    local nX = math.clamp(gPos + (nMPos - mPos) + Diff, 0, Slider.MaxSize);

                    local nValue = Slider:GetValueFromXOffset(nX);
                    local OldValue = Slider.Value;
                    Slider.Value = nValue;

                    Slider:Display();

                    if nValue ~= OldValue then
                        Library:SafeCallback(Slider.Callback, Slider.Value);
                        Library:SafeCallback(Slider.Changed, Slider.Value);
                    end;

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        Slider:Display();
        Groupbox:AddBlank(Info.BlankSize or 6);
        Groupbox:Resize();

        Options[Idx] = Slider;

        return Slider;
    end;

    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then
            Info.Values = GetPlayersString();
            Info.AllowNull = true;
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString();
            Info.AllowNull = true;
        end;

        assert(Info.Values, 'AddDropdown: Missing dropdown value list.');
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')

        if (not Info.Text) then
            Info.Compact = true;
        end;

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            Multi = Info.Multi;
            Type = 'Dropdown';
            SpecialType = Info.SpecialType; -- can be either 'Player' or 'Team'
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local RelativeOffset = 0;

        if not Info.Compact then
            local DropdownLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });

            Groupbox:AddBlank(3);
        end

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
            end;
        end;

        local DropdownOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = 'Black';
        });

        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter;
        });

        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = DropdownInner;
        });

        local DropdownArrow = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = 'http://www.roblox.com/asset/?id=6282522798';
            ZIndex = 8;
            Parent = DropdownInner;
        });

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            TextSize = 14;
            Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true;
            ZIndex = 7;
            Parent = DropdownInner;
        });

        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, DropdownOuter)
        end

        local MAX_DROPDOWN_ITEMS = 8;

        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            ZIndex = 20;
            Visible = false;
            Parent = ScreenGui;
        });

        local function RecalculateListPosition()
            ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 1);
        end;

        local function RecalculateListSize(YSize)
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, YSize or (MAX_DROPDOWN_ITEMS * 20 + 2))
        end;

        RecalculateListPosition();
        RecalculateListSize();

        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition);

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        });

        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListInner;

            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        });

        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = 'AccentColor'
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        });

        function Dropdown:Display()
            local Values = Dropdown.Values;
            local Str = '';

            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. Value .. ', ';
                    end;
                end;

                Str = Str:sub(1, #Str - 2);
            else
                Str = Dropdown.Value or '';
            end;

            ItemList.Text = (Str == '' and '--' or Str);
        end;

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {};

                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value);
                end;

                return T;
            else
                return Dropdown.Value and 1 or 0;
            end;
        end;

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values;
            local Buttons = {};

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then
                    Element:Destroy();
                end;
            end;

            local Count = 0;

            for Idx, Value in next, Values do
                local Table = {};

                Count = Count + 1;

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    Size = UDim2.new(1, -1, 0, 20);
                    ZIndex = 23;
                    Active = true,
                    Parent = Scrolling;
                });

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                    BorderColor3 = 'OutlineColor';
                });

                local ButtonLabel = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = 14;
                    Text = Value;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 25;
                    Parent = Button;
                });

                Library:OnHighlight(Button, Button,
                    { BorderColor3 = 'AccentColor', ZIndex = 24 },
                    { BorderColor3 = 'OutlineColor', ZIndex = 23 }
                );

                local Selected;

                if Info.Multi then
                    Selected = Dropdown.Value[Value];
                else
                    Selected = Dropdown.Value == Value;
                end;

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value];
                    else
                        Selected = Dropdown.Value == Value;
                    end;

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
                end;

                ButtonLabel.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local Try = not Selected;

                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value[Value] = true;
                                else
                                    Dropdown.Value[Value] = nil;
                                end;
                            else
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value = Value;
                                else
                                    Dropdown.Value = nil;
                                end;

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton();
                                end;
                            end;

                            Table:UpdateButton();
                            Dropdown:Display();

                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);

                            Library:AttemptSave();
                        end;
                    end;
                end);

                Table:UpdateButton();
                Dropdown:Display();

                Buttons[Button] = Table;
            end;

            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1);

            local Y = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1;
            RecalculateListSize(Y);
        end;

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues;
            end;

            Dropdown:BuildDropdownList();
        end;

        function Dropdown:OpenDropdown()
            ListOuter.Visible = true;
            Library.OpenedFrames[ListOuter] = true;
            DropdownArrow.Rotation = 180;
        end;

        function Dropdown:CloseDropdown()
            ListOuter.Visible = false;
            Library.OpenedFrames[ListOuter] = nil;
            DropdownArrow.Rotation = 0;
        end;

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func;
            Func(Dropdown.Value);
        end;

        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {};

                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then
                        nTable[Value] = true
                    end;
                end;

                Dropdown.Value = nTable;
            else
                if (not Val) then
                    Dropdown.Value = nil;
                elseif table.find(Dropdown.Values, Val) then
                    Dropdown.Value = Val;
                end;
            end;

            Dropdown:BuildDropdownList();

            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
        end;

        DropdownOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown();
                else
                    Dropdown:OpenDropdown();
                end;
            end;
        end);

        InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    Dropdown:CloseDropdown();
                end;
            end;
        end);

        Dropdown:BuildDropdownList();
        Dropdown:Display();

        local Defaults = {}

        if type(Info.Default) == 'string' then
            local Idx = table.find(Dropdown.Values, Info.Default)
            if Idx then
                table.insert(Defaults, Idx)
            end
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local Idx = table.find(Dropdown.Values, Value)
                if Idx then
                    table.insert(Defaults, Idx)
                end
            end
        elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index];
                end

                if (not Info.Multi) then break end
            end

            Dropdown:BuildDropdownList();
            Dropdown:Display();
        end

        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();

        Options[Idx] = Dropdown;

        return Dropdown;
    end;

    function Funcs:AddDependencyBox()
        local Depbox = {
            Dependencies = {};
        };
        
        local Groupbox = self;
        local Container = Groupbox.Container;

        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            Parent = Container;
        });

        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            Parent = Holder;
        });

        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Frame;
        });

        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y);
            Groupbox:Resize();
        end;

        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            Depbox:Resize();
        end);

        Holder:GetPropertyChangedSignal('Visible'):Connect(function()
            Depbox:Resize();
        end);

        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1];
                local Value = Dependency[2];

                if Elem.Type == 'Toggle' and Elem.Value ~= Value then
                    Holder.Visible = false;
                    Depbox:Resize();
                    return;
                end;
            end;

            Holder.Visible = true;
            Depbox:Resize();
        end;

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.');
                assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.');
                assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.');
            end;

            Depbox.Dependencies = Dependencies;
            Depbox:Update();
        end;

        Depbox.Container = Frame;

        setmetatable(Depbox, BaseGroupbox);

        table.insert(Library.DependencyBoxes, Depbox);

        return Depbox;
    end;

    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

-- < Create other UI elements >
do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 0, 40);
        Size = UDim2.new(0, 300, 0, 200);
        ZIndex = 100;
        Parent = ScreenGui;
    });

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.NotificationArea;
    });

    local WatermarkOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, -25);
        Size = UDim2.new(0, 213, 0, 20);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    });

    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = WatermarkOuter;
    });

    Library:AddToRegistry(WatermarkInner, {
        BorderColor3 = 'AccentColor';
    });

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 202;
        Parent = WatermarkInner;
    });

    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });

    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });

    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 5, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        TextSize = 14;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 203;
        Parent = InnerFrame;
    });

    Library.Watermark = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;
    Library:MakeDraggable(Library.Watermark);



    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 10, 0.5, 0);
        Size = UDim2.new(0, 210, 0, 20);
        Visible = false;
        ZIndex = 100;
        Parent = ScreenGui;
    });

    local KeybindInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = KeybindOuter;
    });

    Library:AddToRegistry(KeybindInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);

    local ColorFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 102;
        Parent = KeybindInner;
    });

    Library:AddToRegistry(ColorFrame, {
        BackgroundColor3 = 'AccentColor';
    }, true);

    local KeybindLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20);
        Position = UDim2.fromOffset(5, 2),
        TextXAlignment = Enum.TextXAlignment.Left,

        Text = 'Keybinds';
        ZIndex = 104;
        Parent = KeybindInner;
    });

    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -20);
        Position = UDim2.new(0, 0, 0, 20);
        ZIndex = 1;
        Parent = KeybindInner;
    });

    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    });

    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        Parent = KeybindContainer,
    })

    Library.KeybindFrame = KeybindOuter;
    Library.KeybindContainer = KeybindContainer;
    Library:MakeDraggable(KeybindOuter);
end;

function Library:SetWatermarkVisibility(Bool)
    Library.Watermark.Visible = Bool;
end;

function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, 14);
    Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3);
    Library:SetWatermarkVisibility(true)

    Library.WatermarkText.Text = Text;
end;

function Library:Notify(Text, Time)
    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 14);

    YSize = YSize + 7

    local NotifyOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, 10);
        Size = UDim2.new(0, 0, 0, YSize);
        ClipsDescendants = true;
        ZIndex = 100;
        Parent = Library.NotificationArea;
    });

    local NotifyInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = NotifyOuter;
    });

    Library:AddToRegistry(NotifyInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 102;
        Parent = NotifyInner;
    });

    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });

    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });

    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, 4, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        Text = Text;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextSize = 14;
        ZIndex = 103;
        Parent = InnerFrame;
    });

    local LeftColor = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, -1, 0, -1);
        Size = UDim2.new(0, 3, 1, 2);
        ZIndex = 104;
        Parent = NotifyOuter;
    });

    Library:AddToRegistry(LeftColor, {
        BackgroundColor3 = 'AccentColor';
    }, true);

    pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize + 8 + 4, 0, YSize), 'Out', 'Quad', 0.4, true);

    task.spawn(function()
        wait(Time or 5);

        pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), 'Out', 'Quad', 0.4, true);

        wait(0.4);

        NotifyOuter:Destroy();
    end);
end;

function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }

    if type(...) == 'table' then
        Config = ...;
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false;
    end

    if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 0 end
    if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end

    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
    if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(550, 600) end

    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position = UDim2.fromScale(0.5, 0.5)
    end

    local Window = {
        Tabs = {};
    };

    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Color3.new(0, 0, 0);
        BorderSizePixel = 0;
        Position = Config.Position,
        Size = Config.Size,
        Visible = false;
        ZIndex = 1;
        Parent = ScreenGui;
    });

    Library:MakeDraggable(Outer, 25);

    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 1;
        Parent = Outer;
    });

    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'AccentColor';
    });

    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 7, 0, 0);
        Size = UDim2.new(0, 0, 0, 25);
        Text = Config.Title or '';
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 1;
        Parent = Inner;
    });

    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 25);
        Size = UDim2.new(1, -16, 1, -33);
        ZIndex = 1;
        Parent = Inner;
    });

    Library:AddToRegistry(MainSectionOuter, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });

    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = MainSectionOuter;
    });

    Library:AddToRegistry(MainSectionInner, {
        BackgroundColor3 = 'BackgroundColor';
    });

    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 8, 0, 8);
        Size = UDim2.new(1, -16, 0, 21);
        ZIndex = 1;
        Parent = MainSectionInner;
    });

    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, Config.TabPadding);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = TabArea;
    });

    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 30);
        Size = UDim2.new(1, -16, 1, -38);
        ZIndex = 2;
        Parent = MainSectionInner;
    });
    

    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    function Window:SetWindowTitle(Title)
        WindowLabel.Text = Title;
    end;

    function Window:AddTab(Name)
        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
        };

        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 16);

        local TabButton = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0);
            ZIndex = 1;
            Parent = TabArea;
        });

        Library:AddToRegistry(TabButton, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, -1);
            Text = Name;
            ZIndex = 1;
            Parent = TabButton;
        });

        local Blocker = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 1, 0);
            Size = UDim2.new(1, 0, 0, 1);
            BackgroundTransparency = 1;
            ZIndex = 3;
            Parent = TabButton;
        });

        Library:AddToRegistry(Blocker, {
            BackgroundColor3 = 'MainColor';
        });

        local TabFrame = Library:Create('Frame', {
            Name = 'TabFrame',
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = TabContainer;
        });

        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 8 - 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });

        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = LeftSide;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = RightSide;
        });

        for _, Side in next, { LeftSide, RightSide } do
            Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y);
            end);
        end;

        function Tab:ShowTab()
            for _, Tab in next, Window.Tabs do
                Tab:HideTab();
            end;

            Blocker.BackgroundTransparency = 0;
            TabButton.BackgroundColor3 = Library.MainColor;
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'MainColor';
            TabFrame.Visible = true;
        end;

        function Tab:HideTab()
            Blocker.BackgroundTransparency = 1;
            TabButton.BackgroundColor3 = Library.BackgroundColor;
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'BackgroundColor';
            TabFrame.Visible = false;
        end;

        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position;
            TabListLayout:ApplyLayout();
        end;

        function Tab:AddGroupbox(Info)
            local Groupbox = {};

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 507 + 2);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                -- BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 5;
                Parent = BoxInner;
            });

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor';
            });

            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 18);
                Position = UDim2.new(0, 4, 0, 2);
                TextSize = 14;
                Text = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 5;
                Parent = BoxInner;
            });

            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 4, 0, 20);
                Size = UDim2.new(1, -4, 1, -20);
                ZIndex = 1;
                Parent = BoxInner;
            });

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container;
            });

            function Groupbox:Resize()
                local Size = 0;

                for _, Element in next, Groupbox.Container:GetChildren() do
                    if (not Element:IsA('UIListLayout')) and Element.Visible then
                        Size = Size + Element.Size.Y.Offset;
                    end;
                end;

                BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
            end;

            Groupbox.Container = Container;
            setmetatable(Groupbox, BaseGroupbox);

            Groupbox:AddBlank(3);
            Groupbox:Resize();

            Tab.Groupboxes[Info.Name] = Groupbox;

            return Groupbox;
        end;

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1; Name = Name; });
        end;

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2; Name = Name; });
        end;

        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {};
            };

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                -- BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 10;
                Parent = BoxInner;
            });

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor';
            });

            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 1);
                Size = UDim2.new(1, 0, 0, 18);
                ZIndex = 5;
                Parent = BoxInner;
            });

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TabboxButtons;
            });

            function Tabbox:AddTab(Name)
                local Tab = {};

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    Size = UDim2.new(0.5, 0, 1, 0);
                    ZIndex = 6;
                    Parent = TabboxButtons;
                });

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                });

                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = 14;
                    Text = Name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = Button;
                });

                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(1, 0, 0, 1);
                    Visible = false;
                    ZIndex = 9;
                    Parent = Button;
                });

                Library:AddToRegistry(Block, {
                    BackgroundColor3 = 'BackgroundColor';
                });

                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 4, 0, 20);
                    Size = UDim2.new(1, -4, 1, -20);
                    ZIndex = 1;
                    Visible = false;
                    Parent = BoxInner;
                });

                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                });

                function Tab:Show()
                    for _, Tab in next, Tabbox.Tabs do
                        Tab:Hide();
                    end;

                    Container.Visible = true;
                    Block.Visible = true;

                    Button.BackgroundColor3 = Library.BackgroundColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';

                    Tab:Resize();
                end;

                function Tab:Hide()
                    Container.Visible = false;
                    Block.Visible = false;

                    Button.BackgroundColor3 = Library.MainColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
                end;

                function Tab:Resize()
                    local TabCount = 0;

                    for _, Tab in next, Tabbox.Tabs do
                        TabCount = TabCount + 1;
                    end;

                    for _, Button in next, TabboxButtons:GetChildren() do
                        if not Button:IsA('UIListLayout') then
                            Button.Size = UDim2.new(1 / TabCount, 0, 1, 0);
                        end;
                    end;

                    if (not Container.Visible) then
                        return;
                    end;

                    local Size = 0;

                    for _, Element in next, Tab.Container:GetChildren() do
                        if (not Element:IsA('UIListLayout')) and Element.Visible then
                            Size = Size + Element.Size.Y.Offset;
                        end;
                    end;

                    BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
                end;

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show();
                        Tab:Resize();
                    end;
                end);

                Tab.Container = Container;
                Tabbox.Tabs[Name] = Tab;

                setmetatable(Tab, BaseGroupbox);

                Tab:AddBlank(3);
                Tab:Resize();

                -- Show first tab (number is 2 cus of the UIListLayout that also sits in that instance)
                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show();
                end;

                return Tab;
            end;

            Tab.Tabboxes[Info.Name or ''] = Tabbox;

            return Tabbox;
        end;

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1; });
        end;

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2; });
        end;

        TabButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Tab:ShowTab();
            end;
        end);

        -- This was the first tab added, so we show it by default.
        if #TabContainer:GetChildren() == 1 then
            Tab:ShowTab();
        end;

        Window.Tabs[Name] = Tab;
        return Tab;
    end;

    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = ScreenGui;
    });

    local TransparencyCache = {};
    local Toggled = false;
    local Fading = false;

    function Library:Toggle()
        if Fading then
            return;
        end;

        local FadeTime = Config.MenuFadeTime;
        Fading = true;
        Toggled = (not Toggled);
        ModalElement.Modal = Toggled;

        if Toggled then
            -- A bit scuffed, but if we're going from not toggled -> toggled we want to show the frame immediately so that the fade is visible.
            Outer.Visible = true;

            task.spawn(function()
                -- TODO: add cursor fade?
                local State = InputService.MouseIconEnabled;

                local Cursor = Drawing.new('Triangle');
                Cursor.Thickness = 1;
                Cursor.Filled = true;
                Cursor.Visible = true;

                local CursorOutline = Drawing.new('Triangle');
                CursorOutline.Thickness = 1;
                CursorOutline.Filled = false;
                CursorOutline.Color = Color3.new(0, 0, 0);
                CursorOutline.Visible = true;

                while Toggled and ScreenGui.Parent do
                    InputService.MouseIconEnabled = false;

                    local mPos = InputService:GetMouseLocation();

                    Cursor.Color = Library.AccentColor;

                    Cursor.PointA = Vector2.new(mPos.X, mPos.Y);
                    Cursor.PointB = Vector2.new(mPos.X + 16, mPos.Y + 6);
                    Cursor.PointC = Vector2.new(mPos.X + 6, mPos.Y + 16);

                    CursorOutline.PointA = Cursor.PointA;
                    CursorOutline.PointB = Cursor.PointB;
                    CursorOutline.PointC = Cursor.PointC;

                    RenderStepped:Wait();
                end;

                InputService.MouseIconEnabled = State;

                Cursor:Remove();
                CursorOutline:Remove();
            end);
        end;

        for _, Desc in next, Outer:GetDescendants() do
            local Properties = {};

            if Desc:IsA('ImageLabel') then
                table.insert(Properties, 'ImageTransparency');
                table.insert(Properties, 'BackgroundTransparency');
            elseif Desc:IsA('TextLabel') or Desc:IsA('TextBox') then
                table.insert(Properties, 'TextTransparency');
            elseif Desc:IsA('Frame') or Desc:IsA('ScrollingFrame') then
                table.insert(Properties, 'BackgroundTransparency');
            elseif Desc:IsA('UIStroke') then
                table.insert(Properties, 'Transparency');
            end;

            local Cache = TransparencyCache[Desc];

            if (not Cache) then
                Cache = {};
                TransparencyCache[Desc] = Cache;
            end;

            for _, Prop in next, Properties do
                if not Cache[Prop] then
                    Cache[Prop] = Desc[Prop];
                end;

                if Cache[Prop] == 1 then
                
                end;

                TweenService:Create(Desc, TweenInfo.new(FadeTime, Enum.EasingStyle.Linear), { [Prop] = Toggled and Cache[Prop] or 1 }):Play();
            end;
        end;

        task.wait(FadeTime);

        Outer.Visible = Toggled;

        Fading = false;
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
            task.spawn(Library.Toggle)
        end
    end))

    if Config.AutoShow then task.spawn(Library.Toggle) end

    Window.Holder = Outer;

    return Window;
end;

local function OnPlayerChange()
    local PlayerList = GetPlayersString();

    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList);
        end;
    end;
end;

Players.PlayerAdded:Connect(OnPlayerChange);
Players.PlayerRemoving:Connect(OnPlayerChange);
print("real script start")
Library:Notify('Loading UI...');
wait(3)
------------------------------------ WINDOW -----------------------------------
local Window = Library:CreateWindow({
    Title = 'Pander.lua',
    Center = true, 
    AutoShow = true,
})
------------------------------------ TABS ------------------------------------
local Tabs = {
    Legitbot = Window:AddTab('Aimbot'), 
    Visuals = Window:AddTab('Visuals'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('Settings'),
}
------------------------------------ SECTIONS ------------------------------------
local AimbotSec1 = Tabs.Legitbot:AddLeftGroupbox('Bullet Redirection')
local AimbotSec2 = Tabs.Legitbot:AddRightGroupbox('Aim Assist')

local ESPTabbox = Tabs.Visuals:AddLeftTabbox()
local ESPTab  = ESPTabbox:AddTab('ESP')
local ESPSTab = Tabs.Visuals:AddLeftGroupbox('ESP Settings')
local LocalTab = ESPTabbox:AddTab('Local')

local CameraTabbox = Tabs.Visuals:AddRightTabbox()
local CamTab  = CameraTabbox:AddTab('Client')
local VWTab = CameraTabbox:AddTab('Viewmodel')

local MiscTabbox = Tabs.Visuals:AddRightTabbox()
local WRLTab  = MiscTabbox:AddTab('World')
local MiscTab  = MiscTabbox:AddTab('Misc')
local ArmsTab = MiscTabbox:AddTab('Self')
local BulletsTab = MiscTabbox:AddTab('Bullet')
local MiscESPTab = Tabs.Visuals:AddLeftGroupbox('Misc ESP')

local MiscSec1 = Tabs.Misc:AddLeftGroupbox('Main')
local MiscSec2 = Tabs.Misc:AddLeftGroupbox('Movement')
local MiscSec3 = Tabs.Misc:AddRightGroupbox('Tweaks')
local MiscSec4 = Tabs.Misc:AddRightGroupbox('Hit')
local MiscSec5 = Tabs.Misc:AddRightGroupbox('Others')
local MiscSec6 = Tabs.Misc:AddLeftGroupbox('Gun Mods')

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
------------------------------------ VARS ------------------------------------
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local workspace = game:GetService("Workspace")
local currentCamera = workspace.CurrentCamera
local guiService = game:GetService("GuiService")
local runService = game:GetService("RunService")
local lighting = game.Lighting
local mouse = localPlayer:GetMouse()
local userInput = game:GetService('UserInputService')
local TweenService = game:GetService("TweenService")
local rayignore = workspace.Ray_Ignore
local CNew, CF, C3, Vec2, Vec3 = ColorSequence.new, CFrame.new, Color3.fromRGB, Vector2.new, Vector3.new
local GetPlayers = players.GetPlayers
local getsenv_supported = pcall(getsenv)
local cbClient
local getsenv2
print("past pcall")

if not getsenv_supported then
    print("GETSENV NOT SUPPORTED. No recoil and no spread and possible more will not work.")
else
    getsenv2 = true
 
end
--[[]]
print("past check 1")
if getsenv2 == true then
   -- print("cb getsnev true")
   cbClient = getsenv(localPlayer.PlayerGui:WaitForChild("Client"))
else
   -- print("reeahasfh")
   cbClient = localPlayer.PlayerGui:WaitForChild("Client")
end

print("goto to skyboxs")
local SkyboxesTable = {
    ["Galaxy"] = {
        SkyboxBk = "http://www.roblox.com/asset/?id=159454299",
        SkyboxDn = "http://www.roblox.com/asset/?id=159454296",
        SkyboxFt = "http://www.roblox.com/asset/?id=159454293",
        SkyboxLf = "http://www.roblox.com/asset/?id=159454286",
        SkyboxRt = "http://www.roblox.com/asset/?id=159454300",
        SkyboxUp = "http://www.roblox.com/asset/?id=159454288"
    },
    ["Pink Sky"] = {
        SkyboxLf = "rbxassetid://271042310",
		SkyboxBk = "rbxassetid://271042516",
		SkyboxDn = "rbxassetid://271077243",
		SkyboxFt = "rbxassetid://271042556",
		SkyboxRt = "rbxassetid://271042467",
		SkyboxUp = "rbxassetid://271077958"
    },
    ["Sunset"] = {
        SkyboxBk = "http://www.roblox.com/asset/?id=458016711",
        SkyboxDn = "http://www.roblox.com/asset/?id=458016826",
        SkyboxFt = "http://www.roblox.com/asset/?id=458016532",
        SkyboxLf = "http://www.roblox.com/asset/?id=458016655",
        SkyboxRt = "http://www.roblox.com/asset/?id=458016782",
        SkyboxUp = "http://www.roblox.com/asset/?id=458016792"
    },
    ["Night"] = {
        SkyboxBk = "rbxassetid://48020371",
        SkyboxDn = "rbxassetid://48020144",
        SkyboxFt = "rbxassetid://48020234",
        SkyboxLf = "rbxassetid://48020211",
        SkyboxRt = "rbxassetid://48020254",
        SkyboxUp = "rbxassetid://48020383"
    },
    ["Evening"] = {
        SkyboxLf = "http://www.roblox.com/asset/?id=7950573918",
        SkyboxBk = "http://www.roblox.com/asset/?id=7950569153",
		SkyboxDn = "http://www.roblox.com/asset/?id=7950570785",
		SkyboxFt = "http://www.roblox.com/asset/?id=7950572449",
		SkyboxRt = "http://www.roblox.com/asset/?id=7950575055",
		SkyboxUp = "http://www.roblox.com/asset/?id=7950627627"
    }
}

local saturationeffect = Instance.new("ColorCorrectionEffect", currentCamera)
saturationeffect.Enabled = false
local Blur = Instance.new("BlurEffect", currentCamera)
Blur.Enabled = false

local bullettracerstexture = 446111271
local armschamstexture = 414144526
local weaponchamstexture = 414144526
local retardarmschams = C3(255, 0, 0)

local ebCooldown = false
local oldState = Enum.HumanoidStateType.None
local ebenabled = false
local ebsfx = 6887181639
local timeout = 0
local ebcount = 0
local graphLines = {}
local lastPos = currentCamera.ViewportSize.Y-90

local HitSoundType = 3124331820
local KillSoundType = 5902468562
------------------------------------ GUI STUFF ------------------------------------
local watermark = Instance.new("ScreenGui")
local ScreenLabel = Instance.new("Frame")
local WatermarkColor = Instance.new("Frame")
local UIGradient = Instance.new("UIGradient")
local Container = Instance.new("Frame")
local UIPadding = Instance.new("UIPadding")
local Text = Instance.new("TextLabel")
local Background = Instance.new("Frame")

watermark.Name = "watermark"
watermark.Parent = game.CoreGui
watermark.Enabled = false

ScreenLabel.Name = "ScreenLabel"
ScreenLabel.Parent = watermark
ScreenLabel.BackgroundColor3 = C3(28, 28, 28)
ScreenLabel.BackgroundTransparency = 1.000
ScreenLabel.BorderColor3 = C3(20, 20, 20)
ScreenLabel.Position = UDim2.new(0, 12, 0, 7)
ScreenLabel.Size = UDim2.new(0, 260, 0, 20)

WatermarkColor.Name = "Color"
WatermarkColor.Parent = ScreenLabel
WatermarkColor.BackgroundColor3 = C3(0, 89, 149)
WatermarkColor.BorderSizePixel = 0
WatermarkColor.Size = UDim2.new(0.534260333, 0, 0, 2)
WatermarkColor.ZIndex = 2

UIGradient.Color = CNew{ColorSequenceKeypoint.new(0.00, C3(255, 255, 255)), ColorSequenceKeypoint.new(1.00, C3(60, 60, 60))}
UIGradient.Rotation = 90
UIGradient.Parent = WatermarkColor

Container.Name = "Container"
Container.Parent = ScreenLabel
Container.BackgroundTransparency = 1.000
Container.BorderSizePixel = 0
Container.Position = UDim2.new(0, 0, 0, 4)
Container.Size = UDim2.new(1, 0, 0, 14)
Container.ZIndex = 3

UIPadding.Parent = Container
UIPadding.PaddingLeft = UDim.new(0, 4)

Text.Name = "Text"
Text.Parent = Container
Text.BackgroundTransparency = 1.000
Text.Position = UDim2.new(0.0230768919, 0, 0, 0)
Text.Size = UDim2.new(0.48046875, 0, 1, 0)
Text.ZIndex = 4
Text.Font = Enum.Font.RobotoMono
Text.Text = "pander.lua | user"
Text.TextColor3 = C3(65025, 65025, 65025)
Text.TextSize = 14.000
Text.TextStrokeTransparency = 0.000
Text.TextXAlignment = Enum.TextXAlignment.Left

Background.Name = "Background"
Background.Parent = ScreenLabel
Background.BackgroundColor3 = C3(23, 23, 23)
Background.BorderColor3 = C3(20, 20, 20)
Background.Size = UDim2.new(0.534260333, 0, 1, 0)

local function ZWWNPAB_fake_script() -- ScreenLabel.LocalScript 
	local script = Instance.new('LocalScript', ScreenLabel)

	local gui = script.Parent
	gui.Draggable = true
	gui.Active = true
end
coroutine.wrap(ZWWNPAB_fake_script)()
print("done with faking scripts")
local SpectatorViewer = Instance.new("ScreenGui")
local Main = Instance.new("Frame")
local Spectators = Instance.new("TextLabel")
local Background = Instance.new("Frame")
local UIGradient = Instance.new("UIGradient")
local SpectColor = Instance.new("Frame")
local UIGradient_2 = Instance.new("UIGradient")
local Frame = Instance.new("Frame")
local Example = Instance.new("TextLabel")
local UIListLayout = Instance.new("UIListLayout")

SpectatorViewer.Name = "SpectatorViewer"
SpectatorViewer.Parent = game.CoreGui

Main.Name = "Main"
Main.Parent = SpectatorViewer
Main.BackgroundColor3 = C3(23, 23, 23)
Main.BackgroundTransparency = 1.000
Main.BorderColor3 = C3(20, 20, 20)
Main.Position = UDim2.new(0.00779589033, 0, 0.400428265, 0)
Main.Size = UDim2.new(0, 153, 0, 20)
Main.Visible = true

Spectators.Name = "Spectators"
Spectators.Parent = Main
Spectators.BackgroundTransparency = 1.000
Spectators.Size = UDim2.new(1, 0, 1, 0)
Spectators.ZIndex = 4
Spectators.Font = Enum.Font.RobotoMono
Spectators.Text = " Spectators"
Spectators.TextColor3 = C3(255, 255, 255)
Spectators.TextSize = 15.000
Spectators.TextStrokeTransparency = 0.000
Spectators.TextXAlignment = Enum.TextXAlignment.Left

Background.Name = "Background"
Background.Parent = Main
Background.BackgroundColor3 = C3(45, 45, 45)
Background.BorderColor3 = C3(20, 20, 20)
Background.Size = UDim2.new(1.00657892, 0, 1, 0)
Background.BorderSizePixel = 0  

UIGradient.Color = CNew{ColorSequenceKeypoint.new(0.00, C3(255, 255, 255)), ColorSequenceKeypoint.new(1.00, C3(112, 112, 112))}
UIGradient.Rotation = 90
UIGradient.Parent = Background

SpectColor.Name = "Color"
SpectColor.Parent = Main
SpectColor.BackgroundColor3 = C3(255, 0, 0)
SpectColor.BorderSizePixel = 0
SpectColor.Position = UDim2.new(0, 1, 0, 1)
SpectColor.Size = UDim2.new(0.991, 0, 0, 2)
SpectColor.ZIndex = 2

UIGradient_2.Color = CNew{ColorSequenceKeypoint.new(0.00, C3(255, 255, 255)), ColorSequenceKeypoint.new(1.00, C3(60, 60, 60))}
UIGradient_2.Rotation = 90
UIGradient_2.Parent = SpectColor

Frame.Parent = Main
Frame.BackgroundColor3 = C3(7, 7, 7)
Frame.BorderSizePixel = 0
Frame.Position = UDim2.new(0, 0, 1, 0)
Frame.Size = UDim2.new(0, 153, 0, 1)

Example.Name = "Example"
Example.Parent = Frame
Example.BackgroundColor3 = C3(22, 22, 22)
Example.BorderSizePixel = 0
Example.Position = UDim2.new(-0.00653594732, 0, 1, 0)
Example.Size = UDim2.new(0, 156, 0, 20)
Example.Font = Enum.Font.RobotoMono
Example.Text = "Name"
Example.Visible = false
Example.TextColor3 = C3(255, 255, 255)
Example.TextSize = 13.000
Example.TextXAlignment = Enum.TextXAlignment.Left

UIListLayout.Parent = Frame
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function spectlist()
	local script = Instance.new('LocalScript', Frame)

	local function GetSpectators()
		local CurrentSpectators = {}
		for i,v in pairs(game:GetService("Players"):GetChildren()) do 
			if v ~= game:GetService("Players").LocalPlayer and not v.Character and v:FindFirstChild("CameraCF") and (v.CameraCF.Value.Position - workspace.CurrentCamera.CFrame.p).Magnitude < 10 then 
				table.insert(CurrentSpectators, #CurrentSpectators+1, v)
			end
		end
		return CurrentSpectators
	end
	
	while wait(0.05) do
		for i,v in next, script.Parent:GetChildren() do
			if v.Name ~= "Example" and not v:IsA("UIListLayout") and not v:IsA("LocalScript") then
				v:Destroy()
			end
		end
		for i,v in next, GetSpectators() do
			local new = script.Parent.Example:Clone()
			new.Parent = script.Parent
			new.Visible = true
			new.ZIndex = 5
			new.Name = v.Name
			new.Text = " ".. v.Name
			new.TextSize = 13
			new.Size = UDim2.new(0, 154,0, 20)
			new.Font = Enum.Font.RobotoMono
			new.BackgroundColor3 = C3(20, 20, 20)
			new.TextColor3 = C3(225, 225, 225)
			new.TextStrokeTransparency = 0
		end
	end
	
end
coroutine.wrap(spectlist)()
print("surpass spectlist")
local keystrokesGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")

local W = Instance.new("TextLabel")
local S = Instance.new("TextLabel")
local A = Instance.new("TextLabel")
local D = Instance.new("TextLabel")
local E = Instance.new("TextLabel")
local R = Instance.new("TextLabel")
local Space = Instance.new("TextLabel")

keystrokesGui.Parent = game.CoreGui
keystrokesGui.Name = "keystrokess"
keystrokesGui.Enabled = false

Frame.Parent = keystrokesGui
Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Frame.BackgroundTransparency = 1.000
Frame.Position = UDim2.new(0.453987718, 0, 0.738977075, 0)
Frame.Size = UDim2.new(0, 72, 0, 75)

W.Name = "W"
W.Parent = Frame
W.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
W.BackgroundTransparency = 1.000
W.Position = UDim2.new(0.287764132, 0, -0.0102292299, 0)
W.Size = UDim2.new(0, 29, 0, 28)
W.Font = Enum.Font.Code
W.Text = "_"
W.TextColor3 = Color3.fromRGB(255, 255, 255)
W.TextSize = 14.000
W.TextStrokeTransparency = 0.000

S.Name = "S"
S.Parent = Frame
S.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
S.BackgroundTransparency = 1.000
S.Position = UDim2.new(0.287764132, 0, 0.35915342, 0)
S.Size = UDim2.new(0, 29, 0, 28)
S.Font = Enum.Font.Code
S.Text = "_"
S.TextColor3 = Color3.fromRGB(255, 255, 255)
S.TextSize = 14.000
S.TextStrokeTransparency = 0.000

A.Name = "A"
A.Parent = Frame
A.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
A.BackgroundTransparency = 1.000
A.Position = UDim2.new(-0.0950409099, 0, 0.35915345, 0)
A.Size = UDim2.new(0, 29, 0, 28)
A.Font = Enum.Font.Code
A.Text = "_"
A.TextColor3 = Color3.fromRGB(255, 255, 255)
A.TextSize = 14.000
A.TextStrokeTransparency = 0.000

D.Name = "D"
D.Parent = Frame
D.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
D.BackgroundTransparency = 1.000
D.Position = UDim2.new(0.684458077, 0, 0.35915342, 0)
D.Size = UDim2.new(0, 29, 0, 28)
D.Font = Enum.Font.Code
D.Text = "_"
D.TextColor3 = Color3.fromRGB(255, 255, 255)
D.TextSize = 14.000
D.TextStrokeTransparency = 0.000

E.Name = "E"
E.Parent = Frame
E.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
E.BackgroundTransparency = 1.000
E.Position = UDim2.new(-0.0950409099, 0, -0.0102293491, 0)
E.Size = UDim2.new(0, 29, 0, 28)
E.Font = Enum.Font.Code
E.Text = "_"
E.TextColor3 = Color3.fromRGB(255, 255, 255)
E.TextSize = 14.000
E.TextStrokeTransparency = 0.000

R.Name = "R"
R.Parent = Frame
R.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
R.BackgroundTransparency = 1.000
R.Position = UDim2.new(0.683231115, 0, -0.0102292895, 0)
R.Size = UDim2.new(0, 29, 0, 28)
R.Font = Enum.Font.Code
R.Text = "_"
R.TextColor3 = Color3.fromRGB(255, 255, 255)
R.TextSize = 14.000
R.TextStrokeTransparency = 0.000

Space.Name = "Space"
Space.Parent = Frame
Space.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Space.BackgroundTransparency = 1.000
Space.Position = UDim2.new(-0.104209319, 0, 0.620387971, 0)
Space.Size = UDim2.new(0, 87, 0, 28)
Space.Font = Enum.Font.Code
Space.Text = "_"
Space.TextColor3 = Color3.fromRGB(255, 255, 255)
Space.TextSize = 14.000
Space.TextStrokeTransparency = 0.000

-- Scripts:

local function SJBA_fake_script() -- Frame.LocalScript 
    local script = Instance.new('LocalScript', Frame)
    local gui = script.Parent
    gui.Draggable = true
    gui.Active = true
end
coroutine.wrap(SJBA_fake_script)()

local function UTCCBQ_fake_script() -- Frame.LocalScript 
    local script = Instance.new('LocalScript', Frame)
    local UIS = game:GetService("UserInputService")
    local Sp = script.Parent.Space
    local W = script.Parent.W
    local A = script.Parent.A
    local S = script.Parent.S
    local D = script.Parent.D
    local E = script.Parent.E
    local R = script.Parent.R
	
    UIS.InputBegan:Connect(function(key)
        if key.KeyCode == Enum.KeyCode.W then
            W.Text = "W"
        elseif key.KeyCode == Enum.KeyCode.A then
            A.Text = "A"
        elseif key.KeyCode == Enum.KeyCode.S then
            S.Text = "S"
        elseif key.KeyCode == Enum.KeyCode.D then
            D.Text = "D"
        elseif key.KeyCode == Enum.KeyCode.E then
            E.Text = "E"
        elseif key.KeyCode == Enum.KeyCode.R then
            R.Text = "R"
        elseif key.KeyCode == Enum.KeyCode.Space then
            Sp.Text = "Space"
        end
    end)
    
    UIS.InputEnded:Connect(function(key)
        if key.KeyCode == Enum.KeyCode.W then
            W.Text = "_"
        elseif key.KeyCode == Enum.KeyCode.A then
            A.Text = "_"
        elseif key.KeyCode == Enum.KeyCode.S then
            S.Text = "_"
        elseif key.KeyCode == Enum.KeyCode.D then
            D.Text = "_"
        elseif key.KeyCode == Enum.KeyCode.E then
            E.Text = "_"
        elseif key.KeyCode == Enum.KeyCode.R then
            R.Text = "_"
        elseif key.KeyCode == Enum.KeyCode.Space then
            Sp.Text = "_"
            end
        end)
    end
coroutine.wrap(UTCCBQ_fake_script)()

local ebtxt = Drawing.new("Text");ebtxt.Text = "EB";ebtxt.Center = true;ebtxt.Outline = true;ebtxt.Color = C3(255, 255, 255);ebtxt.Font = 3;ebtxt.Position = Vec2(currentCamera.ViewportSize.X / 2, currentCamera.ViewportSize.Y - 80);ebtxt.Size = 18;ebtxt.Visible = false;
local ebcounter = Drawing.new("Text");ebcounter.Text = "eb: "..ebcount.."";ebcounter.Center = true;ebcounter.Outline = true;ebcounter.Color = C3(255, 255, 255);ebcounter.Font = 3;ebcounter.Position = Vec2(currentCamera.ViewportSize.X / 2, currentCamera.ViewportSize.Y - 50);ebcounter.Size = 18;ebcounter.Visible = false
local VelocityCounter = Drawing.new("Text");VelocityCounter.Text = "";VelocityCounter.Center = true;VelocityCounter.Outline = true;VelocityCounter.Color = Color3.new(1,1,1);VelocityCounter.Font = 3;VelocityCounter.Position = Vec2(currentCamera.ViewportSize.X/2, currentCamera.ViewportSize.Y-70);VelocityCounter.Size = 20;VelocityCounter.Visible = false
------------------------------------ MAIN FUNCS ------------------------------------
print("main funcs")
local function IsAlive(plr)
	if plr and plr.Character and plr.Character.FindFirstChild(plr.Character, "Humanoid") and plr.Character.Humanoid.Health > 0 then
		return true
	end

	return false
end

function isButtonDown(key)
    if string.find(tostring(key),"KeyCode") then
        return game:GetService("UserInputService"):IsKeyDown(key) 
    else
        for _,v in pairs(game:GetService("UserInputService"):GetMouseButtonsPressed()) do
            if v.UserInputType == key then
                return true
            end
        end
    end
	return false
end
------------------------------------ ESP ------------------------------------
print("esp")
local esp = {
    playerObjects = {},
    enabled = false,
    teamcheck = true,
    fontsize = 13,
    font = 1,
    settings = {
        name = {enabled = false, outline = false, displaynames = false, color = C3(255, 255, 255)},
        box = {enabled = false, outline = false, color = C3(255, 255, 255)},
        boxfill = {enabled = false, color = C3(255, 0, 0), transparency = 0.5},
        healthbar = {enabled = false, outline = false},
        healthtext = {enabled = false, outline = false, color = C3(255, 255, 255)},
        distance = {enabled = false, outline = false, color = C3(255, 255, 255)},
        viewangle = {enabled = false, color = C3(255, 255, 255)},
    }
}

esp.NewDrawing = function(type, properties)
    local newD = Drawing.new(type)
    for i,v in next, properties or {} do
        local s,e = pcall(function()
            newD[i] = v
        end)

        if not s then
            warn(e)
        end
    end
    return newD
end

esp.HasCharacter = function(v)
    local pass = false
    -- if u dont want an self esp then do this: if v ~= game.Players.LocalPlayer and v.Character, else if v ~= v.Character
    if v ~= localPlayer and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Head") then
        pass = true
    end

    if s then return pass; end; return pass;
end

esp.TeamCheck = function(v)
    local pass = true
    if localPlayer.TeamColor == v.TeamColor then
        pass = false
    end

    if s then return pass; end; return pass;
end --[true = Same Team | false = Same Team]

esp.NewPlayer = function(v)
    esp.playerObjects[v] = {
        name = esp.NewDrawing("Text", {Color = C3(255, 255, 255), Outline = true, Center = true, Size = 13, Font = 2}),
        boxOutline = esp.NewDrawing("Square", {Color = C3(0, 0, 0), Thickness = 3, ZIndex = 2}),
        box = esp.NewDrawing("Square", {Color = C3(255, 255, 255), Thickness = 1, ZIndex = 3}),
        boxfill = esp.NewDrawing("Square", {Color = C3(255, 255, 255), Thickness = 1, ZIndex = 1}),
        healthBarOutline = esp.NewDrawing("Line", {Color = C3(0, 0, 0), Thickness = 3}),
        healthBar = esp.NewDrawing("Line", {Color = C3(255, 255, 255), Thickness = 1}),
        healthText = esp.NewDrawing("Text", {Color = C3(255, 255, 255), Outline = true, Center = true, Size = 13, Font = 2}),
        distance = esp.NewDrawing("Text", {Color = C3(255, 255, 255), Outline = true, Center = true, Size = 13, Font = 2}),
        viewAngle = esp.NewDrawing("Line", {Color = C3(255, 255, 255), Thickness = 1}),
    }
end

for _,v in ipairs(players:GetPlayers()) do
    esp.NewPlayer(v)
end

players.PlayerAdded:Connect(esp.NewPlayer)
------------------------------------ SILENT AIM STUFF ---------------------------------
print("silent aim")---
--// all of the silent aim was made by xaxa, credits to him.
local SilentAimSettings = {
    Enabled = false,
    
    ClassName = "Universal Silent Aim - Averiias, Stefanuk12, xaxa",
    ToggleKey = "RightAlt",
    
    TeamCheck = false,
    VisibleCheck = false, 
    TargetPart = "HumanoidRootPart",
    SilentAimMethod = "FindPartOnRayWithIgnoreList",
    
    FOVRadius = 130,
    FOVVisible = false,
    ShowSilentAimTarget = false, 
    
    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    HitChance = 100
}

-- variables
getgenv().SilentAimSettings = Settings

local ValidTargetParts = {"Head", "HumanoidRootPart"}
local PredictionAmount = 0.165

--// Aim Assist FOV Circles
local as_fov_circleout1 = Drawing.new("Circle")
as_fov_circleout1.Thickness = 1
as_fov_circleout1.NumSides = 100
as_fov_circleout1.Radius = 130
as_fov_circleout1.Filled = false
as_fov_circleout1.Visible = false
as_fov_circleout1.ZIndex = 9
as_fov_circleout1.Transparency = 1
as_fov_circleout1.Color = C3(0, 0, 0)
local as_fov_circle = Drawing.new("Circle")
as_fov_circle.Thickness = 1
as_fov_circle.NumSides = 100
as_fov_circle.Radius = 130
as_fov_circle.Filled = false
as_fov_circle.Visible = false
as_fov_circle.ZIndex = 10
as_fov_circle.Transparency = 1
as_fov_circle.Color = C3(54, 57, 241)
local as_fov_circleout2 = Drawing.new("Circle")
as_fov_circleout2.Thickness = 1
as_fov_circleout2.NumSides = 100
as_fov_circleout2.Radius = 130
as_fov_circleout2.Filled = false
as_fov_circleout2.Visible = false
as_fov_circleout2.ZIndex = 9
as_fov_circleout2.Transparency = 1
as_fov_circleout2.Color = C3(0, 0, 0)
--// Silent Aim FOV Circles
local br_fov_circleout1 = Drawing.new("Circle")
br_fov_circleout1.Thickness = 1
br_fov_circleout1.NumSides = 100
br_fov_circleout1.Radius = 130
br_fov_circleout1.Filled = false
br_fov_circleout1.Visible = false
br_fov_circleout1.ZIndex = 9
br_fov_circleout1.Transparency = 1
br_fov_circleout1.Color = C3(0, 0, 0)
local br_fov_circle = Drawing.new("Circle")
br_fov_circle.Thickness = 1
br_fov_circle.NumSides = 100
br_fov_circle.Radius = 130
br_fov_circle.Filled = false
br_fov_circle.Visible = false
br_fov_circle.ZIndex = 10
br_fov_circle.Transparency = 1
br_fov_circle.Color = C3(54, 57, 241)
local br_fov_circleout2 = Drawing.new("Circle")
br_fov_circleout2.Thickness = 1
br_fov_circleout2.NumSides = 100
br_fov_circleout2.Radius = 130
br_fov_circleout2.Filled = false
br_fov_circleout2.Visible = false
br_fov_circleout2.ZIndex = 9
br_fov_circleout2.Transparency = 1
br_fov_circleout2.Color = C3(0, 0, 0)

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean", "boolean"
        }
    }
}

function CalculateChance(Percentage)
    -- // Floor the percentage
    Percentage = math.floor(Percentage)

    -- // Get the chance
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100

    -- // Return
    return chance <= Percentage / 100
end

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = currentCamera.WorldToScreenPoint(currentCamera, Vector)
    return Vec2(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function getMousePosition()
    return userInput.GetMouseLocation(userInput)
end

local function IsPlayerVisible(Player)
    local PlayerCharacter = Player.Character
    local LocalPlayerCharacter = localPlayer.Character
    
    if not (PlayerCharacter or LocalPlayerCharacter) then return end 
    
    local PlayerRoot = game.FindFirstChild(PlayerCharacter, Options.TargetPart.Value) or game.FindFirstChild(PlayerCharacter, "HumanoidRootPart")
    
    if not PlayerRoot then return end 
    
    local CastPoints, IgnoreList = {PlayerRoot.Position, LocalPlayerCharacter, PlayerCharacter}, {LocalPlayerCharacter, PlayerCharacter}
    local ObscuringObjects = #currentCamera.GetPartsObscuringTarget(currentCamera, CastPoints, IgnoreList)
    
    return ((ObscuringObjects == 0 and true) or (ObscuringObjects > 0 and false))
end

local function getClosestPlayer()
    if not Options.TargetPart.Value then return end
    local Closest
    local DistanceToMouse
    for _, Player in next, players.GetPlayers(players) do
        if Player == localPlayer then end
        if Toggles.TeamCheck.Value and Player.Team == localPlayer.Team then end

        local Character = Player.Character
        if not Character then end
        
        if Toggles.VisibleCheck.Value and not IsPlayerVisible(Player) then end

        local HumanoidRootPart = game.FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = game.FindFirstChild(Character, "Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid and Humanoid.Health <= 0 then end

        local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position)
        if not OnScreen then end

        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if Distance <= (DistanceToMouse or Options.Radius.Value or 2000) then
            Closest = ((Options.TargetPart.Value == "Random" and Character[ValidTargetParts[math.random(1, #ValidTargetParts)]]) or Character[Options.TargetPart.Value])
            DistanceToMouse = Distance
        end
    end
    return Closest
end
print("aim aissisting code")
------------------------------------ AIM ASSIST CODE ------------------------------------
local AimSettings = {
    Enabled = false,
    TeamCheck = false,
    --Key = 'E',
    Smoothness = 1,
    Radius = 50,
    Hitbox = 'Head'
}

local function getClosest(cframe)
   local ray = Ray.new(cframe.Position, cframe.LookVector).Unit
   
   local target = nil
   local mag = math.huge
   
    for i,v in pairs(players:GetPlayers()) do
        --if AimSettings.VisibleCheck and not IsPlayerVisible(target) then end
        if v.Character and v.Character:FindFirstChild("Head") and v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") and v ~= localPlayer and (v.Team ~= localPlayer.Team or (not AimSettings.TeamCheck)) then
            local magBuf = (v.Character[AimSettings.Hitbox].Position - ray:ClosestPoint(v.Character[AimSettings.Hitbox].Position)).Magnitude
            
            if magBuf < mag then
                mag = magBuf
                target = v
            end
        end
    end
   
   return target
end
------------------------------------ CONTENT ------------------------------------
print("content")
AimbotSec1:AddToggle("aim_Enabled", {Text = "Enabled"}):AddKeyPicker("aim_Enabled_KeyPicker", {Default = "RightAlt", SyncToggleState = true, Mode = "Toggle", Text = "Silent Aim", NoUI = false});
Options.aim_Enabled_KeyPicker:OnClick(function()
    SilentAimSettings.Enabled = not SilentAimSettings.Enabled
    
    Toggles.aim_Enabled.Value = SilentAimSettings.Enabled
    Toggles.aim_Enabled:SetValue(SilentAimSettings.Enabled)
end)

AimbotSec1:AddToggle("TeamCheck", {Text = "Team Check", Default = SilentAimSettings.TeamCheck}):OnChanged(function()
    SilentAimSettings.TeamCheck = Toggles.TeamCheck.Value
end)
AimbotSec1:AddToggle("VisibleCheck", {Text = "Visible Check", Default = SilentAimSettings.VisibleCheck}):OnChanged(function()
    SilentAimSettings.VisibleCheck = Toggles.VisibleCheck.Value
end)
AimbotSec1:AddDropdown("TargetPart", {Text = "Target Part", Default = SilentAimSettings.TargetPart, Values = {"Head", "HumanoidRootPart", "Random"}}):OnChanged(function()
    SilentAimSettings.TargetPart = Options.TargetPart.Value
end)

AimbotSec1:AddSlider('HitChance', {Text = 'Hit chance', Default = 100, Min = 0, Max = 100, Rounding = 0, Compact = false,})
Options.HitChance:OnChanged(function()
    SilentAimSettings.HitChance = Options.HitChance.Value
end)

AimbotSec1:AddSlider("Radius", {Text = "FOV Circle Radius", Min = 0, Max = 360, Default = 130, Rounding = 0}):OnChanged(function()
    br_fov_circleout1.Radius = Options.Radius.Value + 1
    br_fov_circle.Radius = Options.Radius.Value
    br_fov_circleout2.Radius = Options.Radius.Value - 1
    
    SilentAimSettings.FOVRadius = Options.Radius.Value
end)

AimbotSec1:AddToggle('br_fov', {Text = 'Show FOV Circle', Default = false})
Toggles.br_fov:OnChanged(function()
end)
Toggles.br_fov:AddColorPicker('br_fovcolor', {Default = C3(255,255,255), Title = 'FOV Circle Color'})
Options.br_fovcolor:OnChanged(function()
    br_fov_circle.Color = Options.br_fovcolor.Value
end)
AimbotSec1:AddToggle('br_fovout', {Text = 'Circle Outline', Default = false})

AimbotSec2:AddToggle('as_enabled', {Text = 'Enabled', Default = false})
Toggles.as_enabled:OnChanged(function()
   AimSettings.Enabled = Toggles.as_enabled.Value
end)
    
AimbotSec2:AddToggle('as_tc', {Text = 'Team Check', Default = false})
Toggles.as_tc:OnChanged(function()
   AimSettings.TeamCheck = Toggles.as_tc.Value
end)

--AimbotSec2:AddToggle('as_vis', {Text = 'Visible Check', Default = false})
--Toggles.as_vis:OnChanged(function()
--   AimSettings.VisibleCheck = Toggles.as_vis.Value
--end)

AimbotSec2:AddDropdown("as_hb", {Text = "Target Part", Default = AimSettings.Hitbox, Values = {"Head", "HumanoidRootPart"}}):OnChanged(function()
    AimSettings.Hitbox = Options.as_hb.Value
end)

AimbotSec2:AddSlider('as_smoothness', {Text = 'Smoothness', Default = 1, Min = 1, Max = 10, Rounding = 0, Compact = false})
Options.as_smoothness:OnChanged(function()
    AimSettings.Smoothness = Options.as_smoothness.Value/10
end)

AimbotSec2:AddSlider('as_radius', {Text = 'FOV', Default = 50, Min = 1, Max = 420, Rounding = 0, Compact = false})
Options.as_radius:OnChanged(function()
    AimSettings.Radius = Options.as_radius.Value
    
    as_fov_circleout1.Radius = Options.as_radius.Value - 1
    as_fov_circle.Radius = Options.as_radius.Value
    as_fov_circleout2.Radius = Options.as_radius.Value + 1
end)

AimbotSec2:AddToggle('as_fov', {Text = 'Show FOV Circle', Default = false})
Toggles.as_fov:AddColorPicker('as_fovcolor', {Default = C3(255,255,255), Title = 'FOV Circle Color'})
Options.as_fovcolor:OnChanged(function()
    as_fov_circle.Color = Options.as_fovcolor.Value
end)
AimbotSec2:AddToggle('as_fovout', {Text = 'Circle Outline', Default = false})
--------------------------------------------------------------------------------------

ESPTab:AddToggle('espenabled', {Text = 'Enabled', Default = false})
Toggles.espenabled:OnChanged(function()
   esp.enabled = Toggles.espenabled.Value
end)

ESPTab:AddToggle('espbox', {Text = 'Box', Default = false})
Toggles.espbox:OnChanged(function()
   esp.settings.box.enabled = Toggles.espbox.Value
end)
Toggles.espbox:AddColorPicker('espboxcolor', {Default = C3(255,255,255), Title = 'Box Color'})
Options.espboxcolor:OnChanged(function()
    esp.settings.box.color = Options.espboxcolor.Value
end)

ESPTab:AddToggle('espnames', {Text = 'Names', Default = false})
Toggles.espnames:OnChanged(function()
   esp.settings.name.enabled = Toggles.espnames.Value
end)
Toggles.espnames:AddColorPicker('espnamescolor', {Default = C3(255,0,0), Title = 'Names Color'})
Options.espnamescolor:OnChanged(function()
    esp.settings.name.color = Options.espnamescolor.Value
end)

ESPTab:AddToggle('espboxfill', {Text = 'Box Fill', Default = false})
Toggles.espboxfill:OnChanged(function()
   esp.settings.boxfill.enabled = Toggles.espboxfill.Value
end)
Toggles.espboxfill:AddColorPicker('espboxfillcolor', {Default = C3(255,0,0), Title = 'Box Fill Color'})
Options.espboxfillcolor:OnChanged(function()
    esp.settings.boxfill.color = Options.espboxfillcolor.Value
end)

ESPTab:AddToggle('esphb', {Text = 'Health bar', Default = false})
Toggles.esphb:OnChanged(function()
   esp.settings.healthbar.enabled = Toggles.esphb.Value
end)

ESPTab:AddToggle('espht', {Text = 'Health text', Default = false})
Toggles.espht:OnChanged(function()
   esp.settings.healthtext.enabled = Toggles.espht.Value
end)
Toggles.espht:AddColorPicker('esphtcolor', {Default = C3(0,255,0), Title = 'Health Text Color'})
Options.esphtcolor:OnChanged(function()
    esp.settings.healthtext.color = Options.esphtcolor.Value
end)

ESPTab:AddToggle('espdistance', {Text = 'Distance', Default = false})
Toggles.espdistance:OnChanged(function()
   esp.settings.distance.enabled = Toggles.espdistance.Value
end)
Toggles.espdistance:AddColorPicker('espdistancecolor', {Default = C3(255,255,255), Title = 'Distance Color'})
Options.espdistancecolor:OnChanged(function()
    esp.settings.distance.color = Options.espdistancecolor.Value
end)

ESPSTab:AddToggle('espoutline', {Text = 'Outline', Default = false})
Toggles.espoutline:OnChanged(function()
    for i,v in pairs(esp.settings) do
        v.outline = Toggles.espoutline.Value
    end
end)

ESPSTab:AddToggle('espdisplay', {Text = 'Use Display Names', Default = false})
Toggles.espdisplay:OnChanged(function()
    esp.settings.name.displaynames = Toggles.espdisplay.Value
end)

ESPSTab:AddSlider('esptsize', {Text = 'Text Size', Default = 13, Min = 1, Max = 50, Rounding = 0, Compact = false})
Options.esptsize:OnChanged(function()
    esp.fontsize = Options.esptsize.Value
end)

ESPSTab:AddDropdown('espfont', {Values = {'UI', 'System', 'Plex', 'Monospace'}, Default = 2, Multi = false, Text = 'Font'})
Options.espfont:OnChanged(function()
    if Options.espfont.Value == 'UI' then
        esp.font = 0
    elseif Options.espfont.Value == 'System' then
        esp.font = 1
    elseif Options.espfont.Value == 'Plex' then
        esp.font = 2
    elseif Options.espfont.Value == 'Monospace' then
        esp.font = 3
    end
end)
-- // Local Tab

print("Local")
LocalTab:AddToggle('local_thirdperson', {Text = 'Third Person', Default = false}):AddKeyPicker('local_thirdpersonbind', {Default = 'X', SyncToggleState = true, Mode = 'Toggle', Text = "Third Person", NoUI = false})
Toggles.local_thirdperson:OnChanged(function()
    if Toggles.local_thirdperson.Value == true then
        runService:BindToRenderStep("ThirdPerson", 100, function()
			if localPlayer.CameraMinZoomDistance ~= Options.local_thirdpersondist.Value then
				localPlayer.CameraMinZoomDistance = Options.local_thirdpersondist.Value
				localPlayer.CameraMaxZoomDistance = Options.local_thirdpersondist.Value
				workspace.ThirdPerson.Value = true
			end
		end)
	elseif Toggles.local_thirdperson.Value == false then
		runService:UnbindFromRenderStep("ThirdPerson")
		if IsAlive(localPlayer) then
			wait()
			workspace.ThirdPerson.Value = false
			localPlayer.CameraMinZoomDistance = 0
			localPlayer.CameraMaxZoomDistance = 0
		end
	end
end)
LocalTab:AddSlider('local_thirdpersondist', {Text = 'Distance', Default = 15, Min = 1, Max = 50, Rounding = 0, Compact = false}):OnChanged(function() end)

local selfchmams = LocalTab:AddToggle('local_selfchams', {Text = 'Self Chams', Default = false,})
Toggles.local_selfchams:OnChanged(function()
    while wait() do
        if not Toggles.local_selfchams.Value then break end
        if IsAlive(localPlayer) then
            local chams = Instance.new("Highlight", localPlayer.Character)
            chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            chams.FillColor = Options.selfchams_fill.Value
            chams.FillTransparency = 0.25
            chams.OutlineColor = Options.selfchams_outline.Value
            chams.FillTransparency = 0.5
        end
    end
end)
selfchmams:AddColorPicker('selfchams_fill', {Default = C3(0, 0, 255), Title = 'Fill Color'})
selfchmams:AddColorPicker('selfchams_outline', {Default = C3(0, 0, 0), Title = 'Outline Color'})
-- // Camera Tab
print("Cam")
CamTab:AddToggle('cam_fovenabled', {Text = 'Override FOV', Default = false}):OnChanged(function() end)
CamTab:AddSlider('cam_fovvalue', {Text = 'FOV', Default = 70, Min = 60, Max = 120, Rounding = 0, Compact = false}):OnChanged(function() end)
CamTab:AddToggle('cam_sway', {Text = 'Disable Weapon Swaying', Default = false}):OnChanged(function() end)
CamTab:AddToggle('cam_forcecross', {Text = 'Force Crosshair', Default = false}):OnChanged(function() end)
CamTab:AddToggle('cam_flash', {Text = 'Remove Flash', Default = false})
Toggles.cam_flash:OnChanged(function()
    if Toggles.cam_flash.Value == true then
        localPlayer.PlayerGui.Blnd.Enabled = false
    elseif Toggles.cam_flash.Value == false then
        localPlayer.PlayerGui.Blnd.Enabled = true
    end
end)
CamTab:AddToggle('cam_smoke', {Text = 'Reduce Smoke', Default = false}):OnChanged(function() end)
CamTab:AddSlider('cam_smokereduce', {Text = 'Value', Default = 100, Min = 1, Max = 100, Rounding = 0, Compact = false}):OnChanged(function() end)
CamTab:AddLabel('Aura Color'):AddColorPicker('cam_smokeauracolor', {Default = C3(255, 0, 0), Title = 'Smoke Aura Color'})
-- // Viewmodel Tab

VWTab:AddToggle('vw_enabled', {Text = 'Enabled', Default = false}):OnChanged(function() end)
local vmx = VWTab:AddSlider('vw_x', {Text = 'X', Default = 0, Min = -180, Max = 180, Rounding = 0, Compact = false}):OnChanged(function() end)
local vmy = VWTab:AddSlider('vw_y', {Text = 'Y', Default = 0, Min = -180, Max = 180, Rounding = 0, Compact = false}):OnChanged(function() end)
local vmz = VWTab:AddSlider('vw_z', {Text = 'Z', Default = 0, Min = -180, Max = 180, Rounding = 0, Compact = false}):OnChanged(function() end)
local vmroll = VWTab:AddSlider('vw_roll', {Text = 'Roll', Default = 180, Min = 0, Max = 360, Rounding = 0, Compact = false}):OnChanged(function() end)
VWTab:AddButton('Reset Values', function() 
    vmx:SetValue(0)
    vmy:SetValue(0)
    vmz:SetValue(0)
    vmroll:SetValue(180)
end)
-- // World Tab
print("world")
local ambienttog = WRLTab:AddToggle('wrl_ambient', {Text = 'Ambience', Default = false})
ambienttog:AddColorPicker('wrl_ambient1', {Default = C3(75, 58, 222), Title = 'Ambient'})
ambienttog:AddColorPicker('wrl_ambient2', {Default = C3(109, 58, 206), Title = 'Outdoor'})

WRLTab:AddToggle('wrl_shadows', {Text = 'Shadow Map', Default = false}):OnChanged(function(val)
  --  sethiddenproperty(lighting, "Technology", val and "ShadowMap" or "Legacy")
end)

WRLTab:AddToggle('wrl_forcetime', {Text = 'Force Time', Default = false}):OnChanged(function() end)
WRLTab:AddSlider('wrl_forcetimevalue', {Text = 'Time', Default = 12, Min = 0, Max = 24, Rounding = 0, Compact = false}):OnChanged(function() end)

WRLTab:AddToggle('wrl_saturation', {Text = 'Saturation', Default = false}):OnChanged(function(val)
    if val == true then
        saturationeffect.Enabled = true
    elseif val == false then
        saturationeffect.Enabled = false
    end
end)
WRLTab:AddSlider('wrl_saturationvalue', {Text = 'Value', Default = 0, Min = 0, Max = 1, Rounding = 2, Compact = false}):OnChanged(function(val)
    saturationeffect.Saturation = val
end)

WRLTab:AddToggle('wrl_skyboxenabled', {Text = 'Skybox', Default = false}):OnChanged(function() end)
WRLTab:AddDropdown('wrl_skyboxtype', {Values = {"Galaxy","Pink Sky","Sunset","Night","Evening"}, Default = 1, Multi = false, Text = 'Selected'})
Options.wrl_skyboxtype:OnChanged(function()
    if Toggles.wrl_skyboxenabled.Value == true then
        local pepsisky = lighting:FindFirstChild("pepsisky") or Instance.new("Sky")
        pepsisky.Parent = game.Lighting
        pepsisky.Name = "pepsisky"
        pepsisky.SkyboxBk = SkyboxesTable[Options.wrl_skyboxtype.Value].SkyboxBk
        pepsisky.SkyboxDn = SkyboxesTable[Options.wrl_skyboxtype.Value].SkyboxDn
        pepsisky.SkyboxFt = SkyboxesTable[Options.wrl_skyboxtype.Value].SkyboxFt
        pepsisky.SkyboxLf = SkyboxesTable[Options.wrl_skyboxtype.Value].SkyboxLf
        pepsisky.SkyboxRt = SkyboxesTable[Options.wrl_skyboxtype.Value].SkyboxRt
        pepsisky.SkyboxUp = SkyboxesTable[Options.wrl_skyboxtype.Value].SkyboxUp
    else
        if game.Lighting:FindFirstChild("pepsisky") then
            game.Lighting.pepsisky:Destroy()
        end
    end
end)

local mespbombtog = MiscESPTab:AddToggle('mesp_bomb', {Text = 'Bomb', Default = false})
mespbombtog:AddColorPicker('mesp_bombcolor', {Default = C3(255, 0, 0), Title = 'Color'})

local mespweapontog = MiscESPTab:AddToggle('mesp_weapons', {Text = 'Weapon', Default = false})
mespweapontog:AddColorPicker('mesp_weaponscolor', {Default = C3(88, 124, 220), Title = 'Color'})
-- // Visuals Misc Tab
print("visual misc")

MiscTab:AddToggle('misc_molly', {Text = 'Visualize Molly Radius', Default = false}):OnChanged(function(val)
    if val == true then 
        for i, molly in pairs(rayignore:FindFirstChild("Fires"):GetChildren()) do 
            molly.Transparency = 0
            molly.Color = Options.misc_mollycolor.Value
        end 
    else 
        for i, molly in pairs(rayignore:FindFirstChild("Fires"):GetChildren()) do 
            molly.Transparency = 1 
        end 
    end
end)
MiscTab:AddLabel('Color'):AddColorPicker('misc_mollycolor', {Default = C3(255, 0, 0), Title = 'Molly Color'})

local blurvalue = 50
local lv = Vector3.zero
MiscTab:AddToggle('misc_motionenabled', {Text = 'Motion Blur', Default = false}):OnChanged(function(val)
    Blur.Enabled = val
end)
MiscTab:AddSlider('misc_motionvalue', {Text = 'Size', Default = 50, Min = 1, Max = 100, Rounding = 0, Compact = false}):OnChanged(function(val)
    blurvalue = val
end)
-- // Self Chams Arms Tab
print("self chams")

ArmsTab:AddToggle('arms_chams', {Text = 'Enabled', Default = false})
local armschamstog = ArmsTab:AddToggle('arms_armschams', {Text = 'Arms Chams', Default = false})
armschamstog:AddColorPicker('arms_armschamscolor', {Default = C3(255, 0, 0), Title = 'Arm Color'})
Options.arms_armschamscolor:OnChanged(function()
    retardarmschams = Options.arms_armschamscolor.Value
end)
ArmsTab:AddDropdown('arms_armschamstexture', {Values = {"Swirl","Scan","Grid","Spiral"}, Default = 1, Multi = false, Text = 'Weapon Texture'})
Options.arms_armschamstexture:OnChanged(function()
    if Options.arms_armschamstexture.Value == "Swirl" then
        armschamstexture = 414144526
    elseif Options.arms_armschamstexture.Value == "Scan" then
        armschamstexture = 10203921
    elseif Options.arms_armschamstexture.Value == "Grid" then
        armschamstexture = 2167505061
    elseif Options.arms_armschamstexture.Value == "Spiral" then
        armschamstexture = 159534680
    end
end)

local weaponchamstog = ArmsTab:AddToggle('arms_weaponchams', {Text = 'Weapon Chams', Default = false})
weaponchamstog:AddColorPicker('arms_weaponchamscolor', {Default = C3(255, 0, 0), Title = 'Arm Color'})
ArmsTab:AddDropdown('arms_weaponchamstexture', {Values = {"Swirl","Scan","Grid","Spiral"}, Default = 1, Multi = false, Text = 'Weapon Texture'})
Options.arms_weaponchamstexture:OnChanged(function()
    if Options.arms_weaponchamstexture.Value == "Swirl" then
        weaponchamstexture = 414144526
    elseif Options.arms_weaponchamstexture.Value == "Scan" then
        weaponchamstexture = 10203921
    elseif Options.arms_weaponchamstexture.Value == "Grid" then
        weaponchamstexture = 2167505061
    elseif Options.arms_weaponchamstexture.Value == "Spiral" then
        weaponchamstexture = 159534680
    end
end)

print("bullets")

BulletsTab:AddToggle('bullets_btenabled', {Text = 'Bullet Tracer', Default = false}):OnChanged(function() end)
BulletsTab:AddSlider('bullets_bttime', {Text = 'Tracers Life Time', Default = 2, Min = 1, Max = 10, Rounding = 0, Compact = false}):OnChanged(function() end)
BulletsTab:AddLabel('Tracer Color'):AddColorPicker('bullets_btcolor', {Default = C3(255, 0, 0), Title = 'Tracer Color'})
BulletsTab:AddDropdown('bullets_bttexture', {Values = {"Lightning","Laser 1","Laser 2","Energy"}, Default = 1, Multi = false, Text = 'Tracer Texture'})
Options.bullets_bttexture:OnChanged(function()
    if Options.bullets_bttexture.Value == "Lightning" then
        bullettracerstexture = 446111271
    elseif Options.bullets_bttexture.Value == "Laser 1" then
        bullettracerstexture = 7136858729
    elseif Options.bullets_bttexture.Value == "Laser 2" then
        bullettracerstexture = 6333823534
    elseif Options.bullets_bttexture.Value == "Energy" then
        bullettracerstexture = 5864341017
    end
end)

BulletsTab:AddToggle('bullets_impactenabled', {Text = 'Bullet Impact', Default = false}):OnChanged(function() end)
BulletsTab:AddLabel('Impact Color'):AddColorPicker('bullets_impactenabledcolor', {Default = C3(0, 0, 255), Title = 'Impact Color'})
BulletsTab:AddSlider('bullets_impacttime', {Text = 'Impact Life Time', Default = 3, Min = 1, Max = 10, Rounding = 0, Compact = false}):OnChanged(function() end)

BulletsTab:AddToggle('bullets_hitenabled', {Text = 'Hit Chams', Default = false}):OnChanged(function() end)
BulletsTab:AddLabel('Hit Color'):AddColorPicker('bullets_hitcolor', {Default = C3(0, 0, 255), Title = 'Hit Color'})
BulletsTab:AddSlider('bullets_hittime', {Text = 'Hit Life Time', Default = 3, Min = 1, Max = 10, Rounding = 0, Compact = false}):OnChanged(function() end)
--------------------------------------------------------------------------------------
print("_---misc")

MiscSec1:AddToggle('misc_watermark', {Text = 'Watermark', Default = false}):AddColorPicker('misc_watermarkcolor', {Default = C3(2, 103, 172), Title = 'Watermark Color'})
Options.misc_watermarkcolor:OnChanged(function()
    WatermarkColor.BackgroundColor3 = Options.misc_watermarkcolor.Value
end)

MiscSec1:AddToggle('misc_binds', {Text = 'Show Keybinds List', Default = false})
Toggles.misc_binds:OnChanged(function()
    Library.KeybindFrame.Visible = Toggles.misc_binds.Value
end)

MiscSec1:AddToggle('misc_spectlist', {Text = 'Show Spectators List', Default = false}):AddColorPicker('misc_spectlistcolor', {Default = C3(2, 103, 172), Title = 'List Color'})
Options.misc_spectlistcolor:OnChanged(function()
    SpectColor.BackgroundColor3 = Options.misc_spectlistcolor.Value
end)

MiscSec1:AddToggle('misc_killers', {Text = 'Remove Killers', Default = false})
Toggles.misc_killers:OnChanged(function()
    pcall(function()
        local Clips = workspace.Map.Clips; Clips.Name = "FAT"; Clips.Parent = nil
        local Killers = workspace.Map.Killers; Killers.Name = "FAT"; Killers.Parent = nil
        if Toggles.misc_killers.Value == true then
            for i,v in pairs(Clips:GetChildren()) do
                if v:IsA("BasePart") then
                    v:Remove()
                end
            end
            for i,v in pairs(Killers:GetChildren()) do
                if v:IsA("BasePart") then
                    v:Remove()
                end
            end
        end
        Killers.Name = "Killers"; Killers.Parent = workspace.Map
        Clips.Name = "Clips"; Clips.Parent = workspace.Map
    end)
end)

MiscSec1:AddToggle('misc_oldsounds', {Text = 'Old Gun Sounds', Default = false})

MiscSec1:AddToggle('misc_lastvk', {Text = 'Rejoin on Last VK', Default = false})
Toggles.misc_lastvk:OnChanged(function()
    if Toggles.misc_lastvk.Value == true then
        game.ReplicatedStorage.Events.SendMsg.OnClientEvent:Connect(function(message)
            local msg = string.split(message, " ")
            if game.Players:FindFirstChild(msg[1]) and msg[7] == "1" and msg[12] == game.Players.LocalPlayer.Name then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end
        end)
    end
end)

--[[MiscSec1:AddToggle('misc_spam', {Text = 'Spam Chat', Default = false})
Toggles.misc_spam:OnChanged(function()
    
end)
MiscSec1:AddDropdown('misc_spamtype', {Values = {'Ownage', 'Wow', "Skeet", "Godlike"}, Default = 1, Multi = false, Text = 'Spam Type'})
Options.misc_spamtype:OnChanged(function()
    if Options.misc_spamtype.Value == "Ownage" then
        ebsfx = 6887181639
    elseif Options.misc_spamtype.Value == "Wow" then
        ebsfx = 7872233648
    elseif Options.misc_spamtype.Value == "Skeet" then
        ebsfx = 5447626464
    elseif Options.misc_spamtype.Value == "Godlike" then
        ebsfx = 7463103082
    end
end)]]



MiscSec2:AddToggle('mov_bhop', {Text = 'Bunny Hop', Default = false})
MiscSec2:AddSlider('mov_bhopspeed', {Text = 'Bhop Speed', Default = 25, Min = 1, Max = 150, Rounding = 0, Compact = false})

local ebtog = MiscSec2:AddToggle('mov_edgebug', {Text = 'Edgebug', Default = false})
Toggles.mov_edgebug:OnChanged(function()
    ebenabled = Toggles.mov_edgebug.Value
end)

--ebtog:AddKeyPicker('mov_edgebugbind', {Default = 'E', Mode = 'Hold', SyncToggleState = true, Text = 'Edgebug', NoUI = false})
MiscSec2:AddLabel('Keybind'):AddKeyPicker('mov_edgebugbind', {Default = 'E', Mode = 'Hold', Text = 'Edgebug', NoUI = false})
Options.mov_edgebugbind:SetValue({ 'E', 'Hold' })
print("Misc2")
MiscSec2:AddToggle('mov_edgebugsound', {Text = 'Edgebug Sound', Default = false}):OnChanged(function() end)
MiscSec2:AddDropdown('eb_soundtype', {Values = {'Ownage', 'Wow', "Skeet", "Godlike"}, Default = 1, Multi = false, Text = 'Edgebug Sound'})
Options.eb_soundtype:OnChanged(function()
    if Options.eb_soundtype.Value == "Ownage" then
        ebsfx = 6887181639
    elseif Options.eb_soundtype.Value == "Wow" then
        ebsfx = 7872233648
    elseif Options.eb_soundtype.Value == "Skeet" then
        ebsfx = 5447626464
    elseif Options.eb_soundtype.Value == "Godlike" then
        ebsfx = 7463103082
    end
end)

MiscSec2:AddToggle('mov_jumpbug', {Text = 'Jumpbug', Default = false})
Toggles.mov_jumpbug:OnChanged(function()
end)
MiscSec2:AddLabel('Keybind'):AddKeyPicker('mov_jumpbugbind', {Default = 'R', Mode = 'Hold', Text = 'Edgebug', NoUI = false})
Options.mov_jumpbugbind:SetValue({ 'R', 'Hold' })

MiscSec2:AddToggle('mov_keystrokes', {Text = 'Keystrokes', Default = false})
Toggles.mov_keystrokes:AddColorPicker('mov_keystrokescolor', {Default = C3(255, 255, 255), Title = 'Keystrokes Color'})
Options.mov_keystrokescolor:OnChanged(function()
    W.TextColor3 = Options.mov_keystrokescolor.Value
    A.TextColor3 = Options.mov_keystrokescolor.Value
    S.TextColor3 = Options.mov_keystrokescolor.Value
    D.TextColor3 = Options.mov_keystrokescolor.Value
    E.TextColor3 = Options.mov_keystrokescolor.Value
    R.TextColor3 = Options.mov_keystrokescolor.Value
    Space.TextColor3 = Options.mov_keystrokescolor.Value
end)

MiscSec2:AddToggle('mov_edgebugc', {Text = 'Edgebug Counter', Default = false})
Toggles.mov_edgebugc:OnChanged(function()
    ebcounter.Visible = Toggles.mov_edgebugc.Value
end)

MiscSec2:AddToggle('mov_edgebugchat', {Text = 'Show Edgebug Message', Default = false})
Toggles.mov_edgebugchat:OnChanged(function()
    ebenabled = Toggles.mov_edgebugchat.Value
end)

MiscSec2:AddToggle('mov_graph', {Text = 'Velocity Graph', Default = false}):AddColorPicker('mov_graphcolor', {Default = C3(255, 255, 255), Title = 'Graph Color'})
Toggles.mov_graph:OnChanged(function()
    while Toggles.mov_graph.Value do wait()
        local normalY = currentCamera.ViewportSize.Y-90
        local velocity = IsAlive(localPlayer) and math.floor(math.clamp((localPlayer.Character.HumanoidRootPart.Velocity * Vec3(1,0,1)).magnitude*14.85,0,400)) or 0
        if Toggles.mov_graph.Value then
            local width = 2
            local line = Drawing.new("Line")
            table.insert(graphLines, line)
            line.From = Vec2(currentCamera.ViewportSize.X/2 + 98, lastPos)
            line.To = Vec2(currentCamera.ViewportSize.X/2 + 100, normalY - (velocity/6.5))
            line.Thickness = 1
            line.Transparency = 1
            line.Color = Color3.new(1,1,1)
            line.Visible = true
            if #graphLines > 1 then
                if #graphLines > 110 then
                    graphLines[1]:Remove()
                    table.remove(graphLines,1)
                    for i = 2,8 do
                        graphLines[i].Transparency = i/10
                    end
                    local count = 0
                    for i=110,110-6,-1 do
                        count = count + 1
                        graphLines[i].Transparency = count/10
                    end
                    graphLines[110-7].Transparency = 1
                end
                for i,v in ipairs(graphLines) do
                    v.To = v.To - Vec2(2,0)
                    v.From = v.From - Vec2(2,0)
                    v.Color = Options.mov_graphcolor.Value
                end
            end
            lastPos = line.To.Y
            VelocityCounter.Visible = true
            VelocityCounter.Text = tostring(velocity)
        end
    end
end)


MiscSec3:AddToggle('tweaks_fire', {Text = 'No Fire Damage', Default = false})
MiscSec3:AddToggle('tweaks_fall', {Text = 'No Fall Damage', Default = false})
MiscSec3:AddToggle('tweaks_cash', {Text = 'Infinite Cash', Default = false})
MiscSec3:AddToggle('tweaks_duck', {Text = 'Infinite Duck', Default = false})
MiscSec3:AddToggle('tweaks_time', {Text = 'Infinite Buy Time', Default = true})
MiscSec3:AddToggle('tweaks_buy', {Text = 'Buy Anywhere', Default = false})

MiscSec4:AddToggle('hit_hitsound', {Text = 'Hit Sound', Default = false})
MiscSec4:AddDropdown('hit_hitsoundtype', {Values = {'Bameware', 'Bell', 'Bubble', 'Pick', 'Pop', 'Rust', 'Skeet', 'Neverlose', 'Minecraft'}, Default = 1, Multi = false, Text = 'Hit Sound Type'})
Options.hit_hitsoundtype:OnChanged(function()
    if Options.hit_hitsoundtype.Value == "Bameware" then
        HitSoundType = 3124331820
    elseif Options.hit_hitsoundtype.Value == "Bell" then
        HitSoundType = 6534947240
    elseif Options.hit_hitsoundtype.Value == "Bubble" then
        HitSoundType = 6534947588
    elseif Options.hit_hitsoundtype.Value == "Pick" then
        HitSoundType = 1347140027    
    elseif Options.hit_hitsoundtype.Value == "Pop" then
        HitSoundType = 198598793
    elseif Options.hit_hitsoundtype.Value == "Rust" then
        HitSoundType = 1255040462 
    elseif Options.hit_hitsoundtype.Value == "Skeet" then
        HitSoundType = 5633695679
    elseif Options.hit_hitsoundtype.Value == "Neverlose" then
        HitSoundType = 6534948092
    elseif Options.hit_hitsoundtype.Value == "Minecraft" then
        HitSoundType = 4018616850
    end
end)

MiscSec4:AddToggle('hit_killsound', {Text = 'Kill Sound', Default = false})
MiscSec4:AddDropdown('hit_killsoundtype', {Values = {'1 Sit', 'UltraKill', 'Minecraft'}, Default = 1, Multi = false, Text = 'Kill Sound Type'})
Options.hit_hitsoundtype:OnChanged(function()
    if Options.hit_hitsoundtype.Value == "1 Sit" then
        KillSoundType = 5902468562
    elseif Options.hit_hitsoundtype.Value == "UltraKill" then
        KillSoundType = 937885646
    elseif Options.hit_hitsoundtype.Value == "Minecraft" then
        KillSoundType = 6705984236
    end
end)

MiscSec4:AddToggle('hit_hitmarker', {Text = 'Hit Marker', Default = false}):AddColorPicker('hit_hitmarkercolor', {Default = C3(255, 255, 255), Title = 'Hit Marker Color'})
MiscSec4:AddToggle('hit_killsay', {Text = 'Kill Say', Default = false})
MiscSec4:AddInput('killsay_msg', {Default = 'sit', Numeric = false, Finished = false, Text = 'Message', Placeholder = 'Message'})

MiscSec5:AddButton('Anti Blood Lag', function() 
end)

MiscSec6:AddToggle('mod_spread', {Text = 'No Spread', Default = false})
MiscSec6:AddToggle('mod_recoil', {Text = 'No Recoil', Default = false})
--------------------------------------------------------------------------------------
print("menu")
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind -- Allows you to have a custom keybind for the menu




local OthersSettings = Tabs['UI Settings']:AddRightGroupbox('Others')

OthersSettings:AddInput('uinamechange', {Default = 'pander.lua', Numeric = false, Finished = false, Text = 'Window Title', Tooltip = 'Changes window title', Placeholder = '. . .'})
Options.uinamechange:OnChanged(function()
    Window:SetWindowTitle(Options.uinamechange.Value)
end)

OthersSettings:AddDivider()

OthersSettings:AddButton('Rejoin', function() 
    local ts = game:GetService("TeleportService")
    local p = game:GetService("Players").LocalPlayer
    ts:Teleport(game.PlaceId, p)
end)

OthersSettings:AddButton('Copy Game Invite', function() 
    setclipboard("Roblox.GameLauncher.joinGameInstance("..game.PlaceId..", "..game.JobId.."')")
end)
------------------------------------ HOOK ------------------------------------
local BeamPart = Instance.new("Part", workspace)

BeamPart.Name = "BeamPart"
BeamPart.Transparency = 1

function createBeam(v1, v2)
    local colorSequence = CNew({
    ColorSequenceKeypoint.new(0, Options.bullets_btcolor.Value),
    ColorSequenceKeypoint.new(1, Options.bullets_btcolor.Value),
    })
    -- main part
    local Part = Instance.new("Part", BeamPart)
    Part.Size = Vec3(1, 1, 1)
    Part.Transparency = 1
    Part.CanCollide = false
    Part.CFrame = CFrame.new(v1)
    Part.Anchored = true
    -- attachment
    local Attachment = Instance.new("Attachment", Part)
    -- part 2
    local Part2 = Instance.new("Part", BeamPart)
    Part2.Size = Vec3(1, 1, 1)
    Part2.Transparency = 1
    Part2.CanCollide = false
    Part2.CFrame = CFrame.new(v2)
    Part2.Anchored = true
    Part2.Color = C3(255, 255, 255)
    -- another attachment
    local Attachment2 = Instance.new("Attachment", Part2)
    -- beam
    local Beam = Instance.new("Beam", Part)
    Beam.FaceCamera = true
    Beam.Color = colorSequence
    Beam.Attachment0 = Attachment
    Beam.Attachment1 = Attachment2
    Beam.LightEmission = 6
    Beam.LightInfluence = 1
    Beam.Width0 = 1
    Beam.Width1 = 0.6
    Beam.Texture = "rbxassetid://"..bullettracerstexture
    Beam.LightEmission = 1
    Beam.LightInfluence = 1
    Beam.TextureMode = Enum.TextureMode.Wrap -- wrap so length can be set by TextureLength
    Beam.TextureLength = 3 -- repeating texture is 1 stud long 
    Beam.TextureSpeed = 3
    delay(Options.bullets_bttime.Value, function()
    for i = 0.5, 1, 0.02 do
    wait()
    Beam.Transparency = NumberSequence.new(i)
    end
    Part:Destroy()
    Part2:Destroy()
    end)
end

function CreateBulletImpact(pos)
    local BulletImpacts = Instance.new("Part")
	BulletImpacts.Anchored = true
	BulletImpacts.CanCollide = false
	BulletImpacts.Material = "ForceField"
	BulletImpacts.Color = Options.bullets_impactenabledcolor.Value
	BulletImpacts.Size = Vec3(0.25, 0.25, 0.25)
	BulletImpacts.Position = pos
	BulletImpacts.Name = "BulletImpacts"
	BulletImpacts.Parent = currentCamera
	wait(Options.bullets_impacttime.Value)
	BulletImpacts:Destroy()
end
-- Function support checks
local getrawmetatable_supported = pcall(getrawmetatable)
local hookmetamethod_supported = pcall(hookmetamethod)
local setreadonly_supported = pcall(setreadonly)
local hookfunc_supported = pcall(hookfunc)
local getnamecallmethod_supported = pcall(getnamecallmethod)
local checkcaller_supported = pcall(checkcaller)
local getrenv_supported = pcall(getrenv)
local newcclosure_supported = pcall(newcclosure)

-- Print supported and not supported functions
print("Supported:")
if getrawmetatable_supported then print("- getrawmetatable") else print("Not Supported: - getrawmetatable") end
if hookmetamethod_supported then print("- hookmetamethod") else print("Not Supported: - hookmetamethod") end
if setreadonly_supported then print("- setreadonly") else print("Not Supported: - setreadonly") end
if hookfunc_supported then print("- hookfunc") else print("Not Supported: - hookfunc") end
if getnamecallmethod_supported then print("- getnamecallmethod") else print("Not Supported: - getnamecallmethod") end
if checkcaller_supported then print("- checkcaller") else print("Not Supported: - checkcaller") end
if getrenv_supported then print("- getrenv") else print("Not Supported: - getrenv") end
if newcclosure_supported then print("- newcclosure") else print("Not Supported: - newcclosure") end

if getrawmetatable_supported then
    local meta = getrawmetatable(game)
    local oldNameCall = meta.__namecall
    local oldNewindex = meta.__newindex
    local oldIndex = meta.__index

    if hookfunc_supported and getrenv_supported then
        hookfunc(getrenv().xpcall, function() end)
    end

    if setreadonly_supported then
        setreadonly(meta, false)
    end

    if hookfunc_supported and getnamecallmethod_supported then
        newindex = hookfunction(meta.__newindex, function(self, idx, val)
            local method = getnamecallmethod()
            if self.Name == "Crosshair" and idx == "Visible" and val == false and localPlayer.PlayerGui.GUI.Crosshairs.Scope.Visible == false and Toggles.cam_forcecross.Value == true then
                val = true
            end
            return newindex(self, idx, val)
        end)
    end

    if newcclosure_supported then
        meta.__index = newcclosure(function(self, key)
            if key == "Value" then
                if Toggles.tweaks_time.Value and self.Name == "BuyTime" then
                    return 5
                end
            end
            return oldIndex(self, key)
        end)
    end

    if newcclosure_supported then
        print('WE SUPPORT!!!')
        getrawmetatable(game).__namecall = newcclosure(function(self, ...)
            print("func")
            local args = {...}
            
            if getnamecallmethod_supported and getnamecallmethod() == "SetPrimaryPartCFrame" then
                if self.Name == "Arms" and Toggles.vw_enabled.Value then
                    local vwarg = args[1]
                    vwarg = vwarg * CFrame.new(Vector3.new(math.rad(Options.vw_x.Value-180),math.rad(Options.vw_y.Value-180),math.rad(Options.vw_z.Value-180))) * CFrame.Angles(0, 0, math.rad(Options.vw_roll.Value-180))
                    return oldNameCall(self, vwarg, select(2, ...))
                end
            end
            if not checkcaller_supported or not checkcaller() then
                if getnamecallmethod_supported and getnamecallmethod() == "FindPartOnRayWithWhitelist" and cbClient.gun ~= "none" and cbClient.gun.Name ~= "C4" then 
                    if #args[2] == 1 and args[2][1].Name == "SpawnPoints" then 
                        local Team = localPlayer.Status.Team.Value 
                        if Toggles.tweaks_buy.Value then
                            return Team == "T" and args[2][1].BuyArea or args[2][1].BuyArea2 
                        end
                    end
                end
                if self.Name == "BURNME" and Toggles.tweaks_fire.Value then
                    print("BURNME")
                    return
                elseif self.Name == "FallDamage" and Toggles.tweaks_fall.Value then
                    print('FALLDAMAGE')
                    return
                elseif getnamecallmethod_supported and getnamecallmethod() == "FireServer" and self.Name == "HitPart" then
                    spawn(function()
                        if Toggles.bullets_btenabled.Value and localPlayer.Character and currentCamera:FindFirstChild("Arms") then
                            local gunflash = currentCamera.Arms:FindFirstChild("Flash")
                            if gunflash then
                                wait()
                                createBeam(currentCamera.Arms:FindFirstChild("Flash").Position, mouse.Hit.p)
                            end
                        end
                        if Toggles.bullets_hitenabled.Value then
                            coroutine.wrap(function()
                                if players:GetPlayerFromCharacter(args[1].Parent) and players:GetPlayerFromCharacter(args[1].Parent).Team ~= localPlayer.Team then
                                    for _,hitbox in pairs(args[1].Parent:GetChildren()) do
                                        if hitbox:IsA("BasePart") or hitbox.Name == "Head" then
                                            coroutine.wrap(function()
                                                local part = Instance.new("Part")
                                                part.CFrame = hitbox.CFrame
                                                part.Anchored = true
                                                part.CanCollide = false
                                                part.Material = Enum.Material.ForceField
                                                part.Color = Options.bullets_hitcolor.Value
                                                part.Size = hitbox.Size
                                                part.Parent = workspace.Debris
                                                wait(Options.bullets_hittime.Value)
                                                part:Destroy()
                                            end)()
                                        end
                                    end
                                end
                            end)()
                        end
                        if Toggles.bullets_impactenabled.Value then
                            CreateBulletImpact(mouse.Hit.p)
                        end
                    end)
                end
            end
            return oldNameCall(self, ...)
        end)
    end

    if hookmetamethod_supported and newcclosure_supported then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
            local Method = getnamecallmethod_supported and getnamecallmethod()
            local Arguments = {...}
            local self = Arguments[1]
            local chance = CalculateChance(SilentAimSettings.HitChance)
            if Toggles.aim_Enabled.Value and self == workspace and (not checkcaller_supported or not checkcaller()) and chance == true then
                if Method == "FindPartOnRayWithIgnoreList" and SilentAimSettings.SilentAimMethod == Method then
                    if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithIgnoreList) then
                        local A_Ray = Arguments[2]

                        local HitPart = getClosestPlayer()
                        if HitPart then
                            local Origin = A_Ray.Origin
                            local Direction = getDirection(Origin, HitPart.Position)
                            Arguments[2] = Ray.new(Origin, Direction)

                            return oldNamecall(unpack(Arguments))
                        end
                    end
                end
            end
            return oldNamecall(...)
        end))
    end

    if setreadonly_supported then
        setreadonly(meta, true)
    end
end

------------------------------------ MAIN FUNC ------------------------------------
currentCamera.ChildAdded:Connect(function(new)
spawn(function()
	if new.Name == "Arms" and new:IsA("Model") and Toggles.arms_chams.Value == true then
		for i,v in pairs(new:GetChildren()) do
			if v:IsA("Model") and v:FindFirstChild("Right Arm") or v:FindFirstChild("Left Arm") then
				local RightArm = v:FindFirstChild("Right Arm") or nil
				local LeftArm = v:FindFirstChild("Left Arm") or nil
					
				local RightGlove = (RightArm and (RightArm:FindFirstChild("Glove") or RightArm:FindFirstChild("RGlove"))) or nil
				local LeftGlove = (LeftArm and (LeftArm:FindFirstChild("Glove") or LeftArm:FindFirstChild("LGlove"))) or nil
					
				local RightSleeve = RightArm and RightArm:FindFirstChild("Sleeve") or nil
				local LeftSleeve = LeftArm and LeftArm:FindFirstChild("Sleeve") or nil
				
				if Toggles.arms_armschams.Value == true then
					if RightArm ~= nil then
						RightArm.Mesh.TextureId = 'rbxassetid://'..armschamstexture
						RightArm.Transparency = 0
						RightArm.Color = retardarmschams
						RightArm.Material = 'ForceField'
					end
					if LeftArm ~= nil then
						LeftArm.Mesh.TextureId = 'rbxassetid://'..armschamstexture
						LeftArm.Transparency = 0
						LeftArm.Color = retardarmschams
						LeftArm.Material = 'ForceField'
					end
				end
				
				if Toggles.arms_armschams.Value == true then
					if RightGlove ~= nil then
						RightGlove.Mesh.TextureId = 'rbxassetid://'..armschamstexture
						RightGlove.Transparency = 0
						RightGlove.Color = retardarmschams
						RightGlove.Material = 'ForceField'
					end
					if LeftGlove ~= nil then
						LeftGlove.Mesh.TextureId = 'rbxassetid://'..armschamstexture
						LeftGlove.Transparency = 0
						LeftGlove.Color = retardarmschams
						LeftGlove.Material = 'ForceField'
					end
				end

				if Toggles.arms_armschams.Value == true then
					if RightSleeve ~= nil then
						RightSleeve.Mesh.TextureId = 'rbxassetid://'..armschamstexture
						RightSleeve.Transparency = 0
						RightSleeve.Color = retardarmschams
						RightSleeve.Material = "ForceField"
						RightSleeve.Material = 'ForceField'
					end
					if LeftSleeve ~= nil then
						LeftSleeve.Mesh.TextureId = 'rbxassetid://'..armschamstexture
						LeftSleeve.Transparency = 0
						LeftSleeve.Color = retardarmschams
						LeftSleeve.Material = "ForceField"
					end
				end
			elseif Toggles.arms_weaponchams.Value == true and v:IsA("BasePart") and not table.find({"Right Arm", "Left Arm", "Flash"}, v.Name) and v.Transparency ~= 1 then
				if v:IsA("MeshPart") then v.TextureID = 'rbxassetid://'..weaponchamstexture end
				if v:FindFirstChildOfClass("SpecialMesh") then v:FindFirstChildOfClass("SpecialMesh").TextureId = 'rbxassetid://'..weaponchamstexture end

				v.Transparency = 0
				v.Color = Options.arms_weaponchamscolor.Value
				v.Material = "ForceField"
			end
		end
	end
end)
end)

workspace.Debris.ChildAdded:Connect(function(child)
    if child:IsA("BasePart") and game.ReplicatedStorage.Weapons:FindFirstChild(child.Name) and Toggles.mesp_weapons.Value == true then
        wait()
        
        local BillboardGui = Instance.new("BillboardGui")
        BillboardGui.Parent = child
        BillboardGui.Adornee = child
        BillboardGui.Active = true
        BillboardGui.AlwaysOnTop = true
        BillboardGui.LightInfluence = 1
        BillboardGui.Size = UDim2.new(0, 50, 0, 50)
            
        local TextLabelText = Instance.new("TextLabel")
		TextLabelText.Parent = BillboardGui
		TextLabelText.ZIndex = 2
		TextLabelText.BackgroundTransparency = 1
		TextLabelText.Size = UDim2.new(1, 0, 1, 0)
		TextLabelText.Font = Enum.Font.Code
		TextLabelText.TextColor3 = Options.mesp_weaponscolor.Value
		TextLabelText.TextStrokeTransparency = 0
		TextLabelText.TextSize = 14
		TextLabelText.TextYAlignment = Enum.TextYAlignment.Top
		TextLabelText.Text = "["..tostring(child.Name).."]"
	end
end)

workspace.ChildAdded:Connect(function(new)
    if new.Name == "C4" and new:IsA("Model") and Toggles.mesp_bomb.Value == true then
        local BombTimer = 40
        
        local BillboardGui = Instance.new("BillboardGui")
        BillboardGui.Parent = new
        BillboardGui.Adornee = new
        BillboardGui.Active = true
        BillboardGui.AlwaysOnTop = true
        BillboardGui.LightInfluence = 1
        BillboardGui.Size = UDim2.new(0, 50, 0, 50)
            
        local TextLabelText = Instance.new("TextLabel")
		TextLabelText.Parent = BillboardGui
		TextLabelText.ZIndex = 2
		TextLabelText.BackgroundTransparency = 1
		TextLabelText.Size = UDim2.new(1, 0, 1, 0)
		TextLabelText.Font = Enum.Font.Code
		TextLabelText.TextStrokeTransparency = 0
		TextLabelText.TextColor3 = Options.mesp_bombcolor.Value
		TextLabelText.TextStrokeColor3 = C3(0, 0, 0)
		TextLabelText.TextSize = 14
		TextLabelText.TextYAlignment = Enum.TextYAlignment.Top
		TextLabelText.Text = tostring(new.Name)
			
		local TextLabelBombTimer = Instance.new("TextLabel")
		TextLabelBombTimer.Parent = BillboardGui
		TextLabelBombTimer.ZIndex = 2
		TextLabelBombTimer.BackgroundTransparency = 1
		TextLabelBombTimer.Size = UDim2.new(1, 0, 1, 0)
		TextLabelBombTimer.Font = Enum.Font.Code
		TextLabelBombTimer.TextStrokeTransparency = 0
		TextLabelBombTimer.BackgroundTransparency = 1
		TextLabelBombTimer.TextColor3 = Options.mesp_bombcolor.Value
		TextLabelBombTimer.TextStrokeColor3 = C3(0, 0, 0)
		TextLabelBombTimer.TextSize = 14
		TextLabelBombTimer.TextYAlignment = Enum.TextYAlignment.Bottom
		TextLabelBombTimer.Text = tostring(BombTimer.. "/40")
			
		spawn(function()
            repeat
                wait(1)
                BombTimer = BombTimer - 1
                TextLabelBombTimer.Text = tostring(BombTimer.. "/40")
            until BombTimer == 0 or workspace.Status.RoundOver.Value == true
		end)
    end
end)

localPlayer.Status.Kills.Changed:Connect(function(val)
	if Toggles.hit_killsound.Value and val ~= 0 then
		local killsound = Instance.new("Sound")
		killsound.Parent = game:GetService("SoundService")
		killsound.SoundId = 'rbxassetid://'..KillSoundType
		killsound.Volume = 3
		killsound:Play()
	end
	
	if Toggles.hit_killsay.Value and val ~= 0 then
        game.ReplicatedStorage.Events.PlayerChatted:FireServer(Options.killsay_msg.Value, false, false, false, true)
    end
end)

localPlayer.Additionals.TotalDamage.Changed:Connect(function(val)
	if Toggles.hit_hitsound.Value and val ~= 0 then
		local hitsound = Instance.new("Sound")
		hitsound.Parent = game:GetService("SoundService")
		hitsound.SoundId = 'rbxassetid://'..HitSoundType
		hitsound.Volume = 3
		hitsound:Play()
	end

	if current == 0 then return end
	coroutine.wrap(function()
		if Toggles.hit_hitmarker.Value then
			local Line = Drawing.new("Line")
			local Line2 = Drawing.new("Line")
			local Line3 = Drawing.new("Line")
			local Line4 = Drawing.new("Line")

			local x, y = currentCamera.ViewportSize.X/2, currentCamera.ViewportSize.Y/2

			Line.From = Vec2(x + 4, y + 4)
			Line.To = Vec2(x + 10, y + 10)
			Line.Color = Options.hit_hitmarkercolor.Value
			Line.Visible = true 

			Line2.From = Vec2(x + 4, y - 4)
			Line2.To = Vec2(x + 10, y - 10)
			Line2.Color = Options.hit_hitmarkercolor.Value
			Line2.Visible = true 

			Line3.From = Vec2(x - 4, y - 4)
			Line3.To = Vec2(x - 10, y - 10)
			Line3.Color = Options.hit_hitmarkercolor.Value
			Line3.Visible = true 

			Line4.From = Vec2(x - 4, y + 4)
			Line4.To = Vec2(x - 10, y + 10)
			Line4.Color = Options.hit_hitmarkercolor.Value
			Line4.Visible = true

			Line.Transparency = 1
			Line2.Transparency = 1
			Line3.Transparency = 1
			Line4.Transparency = 1

			Line.Thickness = 1
			Line2.Thickness = 1
			Line3.Thickness = 1
			Line4.Thickness = 1

			wait(0.3)
			for i = 1,0,-0.1 do
				wait()
				Line.Transparency = i 
				Line2.Transparency = i
				Line3.Transparency = i
				Line4.Transparency = i
			end
			Line:Remove()
			Line2:Remove()
			Line3:Remove()
			Line4:Remove()
		end
	end)()
end)



if rayignore:FindFirstChild("Smokes") then
	for _,smoke in pairs(rayignore:FindFirstChild("Smokes"):GetChildren()) do
		smoke.Material = Enum.Material.Neon
		smoke.Transparency = 0.5
	end
    rayignore:FindFirstChild("Smokes").ChildAdded:Connect(function(smoke)
		runService.RenderStepped:Wait()
		if Toggles.cam_smoke.Value then
			smoke.ParticleEmitter.Rate = Options.cam_smokereduce.Value
		end
        smoke.Material = Enum.Material.Neon
        smoke.Transparency = 0.5
        smoke.Color = Options.cam_smokeauracolor.Value
    end)
end
rayignore.ChildAdded:Connect(function(obj) 
	if obj.Name == "Fires" then 
		obj.ChildAdded:Connect(function(fire) 
			if Toggles.misc_molly.Value then 
				fire.Transparency = 0
				fire.Color = Options.misc_mollycolor.Value
			end 
		end) 
	end 
end)

if rayignore:FindFirstChild("Fires") then
	rayignore:FindFirstChild("Fires").ChildAdded:Connect(function(fire)
		if Toggles.misc_molly.Value then
			fire.Transparency = 0
			fire.Color = Options.misc_mollycolor.Value
		end
	end)
end

for i,v in pairs(game.ReplicatedStorage.Viewmodels:GetChildren()) do
    if v:FindFirstChild("HumanoidRootPart") and v.HumanoidRootPart.Transparency ~= 1 then
        v.HumanoidRootPart.Transparency = 1
    end
end

--------------------------------------------------------------------------------------
local function Combat()
    if Toggles.as_enabled.Value then
        local pressed = userInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        
        if pressed and IsAlive(localPlayer) then
            local Line = Drawing.new("Line")
            local curTar = getClosest(currentCamera.CFrame)
            local hbpos = currentCamera:WorldToScreenPoint(curTar.Character[AimSettings.Hitbox].Position)
            hbpos = Vec2(hbpos.X, hbpos.Y)
            if (hbpos - currentCamera.ViewportSize/2).Magnitude < AimSettings.Radius then
                currentCamera.CFrame = currentCamera.CFrame:Lerp(CFrame.new(currentCamera.CFrame.Position, curTar.Character[AimSettings.Hitbox].Position), AimSettings.Smoothness)
            end
        end
    end
    if Toggles.as_fov.Value == true and Toggles.as_fovout.Value == true then
       as_fov_circleout1.Visible = true
       as_fov_circleout2.Visible = true
    else
        as_fov_circleout1.Visible = false
        as_fov_circleout2.Visible = false
    end
    as_fov_circle.Visible = Toggles.as_fov.Value
    
    if Toggles.br_fov.Value == true and Toggles.br_fovout.Value == true then
       br_fov_circleout1.Visible = true
       br_fov_circleout2.Visible = true
    else
        br_fov_circleout1.Visible = false
        br_fov_circleout2.Visible = false
    end
    br_fov_circle.Visible = Toggles.br_fov.Value
    
    
    local mousepos = Vec2(userInput:GetMouseLocation().X, userInput:GetMouseLocation().Y)
    br_fov_circleout1.Position = mousepos
    br_fov_circle.Position = mousepos
    br_fov_circleout2.Position = mousepos
    
    as_fov_circleout1.Position = mousepos
    as_fov_circle.Position = mousepos
    as_fov_circleout2.Position = mousepos
end

local function Visuals()
    if Toggles.wrl_ambient.Value then
        lighting.Ambient = Options.wrl_ambient1.Value
        lighting.OutdoorAmbient = Options.wrl_ambient2.Value
    else
        lighting.Ambient = C3(255, 255, 255)
        lighting.OutdoorAmbient = C3(255, 255, 255)
    end
    
    if Toggles.wrl_forcetime.Value then
        lighting.TimeOfDay = Options.wrl_forcetimevalue.Value
    else
        lighting.TimeOfDay = 12
    end
    
    if localPlayer.PlayerGui.GUI.Crosshairs.Scope.Visible == false then
        if Toggles.cam_fovenabled.Value then
            currentCamera.FieldOfView = Options.cam_fovvalue.Value
        else
            currentCamera.FieldOfView = 70
		end
	end
    
    local x,y,z = currentCamera.CFrame:ToEulerAnglesXYZ()
	x,y,z = math.deg(x),math.deg(y),math.deg(z)
	
	Blur.Size = math.clamp((Vec3(x,y,z)-lv).Magnitude/2,2,10 + blurvalue)
	lv = Vec3(x,y,z)
end

local function ESP()
    for i,v in pairs(esp.playerObjects) do
        if not esp.HasCharacter(i) then
            v.name.Visible = false
            v.boxOutline.Visible = false
            v.box.Visible = false
            v.boxfill.Visible = false
        end
    
        if esp.HasCharacter(i) then
            local hum = i.Character.Humanoid
            local hrp = i.Character.HumanoidRootPart
            local head = i.Character.Head

            local Vector, onScreen = currentCamera:WorldToViewportPoint(i.Character.HumanoidRootPart.Position)
    
            local Size = (currentCamera:WorldToViewportPoint(hrp.Position - Vec3(0, 3, 0)).Y - currentCamera:WorldToViewportPoint(hrp.Position + Vec3(0, 2.6, 0)).Y) / 2
            local BoxSize = Vec2(math.floor(Size * 1.5), math.floor(Size * 1.9))
            local BoxPos = Vec2(math.floor(Vector.X - Size * 1.5 / 2), math.floor(Vector.Y - Size * 1.6 / 2))
            
            local BoxFillSize = Vec2(math.floor(Size * 1.5), math.floor(Size * 1.9)) --same as box
            local BoxFillPos = Vec2(math.floor(Vector.X - Size * 1.5 / 2), math.floor(Vector.Y - Size * 1.6 / 2)) -- this 1 too
    
            local BottomOffset = BoxSize.Y + BoxPos.Y + 1

            if onScreen and esp.enabled then
                if esp.settings.name.enabled then
                    v.name.Position = Vec2(BoxSize.X / 2 + BoxPos.X, BoxPos.Y - 16)
                    v.name.Outline = esp.settings.name.outline
                    v.name.Color = esp.settings.name.color

                    v.name.Font = esp.font
                    v.name.Size = esp.fontsize

                    if esp.settings.name.displaynames then
                        v.name.Text = tostring(i.DisplayName)
                    else
                        v.name.Text = tostring(i.Name)
                    end

                    v.name.Visible = true
                else
                    v.name.Visible = false
                end

                if esp.settings.distance.enabled and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    v.distance.Position = Vec2(BoxSize.X / 2 + BoxPos.X, BottomOffset)
                    v.distance.Outline = esp.settings.distance.outline
                    v.distance.Text = "[ " .. math.floor((hrp.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude) .. " studs]"
                    v.distance.Color = esp.settings.distance.color
                    BottomOffset = BottomOffset + 15

                    v.distance.Font = esp.font
                    v.distance.Size = esp.fontsize

                    v.distance.Visible = true
                else
                    v.distance.Visible = false
                end

                if esp.settings.box.enabled then
                    v.boxOutline.Size = BoxSize
                    v.boxOutline.Position = BoxPos
                    v.boxOutline.Visible = esp.settings.box.outline
    
                    v.box.Size = BoxSize
                    v.box.Position = BoxPos
                    v.box.Color = esp.settings.box.color
                    v.box.Visible = true
                else
                    v.boxOutline.Visible = false
                    v.box.Visible = false
                end
                
                if esp.settings.boxfill.enabled then
                    v.boxfill.Position = BoxFillPos
                    v.boxfill.Size = BoxFillSize
                    v.boxfill.Visible = esp.settings.boxfill.enabled
                    v.boxfill.Filled = true
                    v.boxfill.Color = esp.settings.boxfill.color
                    v.boxfill.Transparency = esp.settings.boxfill.transparency
                else
                    v.boxfill.Visible = false
                    v.boxfill.Filled = false
                end

                if esp.settings.healthbar.enabled then
                    v.healthBar.From = Vec2((BoxPos.X - 5), BoxPos.Y + BoxSize.Y)
                    v.healthBar.To = Vec2(v.healthBar.From.X, v.healthBar.From.Y - (hum.Health / hum.MaxHealth) * BoxSize.Y)
                    v.healthBar.Color = C3(255 - 255 / (hum["MaxHealth"] / hum["Health"]), 255 / (hum["MaxHealth"] / hum["Health"]), 0)
                    v.healthBar.Visible = true

                    v.healthBarOutline.From = Vec2(v.healthBar.From.X, BoxPos.Y + BoxSize.Y + 1)
                    v.healthBarOutline.To = Vec2(v.healthBar.From.X, (v.healthBar.From.Y - 1 * BoxSize.Y) -1)
                    v.healthBarOutline.Visible = esp.settings.healthbar.outline
                else
                    v.healthBarOutline.Visible = false
                    v.healthBar.Visible = false
                end

                if esp.settings.healthtext.enabled then
                    v.healthText.Text = tostring(math.floor((hum.Health / hum.MaxHealth) * 100 + 0.5))
                    v.healthText.Position = Vec2((BoxPos.X - 20), (BoxPos.Y + BoxSize.Y - 1 * BoxSize.Y) -1)
                    v.healthText.Color = esp.settings.healthtext.color
                    v.healthText.Outline = esp.settings.healthtext.outline

                    v.healthText.Font = esp.font
                    v.healthText.Size = esp.fontsize

                    v.healthText.Visible = true
                else
                    v.healthText.Visible = false
                end

                if esp.settings.viewangle.enabled then
                    local fromHead = currentCamera:worldToViewportPoint(head.CFrame.p)
                    local toPoint = currentCamera:worldToViewportPoint((head.CFrame + (head.CFrame.lookVector * 10)).p)
                    v.viewAngle.From = Vec2(fromHead.X, fromHead.Y)
                    v.viewAngle.To = Vec2(toPoint.X, toPoint.Y)
                    v.viewAngle.Color = esp.settings.viewangle.color
                    v.viewAngle.Visible = true
                end
                
                
                if esp.teamcheck then
                    if esp.TeamCheck(i) then
                        v.name.Visible = esp.settings.name.enabled
                        v.box.Visible = esp.settings.box.enabled
                        v.boxfill.Visible = esp.settings.boxfill.enabled
                        v.healthBar.Visible = esp.settings.healthbar.enabled
                        v.healthText.Visible = esp.settings.healthtext.enabled
                        v.distance.Visible = esp.settings.distance.enabled
                        v.viewAngle.Visible = esp.settings.viewangle.enabled
                        if ESPOutline then
                            if esp.settings.box.enabled then
                                v.boxOutline.Visible = esp.settings.box.outline
                                v.boxOutline.Visible = esp.settings.box.outline
                            end

                            if esp.settings.healthbar.enabled then
                                v.healthBarOutline.Visible = esp.settings.healthbar.outline
                            end
                        end
                    else
                        v.name.Visible = false
                        v.boxOutline.Visible = false
                        v.box.Visible = false
                        v.boxfill.Visible = false
                        v.healthBarOutline.Visible = false
                        v.healthBar.Visible = false
                        v.healthText.Visible = false
                        v.distance.Visible = false
                        v.viewAngle.Visible = false
                    end
                end
            else
                v.name.Visible = false
                v.boxOutline.Visible = false
                v.box.Visible = false
                v.boxfill.Visible = false
                v.healthBarOutline.Visible = false
                v.healthBar.Visible = false
                v.healthText.Visible = false
                v.distance.Visible = false
                v.viewAngle.Visible = false
            end
        else
            v.name.Visible = false
            v.boxOutline.Visible = false
            v.box.Visible = false
            v.boxfill.Visible = false
            v.healthBarOutline.Visible = false
            v.healthBar.Visible = false
            v.healthText.Visible = false
            v.distance.Visible = false
            v.viewAngle.Visible = false
        end
    end
end


function Movement()
    if Toggles.mov_bhop.Value then
        if localPlayer.PlayerGui.GUI.Main.GlobalChat.Visible == false then
            if IsAlive(localPlayer) and userInput:IsKeyDown(Enum.KeyCode.Space) then
                localPlayer.Character.Humanoid.Jump = true
                local speed = Options.mov_bhopspeed.Value
                local dir = currentCamera.CFrame.LookVector * Vec3(1,0,1)
                local move = Vec3()
                move = userInput:IsKeyDown(Enum.KeyCode.W) and move + dir or move
                move = userInput:IsKeyDown(Enum.KeyCode.S) and move - dir or move
                move = userInput:IsKeyDown(Enum.KeyCode.D) and move + Vec3(-dir.Z,0,dir.X) or move
                move = userInput:IsKeyDown(Enum.KeyCode.A) and move + Vec3(dir.Z,0,-dir.X) or move
                if move.Unit.X == move.Unit.X then
                    move = move.Unit
                    localPlayer.Character.HumanoidRootPart.Velocity = Vec3(move.X * speed, localPlayer.Character.HumanoidRootPart.Velocity.Y, move.Z * speed)
                end
            end
        end
    end
    
    if IsAlive(localPlayer) then
        local currentState = localPlayer.Character.Humanoid:GetState()
        --hookJp = Toggles.mov_jumpbug.Value and isButtonDown(Enum.KeyCode[Options.mov_jumpbugbind.Value])
        if currentState == Enum.HumanoidStateType.Landed and userInput:IsKeyDown(Enum.KeyCode.Space) and Toggles.mov_bhop.Value then
            localPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        
        if Toggles.mov_edgebug.Value and not ebCooldown and isButtonDown(Enum.KeyCode[Options.mov_edgebugbind.Value]) and IsAlive(localPlayer) then
            if oldState == Enum.HumanoidStateType.Freefall and currentState == Enum.HumanoidStateType.Landed then
                ebCooldown = true
                ebtxt.Visible = true
                local dir = localPlayer.Character.HumanoidRootPart.Velocity
                for i=1,5 do wait()
                    localPlayer.Character.HumanoidRootPart.Velocity = (Vec3(1.2,0,1.2) * dir) - Vec3(0,15,0)
                end
                wait()
              localPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(localPlayer.Character.HumanoidRootPart.Velocity.X * 1.8, localPlayer.Character.HumanoidRootPart.Velocity.Y * 5, localPlayer.Character.HumanoidRootPart.Velocity.Z * 1.8)
 -- Vec3(1.8,1,1.8)
                spawn(function()
                    if Toggles.mov_edgebugsound.Value == true then
                        local ebsound = Instance.new("Sound")
                        ebsound.Parent = game:GetService("SoundService")
                        ebsound.SoundId = "rbxassetid://"..ebsfx
                        ebsound.Volume = 3
                        ebsound:Play()
                    else
                        print("no")
                    end
                    
                    if Toggles.mov_edgebugchat.Value == true then
                    --   getsenv(localPlayer.PlayerGui.GUI.Main.Chats.DisplayChat).moveOldMessages()
                        --[[getsenv(localPlayer.PlayerGui.GUI.Main.Chats.DisplayChat).createNewMessage(
                            "pander.lua",
                            "edgebugged",
                            C3(2, 103, 172), 
                            Color3.new(1,1,1),
                            .01)]]
                    end
                    
                    ebcount = ebcount + 1
                    ebcounter.Text = "eb: "..ebcount..""
                    wait(0.075)
                    ebCooldown = false
                    ebtxt.Visible = false
                end)
                print(ebCooldown)
            end
        end
        oldState = currentState
    end
    
    if not Toggles.mov_graph.Value then
        for i,v in ipairs(graphLines) do
            v:Remove()
            table.remove(graphLines, i)
        end
        VelocityCounter.Visible = false
    end
    keystrokesGui.Enabled = Toggles.mov_keystrokes.Value
end

local function Misc()
    watermark.Enabled = Toggles.misc_watermark.Value
    SpectatorViewer.Enabled = Toggles.misc_spectlist.Value
    
    if Toggles.misc_oldsounds.Value then
        pcall(function()
            if localPlayer.Character.EquippedTool.Value == "AK47" then
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://1112730119"
            end
            if localPlayer.Character.EquippedTool.Value == "M4A1" then
                localPlayer.Character.Gun.SShoot.SoundId = "rbxassetid://1665639883"
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://2515498997"
            end
            if localPlayer.Character.EquippedTool.Value == "Glock" then
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://1112951656"
            end
            if localPlayer.Character.EquippedTool.Value == "Galil" then
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://344800912"
            end
            if localPlayer.Character.EquippedTool.Value == "USP" then
                localPlayer.Character.Gun.SShoot.SoundId = "rbxassetid://1112952739"
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://2515499360"
            end
            if localPlayer.Character.EquippedTool.Value == "P2000" then
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://263589107"
            end
            if  localPlayer.Character.EquippedTool.Value == "P250" then
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://340365431"
            end
            if localPlayer.Character.EquippedTool.Value == "DesertEagle" then
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://202918645"
            end
            if localPlayer.Character.EquippedTool.Value == "MP9" then
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://222888810"
            end
            if localPlayer.Character.EquippedTool.Value == "UMP" then
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://206953341"
            end
            if localPlayer.Character.EquippedTool.Value == "Famas" then
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://206953280"
            end
            if localPlayer.Character.EquippedTool.Value == "Scout" then
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://1112858108"
            end
            if localPlayer.Character.EquippedTool.Value == "AUG" then
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://515215839"
            end
            if localPlayer.Character.EquippedTool.Value == "AWP" then
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://202918637"
            end
            if localPlayer.Character.EquippedTool.Value == "G3SG1" then
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://340365815"
            end
            if localPlayer.Character.EquippedTool.Value == "SG" then
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://347270113"
            end
            if localPlayer.Character.EquippedTool.Value == "M4A4" then
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://202918741"
            end
            if localPlayer.Character.EquippedTool.Value == "Tec9" then
                localPlayer.Character.Gun.Shoot.SoundId = "rbxassetid://206953317"
            end
        end)
    end
print("here1")
    if Toggles.mod_recoil.Value then
        print("CH1 R")
        if getsenv2 == true then
            print("Pass r")

        cbClient.RecoilX = 0;
        cbClient.RecoilY = 0
    end
end
    if Toggles.tweaks_duck.Value then
        if getsenv2 == true then
        if cbClient.crouchcooldown ~= 0 then
            cbClient.crouchcooldown = 0.7
        end
    end
end
    if Toggles.mod_spread.Value then
        if getsenv2 == true then
        cbClient.accuracy_sd = 0.000
    end
end
    localPlayer.Cash.Value = Toggles.tweaks_cash.Value and 99999 or localPlayer.Cash.Value
end

runService.RenderStepped:Connect(function()
    do Combat() end
    do Visuals() end
    do ESP() end
    do Movement() end
    do Misc() end
end)

Library:Notify('Finished Loading! Welcome ' ..localPlayer.Name.. ' to pander.lua!');
Library:Notify("Took to load "..string.format("%.5f", tick() - LoadingTime).." seconds.");
