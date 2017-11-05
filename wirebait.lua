
--[[
    WireBait for Wireshark is a lua package to help write Wireshark 
    Dissectors in lua
    Copyright (C) 2015-2017 Markus Leballeux

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
]]

--dofile("./Wirebait/wireshark_mock.lua")
local wireshark = require("Wirebait.wireshark_mock")


-- # Wirebait Tree
local function newWirebaitTree(wireshark_tree, buffer, position, parent)
    print("WS TREE ITEM is at: " .. tostring(wireshark_tree))
    local wirebait_tree = {
        m_wireshark_tree = wireshark_tree;
        m_buffer = buffer;
        m_start_position = position or 0;
        m_position = position or 0;
        m_end_position = (position or 0) + buffer:len();
        m_parent = parent;
        m_is_root = not parent;
    }
    
    local getParent = function(self)
        return wirebait_tree.m_parent or self;
    end
    
    local getWiresharkTree = function ()
        return wirebait_tree.m_wireshark_tree;
    end
    
    local getBuffer = function()
        return wirebait_tree.m_buffer;
    end

    local getPosition = function()
        return wirebait_tree.m_position;
    end

    local skip = function(self, byte_count)
        if not wirebait_tree.m_is_root then
            self:parent():skip(byte_count);
        end
        assert(wirebait_tree.m_position + byte_count <= wirebait_tree.m_end_position , "Trying to skip more bytes than available in buffer managed by wirebait tree!")
        wirebait_tree.m_position = wirebait_tree.m_position + byte_count;
    end
    
    local setLength = function(self, L)
        print("Setting length to " .. L);
        wirebait_tree.m_wireshark_tree:set_len(L);
    end
    
    local autoFitHighlight = function(self, is_recursive) --makes highlighting fit the data that was added or skipped in the tree
        position =  self:position();
        --print(position);
        assert(position > wirebait_tree.m_start_position, "Current position is before start position!");
        length = position - wirebait_tree.m_start_position
        --print("Length for " .. tostring(self) .. " is " .. length .. " bytes.");
        setLength(self,length);
        if is_recursive and not wirebait_tree.m_is_root then
            print("-----> recursive call")
            self:parent():autoFitHighlight(is_recursive);
        end
        
    end



    local addField = function (self, wirebait_field)

    end

    local addTree = function (self, length)
        sub_ws_tree = wirebait_tree.m_wireshark_tree:add(self.m_position, length or 1);

        --newWireBaitTree()
    end

    local public_interface = {
        __is_wirebait_struct = true, --all wirebait data should have this flag so as to know their type
        __wirebait_type_name = "WirebaitTree",
        __buffer = getBuffer,
        parent = getParent,
        wiresharkTree = getWiresharkTree,
        position = getPosition,
        length = getLength,
        skip = skip,
        autoFitHighlight = autoFitHighlight
    }
    
    --print("Public address: " .. tostring(public_interface));
    return public_interface;
end


local function newWirebaitTree_overload(arg1, arg2, ...)
    --for i in pairs(arg1) do print(i) end
    if arg1.__is_wirebait_struct then
        wirebait_tree = arg1;
        ws_tree_item = arg2;
        return newWirebaitTree(ws_tree_item or wirebait_tree.wiresharkTree(),wirebait_tree.__buffer(), wirebait_tree.position(), wirebait_tree)
    else
        return newWirebaitTree(arg1, arg2, unpack({...}));
    end
end


-- # Wirebait Field
local function newWirebaitField()
    local wirebait_field = {
        m_wireshark_field,
        m_name,
        m_size
    }

    local getName = function()
        return wirebait_field.m_name;
    end

    local getSize = function()
        return wirebait_field.m_size
    end


    return {
        name = getName(),
        size = getSize()
    };
end



--All functions available in wirebait package are named here
wirebait = {
    field = {
        new = newWirebaitField
    },
    tree = {
        new = newWirebaitTree_overload
    }
}






--TEST
local buffer = {
    len = function()
        return 512;
    end
    
    
}

--local ws_test_tree = {
--        len = function ()
--            return 10;
--        end
--    }

--print(ws_test_tree:len())

ws_root_tree_item = wireshark.treeitem.new();
ws_child_tree_item = wireshark.treeitem.new();
ws_child_tree_item2 = wireshark.treeitem.new();

root_tree = wirebait.tree.new(ws_root_tree_item, buffer, 0);
print("root address " .. tostring(root_tree) .. " parent " .. tostring(root_tree:parent()))

--print("parent of root tree: " .. tostring(root_tree.parent()))

--print("old position " .. root_tree:position())
root_tree:skip(1)

child_tree_1 = wirebait.tree.new(root_tree, ws_child_tree_item)
--print("child address " .. tostring(child_tree) .. "\n")

print("old position root: " .. root_tree:position() .. " child " .. child_tree_1:position())

--child_tree.parent();
child_tree_1:skip(3)
print("old position root: " .. root_tree:position() .. " child " .. child_tree_1:position())
--root_tree:skip(4)
print("old position root: " .. root_tree:position() .. " child " .. child_tree_1:position())
child_tree_1:skip(3)
print("old position root: " .. root_tree:position() .. " child " .. child_tree_1:position())
child_tree_1:autoFitHighlight(true)

print("Length for root_tree item is " .. tostring(root_tree:wiresharkTree():get_len()) .. " bytes. tree item is at " .. tostring(root_tree:wiresharkTree()));
print("Length for child_tree item is " .. tostring(child_tree_1:wiresharkTree():get_len()) .. " bytes. tree item is at " .. tostring(child_tree_1:wiresharkTree()));


child_tree_2 = wirebait.tree.new(root_tree, ws_child_tree_item2)
--print("child address " .. tostring(child_tree) .. "\n")
child_tree_2:skip(11);

print("old position root: " .. root_tree:position() .. " child2 " .. child_tree_2:position())
print("Length for root_tree item is " .. tostring(root_tree:wiresharkTree():get_len()) .. " bytes. tree item is at " .. tostring(root_tree:wiresharkTree()));
print("Length for child_tree item is " .. tostring(child_tree_1:wiresharkTree():get_len()) .. " bytes. tree item is at " .. tostring(child_tree_1:wiresharkTree()));
print("Length for child_tree2 item is " .. tostring(child_tree_2:wiresharkTree():get_len()) .. " bytes. tree item is at " .. tostring(child_tree_2:wiresharkTree()));
child_tree_2:autoFitHighlight(false)
print("Length for root_tree item is " .. tostring(root_tree:wiresharkTree():get_len()) .. " bytes. tree item is at " .. tostring(root_tree:wiresharkTree()));
print("Length for child_tree item is " .. tostring(child_tree_1:wiresharkTree():get_len()) .. " bytes. tree item is at " .. tostring(child_tree_1:wiresharkTree()));
print("Length for child_tree2 item is " .. tostring(child_tree_2:wiresharkTree():get_len()) .. " bytes. tree item is at " .. tostring(child_tree_2:wiresharkTree()));
child_tree_2:autoFitHighlight(true)
print("Length for root_tree item is " .. tostring(root_tree:wiresharkTree():get_len()) .. " bytes. tree item is at " .. tostring(root_tree:wiresharkTree()));
print("Length for child_tree item is " .. tostring(child_tree_1:wiresharkTree():get_len()) .. " bytes. tree item is at " .. tostring(child_tree_1:wiresharkTree()));
print("Length for child_tree2 item is " .. tostring(child_tree_2:wiresharkTree():get_len()) .. " bytes. tree item is at " .. tostring(child_tree_2:wiresharkTree()));

