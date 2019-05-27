-- Copyright (c) 2019 Bartek thindil Jasicki <thindil@laeran.pl>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

with Ada.Directories; use Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with GNAT.OS_Lib; use GNAT.OS_Lib;
with Gtk.Widget; use Gtk.Widget;
with ActivateItems; use ActivateItems;
with MainWindow; use MainWindow;
with Messages; use Messages;

package body CreateItems is

   -- ****if* CreateItems/CreateItem
   -- FUNCTION
   -- Create new file or directory or hide text entry
   -- PARAMETERS
   -- Self     - Text entry with name for new file/directory
   -- Icon_Pos - Position of text entry icon which was pressed or if key
   --            Enter was pressed, simulate pressing proper icon
   -- SOURCE
   procedure CreateItem(Self: access Gtk_Entry_Record'Class;
      Icon_Pos: Gtk_Entry_Icon_Position) is
      -- ****
      Name: constant String :=
        To_String(CurrentDirectory) & "/" & Get_Text(Self);
      File: File_Descriptor;
      ActionString, ActionBlocker: Unbounded_String;
      Success: Boolean := False;
   begin
      if Icon_Pos = Gtk_Entry_Icon_Primary then
         Set_Text(Self, "");
         Hide(Gtk_Widget(Self));
         return;
      end if;
      if Get_Text(Self) = "" then
         return;
      end if;
      if Ada.Directories.Exists(Name) or Is_Symbolic_Link(Name) then
         case NewAction is
            when CREATEDIRECTORY =>
               ActionString := To_Unbounded_String("create directory with");
            when CREATEFILE =>
               ActionString := To_Unbounded_String("create file with");
            when RENAME =>
               ActionString := To_Unbounded_String("rename with new");
            when others =>
               null;
         end case;
         if Is_Directory(Name) then
            ActionBlocker := To_Unbounded_String("directory");
         else
            ActionBlocker := To_Unbounded_String("file");
         end if;
         ShowMessage
           ("You can't " & To_String(ActionString) & " name '" & Name &
            "' because there exists " & To_String(ActionBlocker) &
            " with that name.");
         return;
      end if;
      if Is_Write_Accessible_File(Containing_Directory(Name)) then
         case NewAction is
            when CREATEDIRECTORY =>
               Create_Path(Name);
            when CREATEFILE =>
               Create_Path(Containing_Directory(Name));
               File := Create_File(Name, Binary);
               Close(File);
            when RENAME =>
               if To_String(CurrentSelected) /= Name then
                  Rename_File(To_String(CurrentSelected), Name, Success);
                  if not Success then
                     ShowMessage
                       ("Can't rename " & To_String(CurrentSelected) & ".");
                  end if;
               end if;
            when others =>
               null;
         end case;
      else
         if NewAction /= RENAME then
            ShowMessage
              ("You don't have permissions to write to " &
               Containing_Directory(Name));
         else
            ShowMessage("You don't have permissions to rename " & Name);
         end if;
         return;
      end if;
      Set_Text(Self, "");
      Hide(Gtk_Widget(Self));
      CurrentDirectory := To_Unbounded_String(Containing_Directory(Name));
      Reload(Builder);
   end CreateItem;

   procedure AddNew(User_Data: access GObject_Record'Class) is
      GEntry: constant Gtk_Widget := Gtk_Widget(Get_Object(Builder, "entry"));
   begin
      if User_Data = Get_Object(Builder, "newmenudirectory") then
         NewAction := CREATEDIRECTORY;
         Set_Icon_Tooltip_Text
           (Gtk_GEntry(GEntry), Gtk_Entry_Icon_Secondary,
            "Create new directory.");
      else
         NewAction := CREATEFILE;
         Set_Icon_Tooltip_Text
           (Gtk_GEntry(GEntry), Gtk_Entry_Icon_Secondary, "Create new file.");
      end if;
      Show_All(GEntry);
      Grab_Focus(GEntry);
   end AddNew;

   procedure IconPressed(Self: access Gtk_Entry_Record'Class;
      Icon_Pos: Gtk_Entry_Icon_Position; Event: Gdk_Event_Button) is
      pragma Unreferenced(Event);
   begin
      if NewAction /= OPENWITH then
         CreateItem(Self, Icon_Pos);
      else
         OpenItemWith(Self, Icon_Pos);
      end if;
   end IconPressed;

   procedure CreateNew(Object: access Gtkada_Builder_Record'Class) is
   begin
      if NewAction /= OPENWITH then
         CreateItem
           (Gtk_GEntry(Get_Object(Object, "entry")), Gtk_Entry_Icon_Secondary);
      else
         OpenItemWith
           (Gtk_GEntry(Get_Object(Object, "entry")), Gtk_Entry_Icon_Secondary);
      end if;
   end CreateNew;

end CreateItems;
